-module(pager_app).

-behaviour(application).

%% Application callbacks
-export([start/0, start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================
start() ->
    a_start(pager, permanent),
    ok = riak_core:register([{vnode_module, pager_vnode}]),
    ok = riak_core_node_watcher:service_up(pager, self()),
    ok.

a_start(App, Type) ->
    start_ok(App, Type, application:start(App, Type)).

start_ok(_App, _Type, ok) -> ok;
start_ok(_App, _Type, {error, {already_started, _App}}) -> ok;
start_ok(App, Type, {error, {not_started, Dep}}) ->
    ok = a_start(Dep, Type),
    a_start(App, Type);
start_ok(App, _Type, {error, Reason}) ->
    erlang:error({app_start_failed, App, Reason}).

start(_StartType, _StartArgs) ->
    {ok, _} =pager_sup:start_link(),
    start_cowboy().

start_cowboy() ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/", pager_http_handler, []},
               {"/static/[...]", cowboy_static, {dir, "priv/static/"}},
               {"/ws", pager_ws_handler, []}
        ]}
    ]),
    cowboy:start_http(pager_http_listener, 100, [{port, 8080}],
        [{env, [{dispatch, Dispatch}]}]
    ),
    pager_http_sup:start_link().

stop(_State) ->
    ok.
