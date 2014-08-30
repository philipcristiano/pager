-module(pager_fitting_min_ok).
-behaviour(riak_pipe_vnode_worker).
-include("deps/riak_pipe/include/riak_pipe.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {send_output, unique, min, events}).

%% API
init(SendOutput, Args) ->
    {ok, #state{send_output=SendOutput,
                unique=proplists:get_value(unique, Args),
                min=proplists:get_value(min, Args),
                events=dict:new()}}.

process(Event, _Last, State) ->
    SendOutput = State#state.send_output,
    Min = State#state.min,

    Host = proplists:get_value(<<"host">>, Event),
    Events = State#state.events,
    Events1 = dict:store(Host, Event, Events),
    Okays = count_ok(Events1),

    EventState = case Okays of
                    Count when Count >= Min -> <<"ok">>;
                    _ -> <<"critical">>
    end,

    SendOutput([{ok, [{<<"state">>, EventState}]}]),
    State1 = State#state{events=Events1},
    {ok, State1}.

done(_State) ->
    ok.


count_ok(Events) ->

    io:format("Counting"),
    dict:fold(fun is_ok_acc/3, 0, Events).

is_ok_acc(_Key, Value, Acc) ->
    io:format("Event: ~p~n", [Value]),
    case proplists:get_value(<<"state">>, Value) of
        <<"ok">> -> Acc + 1;
        _ -> Acc
    end.
