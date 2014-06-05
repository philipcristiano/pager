%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_event_handler_state_change_tests).

simple_test() ->
   ?assert(1 +1 =:= 2).

another_simple_test() ->
   ?assert(1 +1 =:= 2).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun state_unchanged/1,
      fun state_changed/1]}.

start() ->
    {ok, Pid} = pager_event_handler_state_change:start_link([pager_test_helpers:send_event_func(self()), ok]),
    Pid.

stop(Pid) ->
    pager_event_handler_metric_above:stop(Pid).


state_unchanged(Pid) ->
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{state, ok}]),
    Msg = pager_test_helpers:receive_event(),
    [?_assertEqual(Msg, none)].

state_changed(Pid) ->
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{state, critical}]),
    Msg = pager_test_helpers:receive_event(),
    [?_assertEqual(Msg, [{state, critical}])].
