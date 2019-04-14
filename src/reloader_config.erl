%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 四月 2019 17:18
%%%-------------------------------------------------------------------
-module(reloader_config).
-author("Administrator").

-define(APP,reloader).

-export([
    src/0,ebin/0,
    check_interval/0,
    include/0,
    com_opt/0
]).


src()->
    application:get_env(?APP,src).

ebin()->
    application:get_env(?APP,ebin).

check_interval()->
    {ok,Interval} = application:get_env(?APP,check_interval),
    Interval.

include()->
    application:get_env(?APP,i).

com_opt()->
    application:get_env(?APP,com_opt).