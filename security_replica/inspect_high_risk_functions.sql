SELECT
    p.proname AS function_name,
    pg_get_userbyid(p.proowner) AS owner,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
      'dcc_upsert_user',
      'complete_arr',
      'ncr_admin_delete_user',
      'admin_reset_password_after_otp',
      'ncr_admin_all_ncrs'
  )
ORDER BY p.proname;
