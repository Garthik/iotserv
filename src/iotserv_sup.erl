-module(iotserv_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 3, period => 5},
    
    DbChild = #{
        id => iotserv_db,
        start => {iotserv_db, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [iotserv_db]
    },
    
    ServChild = #{
        id => iotserv,
        start => {iotserv, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [iotserv]
    },
    
    {ok, {SupFlags, [DbChild, ServChild]}}.