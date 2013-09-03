-module(pager_app).

-behaviour(application).

%% Application callbacks
-export([start/0, start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() ->
    ok = application:start(lager),
    ok = application:start(json),
    ok = application:start(sasl),
    ok = application:start(crypto),
    ok = application:start(riak_sysmon),
    ok = application:start(inets),
    ok = application:start(mochiweb),
    ok = application:start(webmachine),
    ok = application:start(os_mon),
    ok = application:start(riak_core),
    ok = riak_core:register(pager, [{vnode_module, pager_vnode}]),
    ok = riak_core_node_watcher:service_up(pager, self()),
    ok = application:start(pager),
    ok.

start(_StartType, _StartArgs) ->
    pager_sup:start_link().

stop(_State) ->
    ok.
