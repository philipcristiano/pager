%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_fitting_filter_tests).
-define(MUT, pager_fitting_filter).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun with_value/1,
      fun without_key/1,
      fun without_value/1]}.

start() ->
    Ref = make_ref(),
    {ok, State} = ?MUT:init(pager_test_helpers:send_event_func(Ref, self()), [{<<"service">>, <<"foo">>}]),
    {Ref, State}.

stop({_Ref, _State}) ->
    ok.

with_value({Ref, State}) ->
    {ok, _NewState} = ?MUT:process([{<<"service">>, <<"foo">>}], ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    [?_assertEqual(Msg, [{<<"service">>, <<"foo">>}])].

without_value({Ref, State}) ->
    {ok, _} = ?MUT:process([{<<"service">>, <<"bar">>}], ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    [?_assertEqual(Msg, none)].

without_key({Ref, State}) ->
    {ok, _} = ?MUT:process([{<<"value">>, <<"foo">>}], ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    [?_assertEqual(Msg, none)].

