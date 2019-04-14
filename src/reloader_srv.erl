-module(reloader_srv).
-author("Administrator").
-include_lib("kernel/include/file.hrl").
-define(ERROR_MSG, fun(Format, Show_Msg) -> io:format(" ~w, ~w ", [?MODULE, ?LINE]), io:format(Format, Show_Msg) end).
-define(NOW, erlang:localtime()).

-record(state, {files, com_opt, last_time}).

%% API
-export([
    start_link/0
    , init/0
]).
start_link() ->
    Pid = erlang:spawn(?MODULE, init, []),
    register(?MODULE, Pid),
    link(Pid),
    {ok, Pid}.


init() ->
    process_flag(trap_exit, true),
    {ok, Opt} = reloader_config:com_opt(),
    start_check_timer(),
    loop(#state{files = files(), com_opt = Opt, last_time = ?NOW}).

loop(State) ->
    receive
        {timeout, _, check} ->
            check_and_load(State),
            start_check_timer(),
            loop(State#state{last_time = ?NOW});
        Msg ->
            ?ERROR_MSG(" ~p~n", [Msg])
    end.

check_and_load(#state{files = Files, com_opt = ComOpt, last_time = LastTime}) ->
    NowTime = ?NOW,
    Fun = fun({File, Module}) ->
        case reloader_file:read_file_info(File) of
            {ok, #file_info{mtime = MinTime}} when MinTime >= LastTime andalso MinTime =< NowTime ->
                compile:file(File, ComOpt),
                case code:soft_purge(Module) of
                    true ->
                        ?ERROR_MSG(" ~p~n", [Module]),
                        code:load_file(Module);
                    false ->
                        ?ERROR_MSG("hot_update fail:~p", [Module])
                end;
            V ->
                V
        end
          end,
    lists:foreach(Fun, Files).


start_check_timer() ->
    erlang:start_timer(reloader_config:check_interval(), self(), check).


files() ->
    Fun = fun(File) ->
        filelib:is_dir(File)
          end,
    {ok, Src} = reloader_config:src(),
    FilePaths = load_src(Src, [], Fun),
    [{FilePath, get_module(FilePath)} || FilePath <- FilePaths].

load_src(Path, Files, Fun) ->
    {ok, Files1} = file:list_dir(Path),
    {Dirs, ItemFiles} = split(Fun, Files1, {[], []}, Path),
    NewDirs = [filename:join(Path, Dir1) || Dir1 <- Dirs],
    Files2 = [filename:join(Path, ItemFile) || ItemFile <- ItemFiles],
    Fun1 = fun(Dir, TotalFiles) ->
        load_src(Dir, TotalFiles, Fun)
           end,
    lists:foldl(Fun1, Files2 ++ Files, NewDirs).

check_file(File, RegExp) ->
    {ok, Re1} = re:compile(RegExp, [unicode]),
    case (catch re:run(File, if is_binary(File) -> true;
                                 true -> Re1 end,
        [{capture, none}])) of
        match ->
            true;
        _ ->
            false
    end.

split(Fun, [Item | Items], {Pre, Tail}, Path) ->
    case Fun(filename:join(Path, Item)) of
        true ->
            split(Fun, Items, {[Item | Pre], Tail}, Path);
        false ->
            case check_file(Item, ".erl") of
                true ->
                    split(Fun, Items, {Pre, [Item | Tail]}, Path);
                false ->
                    split(Fun, Items, {Pre, Tail}, Path)
            end
    end;

split(_, [], Acc, _Path) ->
    Acc.

get_module(FilePath) ->
    L = string:tokens(FilePath, "/"),
    list_to_atom(hd(string:tokens(lists:last(L), "."))).