-module(iotserv_db).
-behaviour(gen_server).

-export([start_link/0, stop/0]).
-export([add_device/1, delete_device/1, update_device/1, lookup_device/1, list_devices/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("iotserv.hrl").

-record(state, {dets_file}).

%% Типы для записи устройства
%% -type device_id() :: integer().
%% -type metrics() :: [{atom(), number()}].

%% API
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:stop(?MODULE).

add_device(#iot_device{id = Id} = Device) ->
    gen_server:call(?MODULE, {add, Id, Device}).

delete_device(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

update_device(#iot_device{id = Id} = Device) ->
    gen_server:call(?MODULE, {update, Id, Device}).

lookup_device(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

list_devices() ->
    gen_server:call(?MODULE, list_all).

%% Callbacks
init([]) ->
    % Получаем имя файла из конфига или используем дефолт
    DetsFile = application:get_env(iotserv, dets_file, "iotserv.dat"),
    
    % Создаём ETS таблицу
    ets:new(iotserv_ram, [named_table, public, {keypos, #iot_device.id}]),
    
    % Открываем DETS файл
    {ok, _} = dets:open_file(iotserv_disk, [{file, DetsFile}, {keypos, #iot_device.id}]),
    
    % Восстанавливаем данные из DETS в ETS
    restore_from_dets(),
    
    {ok, #state{dets_file = DetsFile}}.

terminate(_Reason, _State) ->
    dets:sync(iotserv_disk),
    dets:close(iotserv_disk),
    ets:delete(iotserv_ram),
    ok.

handle_call({add, Id, Device}, _From, State) ->
    Reply = case ets:lookup(iotserv_ram, Id) of
        [] ->
            ets:insert(iotserv_ram, Device),
            dets:insert(iotserv_disk, Device),
            ok;
        [_] -> {error, exists}
    end,
    {reply, Reply, State};

handle_call({delete, Id}, _From, State) ->
    Reply = case ets:lookup(iotserv_ram, Id) of
        [_] ->
            ets:delete(iotserv_ram, Id),
            dets:delete(iotserv_disk, Id),
            ok;
        [] -> {error, not_found}
    end,
    {reply, Reply, State};

handle_call({update, Id, Device}, _From, State) ->
    Reply = case ets:lookup(iotserv_ram, Id) of
        [_] ->
            ets:insert(iotserv_ram, Device),
            dets:insert(iotserv_disk, Device),
            ok;
        [] -> {error, not_found}
    end,
    {reply, Reply, State};

handle_call({lookup, Id}, _From, State) ->
    Reply = case ets:lookup(iotserv_ram, Id) of
        [Device] -> {ok, Device};
        [] -> {error, not_found}
    end,
    {reply, Reply, State};

handle_call(list_all, _From, State) ->
    {reply, ets:tab2list(iotserv_ram), State};

handle_call(_Req, _From, State) ->
    {reply, {error, unknown}, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%% Internal
restore_from_dets() ->
    Fun = fun(Device) when is_record(Device, iot_device) ->
        ets:insert(iotserv_ram, Device),
        continue
    end,
    dets:traverse(iotserv_disk, Fun).