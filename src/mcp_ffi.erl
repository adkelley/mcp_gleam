-module(mcp_ffi).
-export([port_open/2, port_close/1]).

port_open(PortName, PortSettings) ->
  try 
  Port = erlang:open_port(PortName, PortSettings),
  {ok, Port}
  catch
    error:badarg -> {error, badarg};
    _ -> {error, other}
  end.

port_close(Port) -> erlang:port_close(Port), {ok, true}.
