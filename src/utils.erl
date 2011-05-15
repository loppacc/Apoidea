%% @author ??? <???@student.uu.se>
%% @copyright 2011 The Awesome Team
%% @doc A Swiss Army Knife
%% <p>
%% </p>
%% bla bla bla

-module(utils).
-export([generate_content_string/1, generate_content_list/1, list_to_string/2, parse_content_tuple/1, strings_to_ints/1, string_to_ip/1]).
-include_lib("eunit/include/eunit.hrl").

%% @doc Generates a string from a content list.
%% <p>
%% </p>
%% A content list is on the format
%% [Content1, Content2, ..., ContentN]
%% where ContentX = [Name, NumberOfPieces, PiecesInPossesion]
%% where
%% Name = Name of the content
%% NumberOfPieces = The number of pieces that the content is divided into
%% PiecesInPossesion = The number of pieces that the worker has downloaded
%% PiecesInPossesion can either be an integer or the atom "all"
%%
%% A content string is on the format
%% Name_x1\nNumberOfPieces_x1\nPiecesInPossesion_x1\n\nName_x2...
%%
%% That is: each content is separated by double newlines and each
%% element inside the content is separated by a single newline.
generate_content_string([]) -> lists:concat([]);
generate_content_string([H|T]) ->
	L1 = io_lib:format("~s~s~w~s~s", [
		element(1, H),
		"\t",
		element(2, H),
		"\t",
		case element(3, H) of
			all -> "all";
			Pieces -> list_to_string(Pieces, ",")
		end
	]),
	case T of
		[] -> lists:concat(L1);
		_ ->
			lists:concat(
				lists:append(L1, 
					io_lib:format("~n~s", [generate_content_string(T)])
				)
			)
	end.
	
%% @doc Generates a content list from a content string
%% <p>
%% </p>
generate_content_list(String) -> generate_content_tuples(string:tokens(String, "\n")).

%% @doc TODO
%% <p>
%% </p>
generate_content_tuples([]) -> [];
generate_content_tuples([H|T]) -> 
	Tuple = parse_content_tuple(list_to_tuple(string:tokens(H, "\t"))),
	lists:append([Tuple], generate_content_tuples(T)).
	
%% @doc Parse a content tuple
%% <p>
%% Turns the third element of a content tuple from a string into
%% either an atom or a list and fixes all integers.
%% </p>
parse_content_tuple({Name, Pieces, "all"}) -> {Name, string_to_int(Pieces), all};
parse_content_tuple({Name, Pieces, Possessions}) ->
	{
		Name, 
		string_to_int(Pieces),
		strings_to_ints(string:tokens(Possessions, ","))
	}.

%% @doc Turns a list of strings into a list of integers
%% <p>
%% TODO
%% </p>
strings_to_ints([]) -> [];
strings_to_ints([H|T]) -> lists:append([string_to_int(H)], strings_to_ints(T)).

%% @doc Turns a string into an integer
%% <p>
%% TODO
%% </p>
string_to_int(S) -> element(1, string:to_integer(S)).
		
%% @doc Generate a string from a list
%% <p>
%% Create a string from the list List using Sep as
%% the separator between each element.
%% </p>
list_to_string([], _) -> lists:concat([]);
list_to_string([H], _) -> lists:concat([H]);
list_to_string([H|T], Sep) ->
	lists:append(lists:append([lists:concat([H]), Sep], [list_to_string(T, Sep)])).


%% @doc Creates an IP Address tuple out of a string list.
%% <p>
%% </p>
string_to_ip(L) -> string_to_ip([], L).

string_to_ip(L, []) -> erlang:list_to_tuple(L);
string_to_ip(I, L) ->
case string:to_integer(L) of 
	{error, Reason} -> 
		[H | T] = L,	
		string_to_ip(I, T);
	{I1, Rest} -> 
		%io:format("Whats in here? ~w ~n", [I1]),
		L2 = lists:append(I, [I1]),
		string_to_ip(L2, Rest)
	end.	


%%--- TEST CASES ---
list_to_string_test() ->
	?assert(list_to_string([], ",") =:= []),
	?assert(list_to_string([1, 2, 3], ",") =:= "1,2,3"),
	?assert(list_to_string([3, 2, 1], "&") =:= "3&2&1").
	
string_to_int_test() ->
	?assert(string_to_int("1") =:= 1),
	?assert(string_to_int("835") =:= 835).
	
strings_to_ints_test() ->
	?assert(strings_to_ints([]) =:= []),
	?assert(strings_to_ints(["1", "2", "3"]) =:= [1, 2, 3]).
	
parse_content_tuple_test() ->
	?assert(parse_content_tuple({"foo", "2", "all"}) =:= {"foo", 2, all}),
	?assert(parse_content_tuple({"foo", "2", "1,2"}) =:= {"foo", 2, [1,2]}).
	
generate_content_list_test() ->
	ContentList = [
		{"file1", 3, [1, 2]},
		{"file2", 2, all},
		{"file3", 3, [1]}
	],
	ContentString = "file1\t3\t1,2\nfile2\t2\tall\nfile3\t3\t1",
	?assert(generate_content_list(ContentString) =:= ContentList).

generate_content_string_test() ->
	ContentList = [
		{"file1", 3, [1, 2]},
		{"file2", 2, all},
		{"file3", 3, [1]}
	],
	ContentString = "file1\t3\t1,2\nfile2\t2\tall\nfile3\t3\t1",
	?assert(generate_content_string(ContentList) =:= ContentString).
	
content_test() ->
	ContentList = [
		{"file1", 3, [1, 2]},
		{"file2", 2, all},
		{"file3", 3, [1]}
	],
	ContentString = "file1\t3\t1,2\nfile2\t2\tall\nfile3\t3\t1",
	?assert(generate_content_string(generate_content_list(ContentString)) =:= ContentString).

string_to_ip_test() ->
	?assert(string_to_ip([123,49,50,55,44,48,44,48,44,49,125]) =:= {127,0,0,1}).	
