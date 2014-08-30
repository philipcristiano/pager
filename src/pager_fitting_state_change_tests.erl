%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_fitting_state_change_tests).
-define(MUT, pager_fitting_state_change).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun state_changes/1]}.

start() ->
    Ref = make_ref(),
    {ok, State} = ?MUT:init(pager_test_helpers:send_event_func(Ref, self()), [{initial_state, <<"ok">>}]),
    {Ref, State}.

stop({_Ref, _State}) ->
    ok.

next_event(Ref) ->
    pager_test_helpers:receive_event(Ref).

state_changes({Ref, S0}) ->
    {ok, S1} = ?MUT:process([{<<"state">>, <<"ok">>}], ok, S0),
    none = next_event(Ref),

    {ok, _S2} = ?MUT:process([{<<"state">>, <<"critical">>}], ok, S1),
    CriticalEvent = next_event(Ref),

    [?_assertEqual([{<<"state">>, <<"critical">>}], CriticalEvent)].

