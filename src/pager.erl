-module(pager).

-export([ping/0, first_value/1, run/0]).


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
send_metrics(Type, []) ->
    ok.

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
