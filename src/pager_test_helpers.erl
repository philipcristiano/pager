-module(pager_test_helpers).

-export([receive_event/0,
         send_event_func/1]).

receive_event() ->
    Rec = receive
        Msg -> Msg
        after 20 -> none
    end,
    Rec.


send_event_func(Pid) ->
    fun (Event) -> Pid ! Event end.
