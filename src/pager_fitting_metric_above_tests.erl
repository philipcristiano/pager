%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_fitting_metric_above_tests).
-define(MUT, pager_fitting_metric_above).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun threshold_ok/1,
      fun threshold_critical/1]}.

start() ->
    Ref = make_ref(),
    {ok, State} = ?MUT:init(pager_test_helpers:send_event_func(Ref, self()), {50}),
    {Ref, State}.

stop({_Ref, _State}) ->
    ok.

threshold_ok({Ref, State}) ->
    {ok, _NewState} = ?MUT:process([{<<"value">>, 50}], ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    [?_assertEqual(Msg, [{<<"state">>, <<"ok">>}, {<<"value">>, 50}])].

threshold_critical({Ref, State}) ->
    {ok, _} = ?MUT:process([{<<"value">>, 60}], ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    [?_assertEqual(Msg, [{<<"state">>, <<"critical">>}, {<<"value">>, 60}])].
