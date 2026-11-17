SELECT
    c.relname AS table_name,
    CASE
        WHEN a.grantee = 0 THEN 'PUBLIC'
        ELSE r.rolname
    END AS grantee,
    STRING_AGG(a.privilege_type, ', ' ORDER BY a.privilege_type) AS privileges,
    BOOL_OR(a.is_grantable) AS grantable
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL aclexplode(
    COALESCE(c.relacl, acldefault('r', c.relowner))
) AS a
LEFT JOIN pg_roles r ON r.oid = a.grantee
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relname IN (
    'admin_profiles',
    'audit_admin_sessions',
    'audit_admins',
    'ccr_sessions',
    'ccr_users',
    'dcc_dmr_requests',
    'dcc_document_requests',
    'dcc_folders',
    'dcc_master_data',
    'dcc_sessions',
    'ncr_approval_history',
    'ncr_roles',
    'ncr_statuses',
    'ncr_users',
    'ncrs'
  )
GROUP BY c.relname, a.grantee, r.rolname
ORDER BY c.relname, grantee;
