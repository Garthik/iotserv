-record(iot_device, {
    id :: integer(),
    name :: string(),
    address :: string(),
    temperature :: number(),
    metrics :: [{atom(), number()}],
    status = online :: online | offline | error,
    updated_at :: integer()
}).