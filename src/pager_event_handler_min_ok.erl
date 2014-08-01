%%%-------------------------------------------------------------------
%%% @author $AUTHOR
%%% @copyright 2014 $OWNER
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-module(pager_event_handler_min_ok).

-behaviour(gen_server).

%% API
-export([start_link/0,
         start_link/1,
         send_event/2,
         send_metric/2,
         stop/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {passevent, unique, min, events}).

%%%===================================================================
%%% API
%%%===================================================================

send_metric(Pid, Metric) ->
    send_event(Pid, Metric).

send_event(Pid, Event) ->
    gen_server:call(Pid, {event, Event}, 5000).

stop(Pid) ->
    gen_server:cast(Pid, stop).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link(?MODULE, [], []).

start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([PassEvent, Opts]) ->
    {ok, #state{passevent=PassEvent,
                unique=proplists:get_value(unique, Opts),
                min=proplists:get_value(min, Opts),
                events=dict:new()}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({event, Event}, _From, State) ->
    io:format("Handling Call"),
    NextState = ok,
    Next = State#state.passevent,
    Min = State#state.min,
    Host = proplists:get_value(host, Event),
    Events = State#state.events,
    Events1 = dict:store(Host, Event, Events),
    Okays = count_ok(Events1),
    EventState = case Okays of
                    Count when Count >= Min -> ok;
                    _ -> critical
    end,

    Next([{ok, [{state, EventState}]}]),
    State1 = State#state{events=Events1},
    {reply, {ok, NextState}, State1};
handle_call(_Request, _From, State) ->
    io:format("Handling unknown Call"),
    {noreply, State}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(stop, State) ->
        {stop, normal, State};
handle_cast(_Msg, State) ->
        {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
        {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
        ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
        {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


count_ok(Events) ->

    io:format("Counting"),
    dict:fold(fun is_ok_acc/3, 0, Events).

is_ok_acc(Key, Value, Acc) ->
    io:format("Event: ~p~n", [Value]),
    case proplists:get_value(state, Value) of
        <<"ok">> -> Acc + 1;
        _ -> Acc
    end.
