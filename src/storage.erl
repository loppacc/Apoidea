-module(storage).
-export([start/0, add_crap/0]).
-include_lib("eunit/include/eunit.hrl").



table() ->
	ets:new('TheFileList', []).

add_file(FileMap, {IP, Port, Name, Peices, Possessions}) ->
	ets:insert(FileMap, {{Name, IP}, Port, Peices, Possessions}).

%find_peice(FileMap, FileName, Peice) ->
%	ok.
%   ets:match(FileMap, {{FilenName, '$2'}, '$3', '$4', '$5'}).

all(FileMap) ->
	ets:tab2list(FileMap).

find_file(FileMap, File) ->
	ets:match(FileMap, {{File, '$2'}, '$3', '$4', '$5'}).


client_del_file(FileMap, Key) ->
	ets:delete(FileMap,Key).

del_client(FileMap, IP) ->
	ets:match_delete(FileMap, {{'_', IP}, '_', '_', '_'}).
	%ets:delete_object(FileMap, {{'_', IP}, '_', '_', '_'}).
	%ets:delete(FileMap, {'_', IP}).

start() ->
	FileMap = table(),
	loop(FileMap).

loop(FileMap) ->
	receive 
		{add, Addr, Port, Name, Peices, Possessions} ->
			add_file(FileMap, {Addr, Port, Name, Peices, Possessions}),
			loop(FileMap);
		{findfile, File, PID} ->
			case find_file(FileMap, File) of
				[] -> PID ! nosuchfile;
				[T|H] -> PID ! {foundfile, T}
			end,
			loop(FileMap)
	end.
		
		


add_crap() ->
	FileMap = table(),
	add_file(FileMap, {"localhost", 80, "Testfile", 10, all}),
	add_file(FileMap, {"192.168.0.1", 1234, "WoW.exe", 100, [1,2,3,4,5,6, 95]}),
	add_file(FileMap, {"192.168.0.2", 1235, "Porn.exe", 2, [1]}),
	add_file(FileMap, {"192.168.0.3", 1236, "NotAVirus.bat", 5, [1,2,3,4]}),
	add_file(FileMap, {"192.168.0.1", 1234, "Wc3.exe", 50, all}),
	add_file(FileMap, {"192.168.0.4", 5432, "Testfile", 10, all}),
	add_file(FileMap, {"192.168.0.4", 5432, "Skype.exe", 5, all}),
	O = "Testfile",
	X = find_file(FileMap, O),
	io:format("~n-Testfile- found at: ~p ~n", [X]),
	Z = all(FileMap),
	io:format("~n-The entire FileMap: ~p ~n", [Z]),
	P = "WoW.exe",
	io:format("~n-Client deleted: ~s ~n", [P]),
	client_del_file(FileMap, {P, "192.168.0.1"}),
	Y = all(FileMap),
	io:format("~n-The entire FileMap: ~p ~n", [Y]),
	IP = "192.168.0.4",
	io:format("~n-Client <~s> disconnected ~n", [IP]),
	del_client(FileMap, IP),
	K = all(FileMap),
	io:format("~n-The entire FileMap: ~p ~n", [K]).	  
%	Z = find_IP(FileMap, "192.168.0.1"),
%	io:format("~n-IP x.x.x.1 : ~p ~n", [Z]),
%	K = del_client(FileMap, "192.168.0.1"),
%	io:format("Deleted rows: ~w~n", [K]),
%	Q = all(FileMap),
%	io:format("~n-The entire FileMap: ~p ~n", [Q]).
