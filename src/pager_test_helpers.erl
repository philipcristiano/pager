-module(pager_test_helpers).

-export([receive_event/0,
         receive_event/1,
         send_event_func/1,
         send_event_func/2]).

receive_event(Ref) ->
    Rec = receive
        {Ref, Msg} -> Msg
        after 20 -> none
    end,
    Rec.

receive_event() ->
    Rec = receive
        Msg -> Msg
        after 20 -> none
    end,
    Rec.

send_event_func(Ref, Pid) ->
    fun (Event) -> Pid ! {Ref, Event} end.

send_event_func(Pid) ->
    fun (Event) -> Pid ! Event end.
