-module(pager_fitting_publisher).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([
         init/2,
         process/3,
         done/1
        ]).

-record(state, {name}).

%% API
init(_SendOutput, Name) ->
    pg2:create(Name),
    {ok, #state {name=Name}}.

process(Event, _Last, State) ->
    Name = State#state.name,
    Pids = pg2:get_members(Name),
    send(Pids, Name, Event),
    {ok, State}.

done(_State) ->
    ok.


send([], _Name, _Msg) ->
    ok;
send([Pid|Pids], Name, Msg) ->
    Pid ! {pipe, Name, Msg},
    send(Pids, Name, Msg).
