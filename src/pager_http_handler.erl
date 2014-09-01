%% @doc Hello world handler.
-module(pager_http_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Type, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
    Pipelines = riak_pipe:active_pipelines(global),
	{ok, Req2} = cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/plain">>}
	], erlang:term_to_binary(Pipelines), Req),
	{ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
	ok.
