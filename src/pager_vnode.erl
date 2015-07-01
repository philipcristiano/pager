-module(pager_vnode).
-behaviour(riak_core_vnode).
-compile({parse_transform, lager_transform}).

-export([start_vnode/1,
         init/1,
         terminate/2,
         handle_command/3,
         is_empty/1,
         delete/1,
         start_message/1,
         handle_handoff_command/3,
         handoff_starting/2,
         handoff_cancelled/1,
         handoff_finished/2,
         handle_handoff_data/2,
         encode_handoff_item/2,
         handle_coverage/4,
         handle_exit/3]).

-record(state, {partition, count, sup, router}).

%% API
start_vnode(I) ->
    riak_core_vnode_master:get_vnode_pid(I, ?MODULE).

init([Partition]) ->
    lager:info("Starting vnode ~p", [Partition]),
    {ok, SupPid} = pager_vnode_sup:start_link(),
    {ok, RouterPid} = gen_event:start_link(),
    lager:info("Started vnode ~p", [Partition]),
    %ok = gen_event:add_handler(RouterPid, pager_vnode_handler_printer, []),
    Group = {pager_publisher, "puppet_lastrun"},
    pg2:create(Group),
    ok = gen_event:add_handler(RouterPid, pager_handler_match_publisher, [{<<"key">>, <<"puppet_lastrun/ok">>}, Group]),

    {ok, #state { partition=Partition, count=0, sup=SupPid, router=RouterPid}}.

% Sample command: respond to a ping
handle_command(ping, _Sender, State) ->
    State2 = #state {partition=State#state.partition,
                     count=State#state.count + 1},
    {reply, {pong, State2}, State2};
handle_command({first_event, RoutingKey, Data}, _Sender, State) ->
    Router = State#state.router,
    gen_event:notify(Router, {event, RoutingKey, Data}),
    {reply, {pong, {event, RoutingKey, Data}, State}, State};
handle_command({event, RoutingKey, Data}, _Sender, State) ->
    {reply, {pong, {event, RoutingKey, Data}, State}, State};
handle_command({event, Event}, _Sender, State) ->
    Partition = State#state.partition,
    io:format("VNode event ~p~n    ~p~n", [Partition, Event]),
    {reply, ok, State};
handle_command({metric, _Type, _Metric, Value}, _Sender, State) ->
    State2 = #state {partition=State#state.partition,
                     count=State#state.count + 1},
    {reply, {pong, State2, Value}, State2};
handle_command(_Message, _Sender, State) ->
    {noreply, State}.

handle_handoff_command(_Message, _Sender, State) ->
    {noreply, State}.

handoff_starting(_TargetNode, State) ->
    {true, State}.

handoff_cancelled(State) ->
    {ok, State}.

handoff_finished(_TargetNode, State) ->
    {ok, State}.

handle_handoff_data(_Data, State) ->
    {reply, ok, State}.

encode_handoff_item(_ObjectName, _ObjectValue) ->
    <<>>.

is_empty(State) ->
    {true, State}.

delete(State) ->
    {ok, State}.

handle_coverage(_Req, _KeySpaces, _Sender, State) ->
    {stop, not_implemented, State}.

handle_exit(_Pid, _Reason, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

start_message(Msg) ->
    RoutingKey = proplists:get_value(<<"host">>, Msg),
    DocIdx = riak_core_util:chash_key({<<"metrics">>, term_to_binary(RoutingKey)}),
    PrefList = riak_core_apl:get_primary_apl(DocIdx, 1, pager),
    [{IndexNode, _Type}] = PrefList,
    SendMsg = {first_event, RoutingKey, Msg},
    riak_core_vnode_master:command(IndexNode, SendMsg, pager_vnode_master),
    ok.

