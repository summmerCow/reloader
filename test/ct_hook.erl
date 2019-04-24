%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 四月 2019 20:08
%%%-------------------------------------------------------------------
-module(ct_hook).
-author("Administrator").

%% API
-export([
    init/2,
    terminate/1
]).

init(_Id,_Opts)->
    {ok,_} = application:ensure_all_started(reloader),
    ok.

terminate(_Args)->
    ok = application:stop(reloader).
