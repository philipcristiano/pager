-module(pager).

-export([ping/0, create_pipe/1, run_pipe/1, send_event/2, send_to_pipe/1]).

-include_lib("deps/riak_pipe/include/riak_pipe.hrl").



ping() ->
    DocIdx = riak_core_util:chash_key({<<"ping">>, term_to_binary(now())}),
    PrefList = riak_core_apl:get_primary_apl(DocIdx, 1, pager),
    [{IndexNode, _Type}] = PrefList,
    riak_core_vnode_master:sync_spawn_command(IndexNode, ping, pager_vnode_master).

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

run_pipe(Msg) ->
    {ok, Pipe} = create_pipe(pager_test),

    send_to_pipe(Pipe),
    riak_pipe:eoi(Pipe),
    {Pipe, riak_pipe:collect_results(Pipe)}.

send_to_pipe(Pipe) ->
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 20}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 30}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 40}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 50}]),
    ok = riak_pipe:queue_work(Pipe, [{<<"value">>, 60}]).

create_pipe(Name) ->
    {ok, RouterPid} = pager_result_sink:start_link(),
    {ok, Pipe} = riak_pipe:exec(
                          [#fitting_spec{name={Name, metric_above},
                                         arg={
                                            [{module, pager_fitting_metric_above}],
                                            [{threshold, 35}]},
                                         module=pager_fitting_wrapper},
                           #fitting_spec{name={Name, publisher},
                                         arg={
                                            [{module, pager_fitting_publisher}],
                                            {pager_publisher, Name}},
                                         chashfun=follow,
                                         module=pager_fitting_wrapper}], []
                          ).
