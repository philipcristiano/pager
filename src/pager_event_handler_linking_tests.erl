%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_event_handler_linking_tests).

simple_test() ->
   ?assert(1 +1 =:= 2).

another_simple_test() ->
   ?assert(1 +1 =:= 2).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun state_changes/1]}.

start() ->
    Ref = make_ref(),
    {ok, Pid2} = pager_event_handler_state_change:start_link([pager_test_helpers:send_event_func(Ref, self()), ok]),
    {ok, Pid1} = pager_event_handler_metric_above:start_link([fun (Event) -> pager_event_handler_state_change:send_metric(Pid2, Event) end, 50]),
    {Ref, Pid1}.

stop({_Ref, Pid}) ->
    pager_event_handler_metric_above:stop(Pid).


state_changes({Ref, Pid}) ->
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{metric, 20}]),
    none = pager_test_helpers:receive_event(Ref),
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{metric, 40}]),
    none = pager_test_helpers:receive_event(Ref),
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{metric, 60}]),
    Msg = pager_test_helpers:receive_event(Ref),
    none = pager_test_helpers:receive_event(Ref),

    [?_assertEqual([{state, critical}, {metric, 60}], Msg)].
