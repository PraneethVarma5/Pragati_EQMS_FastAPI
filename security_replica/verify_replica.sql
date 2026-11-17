SELECT
    (SELECT COUNT(*)
     FROM pg_tables
     WHERE schemaname IN ('public', 'db_backup')) AS tables,

    (SELECT COUNT(*)
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname IN ('public', 'db_backup')
       AND p.prokind = 'f') AS functions,

    (SELECT COUNT(*)
     FROM pg_trigger t
     JOIN pg_class c ON c.oid = t.tgrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname IN ('public', 'db_backup')
       AND NOT t.tgisinternal) AS triggers,

    (SELECT COUNT(*)
     FROM pg_policy p
     JOIN pg_class c ON c.oid = p.polrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname IN ('public', 'db_backup')) AS policies,

    (SELECT COUNT(*)
     FROM pg_indexes
     WHERE schemaname IN ('public', 'db_backup')) AS indexes,

    (SELECT COUNT(*)
     FROM pg_constraint c
     JOIN pg_class r ON r.oid = c.conrelid
     JOIN pg_namespace n ON n.oid = r.relnamespace
     WHERE n.nspname IN ('public', 'db_backup')) AS constraints,

    (SELECT COUNT(*)
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname IN ('public', 'db_backup')
       AND c.relkind IN ('v', 'm')) AS views,

    (SELECT COUNT(*)
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname IN ('public', 'db_backup')
       AND c.relkind IN ('r', 'p')
       AND c.relrowsecurity) AS rls_enabled_tables;
