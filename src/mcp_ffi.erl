-module(mcp_ffi).
-export([port_open/2, port_close/1, port_send/2, request_id/0, coerce_message/1]).

%% Stdio
port_open(PortName, PortSettings) ->
  try 
    Port = erlang:open_port(PortName, PortSettings),
    {ok, Port}
  catch
    error:badarg -> {error, badarg};
    _ -> {error, other}
  end.

port_close(Port) -> erlang:port_close(Port), {ok, nil}.

port_send(Port, Data) ->
  try
    erlang:port_command(Port, Data),
    {ok, nil}
  catch
    error:badarg -> {error, badarg};
    _ -> {error, other}
  end.

coerce_message({Port, {data, Chunk}}) -> {message_chunk, {Port, Chunk}};
coerce_message({Port, {exit_status, _}}) -> {message_exit, Port};
coerce_message(Other) -> io:format("unexpected: ~p~n", [Other]), {message_other}.


%% SSE

%% Utilities
request_id() -> erlang:unique_integer([positive, monotonic]).

%% normalize(ok) ->
%%   {ok, nil};
%% normalize({ok, P}) -> {ok, P}.

