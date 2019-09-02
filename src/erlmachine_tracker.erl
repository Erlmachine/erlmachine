-module(erlmachine_tracker).

-folder(<<"erlmachine/erlmachine_tracker">>).

-behaviour(gen_server).
-behaviour(erlmachine_transmission).

%% API.
-export([start_link/0]).
-export([tracking_number/1, tracking_number/2, trace/2]).

%% Callbacks

%% gen_server.
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

%% erlmachine_filesystem
-export([directory/0, directory/3]).


-callback tag(Packakge::term()) -> ID::binary().

%% API.

-record('trace', {package :: map(), tracking_number :: binary()}).

-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Catalog, []).

-spec tracking_number(Tracker::atom(), Package::term()) -> Number::binary().
tracking_number(Tracker, Package) ->
    Tag = Tracker:tag(Package),
    tracking_number(Tag).

-spec tracking_number(Tag::binary()) -> Number::binary().
tracking_number(Tag) when is_binary(Tag) ->
    GUID = <<"GUID">>, %% TODO 
    <<Tag/binary, ".", GUID/binary>>.

-spec trace(TrackingNumber::binary(), Package::map()) -> TrackingNumber::binary().
trace(TrackingNumber, Package) ->
    erlmachine_transmission:rotate(?MODULE, #{TrackingNumber => Package}).


%% gen_server.

-record(state, {transmission :: atom()}).

init(Catalogue) ->
    {ok, #state{transmission = ?MODULE}}.

handle_call(_Request, _From, State) ->
    %% We need to provide REST API for management inside transmission
    %% We need to incapsulate transmission management inside callbacks
    %% We need to provide  measurements of transmission loading, etc..
	{reply, ignored, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% erlmachine_transmission.


