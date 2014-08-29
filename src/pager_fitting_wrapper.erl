-module(pager_fitting_wrapper).
-behaviour(riak_pipe_vnode_worker).

-export([init/2,
         process/3,
         setup/0,
         done/1]).

-include("deps/riak_pipe/include/riak_pipe.hrl").

-record(state, {part, fit, module, substate}).

init(Partition, FittingDetails) ->
    {Args, ModArgs} = FittingDetails#fitting_details.arg,
    Module = proplists:get_value(module, Args),
    SendOutput = make_send_output(Partition, FittingDetails),
    {ok, SubState} = Module:init(SendOutput, ModArgs),
    {ok, #state{part=Partition,
                fit=FittingDetails,
                module=Module,
                substate=SubState}}.

process(Input, _Last, #state{module=Mod, substate=SS}=State) ->
    {ok, NewSS} = Mod:process(Input, _Last, SS),
    {ok, State#state{substate=NewSS}}.

make_send_output(Part, Fit) ->
    fun (Output) -> riak_pipe_vnode_worker:send_output(Output, Part, Fit) end.

done(_State) ->
    ok.

setup() ->
    init(0,
         #fitting_details { arg={[{module, pager_fitting_metric_above}], [{threshold, 40}]}}
         ).
