%% @author ??? <???@student.uu.se>
%% @copyright 2011 The Awesome Team
%% @doc The drone of the swarm
%% <p>
%% Equivalent to a tracker in the BitTorrent world.
%% bla bla bla, more info goes here
%% </p>

-module(drone).
-export([start/0, start/1]).
-include_lib("eunit/include/eunit.hrl").

%% @doc Starts a drone
%% <p>
%% Dummy function for starting a predefined drone.
%% </p>
start() -> start(5678).
	
%% @doc Starts a drone
%% <p>
%% Starts the drone on port Port.
%% </p>
start(Port) ->
	register(fileList, spawn(storage, start, [])), 
	io:format("<drone> starting drone~n"),
	network:listen(Port, fun accept_worker/1),
	io:format("<drone> dying~n").
	
	
%% @doc Handles an incoming connection
%% <p>
%% Callback which is called when an incoming connection
%% is made from a worker.
%% </p>
accept_worker(Sock) ->
	io:format("<drone> worker connected~n"),
	
	% TODO: handle errors
	Greeting = network:recv(Sock, ""),
	io:format("<drone> received greeting: ~s~n", [Greeting]),
	
	case Greeting of
	
		 % handshake
		"init" ->
			io:format("<drone> sending challenge~n"),
			% TODO: handle errors
			network:send(Sock, "", "knock knock"),
	
			% TODO: handle errors
			Response = network:recv(Sock, ""),
			io:format("<drone> received response: ~s~n", [Response]),
		
			io:format("<drone> ending handshake~n"),
			% TODO: handle errors
			network:send(Sock, "", "eol"),
		
			% TODO: handle errors
			io:format("<drone> receiving content~n"),
			case network:recv(Sock, "") of
				{error, Reason} -> io:format("<drone> no content~n");
				Content ->
					io:format("<<<For debugging>>~n"),
					case inet:peername(Sock)  of
					{error, EReason} -> io:format("<drone> bleh~n");
					{ok, {Address, Port}} ->
						io:format("<<<For debugging: IP ~w>>>~n", [Address]),
						%gen_tcp:accept(Sock),
						case network:recv(Sock, "") of
						{error, PReason} -> io:format("<drone> no port and reason ~w~n", [PReason]);
					    SPort ->
							io:format("<<For debugging: Port ~s>>~n", [SPort]),
						{LPort, []} = string:to_integer(SPort),
							io:format("<<<For debugging: Port ~w>>>~n", [LPort]),	
							parse_contents(Address, LPort, utils:generate_content_list(Content)),
							io:format("<drone> closing connection to worker~n"),
							network:close(Sock)
						end
					end
			end;
			
		% file request
		"request" ->
			case network:recv(Sock, "") of
				{error, PReason} ->
					io:format("<drone> no port and reason ~w~n", [PReason]);
				SPort ->
					case inet:peername(Sock) of
		            {error, EReason} -> io:format("<drone> bleh~n");
				    {ok, {Address, Port}} ->
						io:format("<<<For debugging: Port ~s>>>~n", [SPort]),
						%{LPort, []} = string:to_integer(SPort),
						io:format("<drone> received request for piece~n"),
						File = "Filename1",
						fileList ! {findfile, File, self()},
						io:format("<drone> just talked to storage ~n"),
						receive
							nosuchfile ->
								io:format("<drone> no such file ~n"),
								network:close(Sock);
							{foundfile, TheFile} ->	
			%["192.168.0.4",5432,10,all]
								io:format("<drone> file found! ~n"),
								IP_addr = lists:nth(1, TheFile),
								Upload_Port = lists:nth(2, TheFile),
								io:format("<drone> this is the port: ~w ~n", [Upload_Port]),
								io:format("<<<For debugging: IP_addr ~w>>>~n", [IP_addr]),
								{ok, SSock} = network:conn(IP_addr, Upload_Port),
								io:format("<<<For debugging: Addr ~w>>>~n", [Address]),
								SAddr = lists:flatten(io_lib:format("~p", [Address])),
								io:format("<<<For debugging: SAddr ~s>>>~n", [SAddr]),
								io:format("<drone> crashed yet? ~n"),
								network:send(SSock, "Key", "send file"),
								timer:sleep(50),
								network:send(SSock, "Key", SPort),
								timer:sleep(50),
								network:send(SSock, "Key", SAddr),
								network:close(SSock),
								io:format("<drone> closing connection to worker~n"),
								network:close(Sock)
						end
				end
			end
	end,
	ok.
			
	
%% @doc TODO
%% <p>
%% TODO
%% </p>
parse_contents(_, _, []) -> io:format("<drone> content: end~n");
parse_contents(Addr, Port, [H|T]) ->
	save_file(Addr, Port, H),
	parse_contents(Addr, Port, T).
	
%% @doc TODO
%% <p>
%% TODO
%% </p>
save_file(Addr, Port, {Name, Pieces, Possessions}) -> 
	io:format("<drone> file: ~s (~w pieces, possessions: ~w)~n", [Name, Pieces, Possessions]),
	fileList ! {add, Addr, Port, Name, Pieces, Possessions}.
