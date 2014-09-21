%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

-module(pager_fitting_publisher_tests).
-define(MUT, pager_fitting_publisher).

metric_above_threshold_test_() ->
    {foreach,
     spawn,
     fun start/0,
     fun stop/1,
     [fun with_group_membership/1]}.

start() ->
    Ref = make_ref(),
    {ok, State} = ?MUT:init(pager_test_helpers:send_event_func(Ref, self()), erlang:term_to_binary(Ref)),
    {Ref, State}.

stop({_Ref, _State}) ->
    ok.

with_group_membership({Ref, State}) ->
    BRef = erlang:term_to_binary(Ref),
    pg2:join(BRef, self()),
    SendMsg = [{<<"service">>, <<"foo">>}],
    {ok, _NewState} = ?MUT:process(SendMsg, ok, State),
    Msg = pager_test_helpers:receive_event(Ref),
    RecMsg = receive
                 {pipe, BRef, SubMsg} -> SubMsg
             after
                 100 -> fail
             end,
    [?_assertEqual(Msg, none),
     ?_assertEqual(RecMsg, SendMsg)].
