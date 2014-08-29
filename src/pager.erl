-module(pager).

-export([ping/0, first_value/1, run/0, run_pipe/1, send_event/2]).

-include_lib("deps/riak_pipe/include/riak_pipe.hrl").



ping() ->
    DocIdx = riak_core_util:chash_key({<<"ping">>, term_to_binary(now())}),
    PrefList = riak_core_apl:get_primary_apl(DocIdx, 1, pager),
    [{IndexNode, _Type}] = PrefList,
    riak_core_vnode_master:sync_spawn_command(IndexNode, ping, pager_vnode_master).

run() ->
    {ok, {Type, {Metrics}}} = get_metrics(),
    send_metrics(Type, Metrics).

send_metrics(Type, [{Target, Value}|T]) ->
    send_metric(Type, Target, Value),
    send_metrics(Type, T);
send_metrics(_, []) ->
    ok.

send_event(RoutingKey, Data) ->
    DocIdx = riak_core_util:chash_key({<<"metrics">>, term_to_binary(RoutingKey)}),
    PrefList = riak_core_apl:get_primary_apl(DocIdx, 1, pager),
    [{IndexNode, _Type}] = PrefList,
    Msg = {event, RoutingKey, Data},
    Resp = riak_core_vnode_master:sync_spawn_command(IndexNode, Msg, pager_vnode_master),
    io:format("send: ~p~n", [Msg]),
    io:format("Resp: ~p~n", [Resp]).


send_metric(Type, Target, Value) ->
    DocIdx = riak_core_util:chash_key({<<"metrics">>, term_to_binary(Type)}),
    PrefList = riak_core_apl:get_primary_apl(DocIdx, 1, pager),
    [{IndexNode, _Type}] = PrefList,
    Msg = {metric, Type, Target, Value},
    Resp = riak_core_vnode_master:sync_spawn_command(IndexNode, Msg, pager_vnode_master),
    io:format("send: ~p~n", [Msg]),
    io:format("Resp: ~p~n", [Resp]).


get_metrics() ->
    Url = "URL HERE",
    {ok, {{_, 200, _}, _, Body}} = httpc:request(Url),
    {ok, Data} = kvc:to_proplist(json:decode(Body)),
    Metrics = [data_to_tv(DataM) || {DataM} <- Data],
    {ok, {loadavg, {Metrics}}}.

data_to_tv(Data) ->
    Target = proplists:get_value(<<"target">>, Data),
    DataPoints = lists:reverse(proplists:get_value(<<"datapoints">>, Data)),
    case first_value(DataPoints) of
        {ok, Value} -> {Target, Value};
        {error, no_value} -> {Target, null}
    end.


first_value([[null,Time]|T]) ->
    first_value(T);
first_value([[Value, Time]|T]) ->
    {ok, Value};
first_value(_)->
    {error, no_value}.



run_pipe(Msg) ->
    {ok, Pipe} = riak_pipe:exec(
                          [#fitting_spec{name={pager_test, node()},
                                         arg={
                                            [{module, pager_fitting_metric_above}],
                                            [{threshold, 40}]},
                                         module=pager_fitting_wrapper}],
                          []),

    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 20}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 30}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 40}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 50}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 60}]),
    riak_pipe:eoi(Pipe),
    {Pipe, riak_pipe:collect_results(Pipe)}.
