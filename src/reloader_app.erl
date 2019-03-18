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

%% Application callbacks
-export([start/2,
    stop/1,
    start/0]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1, 2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
        StartArgs :: term()) ->
    {ok, pid()} |
    {ok, pid(), State :: term()} |
    {error, Reason :: term()}).
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
    load_all_file(),
    start_mod_reloader(),
    ok.

start_mod_reloader()->
    reloader_sup:start_child(mod_reloader, []).

load_all_file()->
    ets:new(ets_reloader_file, [named_table, public, set]),
    Fun = fun(File)->
        filelib:is_dir(File)
          end,
    Path = "D:/workp/Server/mahjong/apps/mahjong/src",
    FilePaths = do_load_all_file(Path, [], Fun),
    [ets:insert(ets_reloader_file, {FilePath, get_module(FilePath)})||FilePath<-FilePaths].

do_load_all_file(Path, Files, Fun)->
    {ok, Files1} = file:list_dir(Path),
    {Dirs, ItemFiles} = split(Fun, Files1, {[], []}, Path),
    NewDirs = [filename:join(Path, Dir1)||Dir1<-Dirs],
    Files2 = [filename:join(Path, ItemFile)||ItemFile<-ItemFiles],
    Fun1 = fun(Dir, TotalFiles)->
        do_load_all_file(Dir, TotalFiles, Fun)
           end,
    lists:foldl(Fun1, Files2++Files, NewDirs).

check_file(File, RegExp)->
    {ok, Re1} = re:compile(RegExp, [unicode]),
    case (catch re:run(File, if is_binary(File) -> true;
                                 true -> Re1 end,
        [{capture, none}])) of
        match->
            true;
        _->
            false
    end.

split(Fun, [Item|Items], {Pre, Tail}, Path)->
    case Fun(filename:join(Path, Item)) of
        true->
            split(Fun, Items, {[Item|Pre], Tail}, Path);
        false->
            case check_file(Item, ".erl") of
                true->
                    split(Fun, Items, {Pre, [Item|Tail]}, Path);
                false->
                    split(Fun, Items, {Pre, Tail}, Path)
            end
    end;

split(_, [], Acc, _Path)->
    Acc.

get_module(FilePath)->
    L = string:tokens(FilePath, "/"),
    list_to_atom(hd(string:tokens(lists:last(L), "."))).