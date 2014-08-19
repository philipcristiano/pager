%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_event_handler_min_ok_tests).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun enough_hosts/1 ]}.

start() ->
    Ref = make_ref(),
    {ok, Pid} = pager_event_handler_min_ok:start_link([pager_test_helpers:send_event_func(Ref, self()), [{unique, {service, pod}}, {min, 2}]]),
    {Ref, Pid}.

stop({_Ref, Pid}) ->
    pager_event_handler_min_ok:stop(Pid).

next_event(Ref) ->
    pager_test_helpers:receive_event(Ref).

enough_hosts({Ref, Pid}) ->
    {ok, _} = pager_event_handler_min_ok:send_event(Pid, [{service, <<"foo">>}, {pod, <<"bar">>}, {host, <<"host_1">>}, {state, <<"ok">>}]),
    {ok, _} = pager_event_handler_min_ok:send_event(Pid, [{service, <<"foo">>}, {pod, <<"bar">>}, {host, <<"host_2">>}, {state, <<"ok">>}]),
    {ok, _} = pager_event_handler_min_ok:send_event(Pid, [{service, <<"foo">>}, {pod, <<"bar">>}, {host, <<"host_2">>}, {state, <<"critical">>}]),
    MsgNotEnough = next_event(Ref),
    MsgOk = next_event(Ref),
    MsgCritical = next_event(Ref),
    [?_assertEqual([{ok, [{state, critical}]}], MsgNotEnough),
     ?_assertEqual([{ok, [{state, ok}]}], MsgOk),
     ?_assertEqual([{ok, [{state, critical}]}], MsgCritical)].
