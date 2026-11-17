SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_userbyid(p.proowner) AS owner,
    p.prosecdef AS security_definer,
    CASE
        WHEN acl.grantee = 0 THEN 'PUBLIC'
        ELSE r.rolname
    END AS executable_by,
    acl.privilege_type,
    acl.is_grantable
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
CROSS JOIN LATERAL aclexplode(
    COALESCE(p.proacl, acldefault('f', p.proowner))
) AS acl
LEFT JOIN pg_roles r ON r.oid = acl.grantee
WHERE n.nspname = 'public'
  AND p.prosecdef = true
ORDER BY p.proname, executable_by;
