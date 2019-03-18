%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 五月 2017 16:08
%%%-------------------------------------------------------------------
-module(reloader_sup).
-author("Administrator").

%%-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1, start_child/2]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Mod, Args)->
    supervisor:start_child(?MODULE, {Mod, {Mod, start_link, Args}, transient, 100, worker, [Mod]}).


init([]) ->
    RestartStrategy = one_for_one, 
    MaxRestarts = 1000, 
    MaxSecondsBetweenRestarts = 3600, 

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts}, 

    {ok, {SupFlags, []}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
