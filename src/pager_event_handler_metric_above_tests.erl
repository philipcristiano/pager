%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_event_handler_metric_above_tests).

simple_test() ->
   ?assert(1 +1 =:= 2).

another_simple_test() ->
   ?assert(1 +1 =:= 2).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun threshold_ok/1,
      fun threshold_critical/1]}.

start() ->
    {ok, Pid} = pager_event_handler_metric_above:start_link([pager_test_helpers:send_event_func(self()), 50]),
    Pid.

stop(Pid) ->
    pager_event_handler_metric_above:stop(Pid).



threshold_ok(Pid) ->
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{metric, 50}]),
    Msg = pager_test_helpers:receive_event(),
    [?_assertEqual(Msg, [{state, ok}, {metric, 50}])].

threshold_critical(Pid) ->
    {ok, _} = pager_event_handler_metric_above:send_metric(Pid, [{metric, 60}]),
    Msg = pager_test_helpers:receive_event(),
    [?_assertEqual(Msg, [{state, critical}, {metric, 60}])].
