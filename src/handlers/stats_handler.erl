-module(stats_handler).
-behaviour(cowboy_http_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init({tcp, http}, Req, Opts) ->
    {ok, Req, init}.

handle(Req, State) ->
    Stats = [{fetching_zips, folsom_metrics:get_metric_value("fetching_zips")}],
    {ok, Resp} = stats_dtl:render([{stats, Stats}]),
    {ok, Req2} = cowboy_req:reply(200, [], Resp, Req),
    {ok, Req2, State}.

terminate(Reason, Req, State) ->
    ok.
