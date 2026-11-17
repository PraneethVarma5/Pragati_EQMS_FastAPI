SELECT
    evtname AS event_trigger_name,
    evtevent AS event_type,
    evtenabled AS enabled,
    evtfoid::regprocedure AS function_called
FROM pg_event_trigger
ORDER BY evtname;
