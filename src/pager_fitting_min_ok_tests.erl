%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_fitting_min_ok_tests).
-define(MUT, pager_fitting_min_ok).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun enough_hosts/1]}.

start() ->
    Ref = make_ref(),
    {ok, State} = ?MUT:init(pager_test_helpers:send_event_func(Ref, self()), [{unique, {service, pod}}, {min, 2}]),
    {Ref, State}.

stop({_Ref, _State}) ->
    ok.

next_event(Ref) ->
    pager_test_helpers:receive_event(Ref).

enough_hosts({Ref, S0}) ->
    {ok, S1} = ?MUT:process([{<<"service">>, <<"foo">>}, {<<"pod">>, <<"bar">>}, {<<"host">>, <<"host_1">>}, {<<"state">>, <<"ok">>}], ok, S0),
    MsgNotEnough = next_event(Ref),

    {ok, S2} = ?MUT:process([{<<"service">>, <<"foo">>}, {<<"pod">>, <<"bar">>}, {<<"host">>, <<"host_2">>}, {<<"state">>, <<"ok">>}], ok, S1),
    MsgOk = next_event(Ref),

    {ok, _S3} = ?MUT:process([{<<"service">>, <<"foo">>}, {<<"pod">>, <<"bar">>}, {<<"host">>, <<"host_2">>}, {<<"state">>, <<"critical">>}], ok, S2),
    MsgCritical = next_event(Ref),

    [?_assertEqual([{ok, [{<<"state">>, <<"critical">>}]}], MsgNotEnough),
     ?_assertEqual([{ok, [{<<"state">>, <<"ok">>}]}], MsgOk),
     ?_assertEqual([{ok, [{<<"state">>, <<"critical">>}]}], MsgCritical)].

