-module(pager_fitting_state_change).
-include("deps/riak_pipe/include/riak_pipe.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {send_output, last_state}).

%% API
init(SendOutput, Args) ->
    {ok, #state{send_output=SendOutput,
                last_state=proplists:get_value(initial_state, Args)}}.

process(Event, _Last, State) ->
    SendOutput = State#state.send_output,
    LastState = State#state.last_state,
    EventState = proplists:get_value(<<"state">>, Event),

    if
        EventState == LastState ->
         ok;
        EventState /= LastState ->
         SendOutput(Event)
    end,
    NewState = State#state{last_state=EventState},
    {ok, NewState}.

done(_State) ->
    ok.
