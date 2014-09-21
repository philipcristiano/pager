-module(pager_result_sink).

-export([start_link/0, loop/0]).


start_link() ->
    ok = pg2:create(pager_receiver),
    Pid = spawn(pager_result_sink, loop, []),
    {ok, Pid}.

loop() ->
    receive
        {pipe_eoi, _Ref} -> io:format("Done!~n");
        Msg -> io:format("Event: ~p~n", [Msg]),
               send(Msg),
               timer:sleep(1000),
               loop()
    end.

send({pipe_result, _Ref, _Pipe, Msg}) ->
    io:format("Sending msg ~p~n", [Msg]),
    Pids = pg2:get_members(pager_receiver),
    io:format("Sending to Pids ~p~n", [Pids]),
    send(Pids, Msg);
send(Msg) ->
    io:format("Can't handle message ~p~n", [Msg]).

send([], _Msg) ->
    ok;
send([Pid|Pids], Msg) ->
    Pid ! {pipe, Msg},
    send(Pids, Msg).
