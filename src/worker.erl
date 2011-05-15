%% @author Christoffer Brodd-Reijer <christoffer.brodd-reijer.3663@student.uu.se>
%% @copyright 2011 The Awesome Team
%% @doc The worker of the swarm
%% <p>
%% Equivalent to a peer/seeder in the BitTorrent world.
%% bla bla bla, more info goes here
%% </p>

-module(worker).
-export([start_uploader/2, start_downloader/4, init/2, content/0, uploader_loop/1]).
-include_lib("eunit/include/eunit.hrl").
-define(UPLOADPORT, 6789).

content() ->
    Content = 
	[
		{"Filename1", 10, [1, 2, 3]},
		{"Filename2", 2, all},
		{"Filename3", 2, [1]}
	],
    utils:generate_content_string(Content).

%% @doc Starts a worker and listens for requests
%% <p>
%% Dummy function for starting a predefined worker which
%% connects to a hive and then listens for connections.
%% </p>
start_uploader(Key, Sock) -> 
    
    io:format("<uploader> starting~n"),
    network:send(Sock, Key, content()),
	%timer:sleep(1000),
	LSock = network:listenInit(0),
	{ok, PSock} = inet:port(LSock),
	SSock = lists:flatten(io_lib:format("~p", [PSock])),
	io:format("<uploader> printing Listening Port: ~w~n", [SSock]),
	network:send(Sock, Key, SSock),
	%network:send(Sock, Key, 
    io:format("<uploader> listening for requests~n"),
    uploader_loop(LSock).

uploader_loop(Sock) ->
	case network:listen(sock, Sock, fun send_piece/1) of
	{error, Reason} ->
			io:format("<uploader> Could not listen: ~s~n", [Reason]);
	eol -> io:format("<<<<send_piece done>>>>~n"),uploader_loop(Sock);
	_ -> io:format(" Wtf? ~n")
	end.

%% @doc Starts a worker and sends a request
%% <p>
%% Dummy function for starting a predefined worker which
%% connects to a hive and then requests a file.
%% </p>
start_downloader(FileName, Key, Sock, LSock) ->
	io:format("<downloader> starting~n"),
	io:format("<downloader> sending request for file~n"),
	%{ok, Sock} = network:conn("localhost", 5678),
	network:send(Sock, Key, "request"), %Stuck here...
	timer:sleep(100),
	{ok, PSock} = inet:port(LSock),
	SSock = lists:flatten(io_lib:format("~p", [PSock])),
	io:format("<downloader> printing Listening Port: ~s~n", [SSock]),
	network:send(Sock, Key, SSock),
	network:close(Sock),
	io:format("<downloader> listening for piece~n"),
	network:listen(sock, LSock, fun accept_piece/1),
	io:format("<downloader> dying~n").


%% @doc Starts a worker
%% <p>
%% Starts a worker, carrying the content Content and
%% connects to the drone on Address:Port.
%% </p>
init(Address, Port) ->
	io:format("<worker> entering hive~n"),
	case network:conn(Address, Port) of
	
		{error, Reason} ->
			io:format("<worker> could not enter hive: ~s~n", [Reason]);
			
		{ok, Sock} ->
			io:format("<worker> connected to drone~n"),
			case network:handshake(Sock) of
			
				{error, Reason} ->
					io:format("<worker> could not handshake with drone: ~s~n", [Reason]);
					
				{Key, Sock} ->
					io:format("<worker> entered hive successfully~n"),
					% TODO: handle errors
					io:format("<worker> sending content list~n"),
					spawn(worker, start_uploader, [Key, Sock]),
					timer:sleep(1000),
					io:format("<worker> closing connection~n"),
					network:close(Sock),
					io:format("<worker> socket: ~w~n", [Sock]),
					Key
			end
	end.
	
	
%% @doc Handles an incoming request
%% <p>
%% Callback which is called when an incoming connection
%% is made from the drone to send a piece.
%% </p>
send_piece(Sock) ->
	io:format("<worker> incoming request from drone~n"),
	io:format("<uploader> My ID is: ~w~n", [self()]),
	% TODO: handle errors
	Response = network:recv(Sock, ""),
	io:format("<worker> received request: ~s~n", [Response]),
	SPort = network:recv(Sock, ""),
	SAddr = network:recv(Sock, ""),
	io:format("<worker> sending file to: ~w at port: ~s ~n", [SAddr, SPort]),
	% sleep in order to let the other worker get ready for us
	{LPort, []} = string:to_integer(SPort),
	Addr = utils:string_to_ip(SAddr),
	timer:sleep(1000),
	{ok, SSock} = network:conn(Addr, LPort),
	network:send(SSock, "Key", "AwesomePiece"),
	network:close(SSock),
	
	io:format("<worker> closing connection to drone~n"),
	network:close(Sock),
	ok.
	
%% @doc Handles an incoming piece
%% <p>
%% Callback which is called when an incoming connection
%% is made from another worker which is about to send a piece.
%% </p>
accept_piece(Sock) ->
	io:format("<worker> incoming piece from worker~n"),
	io:format("<downloader> My ID is: ~w~n", [self()]),
	% TODO: handle errors
	Response = network:recv(Sock, ""),
	io:format("<worker> received piece: ~s~n", [Response]),
	
	io:format("<worker> closing connection to worker~n"),
	network:close(Sock),
	eol.
