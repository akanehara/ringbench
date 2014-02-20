-module(ringbench).
-export([main/1, main/0]).

% Remote Procedure Call
rpc(To, Msg, Timeout, Alt) ->
    To ! {self(), Msg},
    receive
        {To, Val} -> Val
    after Timeout -> Alt
    end.

% ベンチマーク
bench(Ring, N, M) ->
    statistics(wall_clock),
    case rpc(Ring, {emit, M}, 5000, timeout) of
        {reached, Passed} ->
            {_, Time} = statistics(wall_clock),
            io:format("N=~p, M=~p : ~p processes passed, ~p sec.~n", [N, M, Passed, Time / 1000]);
        timeout -> void
    end.

usage() -> io:format("Usage: ringbench main N M~n").

main([ArgN, ArgM | _]) ->
    try
        N = list_to_integer(atom_to_list(ArgN)),
        M = list_to_integer(atom_to_list(ArgM)),
        Ring = ring:create(N), % リングを作る
        rpc(Ring, {emit, 1}, 5000, void), % 最初のメッセージが一周したことをもってリングの完成を確認する
        bench(Ring, N, M) % ベンチマーク開始
    catch
        error:{badarg, _} ->
            usage(),
            init:stop()
    end;
main(_) -> usage().
main()  -> usage().

