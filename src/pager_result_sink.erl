-module(pager_result_sink).

-export([start_link/0, loop/0]).


start_link() ->
    Pid = spawn(pager_result_sink, loop, []),
    {ok, Pid}.

loop() ->
    receive
        {pipe_eoi, _Ref} -> io:format("Done!~n");
        Msg -> io:format("Event: ~p~n", [Msg]),
               timer:sleep(1000),
               loop()
    end.
