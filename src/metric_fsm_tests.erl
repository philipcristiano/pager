-module(metric_fsm_tests).
-include_lib("eunit/include/eunit.hrl").


nominal_test() ->
    {ok, Fsm} = metric_fsm:start_link(),
    metric_fsm:send_metric(Fsm, 50).
