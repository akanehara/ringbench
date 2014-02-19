-module(ring).
-export([create/1,createHead/1,createTail/1]).

% リングを作る
create(N) ->
    Head = spawn(ring, createHead, [N]),
    register(head, Head),
    Head.

createHead(1) ->
    % io:format("~p (head) ready ~n", [self()]),
    loopHead(self());
createHead(N) ->
    % io:format("~p (head) ready ~n", [self()]),
    loopHead(spawn(ring, createTail, [N - 1])).

loopHead(Next) ->
    receive
        {Client, {emit, M}} ->
            % io:format("~p emit! Client=~p M=~p~n", [self(), Client, M]),
            Next ! {self(), {relay, Client, M, 1}},
            loopHead(Next);
        {_From, {relay, Client, M=1, Passed}} ->
            % io:format("~p reached! Client=~p M=~p~n", [self(), Client, M]),
            Client ! {self(), {reached, Passed}},
            loopHead(Next);
        {_From, {relay, Client, M, Passed}} ->
            % io:format("~p loop! M=~p~n", [self(), M]),
            Next ! {self(), {relay, Client, M - 1, Passed + 1}},
            loopHead(Next)
    end.

createTail(1) ->
    % io:format("~p (last) ready ~n", [self()]),
    loopTail(whereis(head));
createTail(N) ->
    % io:format("~p (tail) ready ~n", [self()]),
    loopTail(spawn(ring, createTail, [N - 1])).

loopTail(Next) ->
    receive
        {_From, {relay, Client, M, Passed}} ->
            % io:format("~p ralay! M=~p~n", [self(), M]),
            Next ! {self(), {relay, Client, M, Passed + 1}},
            loopTail(Next)
    end.

