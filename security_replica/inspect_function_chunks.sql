WITH funcs AS (
    SELECT
        p.proname,
        pg_get_functiondef(p.oid) AS definition
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
),
chunks AS (
    SELECT
        f.proname,
        g.chunk_no,
        SUBSTRING(f.definition FROM ((g.chunk_no - 1) * 1200 + 1) FOR 1200) AS code_chunk
    FROM funcs f
    CROSS JOIN LATERAL generate_series(
        1,
        CEIL(LENGTH(f.definition)::numeric / 1200)::integer
    ) AS g(chunk_no)
)
SELECT proname, chunk_no, code_chunk
FROM chunks
ORDER BY proname, chunk_no;
