-module(pager_ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

init({tcp, http}, _Req, _Opts) ->
    % join_all(),
	{upgrade, protocol, cowboy_websocket}.

join_all() ->
    join(pg2:which_groups()).

join([]) ->
    ok;
join([{pager_publisher, Name}|T]) ->
    pg2:join({pager_publisher, Name}, self()),
    join(T);
join([_H|T]) ->
    join(T).

join_once(Group) ->
    io:format("Join: ~p~n", [Group]),
    Members = pg2:get_members(Group),
    case lists:member(self(), Members) of
        true -> ok;
        false -> pg2:join(Group, self())
    end.

sync_membership([]) ->
    ok;
sync_membership([Group | Groups]) ->
    Name = {pager_publisher, proplists:get_value(<<"id">>, Group)},
    Selected = proplists:get_value(<<"selected">>, Group, false),
    case Selected of
        true -> join_once(Name);
        _ -> io:format("Leave: ~p~n", [Name]),
             pg2:leave(Name, self())
    end,
    sync_membership(Groups).

groups_to_proplists(Groups) ->
    [[{id, ID}] || {_, ID} <- Groups].

websocket_init(_TransportName, Req, _Opts) ->
	% erlang:start_timer(1000, self(), <<"Hello!">>),
    self() ! {send_groups},
	{ok, Req, undefined_state}.

%% Handle messages from client
websocket_handle({text, String}, Req, State) ->
    io:format("Message: ~p~n", [String]),
    Data = jsx:decode(String),
    io:format("Data: ~p~n", [Data]),
    sync_membership(proplists:get_value(<<"data">>, Data)),
	{ok, Req, State}.

%% Handle messages from VM
websocket_info({send_groups}, Req, State) ->
    Groups = groups_to_proplists(pager:pipe_groups()),
    Msg = [{type, groups}, {data, Groups}],
    {reply, {text, jsx:encode(Msg)}, Req, State};
websocket_info({pipe, Pipe, Msg}, Req, State) ->
    Send = [{type, event}, {pipe, [Pipe]}, {data, Msg}],
    {reply, {text, jsx:encode(Send)}, Req, State};
websocket_info(_Info, Req, State) ->
	{ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.
