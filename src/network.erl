%% @author Christoffer Brodd-Reijer <christoffer.brodd-reijer.3663@student.uu.se>
%% @copyright 2011 The Awesome Team
%% @doc Low-level network module
%% <p>
%% Sends and receives data over the network.
%% bla bla bla, more info goes here
%% </p>

-module(network).
-export([conn/2, send/3, send/5, recv/2, listen/2, listen/3, listenInit/1,	close/1, handshake/1]).
-define(TCPOPTS, [list, {active, false}, {packet, 0}, {reuseaddr, true}]).
-define(UDPOPTS, [list, {active, false}, {packet, 0}]).
-include_lib("eunit/include/eunit.hrl").


%% @doc Creates a connection over TCP
%% <p>
%% Connect to Address:Port over TCP
%% </p>
conn(Address, Port) ->
	case gen_tcp:connect(Address, Port, ?TCPOPTS) of
		{error, Reason} -> {error, report_error(Reason)};
		{ok, Sock} -> {ok, Sock}
	end.
	
%% @doc Does a three-way handshake
%% <p>
%% Uses a connection to create a three-way handshake
%% </p>
handshake(Sock) ->
	io:format("<net> handshake: connected~n"),

	% part 0: start handshake
	case gen_tcp:send(Sock, "init") of
		{error, Reason} ->
			{error, report_error(Reason)};
			
		ok ->
			% part 1: receive challenge
			case gen_tcp:recv(Sock, 0) of

				{error, Reason} ->
					{error, report_error(Reason)};
	
				{ok, Challenge} ->
					io:format("<net> handshake: challenge: ~s~n", [Challenge]),

					% TODO: do some stuff with the Challenge and calculate Response
					Response = "who's there?",

					% part 2: send response
					case gen_tcp:send(Sock, Response) of
						{error, Reason} ->
							{error, report_error(Reason)};
					
						ok ->
							io:format("<net> handshake: response: ~s~n", [Response]),
		
							% part 3: receive completion
							case gen_tcp:recv(Sock, 0) of
								{error, Reason} ->
									{error, report_error(Reason)};
								{ok, Completion} ->
									io:format("<net> handshake: completion: ~s~n", [Completion]),
									% TODO: calculate a key
									Key = "",
									{Key, Sock}
							end
					end
			end
	end.

%% @doc Sends an encrypted message over a socket
%% <p>
%% Uses Key to encrypt Message and sends it over Sock.
%% </p>
send(Sock, Key, Message) ->
	CryptMessage = crypto:encrypt(Message, Key),
	gen_tcp:send(Sock, CryptMessage).

%% @doc Sends an encrypted message over TCP or UDP
%% <p>
%% Connects to Address:Port and sends Message
%% encrypted using Key over TCP or UDP.
%% </p>
send(Address, Port, Key, tcp, Message) ->
	case gen_tcp:connect(Address, Port, ?TCPOPTS) of
		{error, Reason} -> {error, report_error(Reason)};
		
		{ok, Sock} ->
			CryptMessage = crypto:encrypt(Message, Key),
			gen_tcp:send(Sock, CryptMessage),
			gen_tcp:close(Sock)
	end;
send(Address, Port, Key, udp, Message) ->
	case gen_udp:open(Port) of
		{error, Reason} -> {error, report_error(Reason)};
			
		{ok, Sock} ->
			CryptMessage = crypto:decrypt(Message, Key),
			gen_udp:send(Sock, Address, Port, CryptMessage)
	end;
send(_, _, _, _, _) -> {error, unknown_proto}.
	
%% @doc Receives an encrypted message over a socket
%% <p>
%% Receives data from Sock and decrypts it using Key.
%% </p>
recv(Sock, Key) ->
	case gen_tcp:recv(Sock, 0) of
		{error, Reason} -> {error, report_error(Reason)};
		{ok, CryptMessage} -> crypto:decrypt(CryptMessage, Key)
	end.
	
%% @doc Listens for connections
%% <p>
%% Listens for incoming connection on port Port and calls
%% Callback when a connection is accepted.
%% </p>
listen(Port, Callback) ->
	io:format("<<<Listening initated by: ~w on port: ~w >>>~n", [self(), Port]),
	timer:sleep(1000),
	case gen_tcp:listen(Port, ?TCPOPTS) of
		{error, Reason} -> {error, report_error(Reason)};
		{ok, Sock} -> listen(sock, Sock, Callback)
	end.

%% @doc Listens for connections over a socket
%% <p>
%% Listens for incoming connection on ListenSock and calls
%% Callback when a connection is accepted.
%% </p>
listen(sock, ListenSock, Callback) ->
	io:format("Listening. . . by: ~w ~n", [self()]),
	case gen_tcp:accept(ListenSock) of
		{error, Reason} -> {error, report_error(Reason)};
		
		{ok, Sock} ->
			case Callback(Sock) of %spawn 
				ok -> listen(sock, ListenSock, Callback);
				eol -> eol
			end
	end.

%% @doc Initiating a listen
%% <p>
%% Listens on Port, and returns the Listen Socket.
%% </p>
listenInit(Port) ->
	case gen_tcp:listen(Port, ?TCPOPTS) of
		{error, Reason} -> {error, report_error(Reason)};
        {ok, Sock} -> Sock
	end.


%% @doc Closes a socket
%% <p>
%% Closes the connection over Sock.
%% </p>
close(Sock) ->
	gen_tcp:close(Sock).
	
%% @doc Prints an error
%% <p>
%% Prints an error message to STDOUT according to Error.
%% </p>
report_error(Error) ->
	case Error of
		closed ->
			io:format("<net> the connection was closed~n"),
			closed;
		% TODO: add more cases
		Reason ->
			io:format("<net> there was a problem with the connection: ~s~n", [Reason]),
			Reason
	end.
