# iotserv
1> application:ensure_all_started(iotserv).
{ok,[iotserv]}
2> iotserv:add(1, "Sensor 1", "Loc 1", 20.0).
ok
3> iotserv:add(2, "Sensor 2", "Loc 2", 21.0, [{temp, 25}]).
ok
4> iotserv:lookup(1). 
{ok,{iot_device,1,"Sensor 1","Loc 1",20.0,[],online,
                1778238888}}
5> iotserv:lookup(999).
{error,not_found}
6> iotserv:list().
[{iot_device,1,"Sensor 1","Loc 1",20.0,[],online,1778238888},
 {iot_device,2,"Sensor 2","Loc 2",21.0,
             [{temp,25}],
             online,1778238896}]
7> iotserv:change(1, {temperature, 22.5}).
ok
8> iotserv:change(1, {status, offline}).
ok
9> iotserv:list().
[{iot_device,1,"Sensor 1","Loc 1",22.5,[],offline,
             1778238888},
 {iot_device,2,"Sensor 2","Loc 2",21.0,
             [{temp,25}],
             online,1778238896}]
10> iotserv:change(1, "Updated Name", "New Location").
ok
11> iotserv:list().                                   
[{iot_device,1,"Updated Name","New Location",22.5,[],
             offline,1778238888},
 {iot_device,2,"Sensor 2","Loc 2",21.0,
             [{temp,25}],
             online,1778238896}]
12> iotserv:delete(2).
ok
13> iotserv:lookup(2).
{error,not_found}
14> application:stop(iotserv).
=INFO REPORT==== 8-May-2026::11:16:55.517445 ===
    application: iotserv
    exited: stopped
    type: temporary

ok
15> application:ensure_all_started(iotserv).
{ok,[iotserv]}
16> iotserv:list().
[{iot_device,1,"Updated Name","New Location",22.5,[],
             offline,1778238888}]
