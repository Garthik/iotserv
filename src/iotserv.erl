-module(iotserv).
-behaviour(gen_server).

-export([start_link/0, stop/0]).
-export([add/4, add/5, delete/1, change/2, change/3, lookup/1, list/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("iotserv.hrl").

-record(state, {}).

%% ============================================================================
%% Public API
%% ============================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:cast(?MODULE, stop).

%% Add device: Id, Name, Address, Temperature
add(Id, Name, Address, Temp) ->
    Device = create_device(Id, Name, Address, Temp, []),
    gen_server:call(?MODULE, {add_device, Device}).

%% Add device with metrics
add(Id, Name, Address, Temp, Metrics) ->
    Device = create_device(Id, Name, Address, Temp, Metrics),
    gen_server:call(?MODULE, {add_device, Device}).

%% Delete device by ID
delete(Id) ->
    gen_server:call(?MODULE, {delete_device, Id}).

%% Change: update single field
change(Id, {Field, Value}) ->
    gen_server:call(?MODULE, {update_field, Id, Field, Value}).

%% Change: full device update (Id, NewName, NewAddress)
change(Id, NewName, NewAddress) ->
    gen_server:call(?MODULE, {update_info, Id, NewName, NewAddress}).

%% Lookup device by ID
lookup(Id) ->
    gen_server:call(?MODULE, {lookup_device, Id}).

%% List all devices
list() ->
    gen_server:call(?MODULE, list_devices).

%% ============================================================================
%% gen_server Callbacks
%% ============================================================================

init([]) -> 
    {ok, #state{}}.

terminate(_Reason, _State) -> 
    ok.

handle_cast(stop, State) -> 
    {stop, normal, State};
handle_cast(_Msg, State) -> 
    {noreply, State}.

handle_call({add_device, Device}, _From, State) ->
    {reply, iotserv_db:add_device(Device), State};

handle_call({delete_device, Id}, _From, State) ->
    {reply, iotserv_db:delete_device(Id), State};

handle_call({update_field, Id, Field, Value}, _From, State) ->
    Reply = case iotserv_db:lookup_device(Id) of
        {ok, Dev} ->
            Updated = update_field_in_device(Dev, Field, Value),
            iotserv_db:update_device(Updated);
        {error, _} = Err -> 
            Err
    end,
    {reply, Reply, State};

handle_call({update_info, Id, NewName, NewAddress}, _From, State) ->
    Reply = case iotserv_db:lookup_device(Id) of
        {ok, Dev} ->
            Updated = Dev#iot_device{name = NewName, address = NewAddress},
            iotserv_db:update_device(Updated);
        {error, _} = Err -> 
            Err
    end,
    {reply, Reply, State};

handle_call({lookup_device, Id}, _From, State) ->
    {reply, iotserv_db:lookup_device(Id), State};

handle_call(list_devices, _From, State) ->
    {reply, iotserv_db:list_devices(), State};

handle_call(_Req, _From, State) ->
    {reply, {error, unknown}, State}.

handle_info(_Info, State) -> 
    {noreply, State}.

code_change(_OldVsn, State, _Extra) -> 
    {ok, State}.

%% ============================================================================
%% Internal Helpers
%% ============================================================================

%% Create device record
create_device(Id, Name, Address, Temp, Metrics) ->
    #iot_device{
        id = Id,
        name = Name,
        address = Address,
        temperature = Temp,
        metrics = Metrics,
        status = online,
        updated_at = erlang:system_time(second)
    }.

%% Update field in device record
update_field_in_device(Dev, name, V) -> 
    Dev#iot_device{name = V};
update_field_in_device(Dev, address, V) -> 
    Dev#iot_device{address = V};
update_field_in_device(Dev, temperature, V) when is_number(V) -> 
    Dev#iot_device{temperature = V};
update_field_in_device(Dev, metrics, V) when is_list(V) -> 
    Dev#iot_device{metrics = V};
update_field_in_device(Dev, status, V) when V == online; V == offline; V == error -> 
    Dev#iot_device{status = V};
update_field_in_device(Dev, _F, _V) -> 
    Dev.