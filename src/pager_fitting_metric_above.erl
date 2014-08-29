-module(pager_fitting_metric_above).
-behaviour(riak_pipe_vnode_worker).
-include("deps/riak_pipe/include/riak_pipe.hrl").

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {partition, fitting_details, threshold}).

%% API
init(Partition, FittingDetails) ->
    Threshold = proplists:get_value(threshold, FittingDetails#fitting_details.arg),
    {ok, #state { partition=Partition,
                  fitting_details=FittingDetails,
                  threshold=Threshold}}.

process(Event, _Last, State) ->
    EventValue = proplists:get_value(<<"value">>, Event),
    Threshold = State#state.threshold,
    NewEventState = case EventValue of
                        Val when Val >  Threshold -> <<"critical">>;
                        Val when Val =< Threshold -> <<"ok">>
                    end,
    StatelessEvent = proplists:delete(<<"state">>, Event),
    NewEvent = [{<<"state">>, NewEventState} | StatelessEvent],

    riak_pipe_vnode_worker:send_output(
        {NewEvent},
        State#state.partition,
        State#state.fitting_details),
    {ok, State}.

done(_State) ->
    ok.

