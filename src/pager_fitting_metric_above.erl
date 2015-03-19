-module(pager_fitting_metric_above).
-behaviour(riak_pipe_vnode_worker).
-include_lib("riak_pipe/include/riak_pipe.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {send_output, threshold=30}).

%% API
init(SendOutput, Args) ->
    {ok, #state { send_output=SendOutput,
                  threshold=proplists:get_value(threshold, Args)}}.

process(Event, _Last, State) ->
    EventValue = proplists:get_value(<<"value">>, Event),
    Threshold = State#state.threshold,
    NewEventState = case EventValue of
                        Val when Val >  Threshold -> <<"critical">>;
                        Val when Val =< Threshold -> <<"ok">>
                    end,
    StatelessEvent = proplists:delete(<<"state">>, Event),
    NewEvent = [{<<"state">>, NewEventState} | StatelessEvent],

    SendOutput = State#state.send_output,
    SendOutput(NewEvent),
    {ok, State}.

done(_State) ->
    ok.

