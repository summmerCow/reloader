%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 五月 2017 16:08
%%%-------------------------------------------------------------------
-module(reloader_app).
-author("Administrator").

-behaviour(application).

-define(APP,reloader).

-define(ETS_FILE,ets_cache_file).

%% Application callbacks
-export([start/2,
    stop/1,
    start/0]).


start(_StartType, _StartArgs) ->
    case reloader_sup:start_link() of
        {ok, Pid} ->
            init(),
            {ok, Pid};
        Error ->
            Error
    end.

start()->
    start(normal,permanet).

-spec(stop(State :: term()) -> term()).
stop(_State) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

init()->
    reloader_sup:start_child(reloader_srv, []).
