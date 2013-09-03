-module(atom_handler).
-behaviour(cowboy_http_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init({tcp, http}, Req, Opts) ->
    {ok, Req, init}.

handle(Req, State) ->
    {Zip, Req1} = cowboy_req:binding(zip, Req),
    Events = seatgeek_scraper:fetch_zip(Zip),

    % Resp = erlang:iolist_to_binary([<<"Hello World 2!">>, Zip]),
    {ok, Resp} = atom_dtl:render([{zip, Zip}, {events, Events}]),
    {ok, Req2} = cowboy_req:reply(200, [], Resp, Req1),
    {ok, Req2, State}.

terminate(Reason, Req, State) ->
    ok.
