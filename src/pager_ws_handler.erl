-module(pager_ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

init({tcp, http}, _Req, _Opts) ->
    join_all(),
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

websocket_init(_TransportName, Req, _Opts) ->
	% erlang:start_timer(1000, self(), <<"Hello!">>),
	{ok, Req, undefined_state}.

%% Handle messages from client
websocket_handle(_Data, Req, State) ->
	{ok, Req, State}.

%% Handle messages from VM
websocket_info({pipe, Pipe, Msg}, Req, State) ->
    Send = [{pipe, {[Pipe]}} | Msg],
    {reply, {text, jiffy:encode({Send})}, Req, State};
websocket_info(_Info, Req, State) ->
	{ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.
