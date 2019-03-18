%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 五月 2017 15:55
%%%-------------------------------------------------------------------
-module(mod_reloader).
-author("Administrator").
-include_lib("kernel/include/file.hrl").
-define(ERROR_MSG, fun(Format, Show_Msg)->io:format(" ~w, ~w ", [?MODULE, ?LINE]), io:format(Format, Show_Msg) end).
-define(UPDATE_CYCLE, 2000).

%% API
-export([start_link/0
  , init/1
  , auto_c/1
]).
start_link()->
  ?ERROR_MSG(" ~p~n", [restart]),
  Pid = erlang:spawn(?MODULE, init, [erlang:localtime()]),
  register(?MODULE, Pid),
  link(Pid),
  erlang:send_after(?UPDATE_CYCLE, Pid, update),
  {ok, Pid}.


init(LastTime)->
  process_flag(trap_exit, true),
  loop(LastTime).

loop(LastTime)->
  receive
    update->
      auto_c(LastTime),
      erlang:send_after(?UPDATE_CYCLE, self(), update),
      loop(erlang:localtime());
    Msg->
      ?ERROR_MSG(" ~p~n", [Msg])
  end.

auto_c(LastTime)->
  Opts =  [
    {parse_transform, lager_transform},
    debug_info,
    {d, 'USE_CACHE'},
    {i, "D:/workp/Server/mahjong/apps/mahjong/src/include"},
    {outdir, "D:/workp/Server/mahjong/_build/default/rel/mahjong/lib/mahjong-0.2.0/ebin"}
  ],
  NowTime = erlang:localtime(),
  Fun = fun({File, Module})->
    case util_file:read_file_info(File) of
      {ok, #file_info{mtime = Mtime}} when Mtime >= LastTime andalso Mtime =< NowTime ->
        compile:file(File, [report_errors, error_summary|Opts]),
        case code:soft_purge(Module) of
          true->
            ?ERROR_MSG(" ~p~n", [Module]),
            code:load_file(Module);
          false->
            ?ERROR_MSG("hot_update fail:~p", [Module])
        end;
      V->
        V
    end
        end,
  Files = case get(files) of
            undefined->
              put(files, ets:tab2list(ets_reloader_file)),
              get(files);
            F->
              F
          end,
  lists:foreach(Fun, Files).

