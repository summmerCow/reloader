%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 四月 2019 20:25
%%%-------------------------------------------------------------------
-module(fguc_push_SUITE).
-author("Administrator").
-define(ETS, role).
%% API
-compile([export_all]).

all() ->
    [
        role_exit
    ].


role_exit() ->

    skip.


enter_room() ->
    skip.


send_msg() ->
    skip.