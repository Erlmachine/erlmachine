-module(erlmachine_tracker).

-folder(<<"erlmachine/erlmachine_tracker">>).

-rotate([?MODULE]).
%%-output([?MODULE]). We can use as output  only the last element of branch inside topology cause prevention of blocking by sync calls
-behaviour(gen_server).

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

-callback tag(Packakge::term()) -> ID::binary().

%% API.

-spec start_link() -> {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec tracking_number(Tracker::atom(), Package::term()) -> Number::binary().
tracking_number(Tracker, Package) ->
    Tag = Tracker:tag(Package),
    tracking_number(Tag).

-spec tracking_number(Tag::binary()) -> Number::binary().
tracking_number(Tag) when is_binary(Tag) ->
    GUID = <<"GUID">>, %% TODO 
    <<Tag/binary, ".", GUID/binary>>.

-record(trace, {package :: map(), tracking_number :: binary()}).

-spec trace(TrackingNumber::binary(), Package::map()) -> TrackingNumber::binary().
trace(TrackingNumber, Package) ->
    erlang:send(?MODULE, #trace{tracking_number = TrackingNumber, package = Package}).


%% gen_server.

-record(produce, {model :: atom()}).
-record(state, {model = ?MODULE :: atom, serial_number :: binary()}).

init([]) ->
    %% I guess model doesn't change without specialized behaviour supporting; 
    Model = erlmachine_transmission:model(?MODULE),
    {ok,  #state{model = Model}, {continue, #produce{model = Model}}}.

handle_call(_Request, _From, State) ->
    %% We need to provide REST API for management inside transmission
    %% We need to incapsulate transmission management inside callbacks
    %% We need to provide  measurements of transmission loading, etc..
	{reply, ignored, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(#trace{} = Command, #state{transmission = Transmission} = State) ->
    #trace{tracking_number = TrackingNumber, package = Package} = Command,
    erlmachine_transmission:rotate(Transmission, #{TrackingNumber => Package}), %% we need to find default input here
    {noreply, State};
handle_info() ->
    {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

-record(check, {model :: atom()}).

handle_continue(#produce{model = Model}, State) -> 
    try
        SerialNumber = erlmachine_factory:produce(?MODULE, Model), 
        {noreply, State#state{serial_number = SerialNumber}, {continue, #check{model = Model}}};
    catch E:R ->
            {stop, {E, R}, State} 
    end;
handle_continue(#check{model = Model}, State) -> 
    try
        erlmachine_factory:check(SerialNumber),
        {noreply, State};
    catch E:R ->
            {stop, {E, R}, State} 
    end;
handle_continue(_, State) -> 
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

format_status(Opt, [PDict, State]) -> 
    [].

%% erlmachine_transmission.


