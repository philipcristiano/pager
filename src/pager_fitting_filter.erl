-module(pager_fitting_filter).
-include("deps/riak_pipe/include/riak_pipe.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {send_output, filters=[]}).

%% API
init(SendOutput, Filters) ->
    {ok, #state { send_output=SendOutput,
                  filters=Filters}}.

process(Event, _Last, State) ->
    [{Field, Value}] = State#state.filters,
    SendOutput = State#state.send_output,
    case matches(Field, Value, Event) of
        true -> SendOutput(Event);
        false -> ok
    end,
    {ok, State}.

done(_State) ->
    ok.

matches(Field, Value, Event) ->
    EValue = proplists:get_value(Field, Event),
    if
        EValue == Value -> true;
        EValue /= Value -> false
    end.
