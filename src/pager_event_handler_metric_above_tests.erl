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
     fun start/0,
     fun stop/1,
     [fun threshold_ok/1,
      fun threshold_critical/1]}.

start() ->
    {ok, Pid} = pager_event_handler_metric_above:start_link([50]),
    Pid.

stop(Pid) ->
    pager_event_handler_metric_above:stop(Pid).

threshold_ok(Pid) ->
    [?_assertEqual({ok, ok}, pager_event_handler_metric_above:send_metric(Pid, [{metric, 50}]))].

threshold_critical(Pid) ->
    [?_assertEqual({ok, critical}, pager_event_handler_metric_above:send_metric(Pid, [{metric, 60}]))].
