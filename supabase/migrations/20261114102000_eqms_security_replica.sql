


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "db_backup";


ALTER SCHEMA "db_backup" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."audit_categories" (
    "category_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type_id" "uuid" NOT NULL,
    "category_name" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_categories_name_not_empty" CHECK (("length"(TRIM(BOTH FROM "category_name")) > 0)),
    CONSTRAINT "audit_categories_sort_order_check" CHECK (("sort_order" >= 0))
);


ALTER TABLE "public"."audit_categories" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_create_audit_category"("p_session_token" "text", "p_type_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean DEFAULT true) RETURNS "public"."audit_categories"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_categories;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.audit_types
        WHERE type_id = p_type_id
    ) THEN
        RAISE EXCEPTION 'Audit Type not found.';
    END IF;

    IF trim(COALESCE(p_category_name, '')) = '' THEN
        RAISE EXCEPTION 'Category name is required.';
    END IF;

    IF COALESCE(p_sort_order, 0) < 0 THEN
        RAISE EXCEPTION 'Sort order cannot be negative.';
    END IF;

    INSERT INTO public.audit_categories (
        type_id,
        category_name,
        description,
        sort_order,
        active
    )
    VALUES (
        p_type_id,
        trim(p_category_name),
        NULLIF(trim(COALESCE(p_description, '')), ''),
        COALESCE(p_sort_order, 0),
        COALESCE(p_active, TRUE)
    )
    RETURNING *
    INTO v_result;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_create_audit_category"("p_session_token" "text", "p_type_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_master_data" (
    "master_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "master_name" "text" NOT NULL,
    "audit_type_id" "uuid",
    "audit_type_name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_master_data_audit_type_name_check" CHECK ((TRIM(BOTH FROM "audit_type_name") <> ''::"text")),
    CONSTRAINT "audit_master_data_master_name_check" CHECK ((TRIM(BOTH FROM "master_name") <> ''::"text"))
);


ALTER TABLE "public"."audit_master_data" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_create_audit_master_data"("p_session_token" "text", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean DEFAULT true) RETURNS "public"."audit_master_data"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_master_data;
    v_type_name TEXT;
BEGIN

    IF public.validate_audit_admin_session(
        p_session_token
    ) IS NULL THEN
        RAISE EXCEPTION
            'Unauthorized admin session.';
    END IF;


    IF trim(
        COALESCE(p_master_name, '')
    ) = '' THEN
        RAISE EXCEPTION
            'Master Name is required.';
    END IF;


    -- --------------------------------------------------------
    -- EXISTING AUDIT TYPE
    -- --------------------------------------------------------

    IF p_audit_type_id IS NOT NULL THEN

        SELECT audit_type
        INTO v_type_name
        FROM public.audit_types
        WHERE type_id = p_audit_type_id
          AND active = TRUE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Selected Audit Type was not found or is inactive.';
        END IF;

    ELSE

        -- ----------------------------------------------------
        -- MANUAL AUDIT TYPE
        -- ----------------------------------------------------

        IF trim(
            COALESCE(p_audit_type_name, '')
        ) = '' THEN
            RAISE EXCEPTION
                'Audit Type is required.';
        END IF;

        v_type_name =
            trim(p_audit_type_name);

    END IF;


    -- --------------------------------------------------------
    -- DUPLICATE MASTER NAME
    -- --------------------------------------------------------

    IF EXISTS (
        SELECT 1
        FROM public.audit_master_data
        WHERE lower(trim(master_name))
            =
            lower(trim(p_master_name))
    ) THEN
        RAISE EXCEPTION
            'Master Name already exists.';
    END IF;


    -- --------------------------------------------------------
    -- INSERT
    -- --------------------------------------------------------

    INSERT INTO public.audit_master_data (
        master_name,
        audit_type_id,
        audit_type_name,
        active
    )
    VALUES (
        trim(p_master_name),
        p_audit_type_id,
        v_type_name,
        COALESCE(p_active, TRUE)
    )
    RETURNING *
    INTO v_result;


    RETURN v_result;

END;
$$;


ALTER FUNCTION "public"."admin_create_audit_master_data"("p_session_token" "text", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_questions" (
    "question_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_id" "uuid" NOT NULL,
    "question_number" integer NOT NULL,
    "question" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_questions_number_check" CHECK (("question_number" > 0)),
    CONSTRAINT "audit_questions_sort_order_check" CHECK (("sort_order" >= 0)),
    CONSTRAINT "audit_questions_text_not_empty" CHECK (("length"(TRIM(BOTH FROM "question")) > 0))
);


ALTER TABLE "public"."audit_questions" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean DEFAULT true) RETURNS "public"."audit_questions"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_questions;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.audit_categories
        WHERE category_id = p_category_id
    ) THEN
        RAISE EXCEPTION 'Category not found.';
    END IF;

    IF COALESCE(p_question_number, 0) <= 0 THEN
        RAISE EXCEPTION 'Question Number must be greater than zero.';
    END IF;

    IF trim(COALESCE(p_question, '')) = '' THEN
        RAISE EXCEPTION 'Question is required.';
    END IF;

    IF COALESCE(p_sort_order, 0) < 0 THEN
        RAISE EXCEPTION 'Sort Order cannot be negative.';
    END IF;

    INSERT INTO public.audit_questions (
        category_id,
        question_number,
        question,
        description,
        sort_order,
        active
    )
    VALUES (
        p_category_id,
        p_question_number,
        trim(p_question),
        NULLIF(
            trim(COALESCE(p_description, '')),
            ''
        ),
        COALESCE(p_sort_order, 0),
        COALESCE(p_active, TRUE)
    )
    RETURNING *
    INTO v_result;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_types" (
    "type_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "audit_type" "text" NOT NULL,
    "description" "text",
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_types_name_not_empty" CHECK (("length"(TRIM(BOTH FROM "audit_type")) > 0))
);


ALTER TABLE "public"."audit_types" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean DEFAULT true) RETURNS "public"."audit_types"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_types;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF trim(COALESCE(p_audit_type, '')) = '' THEN
        RAISE EXCEPTION 'Audit Type is required.';
    END IF;

    INSERT INTO public.audit_types (
        audit_type,
        description,
        active
    )
    VALUES (
        trim(p_audit_type),
        NULLIF(trim(COALESCE(p_description, '')), ''),
        COALESCE(p_active, TRUE)
    )
    RETURNING *
    INTO v_result;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_auditors" (
    "auditor_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "auditor_name" "text" NOT NULL,
    "employee_id" "text" NOT NULL,
    "email" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_auditors_email_format" CHECK ((POSITION(('@'::"text") IN ("email")) > 1)),
    CONSTRAINT "audit_auditors_email_not_empty" CHECK (("length"(TRIM(BOTH FROM "email")) > 0)),
    CONSTRAINT "audit_auditors_employee_id_not_empty" CHECK (("length"(TRIM(BOTH FROM "employee_id")) > 0)),
    CONSTRAINT "audit_auditors_name_not_empty" CHECK (("length"(TRIM(BOTH FROM "auditor_name")) > 0))
);


ALTER TABLE "public"."audit_auditors" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_create_auditor"("p_session_token" "text", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean DEFAULT true) RETURNS "public"."audit_auditors"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_auditors;
BEGIN

    -- Validate existing admin session.
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    -- Validate Auditor Name.
    IF trim(COALESCE(p_auditor_name, '')) = '' THEN
        RAISE EXCEPTION 'Auditor Name is required.';
    END IF;

    -- Validate Employee ID.
    IF trim(COALESCE(p_employee_id, '')) = '' THEN
        RAISE EXCEPTION 'Employee ID is required.';
    END IF;

    -- Validate Email.
    IF trim(COALESCE(p_email, '')) = '' THEN
        RAISE EXCEPTION 'Email is required.';
    END IF;

    -- Prevent duplicate Employee ID.
    IF EXISTS (
        SELECT 1
        FROM public.audit_auditors
        WHERE lower(trim(employee_id))
              = lower(trim(p_employee_id))
    ) THEN
        RAISE EXCEPTION 'Employee ID already exists.';
    END IF;

    -- Prevent duplicate Email.
    IF EXISTS (
        SELECT 1
        FROM public.audit_auditors
        WHERE lower(trim(email))
              = lower(trim(p_email))
    ) THEN
        RAISE EXCEPTION 'Email already exists.';
    END IF;

    INSERT INTO public.audit_auditors (
        auditor_name,
        employee_id,
        email,
        active
    )
    VALUES (
        trim(p_auditor_name),
        trim(p_employee_id),
        lower(trim(p_email)),
        COALESCE(p_active, TRUE)
    )
    RETURNING *
    INTO v_result;

    RETURN v_result;

END;
$$;


ALTER FUNCTION "public"."admin_create_auditor"("p_session_token" "text", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_exists boolean;
BEGIN
    IF p_arr_id IS NULL THEN
        RAISE EXCEPTION 'ARR ID is required.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.arr_records
        WHERE arr_id = p_arr_id
    )
    INTO v_exists;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'ARR record not found.';
    END IF;

    DELETE FROM public.arr_records
    WHERE arr_id = p_arr_id;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_audit"("p_session_token" "text", "p_audit_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$

DECLARE
    v_admin_id UUID;

BEGIN

    v_admin_id :=
        public.validate_audit_admin_session(
            p_session_token
        );


    IF v_admin_id IS NULL THEN

        RAISE EXCEPTION
            'Unauthorized admin session.';

    END IF;


    IF NOT EXISTS (
        SELECT 1
        FROM public.audits
        WHERE audit_id = p_audit_id
    ) THEN

        RAISE EXCEPTION
            'Audit record not found.';

    END IF;


    DELETE FROM public.audits
    WHERE audit_id = p_audit_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Audit could not be deleted.';

    END IF;


    RETURN TRUE;

END;

$$;


ALTER FUNCTION "public"."admin_delete_audit"("p_session_token" "text", "p_audit_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_audit_category"("p_session_token" "text", "p_category_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$

BEGIN

    IF public.validate_audit_admin_session(
        p_session_token
    ) IS NULL THEN

        RAISE EXCEPTION
            'Unauthorized admin session.';

    END IF;


    DELETE FROM public.audit_categories
    WHERE category_id = p_category_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Audit Category not found.';

    END IF;


    RETURN TRUE;


EXCEPTION

    WHEN foreign_key_violation THEN

        RAISE EXCEPTION
            'This Audit Category is already used and cannot be deleted.';

END;

$$;


ALTER FUNCTION "public"."admin_delete_audit_category"("p_session_token" "text", "p_category_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_audit_master_data"("p_session_token" "text", "p_master_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN

    IF public.validate_audit_admin_session(
        p_session_token
    ) IS NULL THEN
        RAISE EXCEPTION
            'Unauthorized admin session.';
    END IF;


    DELETE FROM public.audit_master_data
    WHERE master_id = p_master_id;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Master Data record not found.';
    END IF;


    RETURN TRUE;

END;
$$;


ALTER FUNCTION "public"."admin_delete_audit_master_data"("p_session_token" "text", "p_master_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    DELETE FROM public.audit_questions
    WHERE question_id = p_question_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Question not found.';
    END IF;

    RETURN TRUE;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION
            'This Question is already used by an Audit and cannot be deleted.';
END;
$$;


ALTER FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    DELETE FROM public.audit_types
    WHERE type_id = p_type_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Audit Type not found.';
    END IF;

    RETURN TRUE;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION
            'This Audit Type is already used by an Audit and cannot be deleted.';
END;
$$;


ALTER FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_auditor"("p_session_token" "text", "p_auditor_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN

    -- Validate existing admin session.
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    DELETE FROM public.audit_auditors
    WHERE auditor_id = p_auditor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Auditor not found.';
    END IF;

    RETURN TRUE;

END;
$$;


ALTER FUNCTION "public"."admin_delete_auditor"("p_session_token" "text", "p_auditor_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_audit_categories"("p_session_token" "text", "p_type_id" "uuid") RETURNS SETOF "public"."audit_categories"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.audit_categories
    WHERE type_id = p_type_id
    ORDER BY sort_order, category_name;
END;
$$;


ALTER FUNCTION "public"."admin_get_audit_categories"("p_session_token" "text", "p_type_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_audit_master_data"("p_session_token" "text") RETURNS SETOF "public"."audit_master_data"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN

    IF public.validate_audit_admin_session(
        p_session_token
    ) IS NULL THEN
        RAISE EXCEPTION
            'Unauthorized admin session.';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.audit_master_data
    ORDER BY lower(master_name);

END;
$$;


ALTER FUNCTION "public"."admin_get_audit_master_data"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") RETURNS SETOF "public"."audit_questions"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.audit_questions
    WHERE category_id = p_category_id
    ORDER BY sort_order, question_number;
END;
$$;


ALTER FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") RETURNS SETOF "public"."audit_types"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.audit_types
    ORDER BY audit_type;
END;
$$;


ALTER FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_auditors"("p_session_token" "text") RETURNS SETOF "public"."audit_auditors"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN

    -- Validate existing admin session.
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.audit_auditors
    ORDER BY auditor_name;

END;
$$;


ALTER FUNCTION "public"."admin_get_auditors"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_reset_password_after_otp"("p_new_password" "text") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  update admin_profiles
  set password_hash = crypt(p_new_password, gen_salt('bf'))
  where role = 'admin';
$$;


ALTER FUNCTION "public"."admin_reset_password_after_otp"("p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_audit_category"("p_session_token" "text", "p_category_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) RETURNS "public"."audit_categories"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_categories;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF trim(COALESCE(p_category_name, '')) = '' THEN
        RAISE EXCEPTION 'Category name is required.';
    END IF;

    IF COALESCE(p_sort_order, 0) < 0 THEN
        RAISE EXCEPTION 'Sort order cannot be negative.';
    END IF;

    UPDATE public.audit_categories
    SET
        category_name = trim(p_category_name),
        description =
            NULLIF(trim(COALESCE(p_description, '')), ''),
        sort_order = COALESCE(p_sort_order, 0),
        active = COALESCE(p_active, TRUE)
    WHERE category_id = p_category_id
    RETURNING *
    INTO v_result;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found.';
    END IF;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_update_audit_category"("p_session_token" "text", "p_category_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_audit_master_data"("p_session_token" "text", "p_master_id" "uuid", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) RETURNS "public"."audit_master_data"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_master_data;
    v_type_name TEXT;
BEGIN

    IF public.validate_audit_admin_session(
        p_session_token
    ) IS NULL THEN
        RAISE EXCEPTION
            'Unauthorized admin session.';
    END IF;


    IF trim(
        COALESCE(p_master_name, '')
    ) = '' THEN
        RAISE EXCEPTION
            'Master Name is required.';
    END IF;


    -- --------------------------------------------------------
    -- EXISTING AUDIT TYPE
    -- --------------------------------------------------------

    IF p_audit_type_id IS NOT NULL THEN

        SELECT audit_type
        INTO v_type_name
        FROM public.audit_types
        WHERE type_id = p_audit_type_id
          AND active = TRUE;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Selected Audit Type was not found or is inactive.';
        END IF;

    ELSE

        -- ----------------------------------------------------
        -- MANUAL AUDIT TYPE
        -- ----------------------------------------------------

        IF trim(
            COALESCE(p_audit_type_name, '')
        ) = '' THEN
            RAISE EXCEPTION
                'Audit Type is required.';
        END IF;

        v_type_name =
            trim(p_audit_type_name);

    END IF;


    -- --------------------------------------------------------
    -- DUPLICATE MASTER NAME
    -- --------------------------------------------------------

    IF EXISTS (
        SELECT 1
        FROM public.audit_master_data
        WHERE lower(trim(master_name))
            =
            lower(trim(p_master_name))
          AND master_id <> p_master_id
    ) THEN
        RAISE EXCEPTION
            'Master Name already exists.';
    END IF;


    -- --------------------------------------------------------
    -- UPDATE
    -- --------------------------------------------------------

    UPDATE public.audit_master_data
    SET
        master_name =
            trim(p_master_name),

        audit_type_id =
            p_audit_type_id,

        audit_type_name =
            v_type_name,

        active =
            COALESCE(p_active, TRUE),

        updated_at =
            NOW()

    WHERE master_id =
        p_master_id

    RETURNING *
    INTO v_result;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Master Data record not found.';
    END IF;


    RETURN v_result;

END;
$$;


ALTER FUNCTION "public"."admin_update_audit_master_data"("p_session_token" "text", "p_master_id" "uuid", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) RETURNS "public"."audit_questions"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_questions;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF COALESCE(p_question_number, 0) <= 0 THEN
        RAISE EXCEPTION 'Question Number must be greater than zero.';
    END IF;

    IF trim(COALESCE(p_question, '')) = '' THEN
        RAISE EXCEPTION 'Question is required.';
    END IF;

    IF COALESCE(p_sort_order, 0) < 0 THEN
        RAISE EXCEPTION 'Sort Order cannot be negative.';
    END IF;

    UPDATE public.audit_questions
    SET
        question_number = p_question_number,
        question = trim(p_question),
        description =
            NULLIF(
                trim(COALESCE(p_description, '')),
                ''
            ),
        sort_order = COALESCE(p_sort_order, 0),
        active = COALESCE(p_active, TRUE)
    WHERE question_id = p_question_id
    RETURNING *
    INTO v_result;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Question not found.';
    END IF;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) RETURNS "public"."audit_types"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_types;
BEGIN
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    IF trim(COALESCE(p_audit_type, '')) = '' THEN
        RAISE EXCEPTION 'Audit Type is required.';
    END IF;

    UPDATE public.audit_types
    SET
        audit_type = trim(p_audit_type),
        description =
            NULLIF(trim(COALESCE(p_description, '')), ''),
        active = COALESCE(p_active, TRUE)
    WHERE type_id = p_type_id
    RETURNING *
    INTO v_result;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Audit Type not found.';
    END IF;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_auditor"("p_session_token" "text", "p_auditor_id" "uuid", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) RETURNS "public"."audit_auditors"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_result public.audit_auditors;
BEGIN

    -- Validate existing admin session.
    IF public.validate_audit_admin_session(p_session_token) IS NULL THEN
        RAISE EXCEPTION 'Unauthorized admin session.';
    END IF;

    -- Validate Auditor Name.
    IF trim(COALESCE(p_auditor_name, '')) = '' THEN
        RAISE EXCEPTION 'Auditor Name is required.';
    END IF;

    -- Validate Employee ID.
    IF trim(COALESCE(p_employee_id, '')) = '' THEN
        RAISE EXCEPTION 'Employee ID is required.';
    END IF;

    -- Validate Email.
    IF trim(COALESCE(p_email, '')) = '' THEN
        RAISE EXCEPTION 'Email is required.';
    END IF;

    -- Make sure auditor exists.
    IF NOT EXISTS (
        SELECT 1
        FROM public.audit_auditors
        WHERE auditor_id = p_auditor_id
    ) THEN
        RAISE EXCEPTION 'Auditor not found.';
    END IF;

    -- Prevent duplicate Employee ID belonging to another auditor.
    IF EXISTS (
        SELECT 1
        FROM public.audit_auditors
        WHERE lower(trim(employee_id))
              = lower(trim(p_employee_id))
          AND auditor_id <> p_auditor_id
    ) THEN
        RAISE EXCEPTION 'Employee ID already exists.';
    END IF;

    -- Prevent duplicate Email belonging to another auditor.
    IF EXISTS (
        SELECT 1
        FROM public.audit_auditors
        WHERE lower(trim(email))
              = lower(trim(p_email))
          AND auditor_id <> p_auditor_id
    ) THEN
        RAISE EXCEPTION 'Email already exists.';
    END IF;

    UPDATE public.audit_auditors
    SET
        auditor_name = trim(p_auditor_name),
        employee_id = trim(p_employee_id),
        email = lower(trim(p_email)),
        active = COALESCE(p_active, TRUE),
        updated_at = NOW()
    WHERE auditor_id = p_auditor_id
    RETURNING *
    INTO v_result;

    RETURN v_result;

END;
$$;


ALTER FUNCTION "public"."admin_update_auditor"("p_session_token" "text", "p_auditor_id" "uuid", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."arr_reset_password_after_otp"("p_new_password" "text") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  update admin_profiles
  set password_hash = crypt(p_new_password, gen_salt('bf'))
  where role = 'arr';
$$;


ALTER FUNCTION "public"."arr_reset_password_after_otp"("p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_team_id uuid;
    v_member text;
    v_token_hash text;
BEGIN

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can create teams.';
    END IF;

    IF trim(
        coalesce(
            p_team_leader_name,
            ''
        )
    ) = '' THEN
        RAISE EXCEPTION
            'Team leader name is required.';
    END IF;

    INSERT INTO public.ccr_teams (
        team_leader_name,
        is_active
    )
    VALUES (
        trim(p_team_leader_name),
        true
    )
    RETURNING id
    INTO v_team_id;

    IF p_member_names IS NOT NULL THEN

        FOREACH v_member IN ARRAY p_member_names
        LOOP

            IF trim(v_member) <> '' THEN

                INSERT INTO public.ccr_team_members (
                    team_id,
                    member_name
                )
                VALUES (
                    v_team_id,
                    trim(v_member)
                );

            END IF;

        END LOOP;

    END IF;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;

    RETURN v_team_id;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_create_user"("p_session_token" "text", "p_full_name" "text", "p_email" "text", "p_role" "text" DEFAULT 'user'::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_new_user_id uuid;
    v_role text;
    v_token_hash text;
BEGIN

    -- ============================================================
    -- HASH SESSION TOKEN
    -- ============================================================

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    -- ============================================================
    -- VERIFY ACTIVE ADMIN
    -- ============================================================

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can create users.';
    END IF;

    -- ============================================================
    -- VALIDATION
    -- ============================================================

    IF trim(
        coalesce(
            p_full_name,
            ''
        )
    ) = '' THEN
        RAISE EXCEPTION
            'Full name is required.';
    END IF;

    IF trim(
        coalesce(
            p_email,
            ''
        )
    ) = '' THEN
        RAISE EXCEPTION
            'Email is required.';
    END IF;

    v_role :=
        lower(
            trim(
                coalesce(
                    p_role,
                    'user'
                )
            )
        );

    IF v_role NOT IN (
        'admin',
        'user'
    ) THEN
        RAISE EXCEPTION
            'Invalid CCR role.';
    END IF;

    -- ============================================================
    -- DUPLICATE EMAIL
    -- ============================================================

    IF EXISTS (
        SELECT 1
        FROM public.ccr_users
        WHERE lower(email) =
              lower(trim(p_email))
    ) THEN
        RAISE EXCEPTION
            'A CCR user with this email already exists.';
    END IF;

    -- ============================================================
    -- CREATE USER
    --
    -- Default password = welcome123
    -- User must change password after first login.
    -- ============================================================

    INSERT INTO public.ccr_users (
        full_name,
        email,
        password_hash,
        role,
        is_active,
        must_change_password
    )
    VALUES (
        trim(p_full_name),

        lower(
            trim(p_email)
        ),

        extensions.crypt(
            'welcome123'::text,
            extensions.gen_salt(
                'bf'::text,
                12
            )
        ),

        v_role,

        true,

        true
    )
    RETURNING id
    INTO v_new_user_id;

    -- ============================================================
    -- REFRESH ADMIN SESSION
    -- ============================================================

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;

    RETURN v_new_user_id;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_create_user"("p_session_token" "text", "p_full_name" "text", "p_email" "text", "p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_token_hash text;
    v_exists boolean;
BEGIN

    -- ============================================================
    -- VALIDATE INPUT
    -- ============================================================

    IF trim(coalesce(p_session_token, '')) = '' THEN
        RAISE EXCEPTION
            'CCR Admin session token is required.';
    END IF;

    IF p_ccr_id IS NULL THEN
        RAISE EXCEPTION
            'CCR ID is required.';
    END IF;


    -- ============================================================
    -- HASH SESSION TOKEN
    -- Explicitly use pgcrypto from extensions schema
    -- ============================================================

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );


    -- ============================================================
    -- VERIFY ACTIVE ADMIN
    -- ============================================================

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;


    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can delete CCR records.';
    END IF;


    -- ============================================================
    -- CHECK CCR EXISTS
    -- ============================================================

    SELECT EXISTS (
        SELECT 1
        FROM public.ccr_cases
        WHERE id = p_ccr_id
    )
    INTO v_exists;


    IF NOT v_exists THEN
        RAISE EXCEPTION
            'CCR record not found.';
    END IF;


    -- ============================================================
    -- DELETE CCR
    --
    -- Child records linked with ON DELETE CASCADE will also be
    -- removed automatically.
    --
    -- Existing team records are NOT affected.
    -- ============================================================

    DELETE FROM public.ccr_cases
    WHERE id = p_ccr_id;


    -- ============================================================
    -- REFRESH ADMIN SESSION
    -- ============================================================

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;


    RETURN true;

END;
$$;


ALTER FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_token_hash text;
BEGIN

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can delete teams.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.ccr_teams
        WHERE id = p_team_id
    ) THEN
        RAISE EXCEPTION
            'Team not found.';
    END IF;

    /*
     * ccr_team_members.team_id has ON DELETE CASCADE,
     * so deleting the team also deletes its members.
     *
     * ccr_cases.team_id has ON DELETE SET NULL,
     * so existing CCR records remain intact.
     */

    DELETE FROM public.ccr_teams
    WHERE id = p_team_id;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
    v_admin_id uuid;
BEGIN
    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
      ON u.id = s.user_id
    WHERE s.token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          )
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin';

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can delete users.';
    END IF;

    IF v_admin_id = p_user_id THEN
        RAISE EXCEPTION
            'An Admin cannot delete their own account.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.ccr_users
        WHERE id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'CCR user not found.';
    END IF;

    DELETE FROM public.ccr_users
    WHERE id = p_user_id;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          );

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id uuid;
    v_result jsonb;
BEGIN
    SELECT s.user_id
    INTO v_user_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
      ON u.id = s.user_id
    WHERE s.token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          )
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can manage users.';
    END IF;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_user_id
      AND token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          );

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id', u.id,
                'full_name', u.full_name,
                'email', u.email,
                'role', u.role,
                'is_active', u.is_active,
                'must_change_password',
                    u.must_change_password,
                'created_at', u.created_at,
                'last_login_at',
                    u.last_login_at
            )
            ORDER BY u.created_at DESC
        ),
        '[]'::jsonb
    )
    INTO v_result
    FROM public.ccr_users u;

    RETURN v_result;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_token_hash text;
BEGIN

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can modify teams.';
    END IF;

    UPDATE public.ccr_teams
    SET is_active = p_is_active
    WHERE id = p_team_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Team not found.';
    END IF;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
    v_admin_id uuid;
BEGIN
    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
      ON u.id = s.user_id
    WHERE s.token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          )
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin';

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can modify users.';
    END IF;

    IF v_admin_id = p_user_id
       AND p_is_active = false THEN
        RAISE EXCEPTION
            'An Admin cannot deactivate their own account.';
    END IF;

    UPDATE public.ccr_users
    SET
        is_active = p_is_active,
        updated_at = now()
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'CCR user not found.';
    END IF;

    IF NOT p_is_active THEN
        DELETE FROM public.ccr_sessions
        WHERE user_id = p_user_id;
    END IF;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash =
          encode(
              extensions.digest(
                  p_session_token,
                  'sha256'
              ),
              'hex'
          );

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_admin_id uuid;
    v_member text;
    v_token_hash text;
BEGIN

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    SELECT s.user_id
    INTO v_admin_id
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
      AND lower(u.role) = 'admin'
    LIMIT 1;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION
            'Only an active CCR Admin can update teams.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.ccr_teams
        WHERE id = p_team_id
    ) THEN
        RAISE EXCEPTION
            'Team not found.';
    END IF;

    UPDATE public.ccr_teams
    SET team_leader_name =
        trim(p_team_leader_name)
    WHERE id = p_team_id;

    DELETE FROM public.ccr_team_members
    WHERE team_id = p_team_id;

    IF p_member_names IS NOT NULL THEN

        FOREACH v_member IN ARRAY p_member_names
        LOOP

            IF trim(v_member) <> '' THEN

                INSERT INTO public.ccr_team_members (
                    team_id,
                    member_name
                )
                VALUES (
                    p_team_id,
                    trim(v_member)
                );

            END IF;

        END LOOP;

    END IF;

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE user_id = v_admin_id
      AND token_hash = v_token_hash;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_auth_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."ccr_auth_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_change_password"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user_id uuid;
    v_password_hash text;
    v_token_hash text;
BEGIN

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );

    SELECT
        s.user_id,
        u.password_hash
    INTO
        v_user_id,
        v_password_hash
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.token_hash = v_token_hash
      AND s.last_activity_at >=
          now() - interval '15 minutes'
      AND u.is_active = true
    LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION
            'CCR session has expired. Please login again.';
    END IF;

    IF extensions.crypt(
        p_current_password::text,
        v_password_hash
    ) <> v_password_hash THEN
        RAISE EXCEPTION
            'Current password is incorrect.';
    END IF;

    IF length(p_new_password) < 8 THEN
        RAISE EXCEPTION
            'New password must contain at least 8 characters.';
    END IF;

    IF p_current_password = p_new_password THEN
        RAISE EXCEPTION
            'New password must be different from the current password.';
    END IF;

    UPDATE public.ccr_users
    SET
        password_hash =
            extensions.crypt(
                p_new_password::text,
                extensions.gen_salt(
                    'bf'::text,
                    12
                )
            ),
        must_change_password = false,
        updated_at = now()
    WHERE id = v_user_id;

    DELETE FROM public.ccr_sessions
    WHERE user_id = v_user_id;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_change_password"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user_id uuid;
    v_password_hash text;
BEGIN

    SELECT
        id,
        password_hash
    INTO
        v_user_id,
        v_password_hash
    FROM public.ccr_users
    WHERE lower(email) =
          lower(trim(p_email))
      AND is_active = true
    LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION
            'Invalid email or current password.';
    END IF;

    IF extensions.crypt(
        p_current_password::text,
        v_password_hash
    ) <> v_password_hash THEN
        RAISE EXCEPTION
            'Invalid email or current password.';
    END IF;

    IF length(p_new_password) < 8 THEN
        RAISE EXCEPTION
            'New password must contain at least 8 characters.';
    END IF;

    IF p_current_password = p_new_password THEN
        RAISE EXCEPTION
            'New password must be different from the current password.';
    END IF;

    UPDATE public.ccr_users
    SET
        password_hash =
            extensions.crypt(
                p_new_password::text,
                extensions.gen_salt(
                    'bf'::text,
                    12
                )
            ),
        must_change_password = false,
        updated_at = now()
    WHERE id = v_user_id;

    DELETE FROM public.ccr_sessions
    WHERE user_id = v_user_id;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_cleanup_expired_sessions"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
    DELETE FROM public.ccr_sessions
    WHERE last_activity_at < now() - interval '15 minutes';
$$;


ALTER FUNCTION "public"."ccr_cleanup_expired_sessions"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_login"("p_email" "text", "p_password" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user public.ccr_users%ROWTYPE;
    v_token text;
BEGIN

    DELETE FROM public.ccr_sessions
    WHERE last_activity_at <
          now() - interval '15 minutes';

    SELECT *
    INTO v_user
    FROM public.ccr_users
    WHERE lower(email) =
          lower(trim(p_email))
      AND is_active = true
    LIMIT 1;

    IF v_user.id IS NULL THEN
        RAISE EXCEPTION
            'Invalid email or password.';
    END IF;

    IF extensions.crypt(
        p_password::text,
        v_user.password_hash
    ) <> v_user.password_hash THEN
        RAISE EXCEPTION
            'Invalid email or password.';
    END IF;

    DELETE FROM public.ccr_sessions
    WHERE user_id = v_user.id;

    v_token :=
        encode(
            extensions.gen_random_bytes(32),
            'hex'
        );

    INSERT INTO public.ccr_sessions (
        user_id,
        token_hash,
        created_at,
        last_activity_at
    )
    VALUES (
        v_user.id,

        encode(
            extensions.digest(
                v_token::text,
                'sha256'::text
            ),
            'hex'
        ),

        now(),
        now()
    );

    UPDATE public.ccr_users
    SET last_login_at = now()
    WHERE id = v_user.id;

    RETURN jsonb_build_object(
        'user_id', v_user.id,
        'full_name', v_user.full_name,
        'email', v_user.email,
        'role', v_user.role,
        'is_active', v_user.is_active,
        'must_change_password',
            v_user.must_change_password,
        'session_token', v_token,
        'idle_timeout_minutes', 15
    );
END;
$$;


ALTER FUNCTION "public"."ccr_login"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_logout"("p_session_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
    v_token_hash text;
BEGIN
    IF p_session_token IS NULL
       OR trim(p_session_token) = '' THEN
        RETURN true;
    END IF;

    v_token_hash :=
        encode(
            digest(
                trim(p_session_token),
                'sha256'
            ),
            'hex'
        );

    DELETE FROM public.ccr_sessions
    WHERE token_hash = v_token_hash;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ccr_logout"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."ccr_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ccr_validate_session"("p_session_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user public.ccr_users%ROWTYPE;
    v_session_id uuid;
    v_token_hash text;
BEGIN

    -- ============================================================
    -- VALIDATE INPUT
    -- ============================================================

    IF trim(coalesce(p_session_token, '')) = '' THEN
        RAISE EXCEPTION
            'CCR session token is required.';
    END IF;


    -- ============================================================
    -- HASH SESSION TOKEN
    -- ============================================================

    v_token_hash :=
        encode(
            extensions.digest(
                p_session_token::text,
                'sha256'::text
            ),
            'hex'
        );


    -- ============================================================
    -- GET SESSION
    -- ============================================================

    SELECT s.id
    INTO v_session_id
    FROM public.ccr_sessions s
    WHERE s.token_hash = v_token_hash
    LIMIT 1;


    -- ============================================================
    -- SESSION NOT FOUND
    -- ============================================================

    IF v_session_id IS NULL THEN
        RAISE EXCEPTION
            'CCR session is invalid or expired.';
    END IF;


    -- ============================================================
    -- GET USER
    -- ============================================================

    SELECT u.*
    INTO v_user
    FROM public.ccr_sessions s
    JOIN public.ccr_users u
        ON u.id = s.user_id
    WHERE s.id = v_session_id
    LIMIT 1;


    -- ============================================================
    -- USER NOT FOUND
    -- ============================================================

    IF v_user.id IS NULL THEN

        DELETE FROM public.ccr_sessions
        WHERE id = v_session_id;

        RAISE EXCEPTION
            'CCR user account no longer exists.';
    END IF;


    -- ============================================================
    -- CHECK USER ACTIVE
    -- ============================================================

    IF v_user.is_active = false THEN

        DELETE FROM public.ccr_sessions
        WHERE id = v_session_id;

        RAISE EXCEPTION
            'CCR user account is inactive.';
    END IF;


    -- ============================================================
    -- CHECK 15-MINUTE IDLE TIMEOUT
    -- ============================================================

    IF EXISTS (
        SELECT 1
        FROM public.ccr_sessions
        WHERE id = v_session_id
          AND last_activity_at <
              now() - interval '15 minutes'
    ) THEN

        DELETE FROM public.ccr_sessions
        WHERE id = v_session_id;

        RAISE EXCEPTION
            'CCR session expired. Please login again.';
    END IF;


    -- ============================================================
    -- REFRESH SESSION ACTIVITY
    -- ============================================================

    UPDATE public.ccr_sessions
    SET last_activity_at = now()
    WHERE id = v_session_id;


    -- ============================================================
    -- RETURN SESSION INFORMATION
    -- ============================================================

    RETURN jsonb_build_object(
        'user_id',
            v_user.id,

        'full_name',
            v_user.full_name,

        'email',
            v_user.email,

        'role',
            v_user.role,

        'is_active',
            v_user.is_active,

        'must_change_password',
            v_user.must_change_password,

        'session_token',
            p_session_token,

        'idle_timeout_minutes',
            15
    );

END;
$$;


ALTER FUNCTION "public"."ccr_validate_session"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."close_audit_mil"("p_audit_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$

DECLARE
    v_total_items INTEGER;
    v_closed_items INTEGER;
    v_current_mil_status TEXT;
BEGIN

    SELECT mil_status
    INTO v_current_mil_status
    FROM public.audits
    WHERE audit_id = p_audit_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Audit does not exist.';
    END IF;


    -- Already closed.
    IF v_current_mil_status = 'Closed' THEN
        RETURN TRUE;
    END IF;


    SELECT COUNT(*)
    INTO v_total_items
    FROM public.audit_mil_items
    WHERE audit_id = p_audit_id;


    SELECT COUNT(*)
    INTO v_closed_items
    FROM public.audit_mil_items
    WHERE audit_id = p_audit_id
      AND overall_status = 'Closed';


    -- No findings.
    IF v_total_items = 0 THEN

        UPDATE public.audits
        SET
            mil_status = 'Closed',
            status = 'Completed',
            updated_at = NOW()
        WHERE audit_id = p_audit_id;

        RETURN TRUE;

    END IF;


    -- Not all findings are closed.
    IF v_closed_items <> v_total_items THEN

        RAISE EXCEPTION
            'MIL cannot be closed until all MIL items are Closed.';

    END IF;


    -- All findings are closed.
    UPDATE public.audits
    SET
        mil_status = 'Closed',
        status = 'Completed',
        updated_at = NOW()
    WHERE audit_id = p_audit_id;


    RETURN TRUE;

END;

$$;


ALTER FUNCTION "public"."close_audit_mil"("p_audit_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."complete_arr"("p_employee_id" "text", "p_batch_id" "text", "p_product" "text", "p_assessment_date" "date", "p_false_alert_count" integer, "p_miss_alert_count" integer, "p_false_alert_pct" numeric, "p_miss_rate_pct" numeric, "p_effectiveness_pct" numeric, "p_p1" numeric, "p_p0" numeric, "p_p_chance" numeric, "p_kappa_pct" numeric, "p_classification" "text", "p_observations" "jsonb") RETURNS TABLE("arr_id" "uuid", "certificate_number" "text", "attempt_number" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$

DECLARE

  -- Internal variables use names different from
  -- returned column names to avoid ambiguity.

  v_arr_id uuid;
  v_employee_uuid uuid;
  v_employee_code text;
  v_batch_name text;
  v_attempt_number integer;
  v_certificate_number text;
  v_expected_parts integer;
  v_observation_count integer;

BEGIN

  -- ==========================================================
  -- 4. VALIDATE EMPLOYEE INPUT
  -- ==========================================================

  IF p_employee_id IS NULL
     OR trim(p_employee_id) = '' THEN

    RAISE EXCEPTION
      'Employee code cannot be empty';

  END IF;


  -- ==========================================================
  -- 5. FIND EMPLOYEE
  --
  -- Primary lookup:
  -- employee_code = "001"
  --
  -- UUID lookup is also supported in case the application
  -- is later changed to send employee_id.
  -- ==========================================================

  SELECT
    e.employee_id,
    e.employee_code
  INTO
    v_employee_uuid,
    v_employee_code
  FROM public.employees AS e
  WHERE
    e.is_active = true
    AND (
      e.employee_code = trim(p_employee_id)
      OR (
        p_employee_id ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        AND e.employee_id = p_employee_id::uuid
      )
    )
  LIMIT 1;


  IF v_employee_uuid IS NULL THEN

    RAISE EXCEPTION
      'Employee "%" not found or inactive',
      p_employee_id;

  END IF;


  -- ==========================================================
  -- 6. VALIDATE BATCH INPUT
  -- ==========================================================

  IF p_batch_id IS NULL
     OR trim(p_batch_id) = '' THEN

    RAISE EXCEPTION
      'Batch ID cannot be empty';

  END IF;


  -- ==========================================================
  -- 7. FIND BATCH
  -- ==========================================================

  SELECT
    b.batch_name
  INTO
    v_batch_name
  FROM public.batches AS b
  WHERE
    b.batch_id = trim(p_batch_id)
    AND b.is_active = true
  LIMIT 1;


  IF v_batch_name IS NULL THEN

    RAISE EXCEPTION
      'Batch "%" not found or inactive',
      p_batch_id;

  END IF;


  -- ==========================================================
  -- 8. VALIDATE OBSERVATIONS JSON
  -- ==========================================================

  IF p_observations IS NULL THEN

    RAISE EXCEPTION
      'Observations cannot be null';

  END IF;


  IF jsonb_typeof(p_observations) <> 'array' THEN

    RAISE EXCEPTION
      'Observations must be a JSON array';

  END IF;


  -- ==========================================================
  -- 9. COUNT ACTIVE PARTS
  -- ==========================================================

  SELECT
    count(*)
  INTO
    v_expected_parts
  FROM public.parts AS p
  WHERE
    p.batch_id = trim(p_batch_id)
    AND p.is_active = true;


  IF v_expected_parts = 0 THEN

    RAISE EXCEPTION
      'No active parts found for batch "%"',

      p_batch_id;

  END IF;


  -- ==========================================================
  -- 10. COUNT OBSERVATIONS RECEIVED
  -- ==========================================================

  SELECT
    count(*)
  INTO
    v_observation_count
  FROM jsonb_array_elements(p_observations);


  IF v_observation_count <> v_expected_parts THEN

    RAISE EXCEPTION
      'Expected % observations for batch %, but received %',
      v_expected_parts,
      p_batch_id,
      v_observation_count;

  END IF;


  -- ==========================================================
  -- 11. VALIDATE EVERY PART ID
  --
  -- Every observation must:
  --   - contain part_id
  --   - reference an existing part
  --   - belong to selected batch
  --   - be active
  -- ==========================================================

  IF EXISTS (

    SELECT 1

    FROM jsonb_array_elements(p_observations) AS obs

    LEFT JOIN public.parts AS part_row
      ON part_row.part_id::text = obs->>'part_id'

    WHERE
      obs->>'part_id' IS NULL

      OR part_row.part_id IS NULL

      OR part_row.batch_id <> trim(p_batch_id)

      OR part_row.is_active <> true

  ) THEN

    RAISE EXCEPTION
      'One or more observations contain an invalid, inactive, or wrong-batch part_id';

  END IF;


  -- ==========================================================
  -- 12. VALIDATE DUPLICATE PARTS
  -- ==========================================================

  IF EXISTS (

    SELECT 1

    FROM jsonb_array_elements(p_observations) AS obs

    GROUP BY
      obs->>'part_id'

    HAVING count(*) > 1

  ) THEN

    RAISE EXCEPTION
      'Duplicate part observations detected';

  END IF;


  -- ==========================================================
  -- 13. CALCULATE NEXT ATTEMPT NUMBER
  --
  -- Attempt count is per unique employee.
  -- ==========================================================

  SELECT
    COALESCE(MAX(record_row.attempt_number), 0) + 1
  INTO
    v_attempt_number
  FROM public.arr_records AS record_row
  WHERE
    record_row.employee_id = v_employee_uuid;


  -- ==========================================================
  -- 14. GENERATE CERTIFICATE NUMBER
  --
  -- Example:
  -- ARR-001-1
  -- ARR-001-2
  -- ARR-001-3
  -- ==========================================================

  v_certificate_number :=
    'ARR-'
    || v_employee_code
    || '-'
    || v_attempt_number;


  -- ==========================================================
  -- 15. INSERT ARR RECORD
  --
  -- IMPORTANT:
  -- The target table has an explicit alias.
  --
  -- This prevents:
  -- "column reference arr_id is ambiguous"
  -- ==========================================================

  INSERT INTO public.arr_records AS record_insert (

    certificate_number,

    employee_id,

    employee_code_snap,

    batch_id,

    batch_name_snap,

    product,

    attempt_number,

    assessment_date,

    false_alert_count,

    miss_alert_count,

    false_alert_pct,

    miss_rate_pct,

    effectiveness_pct,

    p1,

    p0,

    p_chance,

    kappa_pct,

    classification

  )

  VALUES (

    v_certificate_number,

    v_employee_uuid,

    v_employee_code,

    trim(p_batch_id),

    v_batch_name,

    p_product,

    v_attempt_number,

    COALESCE(
      p_assessment_date,
      CURRENT_DATE
    ),

    p_false_alert_count,

    p_miss_alert_count,

    p_false_alert_pct,

    p_miss_rate_pct,

    p_effectiveness_pct,

    p_p1,

    p_p0,

    p_p_chance,

    p_kappa_pct,

    p_classification

  )

  RETURNING record_insert.arr_id
  INTO v_arr_id;


  -- ==========================================================
  -- 16. INSERT OBSERVATIONS
  -- ==========================================================

  INSERT INTO public.arr_observations (

    arr_id,

    part_id,

    part_number_snap,

    master_status_snapshot,

    trail1,

    trail2,

    trail3

  )

  SELECT

    v_arr_id,

    (obs->>'part_id')::uuid,

    obs->>'part_number_snap',

    (obs->>'master_status_snapshot')::smallint,

    (obs->>'trail1')::smallint,

    (obs->>'trail2')::smallint,

    (obs->>'trail3')::smallint

  FROM jsonb_array_elements(p_observations) AS obs;


  -- ==========================================================
  -- 17. VERIFY SAVED OBSERVATIONS
  -- ==========================================================

  IF EXISTS (

    SELECT 1

    FROM public.arr_observations AS observation_row

    JOIN public.parts AS part_row

      ON part_row.part_id =
         observation_row.part_id

    WHERE
      observation_row.arr_id = v_arr_id

      AND (
        part_row.batch_id <> trim(p_batch_id)
        OR part_row.is_active <> true
      )

  ) THEN

    RAISE EXCEPTION
      'One or more saved observations do not belong to the selected active batch';

  END IF;


  -- ==========================================================
  -- 18. VERIFY OBSERVATION COUNT AFTER INSERT
  -- ==========================================================

  IF (

    SELECT count(*)
    FROM public.arr_observations AS observation_row
    WHERE observation_row.arr_id = v_arr_id

  ) <> v_expected_parts THEN

    RAISE EXCEPTION
      'Saved observation count does not match expected part count';

  END IF;


  -- ==========================================================
  -- 19. RETURN RESULT
  -- ==========================================================

  RETURN QUERY

  SELECT
    v_arr_id,
    v_certificate_number,
    v_attempt_number;


END;

$_$;


ALTER FUNCTION "public"."complete_arr"("p_employee_id" "text", "p_batch_id" "text", "p_product" "text", "p_assessment_date" "date", "p_false_alert_count" integer, "p_miss_alert_count" integer, "p_false_alert_pct" numeric, "p_miss_rate_pct" numeric, "p_effectiveness_pct" numeric, "p_p1" numeric, "p_p0" numeric, "p_p_chance" numeric, "p_kappa_pct" numeric, "p_classification" "text", "p_observations" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_change_password"("p_email" "text", "p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
declare
  v_id text;
begin
  select id into v_id
  from dcc_users
  where email = lower(trim(p_email))
    and active = true
    and password = crypt(p_current_password, password);

  if v_id is null then
    return false;
  end if;

  update dcc_users
  set password = crypt(p_new_password, gen_salt('bf')),
      updated_at = now()
  where id = v_id;

  return true;
end;
$$;


ALTER FUNCTION "public"."dcc_change_password"("p_email" "text", "p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_user_id TEXT;
    v_password_hash TEXT;
BEGIN
    -- Identify the user through the server-validated session.
    SELECT s.id
    INTO v_user_id
    FROM public.dcc_validate_session(p_session_token) AS s;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Your session has expired. Please log in again.';
    END IF;

    IF p_current_password IS NULL
       OR p_new_password IS NULL
       OR LENGTH(p_new_password) < 8
       OR LENGTH(p_new_password) > 128 THEN
        RAISE EXCEPTION 'New password must contain 8 to 128 characters.';
    END IF;

    -- Lock the user's account while changing the password.
    SELECT u.password
    INTO v_password_hash
    FROM public.dcc_users AS u
    WHERE u.id = v_user_id
      AND u.active = TRUE
      AND u.deleted_at IS NULL
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account is not active.';
    END IF;

    -- Verify the existing password.
    IF v_password_hash IS NULL
       OR v_password_hash <> extensions.crypt(
           p_current_password,
           v_password_hash
       ) THEN
        RETURN FALSE;
    END IF;

    -- Do not allow the same password again.
    IF v_password_hash = extensions.crypt(
        p_new_password,
        v_password_hash
    ) THEN
        RAISE EXCEPTION 'New password must be different from the current password.';
    END IF;

    -- Hash and save the new password on the server.
    UPDATE public.dcc_users
    SET password = extensions.crypt(
            p_new_password,
            extensions.gen_salt('bf')
        ),
        updated_at = NOW()
    WHERE id = v_user_id;

    -- Revoke every existing session.
    -- The user must log in again with the new password.
    UPDATE public.dcc_sessions
    SET revoked_at = NOW()
    WHERE user_id = v_user_id
      AND revoked_at IS NULL;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_role TEXT;
    v_new_role TEXT;
BEGIN
    SELECT s.role INTO v_role
    FROM public.dcc_validate_session(p_session_token) AS s;

    IF v_role IS NULL OR UPPER(v_role) <> 'ADMIN' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    v_new_role := UPPER(TRIM(p_role));

    IF COALESCE(TRIM(p_id), '') = ''
       OR COALESCE(TRIM(p_name), '') = ''
       OR COALESCE(TRIM(p_email), '') = ''
       OR POSITION('@' IN p_email) < 2
       OR v_new_role NOT IN ('ADMIN', 'DCC', 'HOD', 'USER')
       OR p_password IS NULL
       OR LENGTH(p_password) < 8
       OR LENGTH(p_password) > 128 THEN
        RAISE EXCEPTION 'Invalid user details or password';
    END IF;

    INSERT INTO public.dcc_users (
        id, name, email, role,
        hod_name, hod_email, password,
        active, created_at, updated_at
    )
    VALUES (
        TRIM(p_id),
        TRIM(p_name),
        LOWER(TRIM(p_email)),
        v_new_role,
        COALESCE(TRIM(p_hod_name), ''),
        LOWER(TRIM(COALESCE(p_hod_email, ''))),
        extensions.crypt(p_password, extensions.gen_salt('bf')),
        COALESCE(p_active, TRUE),
        NOW(),
        NOW()
    );
END;
$$;


ALTER FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_admin_id TEXT;
    v_target_role TEXT;
    v_target_active BOOLEAN;
    v_deleted_at TIMESTAMPTZ;
    v_active_admins BIGINT;
BEGIN
    SELECT s.id INTO v_admin_id
    FROM public.dcc_validate_session(p_session_token) AS s
    WHERE UPPER(s.role) = 'ADMIN';

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    IF p_user_id = v_admin_id THEN
        RAISE EXCEPTION 'You cannot delete your own account';
    END IF;

    SELECT u.role, u.active, u.deleted_at
    INTO v_target_role, v_target_active, v_deleted_at
    FROM public.dcc_users AS u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_deleted_at IS NOT NULL THEN
        RETURN FALSE;
    END IF;

    IF UPPER(v_target_role) = 'ADMIN' AND v_target_active THEN
        SELECT COUNT(*) INTO v_active_admins
        FROM public.dcc_users
        WHERE UPPER(role) = 'ADMIN'
          AND active = TRUE
          AND deleted_at IS NULL;

        IF v_active_admins <= 1 THEN
            RAISE EXCEPTION 'Cannot delete the last active Admin';
        END IF;
    END IF;

    UPDATE public.dcc_users
    SET active = FALSE,
        deleted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_user_id;

    UPDATE public.dcc_sessions
    SET revoked_at = NOW()
    WHERE user_id = p_user_id
      AND revoked_at IS NULL;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_get_users"("p_session_token" "text") RETURNS TABLE("id" "text", "name" "text", "email" "text", "role" "text", "hod_name" "text", "hod_email" "text", "active" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "deleted_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT s.role INTO v_role
    FROM public.dcc_validate_session(p_session_token) AS s;

    IF v_role IS NULL OR UPPER(v_role) <> 'ADMIN' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT
        u.id,
        u.name,
        u.email,
        u.role,
        u.hod_name,
        u.hod_email,
        u.active,
        u.created_at,
        u.updated_at,
        u.deleted_at
    FROM public.dcc_users AS u
    ORDER BY u.created_at ASC;
END;
$$;


ALTER FUNCTION "public"."dcc_get_users"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") RETURNS TABLE("id" "text", "name" "text", "email" "text", "role" "text", "hod_name" "text", "hod_email" "text", "active" boolean, "session_token" "text", "expires_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_user public.dcc_users%ROWTYPE;
    v_token TEXT;
    v_expiry TIMESTAMPTZ;
BEGIN
    IF p_email IS NULL OR p_password IS NULL
       OR LENGTH(p_email) > 320
       OR LENGTH(p_password) > 256
       OR LENGTH(p_password) = 0 THEN
        RETURN;
    END IF;

    -- Verify credentials against the database

    SELECT u.*
    INTO v_user
    FROM public.dcc_users AS u
    WHERE u.email = LOWER(TRIM(p_email))
      AND u.active = TRUE
      AND u.password =
          extensions.crypt(p_password, u.password)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Generate a cryptographically random bearer token

    v_token := pg_catalog.encode(
        extensions.gen_random_bytes(32),
        'hex'
    );

    v_expiry := NOW() + INTERVAL '8 hours';

    -- Store only the token hash

    INSERT INTO public.dcc_sessions (
        token_hash,
        user_id,
        expires_at
    )
    VALUES (
        pg_catalog.encode(
            extensions.digest(
                pg_catalog.convert_to(v_token, 'UTF8'),
                'sha256'
            ),
            'hex'
        ),
        v_user.id,
        v_expiry
    );

    -- Return the raw token exactly once

    RETURN QUERY
    SELECT
        v_user.id,
        v_user.name,
        v_user.email,
        v_user.role,
        v_user.hod_name,
        v_user.hod_email,
        v_user.active,
        v_token,
        v_expiry;
END;
$$;


ALTER FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_user public.dcc_users%ROWTYPE;
    v_token TEXT;
    v_expiry TIMESTAMPTZ;
BEGIN
    IF p_email IS NULL
       OR p_password IS NULL
       OR LENGTH(p_email) > 320
       OR LENGTH(p_password) = 0
       OR LENGTH(p_password) > 256 THEN
        RETURN jsonb_build_object('status', 'INVALID');
    END IF;

    SELECT u.*
    INTO v_user
    FROM public.dcc_users AS u
    WHERE LOWER(u.email) = LOWER(TRIM(p_email))
    LIMIT 1;

    IF NOT FOUND
       OR v_user.password IS NULL
       OR v_user.password <> extensions.crypt(
           p_password,
           v_user.password
       ) THEN
        RETURN jsonb_build_object('status', 'INVALID');
    END IF;

    -- Verify password before disclosing account status.

    IF v_user.deleted_at IS NOT NULL THEN
        RETURN jsonb_build_object('status', 'DELETED');
    END IF;

    IF v_user.active = FALSE THEN
        RETURN jsonb_build_object('status', 'DISABLED');
    END IF;

    v_token := pg_catalog.encode(
        extensions.gen_random_bytes(32),
        'hex'
    );

    v_expiry := NOW() + INTERVAL '8 hours';

    INSERT INTO public.dcc_sessions (
        token_hash,
        user_id,
        expires_at
    )
    VALUES (
        pg_catalog.encode(
            extensions.digest(
                pg_catalog.convert_to(v_token, 'UTF8'),
                'sha256'
            ),
            'hex'
        ),
        v_user.id,
        v_expiry
    );

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'session_token', v_token,
        'expires_at', v_expiry,
        'user', jsonb_build_object(
            'id', v_user.id,
            'name', v_user.name,
            'email', v_user.email,
            'role', v_user.role,
            'hod_name', v_user.hod_name,
            'hod_email', v_user.hod_email,
            'active', v_user.active
        )
    );
END;
$$;


ALTER FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_logout"("p_session_token" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
BEGIN
    IF p_session_token IS NULL
       OR LENGTH(p_session_token) <> 64 THEN
        RETURN FALSE;
    END IF;

    UPDATE public.dcc_sessions
    SET revoked_at = NOW()
    WHERE token_hash = pg_catalog.encode(
        extensions.digest(
            pg_catalog.convert_to(p_session_token, 'UTF8'),
            'sha256'
        ),
        'hex'
    )
      AND revoked_at IS NULL;

    RETURN FOUND;
END;
$$;


ALTER FUNCTION "public"."dcc_logout"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_role TEXT;
    v_deleted_at TIMESTAMPTZ;
BEGIN
    SELECT s.role INTO v_role
    FROM public.dcc_validate_session(p_session_token) AS s;

    IF v_role IS NULL OR UPPER(v_role) <> 'ADMIN' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    SELECT u.deleted_at INTO v_deleted_at
    FROM public.dcc_users AS u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND OR v_deleted_at IS NULL THEN
        RETURN FALSE;
    END IF;

    UPDATE public.dcc_users
    SET active = TRUE,
        deleted_at = NULL,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_admin_id TEXT;
    v_target_role TEXT;
    v_target_active BOOLEAN;
    v_deleted_at TIMESTAMPTZ;
    v_active_admins BIGINT;
BEGIN
    SELECT s.id INTO v_admin_id
    FROM public.dcc_validate_session(p_session_token) AS s
    WHERE UPPER(s.role) = 'ADMIN';

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    IF p_active IS NULL THEN
        RAISE EXCEPTION 'Active status is required';
    END IF;

    SELECT u.role, u.active, u.deleted_at
    INTO v_target_role, v_target_active, v_deleted_at
    FROM public.dcc_users AS u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Deleted accounts must be restored separately';
    END IF;

    IF p_active = FALSE THEN
        IF p_user_id = v_admin_id THEN
            RAISE EXCEPTION 'You cannot deactivate your own account';
        END IF;

        IF UPPER(v_target_role) = 'ADMIN' AND v_target_active THEN
            SELECT COUNT(*) INTO v_active_admins
            FROM public.dcc_users
            WHERE UPPER(role) = 'ADMIN'
              AND active = TRUE
              AND deleted_at IS NULL;

            IF v_active_admins <= 1 THEN
                RAISE EXCEPTION 'Cannot deactivate the last active Admin';
            END IF;
        END IF;
    END IF;

    UPDATE public.dcc_users
    SET active = p_active,
        updated_at = NOW()
    WHERE id = p_user_id
      AND deleted_at IS NULL;

    IF p_active = FALSE THEN
        UPDATE public.dcc_sessions
        SET revoked_at = NOW()
        WHERE user_id = p_user_id
          AND revoked_at IS NULL;
    END IF;

    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_upsert_user"("p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  insert into dcc_users (id, name, email, role, hod_name, hod_email, password, active, updated_at)
  values (
    p_id,
    p_name,
    lower(trim(p_email)),
    upper(trim(p_role)),
    p_hod_name,
    lower(trim(p_hod_email)),
    crypt(p_password, gen_salt('bf')),
    p_active,
    now()
  )
  on conflict (id) do update set
    name = excluded.name,
    email = excluded.email,
    role = excluded.role,
    hod_name = excluded.hod_name,
    hod_email = excluded.hod_email,
    password = excluded.password,
    active = excluded.active,
    updated_at = now();
$$;


ALTER FUNCTION "public"."dcc_upsert_user"("p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dcc_validate_session"("p_session_token" "text") RETURNS TABLE("id" "text", "name" "text", "email" "text", "role" "text", "hod_name" "text", "hod_email" "text", "active" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public', 'extensions', 'pg_temp'
    AS $$
DECLARE
    v_user_id TEXT;
BEGIN
    IF p_session_token IS NULL
       OR LENGTH(p_session_token) <> 64 THEN
        RETURN;
    END IF;

    -- Find a valid session belonging to an active user.
    -- Update last_seen_at only when validation succeeds.

    UPDATE public.dcc_sessions AS s
    SET last_seen_at = NOW()
    FROM public.dcc_users AS u
    WHERE s.user_id = u.id
      AND u.active = TRUE
      AND s.token_hash = pg_catalog.encode(
          extensions.digest(
              pg_catalog.convert_to(p_session_token, 'UTF8'),
              'sha256'
          ),
          'hex'
      )
      AND s.revoked_at IS NULL
      AND s.expires_at > NOW()
    RETURNING s.user_id INTO v_user_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Always retrieve the current role from PostgreSQL.
    -- Never trust the role cached in browser storage.

    RETURN QUERY
    SELECT
        u.id,
        u.name,
        u.email,
        u.role,
        u.hod_name,
        u.hod_email,
        u.active
    FROM public.dcc_users AS u
    WHERE u.id = v_user_id
      AND u.active = TRUE;
END;
$$;


ALTER FUNCTION "public"."dcc_validate_session"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_audit_mil_items"("p_audit_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_count INTEGER;
BEGIN

    INSERT INTO public.audit_mil_items (
        audit_id,
        answer_id,
        question_id,
        question,
        description,
        defect_type,
        overall_status
    )
    SELECT
        a.audit_id,
        a.answer_id,
        a.question_id,
        q.question,
        a.description,
        a.defect_type,
        'Open'
    FROM public.audit_checklist_answers a

    INNER JOIN public.audit_questions q
        ON q.question_id = a.question_id

    WHERE a.audit_id = p_audit_id
      AND a.answer = 'No'

      AND NOT EXISTS (
          SELECT 1
          FROM public.audit_mil_items m
          WHERE m.answer_id = a.answer_id
      );


    GET DIAGNOSTICS v_count = ROW_COUNT;


    IF v_count > 0 THEN

        UPDATE public.audits
        SET
            mil_status = 'Open',
            updated_at = NOW()
        WHERE audit_id = p_audit_id;

    ELSE

        -- No findings means MIL is not required.
        UPDATE public.audits
        SET
            mil_status = 'Closed',
            updated_at = NOW()
        WHERE audit_id = p_audit_id
          AND NOT EXISTS (
              SELECT 1
              FROM public.audit_mil_items
              WHERE audit_id = p_audit_id
          );

    END IF;


    RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."generate_audit_mil_items"("p_audit_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_audit_schedule_number"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
    v_prefix TEXT;
    v_number INTEGER;
BEGIN
    IF NEW.schedule_number IS NOT NULL
       AND trim(NEW.schedule_number) <> '' THEN
        RETURN NEW;
    END IF;

    v_prefix :=
        'AS-' ||
        TO_CHAR(COALESCE(NEW.audit_date, CURRENT_DATE), 'YYYYMMDD') ||
        '-';

    SELECT
        COALESCE(
            MAX(
                CASE
                    WHEN schedule_number ~
                        ('^' || v_prefix || '[0-9]+$')
                    THEN
                        SUBSTRING(
                            schedule_number
                            FROM LENGTH(v_prefix) + 1
                        )::INTEGER
                    ELSE 0
                END
            ),
            0
        ) + 1
    INTO v_number
    FROM public.audit_schedules
    WHERE schedule_number LIKE v_prefix || '%';

    NEW.schedule_number :=
        v_prefix ||
        LPAD(v_number::TEXT, 4, '0');

    RETURN NEW;
END;
$_$;


ALTER FUNCTION "public"."generate_audit_schedule_number"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_ncr_number"() RETURNS character varying
    LANGUAGE "plpgsql"
    AS $$
declare
    next_number bigint;
begin

    next_number := nextval('public.ncr_number_sequence');

    return
        'NCR-' ||
        to_char(current_date, 'YYYY') ||
        '-' ||
        lpad(next_number::text, 4, '0');

end;
$$;


ALTER FUNCTION "public"."generate_ncr_number"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_audit_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
    SELECT COALESCE(
        auth.jwt()->'app_metadata'->>'role',
        ''
    ) = 'ADMIN';
$$;


ALTER FUNCTION "public"."is_audit_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_all_ncrs"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    -- Verify active Admin
    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'admin'
    ) then
        raise exception 'Only an active NCR Admin can view all NCR records.';
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id', n.id,
                'ncr_number', n.ncr_number,

                'process_function', n.process_function,
                'clause_section', n.clause_section,

                'auditee_id', n.auditee_id,
                'auditee_name', auditee.full_name,
                'auditee_email', auditee.email,

                'standard', n.standard,
                'report_no', n.report_no,
                'ia_no', n.ia_no,

                'auditor_id', n.auditor_id,
                'auditor_name', auditor.full_name,
                'auditor_email', auditor.email,

                'audit_date', n.audit_date,

                'finding_statement',
                    n.finding_statement,

                'requirement_clause_reference',
                    n.requirement_clause_reference,

                'root_causes',
                    n.root_causes,

                'correction',
                    n.correction,

                'correction_effective_date',
                    n.correction_effective_date,

                'corrective_action',
                    n.corrective_action,

                'corrective_action_effective_date',
                    n.corrective_action_effective_date,

                'follow_up_audit_details',
                    n.follow_up_audit_details,

                'follow_up_audit_date',
                    n.follow_up_audit_date,

                'effectiveness_of_corrective_action',
                    n.effectiveness_of_corrective_action,

                'effectiveness_date',
                    n.effectiveness_date,

                'status_id', s.id,
                'status_key', s.status_key,
                'status_name', s.status_name,

                'created_by', n.created_by,
                'created_at', n.created_at,
                'updated_at', n.updated_at,

                'hod_action', n.hod_action,
                'hod_comments', n.hod_comments,
                'hod_action_by', n.hod_action_by,
                'hod_action_at', n.hod_action_at,

                'dcc_action', n.dcc_action,
                'dcc_comments', n.dcc_comments,
                'dcc_action_by', n.dcc_action_by,
                'dcc_action_at', n.dcc_action_at,

                'closed_at', n.closed_at
            )
            order by n.created_at desc
        ),
        '[]'::jsonb
    )
    into v_result
    from public.ncrs n

    left join public.ncr_users auditee
        on auditee.id = n.auditee_id

    left join public.ncr_users auditor
        on auditor.id = n.auditor_id

    left join public.ncr_statuses s
        on s.id = n.status_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_admin_all_ncrs"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_create_ncr"("p_process_function" "text", "p_clause_section" "text", "p_auditee_id" "uuid", "p_standard" "text", "p_ia_no" "text", "p_auditor_id" "uuid", "p_audit_date" "date", "p_finding_statement" "text", "p_requirement_clause_reference" "text", "p_created_by" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_ncr_id uuid;
    v_status_id uuid;
    v_result jsonb;
begin

    -- ============================================================
    -- VALIDATION
    -- ============================================================

    if p_process_function is null
       or trim(p_process_function) = '' then
        raise exception 'Process / Function is required.';
    end if;

    if p_clause_section is null
       or trim(p_clause_section) = '' then
        raise exception 'Clause / Section is required.';
    end if;

    if p_auditee_id is null then
        raise exception 'Auditee is required.';
    end if;

    if p_auditor_id is null then
        raise exception 'Auditor is required.';
    end if;

    if p_audit_date is null then
        raise exception 'Audit date is required.';
    end if;

    if p_finding_statement is null
       or trim(p_finding_statement) = '' then
        raise exception 'Audit Finding / Nonconformity Statement is required.';
    end if;

    if p_requirement_clause_reference is null
       or trim(p_requirement_clause_reference) = '' then
        raise exception 'Requirement / Clause Reference is required.';
    end if;

    if p_created_by is null then
        raise exception 'NCR creator is required.';
    end if;


    -- ============================================================
    -- VERIFY AUDITEE
    -- ============================================================

    if not exists (
        select 1
        from public.ncr_users
        where id = p_auditee_id
          and is_active = true
    ) then
        raise exception 'Selected auditee is not an active NCR user.';
    end if;


    -- ============================================================
    -- VERIFY AUDITOR
    -- ============================================================

    if not exists (
        select 1
        from public.ncr_users
        where id = p_auditor_id
          and is_active = true
    ) then
        raise exception 'Selected auditor is not an active NCR user.';
    end if;


    -- ============================================================
    -- VERIFY CREATOR
    -- ============================================================

    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
          on r.id = u.role_id
        where u.id = p_created_by
          and u.is_active = true
          and lower(r.role_key) = 'admin'
          and r.is_active = true
    ) then
        raise exception 'Only an active NCR Admin can create an NCR.';
    end if;


    -- ============================================================
    -- GET INITIAL STATUS
    --
    -- Resolve by status_key rather than hardcoding a UUID.
    -- ============================================================

    select id
    into v_status_id
    from public.ncr_statuses
    where lower(status_key) = 'assigned'
      and is_active = true
    limit 1;

    if v_status_id is null then
        raise exception 'NCR status "assigned" is not configured.';
    end if;


    -- ============================================================
    -- CREATE NCR
    --
    -- ncr_number is generated by the existing trigger.
    -- ============================================================

    insert into public.ncrs (
        process_function,
        clause_section,
        auditee_id,
        standard,
        ia_no,
        auditor_id,
        audit_date,
        finding_statement,
        requirement_clause_reference,
        status_id,
        created_by
    )
    values (
        trim(p_process_function),
        trim(p_clause_section),
        p_auditee_id,
        trim(coalesce(p_standard, '')),
        trim(coalesce(p_ia_no, '')),
        p_auditor_id,
        p_audit_date,
        trim(p_finding_statement),
        trim(p_requirement_clause_reference),
        v_status_id,
        p_created_by
    )
    returning id
    into v_ncr_id;


    -- ============================================================
    -- RETURN COMPLETE NCR
    -- ============================================================

    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,

        'process_function', n.process_function,
        'clause_section', n.clause_section,

        'auditee_id', n.auditee_id,
        'auditee_name', au.full_name,

        'standard', n.standard,
        'report_no', n.report_no,
        'ia_no', n.ia_no,

        'auditor_id', n.auditor_id,
        'auditor_name', ar.full_name,

        'audit_date', n.audit_date,

        'finding_statement',
            n.finding_statement,

        'requirement_clause_reference',
            n.requirement_clause_reference,

        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name,

        'created_by', n.created_by,

        'created_at', n.created_at,
        'updated_at', n.updated_at
    )
    into v_result
    from public.ncrs n

    left join public.ncr_users au
        on au.id = n.auditee_id

    left join public.ncr_users ar
        on ar.id = n.auditor_id

    left join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = v_ncr_id;


    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_admin_create_ncr"("p_process_function" "text", "p_clause_section" "text", "p_auditee_id" "uuid", "p_standard" "text", "p_ia_no" "text", "p_auditor_id" "uuid", "p_audit_date" "date", "p_finding_statement" "text", "p_requirement_clause_reference" "text", "p_created_by" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_create_user"("p_admin_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid", "p_password_hash" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user public.ncr_users%rowtype;
    v_role public.ncr_roles%rowtype;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_admin_id
          AND u.is_active = true
          AND r.is_active = true
          AND lower(r.role_key) = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only an active NCR Admin can create users.';
    END IF;

    IF trim(coalesce(p_full_name, '')) = '' THEN
        RAISE EXCEPTION 'Full name is required.';
    END IF;

    IF trim(coalesce(p_email, '')) = '' THEN
        RAISE EXCEPTION 'Email address is required.';
    END IF;

    IF trim(coalesce(p_password_hash, '')) = '' THEN
        RAISE EXCEPTION 'Password hash is required.';
    END IF;

    SELECT *
    INTO v_role
    FROM public.ncr_roles
    WHERE id = p_role_id
      AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected NCR role does not exist or is inactive.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.ncr_users
        WHERE lower(email) = lower(trim(p_email))
    ) THEN
        RAISE EXCEPTION 'An NCR user with this email already exists.';
    END IF;

    INSERT INTO public.ncr_users (
        full_name,
        email,
        password_hash,
        role_id,
        is_active
    )
    VALUES (
        trim(p_full_name),
        lower(trim(p_email)),
        p_password_hash,
        p_role_id,
        true
    )
    RETURNING *
    INTO v_user;

    RETURN jsonb_build_object(
        'id', v_user.id,
        'full_name', v_user.full_name,
        'email', v_user.email,
        'role_id', v_user.role_id,
        'role_key', v_role.role_key,
        'role_name', v_role.role_name,
        'is_active', v_user.is_active,
        'created_at', v_user.created_at,
        'updated_at', v_user.updated_at
    );

END;
$$;


ALTER FUNCTION "public"."ncr_admin_create_user"("p_admin_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid", "p_password_hash" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_dashboard_data"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_total integer;
    v_in_progress integer;
    v_pending_hod integer;
    v_pending_dcc integer;
    v_closed integer;
begin

    -- ============================================================
    -- TOTAL NCRs
    -- ============================================================

    select count(*)
    into v_total
    from public.ncrs;


    -- ============================================================
    -- IN PROGRESS
    -- ============================================================

    select count(*)
    into v_in_progress
    from public.ncrs n
    join public.ncr_statuses s
        on s.id = n.status_id
    where s.status_key in (
        'assigned',
        'in_progress',
        'hod_rejected',
        'dcc_rejected'
    );


    -- ============================================================
    -- PENDING HOD
    -- ============================================================

    select count(*)
    into v_pending_hod
    from public.ncrs n
    join public.ncr_statuses s
        on s.id = n.status_id
    where s.status_key = 'submitted_to_hod';


    -- ============================================================
    -- PENDING DCC
    -- ============================================================

    select count(*)
    into v_pending_dcc
    from public.ncrs n
    join public.ncr_statuses s
        on s.id = n.status_id
    where s.status_key = 'sent_to_dcc';


    -- ============================================================
    -- CLOSED
    -- ============================================================

    select count(*)
    into v_closed
    from public.ncrs n
    join public.ncr_statuses s
        on s.id = n.status_id
    where s.status_key = 'closed';


    -- ============================================================
    -- RETURN DASHBOARD DATA
    -- ============================================================

    return jsonb_build_object(
        'total_ncrs', v_total,
        'in_progress', v_in_progress,
        'pending_hod', v_pending_hod,
        'pending_dcc', v_pending_dcc,
        'closed', v_closed
    );

end;
$$;


ALTER FUNCTION "public"."ncr_admin_dashboard_data"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_is_admin boolean;
    v_exists boolean;
BEGIN
    -- Validate the requesting user.
    SELECT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_user_id
          AND u.is_active = true
          AND r.is_active = true
          AND LOWER(r.role_key) = 'admin'
    )
    INTO v_is_admin;

    IF NOT v_is_admin THEN
        RAISE EXCEPTION 'Only an NCR Admin can delete NCR records.';
    END IF;

    -- Make sure the NCR exists.
    SELECT EXISTS (
        SELECT 1
        FROM public.ncrs
        WHERE id = p_ncr_id
    )
    INTO v_exists;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'NCR record not found.';
    END IF;

    -- ncr_approval_history.ncr_id is ON DELETE CASCADE,
    -- so related approval history is deleted automatically.
    DELETE FROM public.ncrs
    WHERE id = p_ncr_id;

    RETURN true;
END;
$$;


ALTER FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_delete_user"("p_admin_id" "uuid", "p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_reference_count integer;
BEGIN

    -- Verify Admin
    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_admin_id
          AND u.is_active = true
          AND r.is_active = true
          AND lower(r.role_key) = 'admin'
    ) THEN
        RAISE EXCEPTION
            'Only an active NCR Admin can delete users.';
    END IF;

    -- Prevent self deletion
    IF p_admin_id = p_user_id THEN
        RAISE EXCEPTION
            'An Admin cannot delete their own account.';
    END IF;

    -- Verify user exists
    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users
        WHERE id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'NCR user does not exist.';
    END IF;

    -- Check every historical NCR reference
    SELECT COUNT(*)
    INTO v_reference_count
    FROM (
        SELECT id
        FROM public.ncrs
        WHERE auditee_id = p_user_id

        UNION

        SELECT id
        FROM public.ncrs
        WHERE auditor_id = p_user_id

        UNION

        SELECT id
        FROM public.ncrs
        WHERE created_by = p_user_id

        UNION

        SELECT id
        FROM public.ncrs
        WHERE hod_action_by = p_user_id

        UNION

        SELECT id
        FROM public.ncrs
        WHERE dcc_action_by = p_user_id

        UNION

        SELECT ncr_id
        FROM public.ncr_approval_history
        WHERE action_by = p_user_id
    ) referenced_records;

    IF v_reference_count > 0 THEN
        RAISE EXCEPTION
            'This user is referenced by existing NCR records and cannot be permanently deleted. Deactivate the user instead.';
    END IF;

    DELETE FROM public.ncr_users
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'deleted_user_id', p_user_id
    );

END;
$$;


ALTER FUNCTION "public"."ncr_admin_delete_user"("p_admin_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_ncr_details"("p_user_id" "uuid", "p_ncr_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    -- Verify active Admin
    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'admin'
    ) then
        raise exception 'Only an active NCR Admin can view NCR details.';
    end if;

    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,

        'process_function', n.process_function,
        'clause_section', n.clause_section,

        'auditee_id', n.auditee_id,
        'auditee_name', auditee.full_name,
        'auditee_email', auditee.email,

        'standard', n.standard,
        'report_no', n.report_no,
        'ia_no', n.ia_no,

        'auditor_id', n.auditor_id,
        'auditor_name', auditor.full_name,
        'auditor_email', auditor.email,

        'audit_date', n.audit_date,

        'finding_statement',
            n.finding_statement,

        'requirement_clause_reference',
            n.requirement_clause_reference,

        'root_causes',
            n.root_causes,

        'correction',
            n.correction,

        'correction_effective_date',
            n.correction_effective_date,

        'corrective_action',
            n.corrective_action,

        'corrective_action_effective_date',
            n.corrective_action_effective_date,

        'follow_up_audit_details',
            n.follow_up_audit_details,

        'follow_up_audit_date',
            n.follow_up_audit_date,

        'effectiveness_of_corrective_action',
            n.effectiveness_of_corrective_action,

        'effectiveness_date',
            n.effectiveness_date,

        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name,

        'created_by', n.created_by,
        'created_at', n.created_at,
        'updated_at', n.updated_at,

        'hod_action', n.hod_action,
        'hod_comments', n.hod_comments,
        'hod_action_by', n.hod_action_by,
        'hod_action_at', n.hod_action_at,

        'dcc_action', n.dcc_action,
        'dcc_comments', n.dcc_comments,
        'dcc_action_by', n.dcc_action_by,
        'dcc_action_at', n.dcc_action_at,

        'closed_at', n.closed_at,

        'approval_history',
        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'id', h.id,
                        'ncr_id', h.ncr_id,

                        'action_by', h.action_by,
                        'action_by_name',
                            action_user.full_name,
                        'action_by_email',
                            action_user.email,

                        'action_role_id',
                            h.action_role_id,
                        'action_role_key',
                            action_role.role_key,
                        'action_role_name',
                            action_role.role_name,

                        'previous_status_id',
                            h.previous_status_id,
                        'previous_status_key',
                            previous_status.status_key,
                        'previous_status_name',
                            previous_status.status_name,

                        'new_status_id',
                            h.new_status_id,
                        'new_status_key',
                            new_status.status_key,
                        'new_status_name',
                            new_status.status_name,

                        'action', h.action,
                        'comments', h.comments,
                        'created_at', h.created_at
                    )
                    order by h.created_at desc
                )
                from public.ncr_approval_history h

                left join public.ncr_users action_user
                    on action_user.id = h.action_by

                left join public.ncr_roles action_role
                    on action_role.id = h.action_role_id

                left join public.ncr_statuses previous_status
                    on previous_status.id =
                       h.previous_status_id

                left join public.ncr_statuses new_status
                    on new_status.id =
                       h.new_status_id

                where h.ncr_id = n.id
            ),
            '[]'::jsonb
        )
    )
    into v_result

    from public.ncrs n

    left join public.ncr_users auditee
        on auditee.id = n.auditee_id

    left join public.ncr_users auditor
        on auditor.id = n.auditor_id

    left join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id;

    if v_result is null then
        raise exception 'NCR record could not be found.';
    end if;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_admin_ncr_details"("p_user_id" "uuid", "p_ncr_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_set_user_active"("p_admin_id" "uuid", "p_user_id" "uuid", "p_is_active" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user public.ncr_users%rowtype;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_admin_id
          AND u.is_active = true
          AND r.is_active = true
          AND lower(r.role_key) = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only an active NCR Admin can change user status.';
    END IF;

    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required.';
    END IF;

    IF p_admin_id = p_user_id AND p_is_active = false THEN
        RAISE EXCEPTION 'An Admin cannot deactivate their own account.';
    END IF;

    UPDATE public.ncr_users
    SET
        is_active = p_is_active,
        updated_at = now()
    WHERE id = p_user_id
    RETURNING *
    INTO v_user;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'NCR user does not exist.';
    END IF;

    RETURN jsonb_build_object(
        'id', v_user.id,
        'is_active', v_user.is_active,
        'updated_at', v_user.updated_at
    );

END;
$$;


ALTER FUNCTION "public"."ncr_admin_set_user_active"("p_admin_id" "uuid", "p_user_id" "uuid", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_statuses"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    -- Verify active Admin
    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'admin'
    ) then
        raise exception 'Only an active NCR Admin can view NCR statuses.';
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id', id,
                'status_key', status_key,
                'status_name', status_name,
                'is_active', is_active
            )
            order by status_name
        ),
        '[]'::jsonb
    )
    into v_result
    from public.ncr_statuses
    where is_active = true;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_admin_statuses"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_update_user"("p_admin_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    v_user public.ncr_users%rowtype;
    v_role public.ncr_roles%rowtype;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_admin_id
          AND u.is_active = true
          AND r.is_active = true
          AND lower(r.role_key) = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only an active NCR Admin can update users.';
    END IF;

    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required.';
    END IF;

    IF trim(coalesce(p_full_name, '')) = '' THEN
        RAISE EXCEPTION 'Full name is required.';
    END IF;

    IF trim(coalesce(p_email, '')) = '' THEN
        RAISE EXCEPTION 'Email address is required.';
    END IF;

    IF p_role_id IS NULL THEN
        RAISE EXCEPTION 'Role is required.';
    END IF;

    SELECT *
    INTO v_user
    FROM public.ncr_users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'NCR user does not exist.';
    END IF;

    SELECT *
    INTO v_role
    FROM public.ncr_roles
    WHERE id = p_role_id
      AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected NCR role does not exist or is inactive.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.ncr_users
        WHERE lower(email) = lower(trim(p_email))
          AND id <> p_user_id
    ) THEN
        RAISE EXCEPTION 'Another NCR user already uses this email address.';
    END IF;

    UPDATE public.ncr_users
    SET
        full_name = trim(p_full_name),
        email = lower(trim(p_email)),
        role_id = p_role_id,
        updated_at = now()
    WHERE id = p_user_id
    RETURNING *
    INTO v_user;

    RETURN jsonb_build_object(
        'id', v_user.id,
        'full_name', v_user.full_name,
        'email', v_user.email,
        'role_id', v_user.role_id,
        'role_key', v_role.role_key,
        'role_name', v_role.role_name,
        'is_active', v_user.is_active,
        'created_at', v_user.created_at,
        'updated_at', v_user.updated_at
    );

END;
$$;


ALTER FUNCTION "public"."ncr_admin_update_user"("p_admin_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") RETURNS TABLE("id" "uuid", "full_name" "text", "email" "text", "role_id" "uuid", "role_key" "text", "role_name" "text", "is_active" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM public.ncr_users u
        JOIN public.ncr_roles r
            ON r.id = u.role_id
        WHERE u.id = p_user_id
          AND u.is_active = true
          AND r.is_active = true
          AND lower(r.role_key) = 'admin'
    ) THEN
        RAISE EXCEPTION
            'Only an active NCR Admin can view NCR users.';
    END IF;

    RETURN QUERY
    SELECT
        u.id,
        u.full_name::text,
        u.email::text,
        u.role_id,
        r.role_key::text,
        r.role_name::text,
        u.is_active,
        u.created_at,
        u.updated_at
    FROM public.ncr_users u
    JOIN public.ncr_roles r
        ON r.id = u.role_id
    ORDER BY u.full_name;

END;
$$;


ALTER FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_dcc_all_ncrs"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_is_dcc boolean;
begin

    select exists (
        select 1
        from ncr_users u
        join ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.role_key = 'dcc'
          and r.is_active = true
    )
    into v_is_dcc;

    if not v_is_dcc then
        raise exception 'Only an active NCR DCC user can view NCR records.';
    end if;

    return coalesce(
        (
            select jsonb_agg(
                row_to_json(x)
                order by x.created_at desc
            )
            from (
                select
                    n.id,

                    n.ncr_number,

                    n.process_function,
                    n.clause_section,
                    n.standard,
                    n.report_no,
                    n.ia_no,

                    n.audit_date,
                    n.finding_statement,
                    n.requirement_clause_reference,

                    n.root_causes,
                    n.correction,
                    n.correction_effective_date,

                    n.corrective_action,
                    n.corrective_action_effective_date,

                    n.follow_up_audit_details,
                    n.follow_up_audit_date,

                    n.effectiveness_of_corrective_action,
                    n.effectiveness_date,

                    n.hod_action,
                    n.hod_comments,
                    n.hod_action_by,
                    n.hod_action_at,

                    n.dcc_action,
                    n.dcc_comments,
                    n.dcc_action_by,
                    n.dcc_action_at,

                    n.closed_at,

                    n.created_at,
                    n.updated_at,

                    auditee.full_name as auditee_name,
                    auditee.email as auditee_email,

                    auditor.full_name as auditor_name,
                    auditor.email as auditor_email,

                    status.status_key,
                    status.status_name

                from ncrs n

                left join ncr_users auditee
                    on auditee.id = n.auditee_id

                left join ncr_users auditor
                    on auditor.id = n.auditor_id

                left join ncr_statuses status
                    on status.id = n.status_id

            ) x
        ),
        '[]'::jsonb
    );

end;
$$;


ALTER FUNCTION "public"."ncr_dcc_all_ncrs"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_dcc_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text" DEFAULT ''::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_is_dcc boolean;
    v_old_status_id uuid;
    v_new_status_id uuid;
    v_result jsonb;
begin

    select exists (
        select 1
        from ncr_users u
        join ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.role_key = 'dcc'
          and r.is_active = true
    )
    into v_is_dcc;

    if not v_is_dcc then
        raise exception 'Only an active NCR DCC user can approve NCRs.';
    end if;

    select status_id
    into v_old_status_id
    from ncrs
    where id = p_ncr_id;

    if v_old_status_id is null then
        raise exception 'NCR not found.';
    end if;

    if not exists (
        select 1
        from ncr_statuses
        where id = v_old_status_id
          and status_key = 'sent_to_dcc'
    ) then
        raise exception 'This NCR is not currently pending DCC approval.';
    end if;

    select id
    into v_new_status_id
    from ncr_statuses
    where status_key = 'closed'
      and is_active = true
    limit 1;

    if v_new_status_id is null then
        raise exception 'Closed NCR status is not configured.';
    end if;

    update ncrs
    set
        dcc_action = 'approved',
        dcc_comments = nullif(trim(p_comments), ''),
        dcc_action_by = p_user_id,
        dcc_action_at = now(),
        status_id = v_new_status_id,
        closed_at = now(),
        updated_at = now()
    where id = p_ncr_id;

    insert into ncr_approval_history (
        ncr_id,
        action_by,
        action_role_id,
        previous_status_id,
        new_status_id,
        action,
        comments
    )
    select
        p_ncr_id,
        p_user_id,
        r.id,
        v_old_status_id,
        v_new_status_id,
        'approved',
        nullif(trim(p_comments), '')
    from ncr_roles r
    where r.role_key = 'dcc'
    limit 1;

    select row_to_json(n)::jsonb
    into v_result
    from ncrs n
    where n.id = p_ncr_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_dcc_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_dcc_dashboard_data"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_is_dcc boolean;
begin

    select exists (
        select 1
        from ncr_users u
        join ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.role_key = 'dcc'
          and r.is_active = true
    )
    into v_is_dcc;

    if not v_is_dcc then
        raise exception 'Only an active NCR DCC user can access the DCC dashboard.';
    end if;

    return (
        select jsonb_build_object(
            'total_ncrs',
            count(*),

            'pending_dcc',
            count(*) filter (
                where s.status_key = 'sent_to_dcc'
            ),

            'dcc_rejected',
            count(*) filter (
                where s.status_key = 'dcc_rejected'
            ),

            'closed',
            count(*) filter (
                where s.status_key = 'closed'
            )
        )
        from ncrs n
        left join ncr_statuses s
            on s.id = n.status_id
    );

end;
$$;


ALTER FUNCTION "public"."ncr_dcc_dashboard_data"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_dcc_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_is_dcc boolean;
    v_old_status_id uuid;
    v_new_status_id uuid;
    v_result jsonb;
begin

    select exists (
        select 1
        from ncr_users u
        join ncr_roles r
          on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.role_key = 'dcc'
          and r.is_active = true
    )
    into v_is_dcc;

    if not v_is_dcc then
        raise exception 'Only an active NCR DCC user can reject NCRs.';
    end if;

    if trim(coalesce(p_comments, '')) = '' then
        raise exception 'Rejection comments are required.';
    end if;

    select status_id
    into v_old_status_id
    from ncrs
    where id = p_ncr_id;

    if v_old_status_id is null then
        raise exception 'NCR not found.';
    end if;

    if not exists (
        select 1
        from ncr_statuses
        where id = v_old_status_id
          and status_key = 'sent_to_dcc'
    ) then
        raise exception 'This NCR is not currently pending DCC approval.';
    end if;

    select id
    into v_new_status_id
    from ncr_statuses
    where status_key = 'dcc_rejected'
      and is_active = true
    limit 1;

    if v_new_status_id is null then
        raise exception 'DCC rejected status is not configured.';
    end if;

    update ncrs
    set
        dcc_action = 'rejected',
        dcc_comments = trim(p_comments),
        dcc_action_by = p_user_id,
        dcc_action_at = now(),
        status_id = v_new_status_id,
        closed_at = null,
        updated_at = now()
    where id = p_ncr_id;

    insert into ncr_approval_history (
        ncr_id,
        action_by,
        action_role_id,
        previous_status_id,
        new_status_id,
        action,
        comments
    )
    select
        p_ncr_id,
        p_user_id,
        r.id,
        v_old_status_id,
        v_new_status_id,
        'rejected',
        trim(p_comments)
    from ncr_roles r
    where r.role_key = 'dcc'
    limit 1;

    select row_to_json(n)::jsonb
    into v_result
    from ncrs n
    where n.id = p_ncr_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_dcc_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_hod_all_ncrs"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
            on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'hod'
    ) then
        raise exception
            'Only an active NCR HOD can view NCR records.';
    end if;


    select coalesce(
        jsonb_agg(
            jsonb_build_object(

                'id', n.id,
                'ncr_number', n.ncr_number,

                'process_function',
                    n.process_function,

                'clause_section',
                    n.clause_section,

                'auditee_id',
                    n.auditee_id,

                'auditee_name',
                    auditee.full_name,

                'auditor_id',
                    n.auditor_id,

                'auditor_name',
                    auditor.full_name,

                'standard',
                    n.standard,

                'report_no',
                    n.report_no,

                'ia_no',
                    n.ia_no,

                'audit_date',
                    n.audit_date,

                'finding_statement',
                    n.finding_statement,

                'requirement_clause_reference',
                    n.requirement_clause_reference,

                'root_causes',
                    n.root_causes,

                'correction',
                    n.correction,

                'correction_effective_date',
                    n.correction_effective_date,

                'corrective_action',
                    n.corrective_action,

                'corrective_action_effective_date',
                    n.corrective_action_effective_date,

                'follow_up_audit_details',
                    n.follow_up_audit_details,

                'follow_up_audit_date',
                    n.follow_up_audit_date,

                'effectiveness_of_corrective_action',
                    n.effectiveness_of_corrective_action,

                'effectiveness_date',
                    n.effectiveness_date,

                'status_id',
                    s.id,

                'status_key',
                    s.status_key,

                'status_name',
                    s.status_name,

                'created_by',
                    n.created_by,

                'created_at',
                    n.created_at,

                'updated_at',
                    n.updated_at,

                'hod_action',
                    n.hod_action,

                'hod_comments',
                    n.hod_comments,

                'hod_action_by',
                    n.hod_action_by,

                'hod_action_at',
                    n.hod_action_at,

                'dcc_action',
                    n.dcc_action,

                'dcc_comments',
                    n.dcc_comments,

                'dcc_action_by',
                    n.dcc_action_by,

                'dcc_action_at',
                    n.dcc_action_at,

                'closed_at',
                    n.closed_at
            )
            order by n.created_at desc
        ),
        '[]'::jsonb
    )
    into v_result

    from public.ncrs n

    left join public.ncr_users auditee
        on auditee.id = n.auditee_id

    left join public.ncr_users auditor
        on auditor.id = n.auditor_id

    left join public.ncr_statuses s
        on s.id = n.status_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_hod_all_ncrs"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_hod_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_role_id uuid;
    v_old_status_id uuid;
    v_new_status_id uuid;
    v_result jsonb;
begin

    -- ----------------------------------------------------------
    -- VERIFY HOD
    -- ----------------------------------------------------------

    select r.id
    into v_role_id

    from public.ncr_users u

    join public.ncr_roles r
        on r.id = u.role_id

    where u.id = p_user_id
      and u.is_active = true
      and r.is_active = true
      and lower(r.role_key) = 'hod';

    if v_role_id is null then
        raise exception
            'Only an active NCR HOD can approve NCRs.';
    end if;


    -- ----------------------------------------------------------
    -- CURRENT STATUS
    -- ----------------------------------------------------------

    select n.status_id
    into v_old_status_id

    from public.ncrs n

    join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id
      and lower(s.status_key) =
          'submitted_to_hod';

    if v_old_status_id is null then
        raise exception
            'This NCR is not currently awaiting HOD approval.';
    end if;


    -- ----------------------------------------------------------
    -- TARGET STATUS
    -- ----------------------------------------------------------

    select id
    into v_new_status_id

    from public.ncr_statuses

    where lower(status_key) =
        'sent_to_dcc'

      and is_active = true

    limit 1;

    if v_new_status_id is null then
        raise exception
            'NCR status "sent_to_dcc" is not configured.';
    end if;


    -- ----------------------------------------------------------
    -- UPDATE NCR
    -- ----------------------------------------------------------

    update public.ncrs

    set
        status_id = v_new_status_id,

        hod_action = 'approved',

        hod_comments =
            nullif(trim(p_comments), ''),

        hod_action_by =
            p_user_id,

        hod_action_at =
            now(),

        updated_at =
            now()

    where id = p_ncr_id;


    -- ----------------------------------------------------------
    -- HISTORY
    -- ----------------------------------------------------------

    insert into public.ncr_approval_history (
        ncr_id,
        action_by,
        action_role_id,
        previous_status_id,
        new_status_id,
        action,
        comments
    )
    values (
        p_ncr_id,
        p_user_id,
        v_role_id,
        v_old_status_id,
        v_new_status_id,
        'approved',
        nullif(trim(p_comments), '')
    );


    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,
        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name
    )
    into v_result

    from public.ncrs n

    join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_hod_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_hod_dashboard_data"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    -- ----------------------------------------------------------
    -- VERIFY HOD
    -- ----------------------------------------------------------

    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
            on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'hod'
    ) then
        raise exception
            'Only an active NCR HOD can access the HOD dashboard.';
    end if;


    -- ----------------------------------------------------------
    -- DASHBOARD COUNTS
    -- ----------------------------------------------------------

    select jsonb_build_object(

        'total_ncrs',
        (
            select count(*)
            from public.ncrs
        ),

        'pending_hod',
        (
            select count(*)
            from public.ncrs n
            join public.ncr_statuses s
                on s.id = n.status_id
            where lower(s.status_key) =
                'submitted_to_hod'
        ),

        'hod_rejected',
        (
            select count(*)
            from public.ncrs n
            join public.ncr_statuses s
                on s.id = n.status_id
            where lower(s.status_key) =
                'hod_rejected'
        ),

        'sent_to_dcc',
        (
            select count(*)
            from public.ncrs n
            join public.ncr_statuses s
                on s.id = n.status_id
            where lower(s.status_key) =
                'sent_to_dcc'
        ),

        'closed',
        (
            select count(*)
            from public.ncrs n
            join public.ncr_statuses s
                on s.id = n.status_id
            where lower(s.status_key) =
                'closed'
        )

    )
    into v_result;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_hod_dashboard_data"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_hod_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_role_id uuid;
    v_old_status_id uuid;
    v_new_status_id uuid;
    v_result jsonb;
begin

    -- ----------------------------------------------------------
    -- VERIFY HOD
    -- ----------------------------------------------------------

    select r.id
    into v_role_id

    from public.ncr_users u

    join public.ncr_roles r
        on r.id = u.role_id

    where u.id = p_user_id
      and u.is_active = true
      and r.is_active = true
      and lower(r.role_key) = 'hod';

    if v_role_id is null then
        raise exception
            'Only an active NCR HOD can reject NCRs.';
    end if;


    -- ----------------------------------------------------------
    -- CURRENT STATUS
    -- ----------------------------------------------------------

    select n.status_id
    into v_old_status_id

    from public.ncrs n

    join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id
      and lower(s.status_key) =
          'submitted_to_hod';

    if v_old_status_id is null then
        raise exception
            'This NCR is not currently awaiting HOD approval.';
    end if;


    -- ----------------------------------------------------------
    -- TARGET STATUS
    -- ----------------------------------------------------------

    select id
    into v_new_status_id

    from public.ncr_statuses

    where lower(status_key) =
        'hod_rejected'

      and is_active = true

    limit 1;

    if v_new_status_id is null then
        raise exception
            'NCR status "hod_rejected" is not configured.';
    end if;


    -- ----------------------------------------------------------
    -- REQUIRE COMMENT
    -- ----------------------------------------------------------

    if nullif(trim(p_comments), '') is null then
        raise exception
            'Rejection comments are required.';
    end if;


    -- ----------------------------------------------------------
    -- UPDATE NCR
    -- ----------------------------------------------------------

    update public.ncrs

    set
        status_id = v_new_status_id,

        hod_action = 'rejected',

        hod_comments =
            trim(p_comments),

        hod_action_by =
            p_user_id,

        hod_action_at =
            now(),

        updated_at =
            now()

    where id = p_ncr_id;


    -- ----------------------------------------------------------
    -- HISTORY
    -- ----------------------------------------------------------

    insert into public.ncr_approval_history (
        ncr_id,
        action_by,
        action_role_id,
        previous_status_id,
        new_status_id,
        action,
        comments
    )
    values (
        p_ncr_id,
        p_user_id,
        v_role_id,
        v_old_status_id,
        v_new_status_id,
        'rejected',
        trim(p_comments)
    );


    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,
        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name
    )
    into v_result

    from public.ncrs n

    join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_hod_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_login"("p_email" "text", "p_password" "text") RETURNS TABLE("id" "uuid", "full_name" "text", "email" "text", "role_id" "uuid", "role_key" "text", "role_name" "text", "is_active" boolean, "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
declare
    v_user public.ncr_users%rowtype;
begin

    -- ============================================================
    -- FIND NCR USER
    -- ============================================================

    select u.*
    into v_user
    from public.ncr_users as u
    where lower(u.email) = lower(trim(p_email))
    limit 1;

    if not found then
        raise exception 'Invalid email or password.';
    end if;


    -- ============================================================
    -- CHECK ACCOUNT STATUS
    -- ============================================================

    if v_user.is_active <> true then
        raise exception 'This NCR user account is inactive.';
    end if;


    -- ============================================================
    -- CHECK PASSWORD
    -- ============================================================

    if v_user.password_hash is null
       or v_user.password_hash = '' then
        raise exception 'Invalid email or password.';
    end if;

    if extensions.crypt(
        p_password,
        v_user.password_hash
    ) <> v_user.password_hash then
        raise exception 'Invalid email or password.';
    end if;


    -- ============================================================
    -- RETURN USER + ROLE
    -- ============================================================

    return query
    select
        v_user.id,
        v_user.full_name::text,
        v_user.email::text,
        v_user.role_id,
        r.role_key::text,
        r.role_name::text,
        v_user.is_active,
        v_user.created_at,
        v_user.updated_at
    from public.ncr_roles as r
    where r.id = v_user.role_id
      and r.is_active = true;


    -- ============================================================
    -- ROLE VALIDATION
    -- ============================================================

    if not found then
        raise exception 'NCR role is missing or inactive.';
    end if;

end;
$$;


ALTER FUNCTION "public"."ncr_login"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_public_dashboard_data"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_total_ncrs integer;
    v_in_progress integer;
    v_pending_approval integer;
    v_closed integer;

    v_records jsonb;
begin

    -- ==========================================================
    -- TOTAL
    -- ==========================================================

    select count(*)
    into v_total_ncrs
    from ncrs;


    -- ==========================================================
    -- IN PROGRESS
    --
    -- Includes NCRs which are actively moving through
    -- correction/workflow but are not closed.
    -- ==========================================================

    select count(*)
    into v_in_progress
    from ncrs n
    join ncr_statuses s
      on s.id = n.status_id
    where s.status_key in (
        'assigned',
        'in_progress',
        'hod_rejected',
        'dcc_rejected'
    );


    -- ==========================================================
    -- PENDING APPROVAL
    --
    -- Includes:
    --   submitted_to_hod
    --   sent_to_dcc
    -- ==========================================================

    select count(*)
    into v_pending_approval
    from ncrs n
    join ncr_statuses s
      on s.id = n.status_id
    where s.status_key in (
        'submitted_to_hod',
        'sent_to_dcc'
    );


    -- ==========================================================
    -- CLOSED
    -- ==========================================================

    select count(*)
    into v_closed
    from ncrs n
    join ncr_statuses s
      on s.id = n.status_id
    where s.status_key = 'closed';


    -- ==========================================================
    -- PUBLIC NCR RECORDS
    --
    -- Only information needed for the public dashboard is
    -- returned.
    -- ==========================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                x.id,

                'ncr_number',
                x.ncr_number,

                'process_function',
                x.process_function,

                'clause_section',
                x.clause_section,

                'auditee_name',
                x.auditee_name,

                'standard',
                x.standard,

                'report_no',
                x.report_no,

                'ia_no',
                x.ia_no,

                'auditor_name',
                x.auditor_name,

                'audit_date',
                x.audit_date,

                'finding_statement',
                x.finding_statement,

                'requirement_clause_reference',
                x.requirement_clause_reference,

                'status_key',
                x.status_key,

                'status_name',
                x.status_name,

                'created_at',
                x.created_at,

                'updated_at',
                x.updated_at
            )
            order by x.created_at desc
        ),
        '[]'::jsonb
    )
    into v_records
    from (
        select
            n.id,
            n.ncr_number,

            n.process_function,
            n.clause_section,

            n.standard,
            n.report_no,
            n.ia_no,

            n.audit_date,

            n.finding_statement,
            n.requirement_clause_reference,

            auditee.full_name as auditee_name,
            auditor.full_name as auditor_name,

            s.status_key,
            s.status_name,

            n.created_at,
            n.updated_at

        from ncrs n

        left join ncr_users auditee
            on auditee.id = n.auditee_id

        left join ncr_users auditor
            on auditor.id = n.auditor_id

        left join ncr_statuses s
            on s.id = n.status_id

        order by n.created_at desc
    ) x;


    -- ==========================================================
    -- RETURN
    -- ==========================================================

    return jsonb_build_object(
        'total_ncrs',
        v_total_ncrs,

        'in_progress',
        v_in_progress,

        'pending_approval',
        v_pending_approval,

        'closed',
        v_closed,

        'records',
        v_records
    );

end;
$$;


ALTER FUNCTION "public"."ncr_public_dashboard_data"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_roles_list"() RETURNS TABLE("id" "uuid", "role_key" "text", "role_name" "text", "description" "text", "is_active" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    select
        r.id,
        r.role_key::text,
        r.role_name::text,
        r.description::text,
        r.is_active
    from public.ncr_roles r
    where r.is_active = true
    order by r.role_name;
$$;


ALTER FUNCTION "public"."ncr_roles_list"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin

    new.updated_at := now();

    return new;

end;
$$;


ALTER FUNCTION "public"."ncr_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_user_assigned_ncrs"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
            on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'user'
    ) then
        raise exception
            'Only an active NCR User can access assigned NCRs.';
    end if;

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id', n.id,
                'ncr_number', n.ncr_number,

                'process_function',
                    n.process_function,

                'clause_section',
                    n.clause_section,

                'auditee_id',
                    n.auditee_id,

                'auditee_name',
                    auditee.full_name,

                'auditor_id',
                    n.auditor_id,

                'auditor_name',
                    auditor.full_name,

                'standard',
                    n.standard,

                'report_no',
                    n.report_no,

                'ia_no',
                    n.ia_no,

                'audit_date',
                    n.audit_date,

                'finding_statement',
                    n.finding_statement,

                'requirement_clause_reference',
                    n.requirement_clause_reference,

                'root_causes',
                    n.root_causes,

                'correction',
                    n.correction,

                'correction_effective_date',
                    n.correction_effective_date,

                'corrective_action',
                    n.corrective_action,

                'corrective_action_effective_date',
                    n.corrective_action_effective_date,

                'follow_up_audit_details',
                    n.follow_up_audit_details,

                'follow_up_audit_date',
                    n.follow_up_audit_date,

                'effectiveness_of_corrective_action',
                    n.effectiveness_of_corrective_action,

                'effectiveness_date',
                    n.effectiveness_date,

                'status_id',
                    s.id,

                'status_key',
                    s.status_key,

                'status_name',
                    s.status_name,

                'created_by',
                    n.created_by,

                'created_at',
                    n.created_at,

                'updated_at',
                    n.updated_at,

                'hod_action',
                    n.hod_action,

                'hod_comments',
                    n.hod_comments,

                'hod_action_at',
                    n.hod_action_at,

                'dcc_action',
                    n.dcc_action,

                'dcc_comments',
                    n.dcc_comments,

                'dcc_action_at',
                    n.dcc_action_at,

                'closed_at',
                    n.closed_at
            )
            order by n.created_at desc
        ),
        '[]'::jsonb
    )
    into v_result

    from public.ncrs n

    left join public.ncr_users auditee
        on auditee.id = n.auditee_id

    left join public.ncr_users auditor
        on auditor.id = n.auditor_id

    left join public.ncr_statuses s
        on s.id = n.status_id

    where n.auditee_id = p_user_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_user_assigned_ncrs"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_user_submit_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_old_status_id uuid;
    v_new_status_id uuid;
    v_role_id uuid;
    v_result jsonb;
begin

    -- ----------------------------------------------------------
    -- VERIFY USER
    -- ----------------------------------------------------------

    select r.id
    into v_role_id

    from public.ncr_users u

    join public.ncr_roles r
        on r.id = u.role_id

    where u.id = p_user_id
      and u.is_active = true
      and r.is_active = true
      and lower(r.role_key) = 'user';

    if v_role_id is null then
        raise exception
            'Only an active NCR User can submit an action plan.';
    end if;


    -- ----------------------------------------------------------
    -- GET NCR
    -- ----------------------------------------------------------

    select status_id
    into v_old_status_id

    from public.ncrs

    where id = p_ncr_id
      and auditee_id = p_user_id;

    if v_old_status_id is null then
        raise exception
            'You are not assigned to this NCR.';
    end if;


    -- ----------------------------------------------------------
    -- GET TARGET STATUS
    -- ----------------------------------------------------------

    select id
    into v_new_status_id

    from public.ncr_statuses

    where lower(status_key) = 'submitted_to_hod'
      and is_active = true

    limit 1;

    if v_new_status_id is null then
        raise exception
            'NCR status "submitted_to_hod" is not configured.';
    end if;


    -- ----------------------------------------------------------
    -- UPDATE NCR
    -- ----------------------------------------------------------

    update public.ncrs

    set
        status_id = v_new_status_id,
        updated_at = now()

    where id = p_ncr_id
      and auditee_id = p_user_id;


    -- ----------------------------------------------------------
    -- HISTORY
    -- ----------------------------------------------------------

    insert into public.ncr_approval_history (
        ncr_id,
        action_by,
        action_role_id,
        previous_status_id,
        new_status_id,
        action,
        comments
    )
    values (
        p_ncr_id,
        p_user_id,
        v_role_id,
        v_old_status_id,
        v_new_status_id,
        'submitted',
        'Action plan submitted to HOD.'
    );


    -- ----------------------------------------------------------
    -- RETURN
    -- ----------------------------------------------------------

    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,
        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name,
        'updated_at', n.updated_at
    )
    into v_result

    from public.ncrs n

    left join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id;


    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_user_submit_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ncr_user_update_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_root_causes" "text", "p_correction" "text", "p_correction_effective_date" "date", "p_corrective_action" "text", "p_corrective_action_effective_date" "date", "p_follow_up_audit_details" "text", "p_follow_up_audit_date" "date", "p_effectiveness_of_corrective_action" "text", "p_effectiveness_date" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
    v_result jsonb;
begin

    if not exists (
        select 1
        from public.ncr_users u
        join public.ncr_roles r
            on r.id = u.role_id
        where u.id = p_user_id
          and u.is_active = true
          and r.is_active = true
          and lower(r.role_key) = 'user'
    ) then
        raise exception
            'Only an active NCR User can update an action plan.';
    end if;


    if not exists (
        select 1
        from public.ncrs
        where id = p_ncr_id
          and auditee_id = p_user_id
    ) then
        raise exception
            'You are not assigned to this NCR.';
    end if;


    update public.ncrs
    set
        root_causes =
            nullif(trim(p_root_causes), ''),

        correction =
            nullif(trim(p_correction), ''),

        correction_effective_date =
            p_correction_effective_date,

        corrective_action =
            nullif(trim(p_corrective_action), ''),

        corrective_action_effective_date =
            p_corrective_action_effective_date,

        follow_up_audit_details =
            nullif(
                trim(p_follow_up_audit_details),
                ''
            ),

        follow_up_audit_date =
            p_follow_up_audit_date,

        effectiveness_of_corrective_action =
            nullif(
                trim(
                    p_effectiveness_of_corrective_action
                ),
                ''
            ),

        effectiveness_date =
            p_effectiveness_date,

        updated_at =
            now()

    where id = p_ncr_id
      and auditee_id = p_user_id;


    select jsonb_build_object(
        'id', n.id,
        'ncr_number', n.ncr_number,
        'status_id', s.id,
        'status_key', s.status_key,
        'status_name', s.status_name,
        'updated_at', n.updated_at
    )
    into v_result

    from public.ncrs n

    left join public.ncr_statuses s
        on s.id = n.status_id

    where n.id = p_ncr_id;

    return v_result;

end;
$$;


ALTER FUNCTION "public"."ncr_user_update_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_root_causes" "text", "p_correction" "text", "p_correction_effective_date" "date", "p_corrective_action" "text", "p_corrective_action_effective_date" "date", "p_follow_up_audit_details" "text", "p_follow_up_audit_date" "date", "p_effectiveness_of_corrective_action" "text", "p_effectiveness_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rename_batch"("p_old_batch_id" "text", "p_new_batch_id" "text", "p_batch_name" "text", "p_description" "text", "p_is_active" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
declare
    v_old_id text := trim(p_old_batch_id);
    v_new_id text := trim(p_new_batch_id);
    v_result jsonb;
begin

    if v_old_id = '' or v_new_id = '' then
        raise exception 'Batch ID cannot be empty';
    end if;

    if v_old_id = v_new_id then

        update public.batches
        set
            batch_name = trim(p_batch_name),
            description = trim(p_description),
            is_active = p_is_active,
            updated_at = now()
        where batch_id = v_old_id;

        if not found then
            raise exception 'Batch % does not exist', v_old_id;
        end if;

    else

        -- Prevent duplicate Batch ID
        if exists (
            select 1
            from public.batches
            where batch_id = v_new_id
        ) then
            raise exception 'Batch ID % already exists', v_new_id;
        end if;

        -- Create the new parent row first.
        insert into public.batches (
            batch_id,
            batch_name,
            description,
            is_active,
            created_at,
            updated_at
        )
        select
            v_new_id,
            trim(p_batch_name),
            trim(p_description),
            p_is_active,
            created_at,
            now()
        from public.batches
        where batch_id = v_old_id;

        if not found then
            raise exception 'Batch % does not exist', v_old_id;
        end if;

        -- Move all parts to the new Batch ID.
        update public.parts
        set
            batch_id = v_new_id,
            updated_at = now()
        where batch_id = v_old_id;

        -- Move existing ARR records.
        update public.arr_records
        set
            batch_id = v_new_id
        where batch_id = v_old_id;

        -- Delete the old parent only after children are moved.
        delete from public.batches
        where batch_id = v_old_id;

    end if;

    select to_jsonb(b)
    into v_result
    from public.batches b
    where b.batch_id = v_new_id;

    return v_result;
end;
$$;


ALTER FUNCTION "public"."rename_batch"("p_old_batch_id" "text", "p_new_batch_id" "text", "p_batch_name" "text", "p_description" "text", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_admin_password"("p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
begin
  if not verify_admin_password(p_current_password) then
    return false;
  end if;

  update admin_profiles
  set password_hash = crypt(p_new_password, gen_salt('bf'))
  where role = 'admin';

  return true;
end;
$$;


ALTER FUNCTION "public"."set_admin_password"("p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_arr_password"("p_current_password" "text", "p_new_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
begin
  if not verify_arr_password(p_current_password) then
    return false;
  end if;

  update admin_profiles
  set password_hash = crypt(p_new_password, gen_salt('bf'))
  where role = 'arr';

  return true;
end;
$$;


ALTER FUNCTION "public"."set_arr_password"("p_current_password" "text", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_audit_master_data_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_audit_master_data_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_audit_schedule_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_audit_schedule_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_audit_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_audit_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_ncr_number"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin

    if new.ncr_number is null
       or trim(new.ncr_number) = '' then

        new.ncr_number := public.generate_ncr_number();

    end if;

    return new;

end;
$$;


ALTER FUNCTION "public"."set_ncr_number"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."submit_audit"("p_audit_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_total_categories INTEGER;
    v_completed_categories INTEGER;

    v_total_questions INTEGER;
    v_answered_questions INTEGER;

    v_invalid_no_answers INTEGER;
BEGIN

    -- --------------------------------------------------------
    -- Check audit exists
    -- --------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.audits
        WHERE audit_id = p_audit_id
    ) THEN

        RAISE EXCEPTION
            'Audit does not exist.';

    END IF;


    -- --------------------------------------------------------
    -- Count active categories
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_total_categories
    FROM public.audit_categories c

    INNER JOIN public.audits a
        ON a.type_id = c.type_id

    WHERE a.audit_id = p_audit_id
      AND c.active = TRUE;


    -- --------------------------------------------------------
    -- Count completed categories
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_completed_categories
    FROM public.audit_category_progress p

    INNER JOIN public.audit_categories c
        ON c.category_id = p.category_id

    WHERE p.audit_id = p_audit_id
      AND c.active = TRUE
      AND p.completed = TRUE;


    IF v_completed_categories <> v_total_categories THEN

        RAISE EXCEPTION
            'All audit categories must be completed before submission.';

    END IF;


    -- --------------------------------------------------------
    -- Count active questions
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_total_questions
    FROM public.audit_questions q

    INNER JOIN public.audit_categories c
        ON c.category_id = q.category_id

    INNER JOIN public.audits a
        ON a.type_id = c.type_id

    WHERE a.audit_id = p_audit_id
      AND c.active = TRUE
      AND q.active = TRUE;


    -- --------------------------------------------------------
    -- Count answered questions
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_answered_questions
    FROM public.audit_checklist_answers ans

    INNER JOIN public.audit_questions q
        ON q.question_id = ans.question_id

    INNER JOIN public.audit_categories c
        ON c.category_id = q.category_id

    WHERE ans.audit_id = p_audit_id
      AND c.active = TRUE
      AND q.active = TRUE
      AND ans.answer IS NOT NULL;


    IF v_answered_questions <> v_total_questions THEN

        RAISE EXCEPTION
            'Every active audit question must be answered before submission.';

    END IF;


    -- --------------------------------------------------------
    -- Validate every NO answer
    -- --------------------------------------------------------

    SELECT COUNT(*)
    INTO v_invalid_no_answers
    FROM public.audit_checklist_answers
    WHERE audit_id = p_audit_id
      AND answer = 'No'
      AND (
          description IS NULL
          OR length(trim(description)) = 0
          OR defect_type IS NULL
      );


    IF v_invalid_no_answers > 0 THEN

        RAISE EXCEPTION
            'Every No answer must contain a description and defect type.';

    END IF;


    -- --------------------------------------------------------
    -- Submit audit
    -- --------------------------------------------------------

    UPDATE public.audits
    SET
        status = 'Submitted',
        finished_at = COALESCE(finished_at, NOW()),
        updated_at = NOW()
    WHERE audit_id = p_audit_id;


    -- --------------------------------------------------------
    -- Generate MIL
    -- --------------------------------------------------------

    PERFORM public.generate_audit_mil_items(
        p_audit_id
    );


    RETURN TRUE;

END;
$$;


ALTER FUNCTION "public"."submit_audit"("p_audit_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    IF p_session_token IS NULL
       OR trim(p_session_token) = '' THEN
        RETURN NULL;
    END IF;

    SELECT s.admin_id
    INTO v_admin_id
    FROM public.audit_admin_sessions s
    JOIN public.audit_admins a
      ON a.admin_id = s.admin_id
    WHERE s.token_hash =
          encode(
              digest(trim(p_session_token), 'sha256'),
              'hex'
          )
      AND s.expires_at > NOW()
      AND a.active = TRUE
    LIMIT 1;

    RETURN v_admin_id;
END;
$$;


ALTER FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_audit_category_completion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$

DECLARE
    v_total_questions INTEGER;
    v_answered_questions INTEGER;
    v_audit_status TEXT;

BEGIN

    SELECT status
    INTO v_audit_status
    FROM public.audits
    WHERE audit_id = NEW.audit_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Audit does not exist.';

    END IF;


    IF TG_OP = 'UPDATE'
       AND v_audit_status IN ('Submitted', 'Completed') THEN

        RAISE EXCEPTION
            'Audit is already submitted/completed and category progress cannot be modified.';

    END IF;


    IF NEW.completed = TRUE THEN

        SELECT COUNT(*)
        INTO v_total_questions
        FROM public.audit_questions q
        WHERE q.category_id = NEW.category_id
          AND q.active = TRUE;


        SELECT COUNT(*)
        INTO v_answered_questions
        FROM public.audit_checklist_answers a
        INNER JOIN public.audit_questions q
            ON q.question_id = a.question_id
        WHERE a.audit_id = NEW.audit_id
          AND q.category_id = NEW.category_id
          AND q.active = TRUE
          AND a.answer IS NOT NULL;


        IF v_answered_questions <> v_total_questions THEN

            RAISE EXCEPTION
                'Category cannot be marked completed until all active questions are answered.';

        END IF;


        NEW.completed_at =
            COALESCE(
                NEW.completed_at,
                NOW()
            );

    ELSE

        NEW.completed_at = NULL;

    END IF;


    RETURN NEW;

END;

$$;


ALTER FUNCTION "public"."validate_audit_category_completion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_audit_checklist_answer"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$

DECLARE
    v_audit_status TEXT;
    v_mil_status TEXT;

BEGIN

    SELECT
        status,
        mil_status
    INTO
        v_audit_status,
        v_mil_status
    FROM public.audits
    WHERE audit_id = NEW.audit_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Audit does not exist.';

    END IF;


    IF TG_OP = 'UPDATE'
       AND (
           v_audit_status IN ('Submitted', 'Completed')
           OR v_mil_status = 'Closed'
       ) THEN

        RAISE EXCEPTION
            'This audit is submitted/completed and checklist answers cannot be modified.';

    END IF;


    IF NEW.answer IS NULL THEN

        RAISE EXCEPTION
            'Audit checklist answer cannot be NULL.';

    END IF;


    IF NEW.answer = 'Yes' THEN

        IF NEW.defect_type IS NOT NULL THEN

            RAISE EXCEPTION
                'Defect type must be NULL when the answer is Yes.';

        END IF;

    END IF;


    IF NEW.answer = 'No' THEN

        IF NEW.description IS NULL
           OR length(trim(NEW.description)) = 0 THEN

            RAISE EXCEPTION
                'Description is required when the answer is No.';

        END IF;


        IF NEW.defect_type IS NULL THEN

            RAISE EXCEPTION
                'Defect type is required when the answer is No.';

        END IF;

    END IF;


    NEW.answered_at =
        COALESCE(
            NEW.answered_at,
            NOW()
        );


    RETURN NEW;

END;

$$;


ALTER FUNCTION "public"."validate_audit_checklist_answer"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_audit_mil_item"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$

DECLARE
    v_answer TEXT;
    v_answer_audit_id UUID;
    v_answer_question_id UUID;
    v_defect_type TEXT;
    v_mil_status TEXT;
BEGIN

    SELECT
        answer,
        audit_id,
        question_id,
        defect_type
    INTO
        v_answer,
        v_answer_audit_id,
        v_answer_question_id,
        v_defect_type
    FROM public.audit_checklist_answers
    WHERE answer_id = NEW.answer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'MIL item references a checklist answer that does not exist.';
    END IF;


    SELECT mil_status
    INTO v_mil_status
    FROM public.audits
    WHERE audit_id = NEW.audit_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'MIL item references an audit that does not exist.';
    END IF;


    -- A closed MIL can never be inserted or modified.
    IF v_mil_status = 'Closed' THEN
        RAISE EXCEPTION
            'MIL is closed and cannot be modified.';
    END IF;


    IF v_answer <> 'No' THEN
        RAISE EXCEPTION
            'MIL item can only be created for a checklist answer of No.';
    END IF;


    IF v_answer_audit_id <> NEW.audit_id THEN
        RAISE EXCEPTION
            'MIL item audit_id does not match the checklist answer audit_id.';
    END IF;


    IF v_answer_question_id <> NEW.question_id THEN
        RAISE EXCEPTION
            'MIL item question_id does not match the checklist answer question_id.';
    END IF;


    IF v_defect_type <> NEW.defect_type THEN
        RAISE EXCEPTION
            'MIL defect type does not match the checklist answer defect type.';
    END IF;


    RETURN NEW;

END;

$$;


ALTER FUNCTION "public"."validate_audit_mil_item"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_audit_times"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN

    IF NEW.finished_at IS NOT NULL
       AND NEW.started_at IS NOT NULL
       AND NEW.finished_at < NEW.started_at THEN

        RAISE EXCEPTION
            'Audit finished_at cannot be earlier than started_at.';

    END IF;


    IF NEW.elapsed_seconds < 0 THEN
        RAISE EXCEPTION
            'Audit elapsed_seconds cannot be negative.';
    END IF;


    IF NEW.total_time_taken_hours < 0 THEN
        RAISE EXCEPTION
            'Audit total_time_taken_hours cannot be negative.';
    END IF;


    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_audit_times"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_admin_password"("p_password" "text") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  select exists (
    select 1
    from admin_profiles
    where role = 'admin'
      and password_hash is not null
      and password_hash = crypt(p_password, password_hash)
  );
$$;


ALTER FUNCTION "public"."verify_admin_password"("p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_arr_password"("p_password" "text") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  select exists (
    select 1
    from admin_profiles
    where role = 'arr'
      and password_hash is not null
      and password_hash = crypt(p_password, password_hash)
  );
$$;


ALTER FUNCTION "public"."verify_arr_password"("p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_audit_admin"("p_email" "text", "p_password" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
declare
  v_hash text;
begin
  select password_hash into v_hash
  from public.audit_admins
  where lower(email) = lower(p_email)
    and active = true
  limit 1;

  if v_hash is null then
    return false;
  end if;

  return v_hash = crypt(p_password, v_hash);
end;
$$;


ALTER FUNCTION "public"."verify_audit_admin"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$

DECLARE
    v_admin public.audit_admins%ROWTYPE;
    v_token TEXT;
    v_session_id UUID;
    v_expires_at TIMESTAMPTZ;

BEGIN

    SELECT *
    INTO v_admin
    FROM public.audit_admins
    WHERE lower(email) = lower(trim(p_email))
      AND active = TRUE
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid admin email or password.'
        );
    END IF;


    IF crypt(p_password, v_admin.password_hash)
       <> v_admin.password_hash THEN

        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid admin email or password.'
        );

    END IF;


    v_token := encode(
        gen_random_bytes(32),
        'hex'
    );

    v_expires_at := NOW() + INTERVAL '15 minutes';


    INSERT INTO public.audit_admin_sessions (
        admin_id,
        token_hash,
        expires_at
    )
    VALUES (
        v_admin.admin_id,
        encode(
            digest(v_token, 'sha256'),
            'hex'
        ),
        v_expires_at
    )
    RETURNING session_id
    INTO v_session_id;


    RETURN jsonb_build_object(
        'success', true,
        'admin_id', v_admin.admin_id,
        'email', v_admin.email,
        'session_token', v_token,
        'expires_at', v_expires_at
    );

END;

$$;


ALTER FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_dcc_login"("p_email" "text", "p_password" "text") RETURNS TABLE("id" "text", "name" "text", "email" "text", "role" "text", "hod_name" "text", "hod_email" "text", "active" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
  select u.id, u.name, u.email, u.role, u.hod_name, u.hod_email, u.active
  from dcc_users u
  where u.email = lower(trim(p_email))
    and u.active = true
    and u.password = crypt(p_password, u.password);
$$;


ALTER FUNCTION "public"."verify_dcc_login"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "db_backup"."rls_policies" (
    "schemaname" "name",
    "tablename" "name",
    "policyname" "name",
    "permissive" "text",
    "roles" "name"[],
    "cmd" "text",
    "qual" "text" COLLATE "pg_catalog"."C",
    "with_check" "text" COLLATE "pg_catalog"."C"
);


ALTER TABLE "db_backup"."rls_policies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "db_backup"."rls_status" (
    "schemaname" "name",
    "tablename" "name",
    "rowsecurity" boolean
);


ALTER TABLE "db_backup"."rls_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "db_backup"."table_definitions" (
    "table_schema" "information_schema"."sql_identifier",
    "table_name" "information_schema"."sql_identifier",
    "column_name" "information_schema"."sql_identifier",
    "ordinal_position" "information_schema"."cardinal_number",
    "data_type" "information_schema"."character_data",
    "udt_name" "information_schema"."sql_identifier",
    "is_nullable" "information_schema"."yes_or_no",
    "column_default" "information_schema"."character_data"
);


ALTER TABLE "db_backup"."table_definitions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_profiles" (
    "user_id" "uuid" NOT NULL,
    "full_name" "text",
    "role" "text" DEFAULT 'admin'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "password_hash" "text"
);


ALTER TABLE "public"."admin_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."arr_observation_defects" (
    "observation_defect_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "observation_id" "uuid" NOT NULL,
    "defect_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "trail_no" smallint NOT NULL,
    CONSTRAINT "arr_observation_defects_trail_no_check" CHECK (("trail_no" = ANY (ARRAY[1, 2, 3])))
);


ALTER TABLE "public"."arr_observation_defects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."arr_observations" (
    "observation_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "arr_id" "uuid" NOT NULL,
    "part_id" "uuid",
    "part_number_snap" "text" NOT NULL,
    "master_status_snapshot" smallint NOT NULL,
    "trail1" smallint NOT NULL,
    "trail2" smallint NOT NULL,
    "trail3" smallint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "arr_observations_master_status_snapshot_check" CHECK (("master_status_snapshot" = ANY (ARRAY[0, 1]))),
    CONSTRAINT "arr_observations_trail1_check" CHECK (("trail1" = ANY (ARRAY[0, 1]))),
    CONSTRAINT "arr_observations_trail2_check" CHECK (("trail2" = ANY (ARRAY[0, 1]))),
    CONSTRAINT "arr_observations_trail3_check" CHECK (("trail3" = ANY (ARRAY[0, 1])))
);


ALTER TABLE "public"."arr_observations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."arr_records" (
    "arr_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "certificate_number" "text" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "employee_code_snap" "text" NOT NULL,
    "batch_id" "text",
    "batch_name_snap" "text" NOT NULL,
    "product" "text",
    "attempt_number" integer NOT NULL,
    "assessment_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "false_alert_count" integer DEFAULT 0 NOT NULL,
    "miss_alert_count" integer DEFAULT 0 NOT NULL,
    "false_alert_pct" numeric(6,3) DEFAULT 0 NOT NULL,
    "miss_rate_pct" numeric(6,3) DEFAULT 0 NOT NULL,
    "effectiveness_pct" numeric(6,3) DEFAULT 0 NOT NULL,
    "p1" numeric(6,3) DEFAULT 0 NOT NULL,
    "p0" numeric(6,3) DEFAULT 0 NOT NULL,
    "p_chance" numeric(6,3) DEFAULT 0 NOT NULL,
    "kappa_pct" numeric(6,3) DEFAULT 0 NOT NULL,
    "classification" "text" NOT NULL,
    "is_voided" boolean DEFAULT false NOT NULL,
    "voided_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."arr_records" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_admin_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "admin_id" "uuid" NOT NULL,
    "token_hash" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_admin_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_admins" (
    "admin_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "password_hash" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_category_progress" (
    "progress_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "audit_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "completed_at" timestamp with time zone,
    "time_taken_hours" numeric(10,2) DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_category_progress_time_check" CHECK (("time_taken_hours" >= (0)::numeric))
);


ALTER TABLE "public"."audit_category_progress" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_checklist_answers" (
    "answer_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "audit_id" "uuid" NOT NULL,
    "question_id" "uuid" NOT NULL,
    "answer" "text",
    "description" "text",
    "defect_type" "text",
    "answered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_answers_answer_check" CHECK ((("answer" IS NULL) OR ("answer" = ANY (ARRAY['Yes'::"text", 'No'::"text"])))),
    CONSTRAINT "audit_answers_defect_check" CHECK ((("defect_type" IS NULL) OR ("defect_type" = ANY (ARRAY['Critical'::"text", 'Major'::"text", 'Minor'::"text"])))),
    CONSTRAINT "audit_answers_no_requires_defect" CHECK ((("answer" = 'No'::"text") OR ("defect_type" IS NULL) OR ("defect_type" = ANY (ARRAY['Critical'::"text", 'Major'::"text", 'Minor'::"text"]))))
);


ALTER TABLE "public"."audit_checklist_answers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_mil_items" (
    "mil_item_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "audit_id" "uuid" NOT NULL,
    "answer_id" "uuid" NOT NULL,
    "question_id" "uuid" NOT NULL,
    "question" "text" NOT NULL,
    "description" "text",
    "defect_type" "text" NOT NULL,
    "root_cause" "text",
    "corrective_action" "text",
    "dri_name" "text",
    "dri_mail" "text",
    "deadline" "date",
    "overall_status" "text" DEFAULT 'Open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_mil_defect_check" CHECK (("defect_type" = ANY (ARRAY['Critical'::"text", 'Major'::"text", 'Minor'::"text"]))),
    CONSTRAINT "audit_mil_status_check" CHECK (("overall_status" = ANY (ARRAY['Open'::"text", 'In Progress'::"text", 'Closed'::"text"])))
);


ALTER TABLE "public"."audit_mil_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_schedules" (
    "schedule_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "schedule_number" "text" NOT NULL,
    "audit_date" "date" NOT NULL,
    "type_id" "uuid",
    "master_id" "uuid",
    "master_data_name" "text" NOT NULL,
    "auditor_id" "uuid",
    "auditor_name" "text" NOT NULL,
    "status" "text" DEFAULT 'Planned'::"text" NOT NULL,
    "notes" "text",
    "audit_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "auditor_email" "text",
    CONSTRAINT "audit_schedule_auditor_name_check" CHECK (("length"(TRIM(BOTH FROM "auditor_name")) > 0)),
    CONSTRAINT "audit_schedule_master_name_check" CHECK (("length"(TRIM(BOTH FROM "master_data_name")) > 0)),
    CONSTRAINT "audit_schedule_status_check" CHECK (("status" = ANY (ARRAY['Planned'::"text", 'In Progress'::"text", 'Completed'::"text", 'Cancelled'::"text"])))
);


ALTER TABLE "public"."audit_schedules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audits" (
    "audit_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mil_number" "text",
    "type_id" "uuid" NOT NULL,
    "audit_date" "date" NOT NULL,
    "vendor" "text" NOT NULL,
    "site" "text" NOT NULL,
    "lob" "text" NOT NULL,
    "program" "text",
    "line" "text",
    "apn" "text",
    "auditor_name" "text" NOT NULL,
    "auditor_email" "text",
    "total_audit_hours" numeric(10,2) NOT NULL,
    "started_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "elapsed_seconds" bigint DEFAULT 0 NOT NULL,
    "total_time_taken_hours" numeric(10,2) DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'Draft'::"text" NOT NULL,
    "mil_status" "text" DEFAULT 'Not Generated'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audits_elapsed_seconds_check" CHECK (("elapsed_seconds" >= 0)),
    CONSTRAINT "audits_mil_status_check" CHECK (("mil_status" = ANY (ARRAY['Not Generated'::"text", 'Open'::"text", 'Closed'::"text"]))),
    CONSTRAINT "audits_status_check" CHECK (("status" = ANY (ARRAY['Draft'::"text", 'In Progress'::"text", 'Submitted'::"text", 'Completed'::"text"]))),
    CONSTRAINT "audits_total_hours_positive" CHECK (("total_audit_hours" > (0)::numeric)),
    CONSTRAINT "audits_total_time_check" CHECK (("total_time_taken_hours" >= (0)::numeric))
);


ALTER TABLE "public"."audits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."batch_defect_categories" (
    "batch_id" "text" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."batch_defect_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."batches" (
    "batch_id" "text" DEFAULT "gen_random_uuid"() NOT NULL,
    "batch_code" "text" NOT NULL,
    "batch_name" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."batches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_defect_pairs" (
    "category_defect_pair_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_id" "uuid" NOT NULL,
    "defect_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."category_defect_pairs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_action_evidence" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "corrective_action_id" "uuid" NOT NULL,
    "evidence_type" "text" NOT NULL,
    "title" "text",
    "description" "text",
    "attachment_id" "uuid",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_action_evidence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_action_verifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "corrective_action_id" "uuid" NOT NULL,
    "verification_required" boolean DEFAULT true NOT NULL,
    "verification_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "verified_by" "text",
    "verification_date" "date",
    "verification_method" "text",
    "verification_result" "text",
    "verification_remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_verification_status_check" CHECK (("verification_status" = ANY (ARRAY['pending'::"text", 'in_progress'::"text", 'passed'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."ccr_action_verifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_activity_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "stage" "text",
    "action" "text" NOT NULL,
    "description" "text",
    "performed_by" "uuid",
    "performed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "metadata" "jsonb"
);


ALTER TABLE "public"."ccr_activity_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_assignment_statuses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status_key" "text" NOT NULL,
    "status_name" "text" NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_assignment_statuses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "activity" "text" NOT NULL,
    "dri" "text",
    "due_date" "date",
    "done_date" "date",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_assignments_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'in_progress'::"text", 'completed'::"text", 'overdue'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."ccr_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "attachment_type" "text" NOT NULL,
    "title" "text",
    "description" "text",
    "storage_bucket" "text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "original_file_name" "text",
    "mime_type" "text",
    "file_size" bigint,
    "uploaded_by" "uuid",
    "uploaded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    CONSTRAINT "ccr_attachments_type_check" CHECK (("attachment_type" = ANY (ARRAY['bad_part'::"text", 'good_part'::"text", 'complaint_photo'::"text", 'customer_complaint_document'::"text", 'containment'::"text", 'fishbone_evidence'::"text", 'why_evidence'::"text", 'corrective_action_before'::"text", 'corrective_action_after'::"text", 'corrective_action_document'::"text", 'customer_format'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."ccr_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_case_team_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "member_name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_case_team_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_cases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_number" bigint NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "current_stage" "text" DEFAULT 'registration'::"text" NOT NULL,
    "complaint_date" "date",
    "complaint_source" "text",
    "customer_name" "text",
    "team_leader" "text",
    "group_name" "text",
    "customer_contact_name" "text",
    "customer_contact_position" "text",
    "customer_contact_company" "text",
    "customer_part_number" "text",
    "supplier_part_number" "text",
    "problem_description" "text",
    "customer_location" "text",
    "detected_date" "date",
    "detected_by" "text",
    "created_by" "uuid",
    "updated_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid",
    "part_description" "text",
    "part_no" "text",
    "qty" numeric,
    "complaint_description" "text"
);


ALTER TABLE "public"."ccr_cases" OWNER TO "postgres";


ALTER TABLE "public"."ccr_cases" ALTER COLUMN "ccr_number" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."ccr_cases_ccr_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."ccr_closure" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "closure_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "closure_summary" "text",
    "customer_response" "text",
    "final_remarks" "text",
    "closed_by" "text",
    "closed_at" timestamp with time zone,
    "reopened_reason" "text",
    "reopened_by" "text",
    "reopened_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_closure_status_check" CHECK (("closure_status" = ANY (ARRAY['pending'::"text", 'closed'::"text", 'reopened'::"text"])))
);


ALTER TABLE "public"."ccr_closure" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_containment" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "sorting_activity" "text",
    "sorting_learnings" "text",
    "customer_protection_action" "text",
    "recover_prq_schedule" "text",
    "first_certified_good_shipment" "text",
    "target_eta" "date",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_containment_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'in_progress'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."ccr_containment" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_containment_sorting" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "containment_id" "uuid" NOT NULL,
    "location" "text" NOT NULL,
    "qty_ng" numeric,
    "qty_sorted" numeric,
    "ng_percentage" numeric GENERATED ALWAYS AS (
CASE
    WHEN (("qty_sorted" IS NULL) OR ("qty_sorted" = (0)::numeric)) THEN NULL::numeric
    ELSE (("qty_ng" / "qty_sorted") * (100)::numeric)
END) STORED,
    "sorting_date" "date",
    "dri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_containment_sorting" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_corrective_actions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "problem_statement" "text",
    "occurrence_root_cause" "text",
    "detection_root_cause" "text",
    "corrective_action" "text",
    "dri" "text",
    "result_before" "text",
    "result_after" "text",
    "due_date" "date",
    "completion_date" "date",
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "validation_id" "uuid",
    CONSTRAINT "ccr_corrective_actions_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'in_progress'::"text", 'completed'::"text", 'verified'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."ccr_corrective_actions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_customer_view" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "what_happened" "text",
    "why_is_it_a_problem" "text",
    "when_detected" "date",
    "who_detected" "text",
    "where_detected" "text",
    "how_detected" "text",
    "bad_parts_quantity" numeric,
    "inspected_quantity" numeric,
    "defect_rate" numeric,
    "ppm" numeric,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_customer_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_fishbone_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "display_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_fishbone_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_fishbone_causes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "cause_text" "text" NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_fishbone_causes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_root_cause_validations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fishbone_cause_id" "uuid" NOT NULL,
    "validation_text" "text",
    "relevance" boolean,
    "validated_by" "text",
    "validated_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_root_cause_validations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token_hash" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_activity_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_statuses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status_key" "text" NOT NULL,
    "status_name" "text" NOT NULL,
    "display_order" integer NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_statuses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_supplier_view" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ccr_id" "uuid" NOT NULL,
    "good_vs_bad_difference" "text",
    "defect_process" "text",
    "supplier_manufacture_date" "date",
    "supplier_lot_information" "text",
    "supplier_manufactured_quantity" numeric,
    "supplier_site" "text",
    "supplier_line_number" "text",
    "supplier_shift" "text",
    "defect_should_be_detected_at" "text",
    "covered_by_msop_sip" boolean,
    "similar_problem_previously" boolean,
    "previous_problem_details" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_supplier_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_team_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "member_name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_team_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_teams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_leader_name" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_teams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "password_hash" "text" NOT NULL,
    "role" "text" DEFAULT 'user'::"text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "must_change_password" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_login_at" timestamp with time zone,
    CONSTRAINT "ccr_users_role_check" CHECK (("role" = ANY (ARRAY['admin'::"text", 'user'::"text"])))
);


ALTER TABLE "public"."ccr_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_why_analyses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "validation_id" "uuid" NOT NULL,
    "analysis_type" "text" NOT NULL,
    "potential_root_cause" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_why_analysis_type_check" CHECK (("analysis_type" = ANY (ARRAY['occurrence'::"text", 'non_detection'::"text"])))
);


ALTER TABLE "public"."ccr_why_analyses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_why_steps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "analysis_id" "uuid" NOT NULL,
    "why_number" integer NOT NULL,
    "why_text" "text",
    "verification_text" "text",
    "evidence_available" boolean,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ccr_why_number_check" CHECK ((("why_number" >= 1) AND ("why_number" <= 5)))
);


ALTER TABLE "public"."ccr_why_steps" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ccr_workflow_stages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stage_key" "text" NOT NULL,
    "stage_name" "text" NOT NULL,
    "display_order" integer NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ccr_workflow_stages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cross_tab_analyses" (
    "cross_tab_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "batch_id" "text" NOT NULL,
    "arr_id_a" "uuid" NOT NULL,
    "arr_id_b" "uuid" NOT NULL,
    "arr_id_c" "uuid" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cross_tab_analyses_check" CHECK ((("arr_id_a" <> "arr_id_b") AND ("arr_id_b" <> "arr_id_c") AND ("arr_id_a" <> "arr_id_c")))
);


ALTER TABLE "public"."cross_tab_analyses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_activities" (
    "id" "text" NOT NULL,
    "user_email" "text" NOT NULL,
    "user_name" "text" DEFAULT ''::"text" NOT NULL,
    "action" "text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "document_no" "text" DEFAULT ''::"text" NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."dcc_activities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_dmr_requests" (
    "id" "text" NOT NULL,
    "document_id" "text",
    "document_no" "text",
    "document_name" "text",
    "document_type" "text",
    "department" "text",
    "requested_by_name" "text",
    "requested_by_email" "text",
    "hod_name" "text",
    "hod_email" "text",
    "current_revision" integer DEFAULT 1,
    "request_reason" "text",
    "status" "text" DEFAULT 'PENDING_HOD'::"text",
    "rejection_reason" "text",
    "created_date" "text",
    "hod_action_date" "text",
    "dcc_action_date" "text",
    "source_file_path" "text",
    "source_file_name" "text",
    "revised_file_path" "text",
    "revised_file_name" "text",
    "revised_submitted_date" "text",
    "revised_rejection_reason" "text",
    "modification_access_granted" boolean DEFAULT false,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."dcc_dmr_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_document_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "document_name" "text" NOT NULL,
    "user_name" "text" NOT NULL,
    "user_email" "text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "document_no" "text",
    "document_type" "text",
    "department" "text",
    "candidate_name" "text",
    "candidate_email" "text",
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notified_at" timestamp with time zone,
    CONSTRAINT "dcc_document_requests_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'NOTIFIED'::"text", 'UPLOADED'::"text"])))
);


ALTER TABLE "public"."dcc_document_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_documents" (
    "id" "text" NOT NULL,
    "document_no" "text" NOT NULL,
    "document_name" "text" NOT NULL,
    "department" "text" DEFAULT ''::"text" NOT NULL,
    "document_type" "text" DEFAULT ''::"text" NOT NULL,
    "revision" integer DEFAULT 1 NOT NULL,
    "attachment_name" "text" DEFAULT ''::"text" NOT NULL,
    "attachment_path" "text" DEFAULT ''::"text" NOT NULL,
    "released_pdf_name" "text" DEFAULT ''::"text" NOT NULL,
    "released_pdf_path" "text" DEFAULT ''::"text" NOT NULL,
    "created_by_name" "text" DEFAULT ''::"text" NOT NULL,
    "created_by_email" "text" DEFAULT ''::"text" NOT NULL,
    "hod_name" "text" DEFAULT ''::"text" NOT NULL,
    "hod_email" "text" DEFAULT ''::"text" NOT NULL,
    "dcc_name" "text" DEFAULT ''::"text" NOT NULL,
    "dcc_email" "text" DEFAULT ''::"text" NOT NULL,
    "status" "text" DEFAULT 'PENDING_HOD'::"text" NOT NULL,
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "hod_action_at" timestamp with time zone,
    "dcc_action_at" timestamp with time zone,
    "rejection_reason" "text" DEFAULT ''::"text" NOT NULL,
    "remarks" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "candidate_name" "text" DEFAULT ''::"text" NOT NULL,
    "employee_id" "text" DEFAULT ''::"text" NOT NULL,
    "released_by_name" "text" DEFAULT ''::"text" NOT NULL,
    "released_by_email" "text" DEFAULT ''::"text" NOT NULL,
    "revision_date" "text" DEFAULT ''::"text" NOT NULL,
    "folder_name" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."dcc_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_folders" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "created_by_name" "text" DEFAULT ''::"text" NOT NULL,
    "created_by_email" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."dcc_folders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_master_data" (
    "document_no" "text" NOT NULL,
    "document_name" "text",
    "document_type" "text",
    "department" "text",
    "candidate_name" "text",
    "candidate_email" "text",
    "created_by_name" "text",
    "created_by_email" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "revision" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."dcc_master_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_notifications" (
    "id" "text" NOT NULL,
    "recipient_email" "text" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" DEFAULT ''::"text" NOT NULL,
    "type" "text" DEFAULT 'GENERAL'::"text" NOT NULL,
    "document_no" "text" DEFAULT ''::"text" NOT NULL,
    "document_request_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_read" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."dcc_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_sessions" (
    "token_hash" "text" NOT NULL,
    "user_id" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone
);

ALTER TABLE ONLY "public"."dcc_sessions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dcc_users" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "role" "text" NOT NULL,
    "hod_name" "text" DEFAULT ''::"text" NOT NULL,
    "hod_email" "text" DEFAULT ''::"text" NOT NULL,
    "password" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."dcc_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."defect_categories" (
    "category_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_name" "text" NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."defect_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."defect_types" (
    "defect_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "defect_name" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."defect_types" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employees" (
    "employee_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_code" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "department" "text",
    "product" "text",
    "photo_path" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."employees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ncr_approval_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ncr_id" "uuid" NOT NULL,
    "action_by" "uuid" NOT NULL,
    "action_role_id" "uuid" NOT NULL,
    "previous_status_id" "uuid",
    "new_status_id" "uuid" NOT NULL,
    "action" character varying(100) NOT NULL,
    "comments" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ncr_approval_history" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."ncr_number_sequence"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."ncr_number_sequence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ncr_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_key" character varying(50) NOT NULL,
    "role_name" character varying(100) NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ncr_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ncr_statuses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status_key" character varying(50) NOT NULL,
    "status_name" character varying(100) NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ncr_statuses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ncr_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" character varying(200) NOT NULL,
    "email" character varying(320) NOT NULL,
    "password_hash" "text" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ncr_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ncrs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ncr_number" character varying(50) NOT NULL,
    "process_function" "text",
    "clause_section" "text",
    "auditee_id" "uuid",
    "standard" "text",
    "report_no" "text",
    "ia_no" "text",
    "auditor_id" "uuid",
    "audit_date" "date",
    "finding_statement" "text",
    "requirement_clause_reference" "text",
    "root_causes" "text",
    "correction" "text",
    "correction_effective_date" "date",
    "corrective_action" "text",
    "corrective_action_effective_date" "date",
    "follow_up_audit_details" "text",
    "follow_up_audit_date" "date",
    "effectiveness_of_corrective_action" "text",
    "effectiveness_date" "date",
    "status_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "hod_action" character varying(50),
    "hod_comments" "text",
    "hod_action_by" "uuid",
    "hod_action_at" timestamp with time zone,
    "dcc_action" character varying(50),
    "dcc_comments" "text",
    "dcc_action_by" "uuid",
    "dcc_action_at" timestamp with time zone,
    "closed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ncrs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."part_defects" (
    "part_defect_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "part_id" "uuid" NOT NULL,
    "defect_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."part_defects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."parts" (
    "part_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "batch_id" "text" NOT NULL,
    "part_number" "text" NOT NULL,
    "master_status" smallint NOT NULL,
    "sequence_order" integer NOT NULL,
    "barcode_value" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "parts_master_status_check" CHECK (("master_status" = ANY (ARRAY[0, 1])))
);


ALTER TABLE "public"."parts" OWNER TO "postgres";


ALTER TABLE ONLY "public"."admin_profiles"
    ADD CONSTRAINT "admin_profiles_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."arr_observation_defects"
    ADD CONSTRAINT "arr_observation_defects_pkey" PRIMARY KEY ("observation_defect_id");



ALTER TABLE ONLY "public"."arr_observations"
    ADD CONSTRAINT "arr_observations_arr_id_part_id_key" UNIQUE ("arr_id", "part_id");



ALTER TABLE ONLY "public"."arr_observations"
    ADD CONSTRAINT "arr_observations_pkey" PRIMARY KEY ("observation_id");



ALTER TABLE ONLY "public"."arr_records"
    ADD CONSTRAINT "arr_records_certificate_number_key" UNIQUE ("certificate_number");



ALTER TABLE ONLY "public"."arr_records"
    ADD CONSTRAINT "arr_records_employee_id_attempt_number_key" UNIQUE ("employee_id", "attempt_number");



ALTER TABLE ONLY "public"."arr_records"
    ADD CONSTRAINT "arr_records_pkey" PRIMARY KEY ("arr_id");



ALTER TABLE ONLY "public"."audit_admin_sessions"
    ADD CONSTRAINT "audit_admin_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "public"."audit_admin_sessions"
    ADD CONSTRAINT "audit_admin_sessions_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."audit_admins"
    ADD CONSTRAINT "audit_admins_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."audit_admins"
    ADD CONSTRAINT "audit_admins_pkey" PRIMARY KEY ("admin_id");



ALTER TABLE ONLY "public"."audit_checklist_answers"
    ADD CONSTRAINT "audit_answers_unique" UNIQUE ("audit_id", "question_id");



ALTER TABLE ONLY "public"."audit_auditors"
    ADD CONSTRAINT "audit_auditors_pkey" PRIMARY KEY ("auditor_id");



ALTER TABLE ONLY "public"."audit_categories"
    ADD CONSTRAINT "audit_categories_pkey" PRIMARY KEY ("category_id");



ALTER TABLE ONLY "public"."audit_categories"
    ADD CONSTRAINT "audit_categories_unique_name_per_type" UNIQUE ("type_id", "category_name");



ALTER TABLE ONLY "public"."audit_category_progress"
    ADD CONSTRAINT "audit_category_progress_pkey" PRIMARY KEY ("progress_id");



ALTER TABLE ONLY "public"."audit_category_progress"
    ADD CONSTRAINT "audit_category_progress_unique" UNIQUE ("audit_id", "category_id");



ALTER TABLE ONLY "public"."audit_checklist_answers"
    ADD CONSTRAINT "audit_checklist_answers_pkey" PRIMARY KEY ("answer_id");



ALTER TABLE ONLY "public"."audit_master_data"
    ADD CONSTRAINT "audit_master_data_pkey" PRIMARY KEY ("master_id");



ALTER TABLE ONLY "public"."audit_mil_items"
    ADD CONSTRAINT "audit_mil_items_pkey" PRIMARY KEY ("mil_item_id");



ALTER TABLE ONLY "public"."audit_mil_items"
    ADD CONSTRAINT "audit_mil_unique_answer" UNIQUE ("answer_id");



ALTER TABLE ONLY "public"."audit_questions"
    ADD CONSTRAINT "audit_questions_pkey" PRIMARY KEY ("question_id");



ALTER TABLE ONLY "public"."audit_questions"
    ADD CONSTRAINT "audit_questions_unique_number_per_category" UNIQUE ("category_id", "question_number");



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_pkey" PRIMARY KEY ("schedule_id");



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_schedule_number_key" UNIQUE ("schedule_number");



ALTER TABLE ONLY "public"."audit_types"
    ADD CONSTRAINT "audit_types_name_unique" UNIQUE ("audit_type");



ALTER TABLE ONLY "public"."audit_types"
    ADD CONSTRAINT "audit_types_pkey" PRIMARY KEY ("type_id");



ALTER TABLE ONLY "public"."audits"
    ADD CONSTRAINT "audits_pkey" PRIMARY KEY ("audit_id");



ALTER TABLE ONLY "public"."batch_defect_categories"
    ADD CONSTRAINT "batch_defect_categories_pkey" PRIMARY KEY ("batch_id", "category_id");



ALTER TABLE ONLY "public"."batches"
    ADD CONSTRAINT "batches_batch_code_key" UNIQUE ("batch_code");



ALTER TABLE ONLY "public"."batches"
    ADD CONSTRAINT "batches_pkey" PRIMARY KEY ("batch_id");



ALTER TABLE ONLY "public"."category_defect_pairs"
    ADD CONSTRAINT "category_defect_pairs_pkey" PRIMARY KEY ("category_defect_pair_id");



ALTER TABLE ONLY "public"."ccr_action_evidence"
    ADD CONSTRAINT "ccr_action_evidence_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_action_verifications"
    ADD CONSTRAINT "ccr_action_verifications_corrective_action_id_key" UNIQUE ("corrective_action_id");



ALTER TABLE ONLY "public"."ccr_action_verifications"
    ADD CONSTRAINT "ccr_action_verifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_activity_log"
    ADD CONSTRAINT "ccr_activity_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_assignment_statuses"
    ADD CONSTRAINT "ccr_assignment_statuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_assignment_statuses"
    ADD CONSTRAINT "ccr_assignment_statuses_status_key_key" UNIQUE ("status_key");



ALTER TABLE ONLY "public"."ccr_assignment_statuses"
    ADD CONSTRAINT "ccr_assignment_statuses_status_name_key" UNIQUE ("status_name");



ALTER TABLE ONLY "public"."ccr_assignments"
    ADD CONSTRAINT "ccr_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_attachments"
    ADD CONSTRAINT "ccr_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_case_team_members"
    ADD CONSTRAINT "ccr_case_team_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_cases"
    ADD CONSTRAINT "ccr_cases_ccr_number_key" UNIQUE ("ccr_number");



ALTER TABLE ONLY "public"."ccr_cases"
    ADD CONSTRAINT "ccr_cases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_closure"
    ADD CONSTRAINT "ccr_closure_ccr_id_key" UNIQUE ("ccr_id");



ALTER TABLE ONLY "public"."ccr_closure"
    ADD CONSTRAINT "ccr_closure_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_containment"
    ADD CONSTRAINT "ccr_containment_ccr_id_key" UNIQUE ("ccr_id");



ALTER TABLE ONLY "public"."ccr_containment"
    ADD CONSTRAINT "ccr_containment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_containment_sorting"
    ADD CONSTRAINT "ccr_containment_sorting_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_corrective_actions"
    ADD CONSTRAINT "ccr_corrective_actions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_customer_view"
    ADD CONSTRAINT "ccr_customer_view_ccr_id_key" UNIQUE ("ccr_id");



ALTER TABLE ONLY "public"."ccr_customer_view"
    ADD CONSTRAINT "ccr_customer_view_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_fishbone_categories"
    ADD CONSTRAINT "ccr_fishbone_categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."ccr_fishbone_categories"
    ADD CONSTRAINT "ccr_fishbone_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_fishbone_causes"
    ADD CONSTRAINT "ccr_fishbone_causes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_root_cause_validations"
    ADD CONSTRAINT "ccr_root_cause_validations_fishbone_cause_id_key" UNIQUE ("fishbone_cause_id");



ALTER TABLE ONLY "public"."ccr_root_cause_validations"
    ADD CONSTRAINT "ccr_root_cause_validations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_sessions"
    ADD CONSTRAINT "ccr_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_sessions"
    ADD CONSTRAINT "ccr_sessions_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."ccr_statuses"
    ADD CONSTRAINT "ccr_statuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_statuses"
    ADD CONSTRAINT "ccr_statuses_status_key_key" UNIQUE ("status_key");



ALTER TABLE ONLY "public"."ccr_statuses"
    ADD CONSTRAINT "ccr_statuses_status_name_key" UNIQUE ("status_name");



ALTER TABLE ONLY "public"."ccr_supplier_view"
    ADD CONSTRAINT "ccr_supplier_view_ccr_id_key" UNIQUE ("ccr_id");



ALTER TABLE ONLY "public"."ccr_supplier_view"
    ADD CONSTRAINT "ccr_supplier_view_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_team_members"
    ADD CONSTRAINT "ccr_team_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_teams"
    ADD CONSTRAINT "ccr_teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_users"
    ADD CONSTRAINT "ccr_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_why_analyses"
    ADD CONSTRAINT "ccr_why_analyses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_why_analyses"
    ADD CONSTRAINT "ccr_why_analyses_validation_id_analysis_type_key" UNIQUE ("validation_id", "analysis_type");



ALTER TABLE ONLY "public"."ccr_why_steps"
    ADD CONSTRAINT "ccr_why_steps_analysis_id_why_number_key" UNIQUE ("analysis_id", "why_number");



ALTER TABLE ONLY "public"."ccr_why_steps"
    ADD CONSTRAINT "ccr_why_steps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_workflow_stages"
    ADD CONSTRAINT "ccr_workflow_stages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ccr_workflow_stages"
    ADD CONSTRAINT "ccr_workflow_stages_stage_key_key" UNIQUE ("stage_key");



ALTER TABLE ONLY "public"."ccr_workflow_stages"
    ADD CONSTRAINT "ccr_workflow_stages_stage_name_key" UNIQUE ("stage_name");



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_pkey" PRIMARY KEY ("cross_tab_id");



ALTER TABLE ONLY "public"."dcc_activities"
    ADD CONSTRAINT "dcc_activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_dmr_requests"
    ADD CONSTRAINT "dcc_dmr_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_document_requests"
    ADD CONSTRAINT "dcc_document_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_documents"
    ADD CONSTRAINT "dcc_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_folders"
    ADD CONSTRAINT "dcc_folders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_master_data"
    ADD CONSTRAINT "dcc_master_data_pkey" PRIMARY KEY ("document_no");



ALTER TABLE ONLY "public"."dcc_notifications"
    ADD CONSTRAINT "dcc_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dcc_sessions"
    ADD CONSTRAINT "dcc_sessions_pkey" PRIMARY KEY ("token_hash");



ALTER TABLE ONLY "public"."dcc_users"
    ADD CONSTRAINT "dcc_users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."dcc_users"
    ADD CONSTRAINT "dcc_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."defect_categories"
    ADD CONSTRAINT "defect_categories_pkey" PRIMARY KEY ("category_id");



ALTER TABLE ONLY "public"."defect_types"
    ADD CONSTRAINT "defect_types_pkey" PRIMARY KEY ("defect_id");



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_employee_code_key" UNIQUE ("employee_code");



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_pkey" PRIMARY KEY ("employee_id");



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ncr_roles"
    ADD CONSTRAINT "ncr_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ncr_roles"
    ADD CONSTRAINT "ncr_roles_role_key_key" UNIQUE ("role_key");



ALTER TABLE ONLY "public"."ncr_roles"
    ADD CONSTRAINT "ncr_roles_role_name_key" UNIQUE ("role_name");



ALTER TABLE ONLY "public"."ncr_statuses"
    ADD CONSTRAINT "ncr_statuses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ncr_statuses"
    ADD CONSTRAINT "ncr_statuses_status_key_key" UNIQUE ("status_key");



ALTER TABLE ONLY "public"."ncr_statuses"
    ADD CONSTRAINT "ncr_statuses_status_name_key" UNIQUE ("status_name");



ALTER TABLE ONLY "public"."ncr_users"
    ADD CONSTRAINT "ncr_users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."ncr_users"
    ADD CONSTRAINT "ncr_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_ncr_number_key" UNIQUE ("ncr_number");



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."part_defects"
    ADD CONSTRAINT "part_defects_pkey" PRIMARY KEY ("part_defect_id");



ALTER TABLE ONLY "public"."parts"
    ADD CONSTRAINT "parts_barcode_value_key" UNIQUE ("barcode_value");



ALTER TABLE ONLY "public"."parts"
    ADD CONSTRAINT "parts_batch_id_part_number_key" UNIQUE ("batch_id", "part_number");



ALTER TABLE ONLY "public"."parts"
    ADD CONSTRAINT "parts_pkey" PRIMARY KEY ("part_id");



CREATE INDEX "audit_auditors_active_idx" ON "public"."audit_auditors" USING "btree" ("active");



CREATE UNIQUE INDEX "audit_auditors_email_unique" ON "public"."audit_auditors" USING "btree" ("lower"(TRIM(BOTH FROM "email")));



CREATE UNIQUE INDEX "audit_auditors_employee_id_unique" ON "public"."audit_auditors" USING "btree" ("lower"(TRIM(BOTH FROM "employee_id")));



CREATE INDEX "audit_auditors_name_idx" ON "public"."audit_auditors" USING "btree" ("auditor_name");



CREATE INDEX "ccr_sessions_last_activity_idx" ON "public"."ccr_sessions" USING "btree" ("last_activity_at");



CREATE INDEX "ccr_sessions_user_id_idx" ON "public"."ccr_sessions" USING "btree" ("user_id");



CREATE UNIQUE INDEX "ccr_users_email_unique_idx" ON "public"."ccr_users" USING "btree" ("lower"("email"));



CREATE INDEX "dcc_activities_timestamp_idx" ON "public"."dcc_activities" USING "btree" ("timestamp" DESC);



CREATE INDEX "dcc_activities_user_email_idx" ON "public"."dcc_activities" USING "btree" ("user_email");



CREATE INDEX "dcc_documents_folder_name_idx" ON "public"."dcc_documents" USING "btree" ("folder_name");



CREATE UNIQUE INDEX "dcc_folders_name_lower_uidx" ON "public"."dcc_folders" USING "btree" ("lower"("name"));



CREATE UNIQUE INDEX "dcc_master_data_document_no_uidx" ON "public"."dcc_master_data" USING "btree" ("document_no");



CREATE INDEX "dcc_notifications_created_at_idx" ON "public"."dcc_notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "dcc_notifications_recipient_email_idx" ON "public"."dcc_notifications" USING "btree" ("recipient_email");



CREATE INDEX "dcc_notifications_unread_idx" ON "public"."dcc_notifications" USING "btree" ("recipient_email", "is_read");



CREATE UNIQUE INDEX "defect_categories_name_unique" ON "public"."defect_categories" USING "btree" ("lower"(TRIM(BOTH FROM "category_name")));



CREATE UNIQUE INDEX "defect_types_name_unique" ON "public"."defect_types" USING "btree" ("lower"(TRIM(BOTH FROM "defect_name")));



CREATE INDEX "idx_arr_batch" ON "public"."arr_records" USING "btree" ("batch_id");



CREATE INDEX "idx_arr_certificate" ON "public"."arr_records" USING "btree" ("certificate_number");



CREATE INDEX "idx_arr_date" ON "public"."arr_records" USING "btree" ("assessment_date");



CREATE INDEX "idx_arr_employee" ON "public"."arr_records" USING "btree" ("employee_id");



CREATE INDEX "idx_arr_observation_defects_observation_trail" ON "public"."arr_observation_defects" USING "btree" ("observation_id", "trail_no");



CREATE INDEX "idx_audit_admin_sessions_admin_id" ON "public"."audit_admin_sessions" USING "btree" ("admin_id");



CREATE INDEX "idx_audit_admin_sessions_expires_at" ON "public"."audit_admin_sessions" USING "btree" ("expires_at");



CREATE INDEX "idx_audit_admin_sessions_token_hash" ON "public"."audit_admin_sessions" USING "btree" ("token_hash");



CREATE INDEX "idx_audit_answers_answer" ON "public"."audit_checklist_answers" USING "btree" ("answer");



CREATE INDEX "idx_audit_answers_audit" ON "public"."audit_checklist_answers" USING "btree" ("audit_id");



CREATE INDEX "idx_audit_answers_question" ON "public"."audit_checklist_answers" USING "btree" ("question_id");



CREATE INDEX "idx_audit_categories_active" ON "public"."audit_categories" USING "btree" ("active");



CREATE INDEX "idx_audit_categories_type_id" ON "public"."audit_categories" USING "btree" ("type_id");



CREATE INDEX "idx_audit_category_progress_audit" ON "public"."audit_category_progress" USING "btree" ("audit_id");



CREATE INDEX "idx_audit_category_progress_category" ON "public"."audit_category_progress" USING "btree" ("category_id");



CREATE INDEX "idx_audit_master_data_active" ON "public"."audit_master_data" USING "btree" ("active");



CREATE INDEX "idx_audit_master_data_audit_type" ON "public"."audit_master_data" USING "btree" ("audit_type_id");



CREATE INDEX "idx_audit_mil_audit" ON "public"."audit_mil_items" USING "btree" ("audit_id");



CREATE INDEX "idx_audit_mil_deadline" ON "public"."audit_mil_items" USING "btree" ("deadline");



CREATE INDEX "idx_audit_mil_status" ON "public"."audit_mil_items" USING "btree" ("overall_status");



CREATE INDEX "idx_audit_questions_active" ON "public"."audit_questions" USING "btree" ("active");



CREATE INDEX "idx_audit_questions_category_id" ON "public"."audit_questions" USING "btree" ("category_id");



CREATE INDEX "idx_audit_schedules_auditor" ON "public"."audit_schedules" USING "btree" ("auditor_id");



CREATE INDEX "idx_audit_schedules_date" ON "public"."audit_schedules" USING "btree" ("audit_date");



CREATE INDEX "idx_audit_schedules_master" ON "public"."audit_schedules" USING "btree" ("master_id");



CREATE INDEX "idx_audit_schedules_status" ON "public"."audit_schedules" USING "btree" ("status");



CREATE INDEX "idx_audit_schedules_type" ON "public"."audit_schedules" USING "btree" ("type_id");



CREATE INDEX "idx_audits_date" ON "public"."audits" USING "btree" ("audit_date");



CREATE INDEX "idx_audits_mil_status" ON "public"."audits" USING "btree" ("mil_status");



CREATE INDEX "idx_audits_status" ON "public"."audits" USING "btree" ("status");



CREATE INDEX "idx_audits_type_id" ON "public"."audits" USING "btree" ("type_id");



CREATE INDEX "idx_batch_defect_categories_batch" ON "public"."batch_defect_categories" USING "btree" ("batch_id");



CREATE INDEX "idx_batch_defect_categories_category" ON "public"."batch_defect_categories" USING "btree" ("category_id");



CREATE INDEX "idx_category_defect_pairs_category" ON "public"."category_defect_pairs" USING "btree" ("category_id");



CREATE INDEX "idx_category_defect_pairs_defect" ON "public"."category_defect_pairs" USING "btree" ("defect_id");



CREATE INDEX "idx_ccr_actions_ccr" ON "public"."ccr_corrective_actions" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_activity_ccr" ON "public"."ccr_activity_log" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_assignments_ccr" ON "public"."ccr_assignments" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_attachments_ccr" ON "public"."ccr_attachments" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_case_team_members_ccr" ON "public"."ccr_case_team_members" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_cases_created_at" ON "public"."ccr_cases" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_ccr_cases_customer" ON "public"."ccr_cases" USING "btree" ("customer_name");



CREATE INDEX "idx_ccr_cases_customer_pn" ON "public"."ccr_cases" USING "btree" ("customer_part_number");



CREATE INDEX "idx_ccr_cases_stage" ON "public"."ccr_cases" USING "btree" ("current_stage");



CREATE INDEX "idx_ccr_cases_status" ON "public"."ccr_cases" USING "btree" ("status");



CREATE INDEX "idx_ccr_cases_supplier_pn" ON "public"."ccr_cases" USING "btree" ("supplier_part_number");



CREATE INDEX "idx_ccr_cases_team" ON "public"."ccr_cases" USING "btree" ("team_id");



CREATE INDEX "idx_ccr_fishbone_causes_ccr" ON "public"."ccr_fishbone_causes" USING "btree" ("ccr_id");



CREATE INDEX "idx_ccr_root_cause_validations_cause" ON "public"."ccr_root_cause_validations" USING "btree" ("fishbone_cause_id");



CREATE INDEX "idx_ccr_team_members_team" ON "public"."ccr_team_members" USING "btree" ("team_id");



CREATE INDEX "idx_ccr_teams_active" ON "public"."ccr_teams" USING "btree" ("is_active");



CREATE INDEX "idx_crosstab_batch" ON "public"."cross_tab_analyses" USING "btree" ("batch_id");



CREATE INDEX "idx_dcc_dmr_requests_hod_email" ON "public"."dcc_dmr_requests" USING "btree" ("hod_email");



CREATE INDEX "idx_dcc_dmr_requests_requested_by_email" ON "public"."dcc_dmr_requests" USING "btree" ("requested_by_email");



CREATE INDEX "idx_dcc_dmr_requests_status" ON "public"."dcc_dmr_requests" USING "btree" ("status");



CREATE INDEX "idx_dcc_documents_created_by_email" ON "public"."dcc_documents" USING "btree" ("created_by_email");



CREATE INDEX "idx_dcc_documents_dcc" ON "public"."dcc_documents" USING "btree" ("dcc_email");



CREATE INDEX "idx_dcc_documents_document_no" ON "public"."dcc_documents" USING "btree" ("document_no");



CREATE INDEX "idx_dcc_documents_hod" ON "public"."dcc_documents" USING "btree" ("hod_email");



CREATE INDEX "idx_dcc_documents_hod_email" ON "public"."dcc_documents" USING "btree" ("hod_email");



CREATE INDEX "idx_dcc_documents_status" ON "public"."dcc_documents" USING "btree" ("status");



CREATE INDEX "idx_dcc_documents_user" ON "public"."dcc_documents" USING "btree" ("created_by_email");



CREATE INDEX "idx_dcc_master_data_document_name" ON "public"."dcc_master_data" USING "btree" ("document_name");



CREATE INDEX "idx_dcc_sessions_expiry" ON "public"."dcc_sessions" USING "btree" ("expires_at");



CREATE INDEX "idx_dcc_sessions_user_id" ON "public"."dcc_sessions" USING "btree" ("user_id");



CREATE INDEX "idx_dcc_users_email" ON "public"."dcc_users" USING "btree" ("email");



CREATE INDEX "idx_dcc_users_role" ON "public"."dcc_users" USING "btree" ("role");



CREATE INDEX "idx_employees_code" ON "public"."employees" USING "btree" ("employee_code");



CREATE INDEX "idx_ncr_history_action_by" ON "public"."ncr_approval_history" USING "btree" ("action_by");



CREATE INDEX "idx_ncr_history_ncr_id" ON "public"."ncr_approval_history" USING "btree" ("ncr_id");



CREATE INDEX "idx_ncr_users_email" ON "public"."ncr_users" USING "btree" ("email");



CREATE INDEX "idx_ncr_users_is_active" ON "public"."ncr_users" USING "btree" ("is_active");



CREATE INDEX "idx_ncr_users_role_id" ON "public"."ncr_users" USING "btree" ("role_id");



CREATE INDEX "idx_ncrs_auditee_id" ON "public"."ncrs" USING "btree" ("auditee_id");



CREATE INDEX "idx_ncrs_auditor_id" ON "public"."ncrs" USING "btree" ("auditor_id");



CREATE INDEX "idx_ncrs_created_at" ON "public"."ncrs" USING "btree" ("created_at");



CREATE INDEX "idx_ncrs_created_by" ON "public"."ncrs" USING "btree" ("created_by");



CREATE INDEX "idx_ncrs_status_id" ON "public"."ncrs" USING "btree" ("status_id");



CREATE INDEX "idx_obs_arr" ON "public"."arr_observations" USING "btree" ("arr_id");



CREATE INDEX "idx_obs_part" ON "public"."arr_observations" USING "btree" ("part_id");



CREATE INDEX "idx_parts_barcode" ON "public"."parts" USING "btree" ("barcode_value");



CREATE INDEX "idx_parts_batch" ON "public"."parts" USING "btree" ("batch_id");



CREATE UNIQUE INDEX "ux_audit_master_data_master_name" ON "public"."audit_master_data" USING "btree" ("lower"(TRIM(BOTH FROM "master_name")));



CREATE UNIQUE INDEX "ux_ccr_corrective_actions_validation_id" ON "public"."ccr_corrective_actions" USING "btree" ("validation_id");



CREATE OR REPLACE TRIGGER "trg_audit_auditors_updated_at" BEFORE UPDATE ON "public"."audit_auditors" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_categories_updated_at" BEFORE UPDATE ON "public"."audit_categories" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_category_progress_updated_at" BEFORE UPDATE ON "public"."audit_category_progress" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_checklist_answers_updated_at" BEFORE UPDATE ON "public"."audit_checklist_answers" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_master_data_updated_at" BEFORE UPDATE ON "public"."audit_master_data" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_master_data_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_mil_items_updated_at" BEFORE UPDATE ON "public"."audit_mil_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_questions_updated_at" BEFORE UPDATE ON "public"."audit_questions" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_schedule_updated_at" BEFORE UPDATE ON "public"."audit_schedules" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_schedule_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_schedules_updated_at" BEFORE UPDATE ON "public"."audit_schedules" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_types_updated_at" BEFORE UPDATE ON "public"."audit_types" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audits_updated_at" BEFORE UPDATE ON "public"."audits" FOR EACH ROW EXECUTE FUNCTION "public"."set_audit_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_action_verifications_updated_at" BEFORE UPDATE ON "public"."ccr_action_verifications" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_assignments_updated_at" BEFORE UPDATE ON "public"."ccr_assignments" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_auth_users_updated_at" BEFORE UPDATE ON "public"."ccr_users" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_auth_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_cases_updated_at" BEFORE UPDATE ON "public"."ccr_cases" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_closure_updated_at" BEFORE UPDATE ON "public"."ccr_closure" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_containment_updated_at" BEFORE UPDATE ON "public"."ccr_containment" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_corrective_actions_updated_at" BEFORE UPDATE ON "public"."ccr_corrective_actions" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_customer_view_updated_at" BEFORE UPDATE ON "public"."ccr_customer_view" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_fishbone_causes_updated_at" BEFORE UPDATE ON "public"."ccr_fishbone_causes" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_root_cause_validations_updated_at" BEFORE UPDATE ON "public"."ccr_root_cause_validations" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_supplier_view_updated_at" BEFORE UPDATE ON "public"."ccr_supplier_view" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_teams_updated_at" BEFORE UPDATE ON "public"."ccr_teams" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_why_analyses_updated_at" BEFORE UPDATE ON "public"."ccr_why_analyses" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ccr_why_steps_updated_at" BEFORE UPDATE ON "public"."ccr_why_steps" FOR EACH ROW EXECUTE FUNCTION "public"."ccr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_generate_audit_schedule_number" BEFORE INSERT ON "public"."audit_schedules" FOR EACH ROW EXECUTE FUNCTION "public"."generate_audit_schedule_number"();



CREATE OR REPLACE TRIGGER "trg_ncr_roles_updated_at" BEFORE UPDATE ON "public"."ncr_roles" FOR EACH ROW EXECUTE FUNCTION "public"."ncr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ncr_statuses_updated_at" BEFORE UPDATE ON "public"."ncr_statuses" FOR EACH ROW EXECUTE FUNCTION "public"."ncr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ncr_updated_at" BEFORE UPDATE ON "public"."ncrs" FOR EACH ROW EXECUTE FUNCTION "public"."ncr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_ncr_users_updated_at" BEFORE UPDATE ON "public"."ncr_users" FOR EACH ROW EXECUTE FUNCTION "public"."ncr_set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_set_ncr_number" BEFORE INSERT ON "public"."ncrs" FOR EACH ROW EXECUTE FUNCTION "public"."set_ncr_number"();



CREATE OR REPLACE TRIGGER "trg_validate_audit_category_completion" BEFORE INSERT OR UPDATE ON "public"."audit_category_progress" FOR EACH ROW EXECUTE FUNCTION "public"."validate_audit_category_completion"();



CREATE OR REPLACE TRIGGER "trg_validate_audit_checklist_answer" BEFORE INSERT OR UPDATE ON "public"."audit_checklist_answers" FOR EACH ROW EXECUTE FUNCTION "public"."validate_audit_checklist_answer"();



CREATE OR REPLACE TRIGGER "trg_validate_audit_mil_item" BEFORE INSERT OR UPDATE ON "public"."audit_mil_items" FOR EACH ROW EXECUTE FUNCTION "public"."validate_audit_mil_item"();



CREATE OR REPLACE TRIGGER "trg_validate_audit_times" BEFORE INSERT OR UPDATE ON "public"."audits" FOR EACH ROW EXECUTE FUNCTION "public"."validate_audit_times"();



ALTER TABLE ONLY "public"."arr_observation_defects"
    ADD CONSTRAINT "arr_observation_defects_defect_id_fkey" FOREIGN KEY ("defect_id") REFERENCES "public"."defect_types"("defect_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."arr_observation_defects"
    ADD CONSTRAINT "arr_observation_defects_observation_id_fkey" FOREIGN KEY ("observation_id") REFERENCES "public"."arr_observations"("observation_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."arr_observations"
    ADD CONSTRAINT "arr_observations_arr_id_fkey" FOREIGN KEY ("arr_id") REFERENCES "public"."arr_records"("arr_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."arr_observations"
    ADD CONSTRAINT "arr_observations_part_id_fkey" FOREIGN KEY ("part_id") REFERENCES "public"."parts"("part_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."arr_records"
    ADD CONSTRAINT "arr_records_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("batch_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."arr_records"
    ADD CONSTRAINT "arr_records_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("employee_id");



ALTER TABLE ONLY "public"."audit_admin_sessions"
    ADD CONSTRAINT "audit_admin_sessions_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "public"."audit_admins"("admin_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_checklist_answers"
    ADD CONSTRAINT "audit_answers_audit_fk" FOREIGN KEY ("audit_id") REFERENCES "public"."audits"("audit_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_checklist_answers"
    ADD CONSTRAINT "audit_answers_question_fk" FOREIGN KEY ("question_id") REFERENCES "public"."audit_questions"("question_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audit_categories"
    ADD CONSTRAINT "audit_categories_type_fk" FOREIGN KEY ("type_id") REFERENCES "public"."audit_types"("type_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_category_progress"
    ADD CONSTRAINT "audit_category_progress_audit_fk" FOREIGN KEY ("audit_id") REFERENCES "public"."audits"("audit_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_category_progress"
    ADD CONSTRAINT "audit_category_progress_category_fk" FOREIGN KEY ("category_id") REFERENCES "public"."audit_categories"("category_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audit_master_data"
    ADD CONSTRAINT "audit_master_data_audit_type_id_fkey" FOREIGN KEY ("audit_type_id") REFERENCES "public"."audit_types"("type_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."audit_mil_items"
    ADD CONSTRAINT "audit_mil_answer_fk" FOREIGN KEY ("answer_id") REFERENCES "public"."audit_checklist_answers"("answer_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_mil_items"
    ADD CONSTRAINT "audit_mil_audit_fk" FOREIGN KEY ("audit_id") REFERENCES "public"."audits"("audit_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_mil_items"
    ADD CONSTRAINT "audit_mil_question_fk" FOREIGN KEY ("question_id") REFERENCES "public"."audit_questions"("question_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audit_questions"
    ADD CONSTRAINT "audit_questions_category_fk" FOREIGN KEY ("category_id") REFERENCES "public"."audit_categories"("category_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_audit_id_fkey" FOREIGN KEY ("audit_id") REFERENCES "public"."audits"("audit_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_auditor_id_fkey" FOREIGN KEY ("auditor_id") REFERENCES "public"."audit_auditors"("auditor_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_master_id_fkey" FOREIGN KEY ("master_id") REFERENCES "public"."audit_master_data"("master_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audit_schedules"
    ADD CONSTRAINT "audit_schedules_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "public"."audit_types"("type_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audits"
    ADD CONSTRAINT "audits_type_fk" FOREIGN KEY ("type_id") REFERENCES "public"."audit_types"("type_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."batch_defect_categories"
    ADD CONSTRAINT "batch_defect_categories_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("batch_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."batch_defect_categories"
    ADD CONSTRAINT "batch_defect_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."defect_categories"("category_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."category_defect_pairs"
    ADD CONSTRAINT "category_defect_pairs_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."defect_categories"("category_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_defect_pairs"
    ADD CONSTRAINT "category_defect_pairs_defect_id_fkey" FOREIGN KEY ("defect_id") REFERENCES "public"."defect_types"("defect_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ccr_action_evidence"
    ADD CONSTRAINT "ccr_action_evidence_attachment_id_fkey" FOREIGN KEY ("attachment_id") REFERENCES "public"."ccr_attachments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."ccr_action_evidence"
    ADD CONSTRAINT "ccr_action_evidence_corrective_action_id_fkey" FOREIGN KEY ("corrective_action_id") REFERENCES "public"."ccr_corrective_actions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_action_verifications"
    ADD CONSTRAINT "ccr_action_verifications_corrective_action_id_fkey" FOREIGN KEY ("corrective_action_id") REFERENCES "public"."ccr_corrective_actions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_activity_log"
    ADD CONSTRAINT "ccr_activity_log_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_assignments"
    ADD CONSTRAINT "ccr_assignments_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_attachments"
    ADD CONSTRAINT "ccr_attachments_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_case_team_members"
    ADD CONSTRAINT "ccr_case_team_members_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_closure"
    ADD CONSTRAINT "ccr_closure_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_containment"
    ADD CONSTRAINT "ccr_containment_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_containment_sorting"
    ADD CONSTRAINT "ccr_containment_sorting_containment_id_fkey" FOREIGN KEY ("containment_id") REFERENCES "public"."ccr_containment"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_corrective_actions"
    ADD CONSTRAINT "ccr_corrective_actions_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_corrective_actions"
    ADD CONSTRAINT "ccr_corrective_actions_validation_id_fkey" FOREIGN KEY ("validation_id") REFERENCES "public"."ccr_root_cause_validations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_customer_view"
    ADD CONSTRAINT "ccr_customer_view_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_fishbone_causes"
    ADD CONSTRAINT "ccr_fishbone_causes_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."ccr_fishbone_categories"("id");



ALTER TABLE ONLY "public"."ccr_fishbone_causes"
    ADD CONSTRAINT "ccr_fishbone_causes_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_root_cause_validations"
    ADD CONSTRAINT "ccr_root_cause_validations_fishbone_cause_id_fkey" FOREIGN KEY ("fishbone_cause_id") REFERENCES "public"."ccr_fishbone_causes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_sessions"
    ADD CONSTRAINT "ccr_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."ccr_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_supplier_view"
    ADD CONSTRAINT "ccr_supplier_view_ccr_id_fkey" FOREIGN KEY ("ccr_id") REFERENCES "public"."ccr_cases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_team_members"
    ADD CONSTRAINT "ccr_team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."ccr_teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_why_analyses"
    ADD CONSTRAINT "ccr_why_analyses_validation_id_fkey" FOREIGN KEY ("validation_id") REFERENCES "public"."ccr_root_cause_validations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_why_steps"
    ADD CONSTRAINT "ccr_why_steps_analysis_id_fkey" FOREIGN KEY ("analysis_id") REFERENCES "public"."ccr_why_analyses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_arr_id_a_fkey" FOREIGN KEY ("arr_id_a") REFERENCES "public"."arr_records"("arr_id");



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_arr_id_b_fkey" FOREIGN KEY ("arr_id_b") REFERENCES "public"."arr_records"("arr_id");



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_arr_id_c_fkey" FOREIGN KEY ("arr_id_c") REFERENCES "public"."arr_records"("arr_id");



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("batch_id");



ALTER TABLE ONLY "public"."cross_tab_analyses"
    ADD CONSTRAINT "cross_tab_analyses_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."dcc_sessions"
    ADD CONSTRAINT "dcc_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."dcc_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ccr_assignments"
    ADD CONSTRAINT "fk_ccr_assignments_status" FOREIGN KEY ("status") REFERENCES "public"."ccr_assignment_statuses"("status_key");



ALTER TABLE ONLY "public"."ccr_cases"
    ADD CONSTRAINT "fk_ccr_cases_stage" FOREIGN KEY ("current_stage") REFERENCES "public"."ccr_workflow_stages"("stage_key");



ALTER TABLE ONLY "public"."ccr_cases"
    ADD CONSTRAINT "fk_ccr_cases_status" FOREIGN KEY ("status") REFERENCES "public"."ccr_statuses"("status_key");



ALTER TABLE ONLY "public"."ccr_cases"
    ADD CONSTRAINT "fk_ccr_cases_team" FOREIGN KEY ("team_id") REFERENCES "public"."ccr_teams"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_action_by_fkey" FOREIGN KEY ("action_by") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_action_role_id_fkey" FOREIGN KEY ("action_role_id") REFERENCES "public"."ncr_roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_ncr_id_fkey" FOREIGN KEY ("ncr_id") REFERENCES "public"."ncrs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_new_status_id_fkey" FOREIGN KEY ("new_status_id") REFERENCES "public"."ncr_statuses"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncr_approval_history"
    ADD CONSTRAINT "ncr_approval_history_previous_status_id_fkey" FOREIGN KEY ("previous_status_id") REFERENCES "public"."ncr_statuses"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncr_users"
    ADD CONSTRAINT "ncr_users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."ncr_roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_auditee_id_fkey" FOREIGN KEY ("auditee_id") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_auditor_id_fkey" FOREIGN KEY ("auditor_id") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_dcc_action_by_fkey" FOREIGN KEY ("dcc_action_by") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_hod_action_by_fkey" FOREIGN KEY ("hod_action_by") REFERENCES "public"."ncr_users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."ncrs"
    ADD CONSTRAINT "ncrs_status_id_fkey" FOREIGN KEY ("status_id") REFERENCES "public"."ncr_statuses"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."part_defects"
    ADD CONSTRAINT "part_defects_defect_id_fkey" FOREIGN KEY ("defect_id") REFERENCES "public"."defect_types"("defect_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."part_defects"
    ADD CONSTRAINT "part_defects_part_id_fkey" FOREIGN KEY ("part_id") REFERENCES "public"."parts"("part_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."parts"
    ADD CONSTRAINT "parts_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "public"."batches"("batch_id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE "db_backup"."rls_policies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "db_backup"."rls_status" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "db_backup"."table_definitions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Allow all access to dcc_activities" ON "public"."dcc_activities" USING (true) WITH CHECK (true);



CREATE POLICY "Allow all access to dcc_notifications" ON "public"."dcc_notifications" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon delete batches" ON "public"."batches" FOR DELETE TO "anon" USING (true);



CREATE POLICY "Allow anon delete ccr action evidence" ON "public"."ccr_action_evidence" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr action verifications" ON "public"."ccr_action_verifications" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr activity log" ON "public"."ccr_activity_log" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr assignments" ON "public"."ccr_assignments" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr attachments" ON "public"."ccr_attachments" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr closure" ON "public"."ccr_closure" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr containment" ON "public"."ccr_containment" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr containment sorting" ON "public"."ccr_containment_sorting" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr corrective actions" ON "public"."ccr_corrective_actions" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr customer view" ON "public"."ccr_customer_view" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr fishbone categories" ON "public"."ccr_fishbone_categories" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr fishbone causes" ON "public"."ccr_fishbone_causes" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr root validations" ON "public"."ccr_root_cause_validations" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr statuses" ON "public"."ccr_statuses" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr supplier view" ON "public"."ccr_supplier_view" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr why analyses" ON "public"."ccr_why_analyses" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr why steps" ON "public"."ccr_why_steps" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon delete ccr workflow stages" ON "public"."ccr_workflow_stages" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon insert batches" ON "public"."batches" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr action evidence" ON "public"."ccr_action_evidence" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr action verifications" ON "public"."ccr_action_verifications" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr activity log" ON "public"."ccr_activity_log" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr assignments" ON "public"."ccr_assignments" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr attachments" ON "public"."ccr_attachments" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr cases" ON "public"."ccr_cases" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr closure" ON "public"."ccr_closure" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr containment" ON "public"."ccr_containment" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr containment sorting" ON "public"."ccr_containment_sorting" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr corrective actions" ON "public"."ccr_corrective_actions" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr customer view" ON "public"."ccr_customer_view" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr fishbone categories" ON "public"."ccr_fishbone_categories" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr fishbone causes" ON "public"."ccr_fishbone_causes" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr root validations" ON "public"."ccr_root_cause_validations" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr statuses" ON "public"."ccr_statuses" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr supplier view" ON "public"."ccr_supplier_view" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr why analyses" ON "public"."ccr_why_analyses" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr why steps" ON "public"."ccr_why_steps" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon insert ccr workflow stages" ON "public"."ccr_workflow_stages" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow anon read batches" ON "public"."batches" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow anon read ccr action evidence" ON "public"."ccr_action_evidence" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr action verifications" ON "public"."ccr_action_verifications" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr activity log" ON "public"."ccr_activity_log" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr assignments" ON "public"."ccr_assignments" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr attachments" ON "public"."ccr_attachments" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr cases" ON "public"."ccr_cases" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr closure" ON "public"."ccr_closure" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr containment" ON "public"."ccr_containment" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr containment sorting" ON "public"."ccr_containment_sorting" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr corrective actions" ON "public"."ccr_corrective_actions" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr customer view" ON "public"."ccr_customer_view" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr fishbone categories" ON "public"."ccr_fishbone_categories" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr fishbone causes" ON "public"."ccr_fishbone_causes" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr root validations" ON "public"."ccr_root_cause_validations" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr statuses" ON "public"."ccr_statuses" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr supplier view" ON "public"."ccr_supplier_view" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr why analyses" ON "public"."ccr_why_analyses" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr why steps" ON "public"."ccr_why_steps" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon read ccr workflow stages" ON "public"."ccr_workflow_stages" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow anon update batches" ON "public"."batches" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr action evidence" ON "public"."ccr_action_evidence" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr action verifications" ON "public"."ccr_action_verifications" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr activity log" ON "public"."ccr_activity_log" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr assignments" ON "public"."ccr_assignments" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr attachments" ON "public"."ccr_attachments" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr cases" ON "public"."ccr_cases" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr closure" ON "public"."ccr_closure" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr containment" ON "public"."ccr_containment" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr containment sorting" ON "public"."ccr_containment_sorting" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr corrective actions" ON "public"."ccr_corrective_actions" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr customer view" ON "public"."ccr_customer_view" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr fishbone categories" ON "public"."ccr_fishbone_categories" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr fishbone causes" ON "public"."ccr_fishbone_causes" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr root validations" ON "public"."ccr_root_cause_validations" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr statuses" ON "public"."ccr_statuses" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr supplier view" ON "public"."ccr_supplier_view" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr why analyses" ON "public"."ccr_why_analyses" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr why steps" ON "public"."ccr_why_steps" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow anon update ccr workflow stages" ON "public"."ccr_workflow_stages" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Anonymous users can read active assignment statuses" ON "public"."ccr_assignment_statuses" FOR SELECT TO "anon" USING (("is_active" = true));



CREATE POLICY "Authenticated users can read assignment statuses" ON "public"."ccr_assignment_statuses" FOR SELECT TO "authenticated" USING (("is_active" = true));



ALTER TABLE "public"."admin_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."arr_observation_defects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."arr_observations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."arr_records" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_admin_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_auditors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_auditors_public_select" ON "public"."audit_auditors" FOR SELECT TO "authenticated", "anon" USING (("active" = true));



ALTER TABLE "public"."audit_categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_categories_admin_delete" ON "public"."audit_categories" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_categories_admin_insert" ON "public"."audit_categories" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_categories_admin_update" ON "public"."audit_categories" FOR UPDATE TO "authenticated" USING ("public"."is_audit_admin"()) WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_categories_public_select" ON "public"."audit_categories" FOR SELECT TO "authenticated", "anon" USING ((("active" = true) OR "public"."is_audit_admin"()));



ALTER TABLE "public"."audit_category_progress" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_category_progress_admin_delete" ON "public"."audit_category_progress" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_category_progress_public_insert" ON "public"."audit_category_progress" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "audit_category_progress_public_select" ON "public"."audit_category_progress" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "audit_category_progress_public_update" ON "public"."audit_category_progress" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."audit_checklist_answers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_checklist_answers_admin_delete" ON "public"."audit_checklist_answers" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_checklist_answers_public_insert" ON "public"."audit_checklist_answers" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "audit_checklist_answers_public_select" ON "public"."audit_checklist_answers" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "audit_checklist_answers_public_update" ON "public"."audit_checklist_answers" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."audit_master_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_master_data_select" ON "public"."audit_master_data" FOR SELECT TO "authenticated", "anon" USING ((("active" = true) OR "public"."is_audit_admin"()));



ALTER TABLE "public"."audit_mil_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_mil_items_admin_delete" ON "public"."audit_mil_items" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_mil_items_insert_open" ON "public"."audit_mil_items" FOR INSERT TO "authenticated", "anon" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."audits" "a"
  WHERE (("a"."audit_id" = "audit_mil_items"."audit_id") AND (COALESCE("a"."mil_status", ''::"text") <> 'Closed'::"text")))));



CREATE POLICY "audit_mil_items_public_select" ON "public"."audit_mil_items" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "audit_mil_items_update_open" ON "public"."audit_mil_items" FOR UPDATE TO "authenticated", "anon" USING ((EXISTS ( SELECT 1
   FROM "public"."audits" "a"
  WHERE (("a"."audit_id" = "audit_mil_items"."audit_id") AND (COALESCE("a"."mil_status", ''::"text") <> 'Closed'::"text"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."audits" "a"
  WHERE (("a"."audit_id" = "audit_mil_items"."audit_id") AND (COALESCE("a"."mil_status", ''::"text") <> 'Closed'::"text")))));



ALTER TABLE "public"."audit_questions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_questions_admin_delete" ON "public"."audit_questions" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_questions_admin_insert" ON "public"."audit_questions" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_questions_admin_update" ON "public"."audit_questions" FOR UPDATE TO "authenticated" USING ("public"."is_audit_admin"()) WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_questions_public_select" ON "public"."audit_questions" FOR SELECT TO "authenticated", "anon" USING ((("active" = true) OR "public"."is_audit_admin"()));



ALTER TABLE "public"."audit_schedules" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_schedules_delete" ON "public"."audit_schedules" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "audit_schedules_insert" ON "public"."audit_schedules" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "audit_schedules_select" ON "public"."audit_schedules" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "audit_schedules_update" ON "public"."audit_schedules" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."audit_types" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_types_admin_delete" ON "public"."audit_types" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audit_types_admin_insert" ON "public"."audit_types" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_types_admin_update" ON "public"."audit_types" FOR UPDATE TO "authenticated" USING ("public"."is_audit_admin"()) WITH CHECK ("public"."is_audit_admin"());



CREATE POLICY "audit_types_public_select" ON "public"."audit_types" FOR SELECT TO "authenticated", "anon" USING ((("active" = true) OR "public"."is_audit_admin"()));



ALTER TABLE "public"."audits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audits_admin_delete" ON "public"."audits" FOR DELETE TO "authenticated" USING ("public"."is_audit_admin"());



CREATE POLICY "audits_public_insert" ON "public"."audits" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "audits_public_select" ON "public"."audits" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "audits_public_update" ON "public"."audits" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."batch_defect_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."category_defect_pairs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_action_evidence" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_action_verifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_activity_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_assignment_statuses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_case_team_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ccr_case_team_members_delete" ON "public"."ccr_case_team_members" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_case_team_members_insert" ON "public"."ccr_case_team_members" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "ccr_case_team_members_select" ON "public"."ccr_case_team_members" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_case_team_members_update" ON "public"."ccr_case_team_members" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."ccr_cases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_closure" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_containment" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_containment_sorting" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_corrective_actions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_customer_view" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_fishbone_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_fishbone_causes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_root_cause_validations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_statuses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_supplier_view" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_team_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ccr_team_members_delete" ON "public"."ccr_team_members" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_team_members_insert" ON "public"."ccr_team_members" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "ccr_team_members_select" ON "public"."ccr_team_members" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_team_members_update" ON "public"."ccr_team_members" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."ccr_teams" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ccr_teams_delete" ON "public"."ccr_teams" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_teams_insert" ON "public"."ccr_teams" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "ccr_teams_select" ON "public"."ccr_teams" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "ccr_teams_update" ON "public"."ccr_teams" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."ccr_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_why_analyses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_why_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ccr_workflow_stages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cross_tab_analyses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_activities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dcc_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."defect_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."defect_types" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "demo delete dcc documents" ON "public"."dcc_documents" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "demo delete dcc users" ON "public"."dcc_users" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "demo insert dcc documents" ON "public"."dcc_documents" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "demo insert dcc users" ON "public"."dcc_users" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "demo read dcc documents" ON "public"."dcc_documents" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "demo read dcc users" ON "public"."dcc_users" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "demo update dcc documents" ON "public"."dcc_documents" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "demo update dcc users" ON "public"."dcc_users" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_arr_observation_defects_delete" ON "public"."arr_observation_defects" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_arr_observation_defects_insert" ON "public"."arr_observation_defects" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_arr_observation_defects_select" ON "public"."arr_observation_defects" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_arr_observation_defects_update" ON "public"."arr_observation_defects" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_arr_observations_delete" ON "public"."arr_observations" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_arr_observations_insert" ON "public"."arr_observations" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_arr_observations_select" ON "public"."arr_observations" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_arr_observations_update" ON "public"."arr_observations" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_arr_records_delete" ON "public"."arr_records" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_arr_records_insert" ON "public"."arr_records" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_arr_records_select" ON "public"."arr_records" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_arr_records_update" ON "public"."arr_records" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_batch_defect_categories_delete" ON "public"."batch_defect_categories" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_batch_defect_categories_insert" ON "public"."batch_defect_categories" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_batch_defect_categories_select" ON "public"."batch_defect_categories" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_batch_defect_categories_update" ON "public"."batch_defect_categories" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_batches_delete" ON "public"."batches" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_batches_insert" ON "public"."batches" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_batches_select" ON "public"."batches" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_batches_update" ON "public"."batches" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_category_defect_pairs_delete" ON "public"."category_defect_pairs" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_category_defect_pairs_insert" ON "public"."category_defect_pairs" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_category_defect_pairs_select" ON "public"."category_defect_pairs" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_category_defect_pairs_update" ON "public"."category_defect_pairs" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_cross_tab_delete" ON "public"."cross_tab_analyses" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_cross_tab_insert" ON "public"."cross_tab_analyses" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_cross_tab_select" ON "public"."cross_tab_analyses" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_cross_tab_update" ON "public"."cross_tab_analyses" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_defect_categories_delete" ON "public"."defect_categories" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_defect_categories_insert" ON "public"."defect_categories" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_defect_categories_select" ON "public"."defect_categories" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_defect_categories_update" ON "public"."defect_categories" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_defect_types_delete" ON "public"."defect_types" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_defect_types_insert" ON "public"."defect_types" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_defect_types_select" ON "public"."defect_types" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_defect_types_update" ON "public"."defect_types" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_employees_delete" ON "public"."employees" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_employees_insert" ON "public"."employees" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_employees_select" ON "public"."employees" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_employees_update" ON "public"."employees" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_part_defects_delete" ON "public"."part_defects" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_part_defects_insert" ON "public"."part_defects" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_part_defects_select" ON "public"."part_defects" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_part_defects_update" ON "public"."part_defects" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "dev_parts_delete" ON "public"."parts" FOR DELETE TO "anon" USING (true);



CREATE POLICY "dev_parts_insert" ON "public"."parts" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "dev_parts_select" ON "public"."parts" FOR SELECT TO "anon" USING (true);



CREATE POLICY "dev_parts_update" ON "public"."parts" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



ALTER TABLE "public"."employees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ncr_approval_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ncr_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ncr_statuses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ncr_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ncrs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."part_defects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."parts" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."arr_records";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dcc_activities";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dcc_dmr_requests";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dcc_documents";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dcc_master_data";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."dcc_notifications";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON TABLE "public"."audit_categories" TO "anon";
GRANT ALL ON TABLE "public"."audit_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_categories" TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_create_audit_category"("p_session_token" "text", "p_type_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_create_audit_category"("p_session_token" "text", "p_type_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_create_audit_category"("p_session_token" "text", "p_type_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "service_role";



GRANT ALL ON TABLE "public"."audit_master_data" TO "anon";
GRANT ALL ON TABLE "public"."audit_master_data" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_master_data" TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_create_audit_master_data"("p_session_token" "text", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_create_audit_master_data"("p_session_token" "text", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_create_audit_master_data"("p_session_token" "text", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "service_role";



GRANT ALL ON TABLE "public"."audit_questions" TO "anon";
GRANT ALL ON TABLE "public"."audit_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_questions" TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_create_audit_question"("p_session_token" "text", "p_category_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "service_role";



GRANT ALL ON TABLE "public"."audit_types" TO "anon";
GRANT ALL ON TABLE "public"."audit_types" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_types" TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_create_audit_type"("p_session_token" "text", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "service_role";



GRANT ALL ON TABLE "public"."audit_auditors" TO "anon";
GRANT ALL ON TABLE "public"."audit_auditors" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_auditors" TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_create_auditor"("p_session_token" "text", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_create_auditor"("p_session_token" "text", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_create_auditor"("p_session_token" "text", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_arr_record"("p_arr_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_audit"("p_session_token" "text", "p_audit_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_audit"("p_session_token" "text", "p_audit_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_audit"("p_session_token" "text", "p_audit_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_audit_category"("p_session_token" "text", "p_category_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_category"("p_session_token" "text", "p_category_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_category"("p_session_token" "text", "p_category_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_audit_master_data"("p_session_token" "text", "p_master_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_master_data"("p_session_token" "text", "p_master_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_master_data"("p_session_token" "text", "p_master_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_question"("p_session_token" "text", "p_question_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_audit_type"("p_session_token" "text", "p_type_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_auditor"("p_session_token" "text", "p_auditor_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_auditor"("p_session_token" "text", "p_auditor_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_auditor"("p_session_token" "text", "p_auditor_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_audit_categories"("p_session_token" "text", "p_type_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_audit_categories"("p_session_token" "text", "p_type_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_audit_categories"("p_session_token" "text", "p_type_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_audit_master_data"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_audit_master_data"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_audit_master_data"("p_session_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_audit_questions"("p_session_token" "text", "p_category_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_audit_types"("p_session_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_auditors"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_auditors"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_auditors"("p_session_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_reset_password_after_otp"("p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_reset_password_after_otp"("p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_reset_password_after_otp"("p_new_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_update_audit_category"("p_session_token" "text", "p_category_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_audit_category"("p_session_token" "text", "p_category_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_audit_category"("p_session_token" "text", "p_category_id" "uuid", "p_category_name" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_update_audit_master_data"("p_session_token" "text", "p_master_id" "uuid", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_audit_master_data"("p_session_token" "text", "p_master_id" "uuid", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_audit_master_data"("p_session_token" "text", "p_master_id" "uuid", "p_master_name" "text", "p_audit_type_id" "uuid", "p_audit_type_name" "text", "p_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_audit_question"("p_session_token" "text", "p_question_id" "uuid", "p_question_number" integer, "p_question" "text", "p_description" "text", "p_sort_order" integer, "p_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_audit_type"("p_session_token" "text", "p_type_id" "uuid", "p_audit_type" "text", "p_description" "text", "p_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_update_auditor"("p_session_token" "text", "p_auditor_id" "uuid", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_auditor"("p_session_token" "text", "p_auditor_id" "uuid", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_auditor"("p_session_token" "text", "p_auditor_id" "uuid", "p_auditor_name" "text", "p_employee_id" "text", "p_email" "text", "p_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."arr_reset_password_after_otp"("p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."arr_reset_password_after_otp"("p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."arr_reset_password_after_otp"("p_new_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_create_team"("p_session_token" "text", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_admin_create_user"("p_session_token" "text", "p_full_name" "text", "p_email" "text", "p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_create_user"("p_session_token" "text", "p_full_name" "text", "p_email" "text", "p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_create_user"("p_session_token" "text", "p_full_name" "text", "p_email" "text", "p_role" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_case"("p_session_token" "text", "p_ccr_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_team"("p_session_token" "text", "p_team_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_delete_user"("p_session_token" "text", "p_user_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_get_users"("p_session_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_set_team_active"("p_session_token" "text", "p_team_id" "uuid", "p_is_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_set_user_active"("p_session_token" "text", "p_user_id" "uuid", "p_is_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_admin_update_team"("p_session_token" "text", "p_team_id" "uuid", "p_team_leader_name" "text", "p_member_names" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_auth_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_auth_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_auth_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_change_password"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_change_password"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_change_password"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_change_password_from_login"("p_email" "text", "p_current_password" "text", "p_new_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_cleanup_expired_sessions"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_cleanup_expired_sessions"() TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_cleanup_expired_sessions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_cleanup_expired_sessions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_login"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_login"("p_email" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_login"("p_email" "text", "p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_logout"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_logout"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_logout"("p_session_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ccr_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_set_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."ccr_validate_session"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ccr_validate_session"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ccr_validate_session"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ccr_validate_session"("p_session_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."close_audit_mil"("p_audit_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."close_audit_mil"("p_audit_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_audit_mil"("p_audit_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_arr"("p_employee_id" "text", "p_batch_id" "text", "p_product" "text", "p_assessment_date" "date", "p_false_alert_count" integer, "p_miss_alert_count" integer, "p_false_alert_pct" numeric, "p_miss_rate_pct" numeric, "p_effectiveness_pct" numeric, "p_p1" numeric, "p_p0" numeric, "p_p_chance" numeric, "p_kappa_pct" numeric, "p_classification" "text", "p_observations" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_arr"("p_employee_id" "text", "p_batch_id" "text", "p_product" "text", "p_assessment_date" "date", "p_false_alert_count" integer, "p_miss_alert_count" integer, "p_false_alert_pct" numeric, "p_miss_rate_pct" numeric, "p_effectiveness_pct" numeric, "p_p1" numeric, "p_p0" numeric, "p_p_chance" numeric, "p_kappa_pct" numeric, "p_classification" "text", "p_observations" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_arr"("p_employee_id" "text", "p_batch_id" "text", "p_product" "text", "p_assessment_date" "date", "p_false_alert_count" integer, "p_miss_alert_count" integer, "p_false_alert_pct" numeric, "p_miss_rate_pct" numeric, "p_effectiveness_pct" numeric, "p_p1" numeric, "p_p0" numeric, "p_p_chance" numeric, "p_kappa_pct" numeric, "p_classification" "text", "p_observations" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_change_password"("p_email" "text", "p_current_password" "text", "p_new_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_change_password"("p_email" "text", "p_current_password" "text", "p_new_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."dcc_change_password_v2"("p_session_token" "text", "p_current_password" "text", "p_new_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_create_user"("p_session_token" "text", "p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) TO "authenticated";



REVOKE ALL ON FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."dcc_delete_user"("p_session_token" "text", "p_user_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_get_users"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_get_users"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_get_users"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."dcc_get_users"("p_session_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_login_with_session"("p_email" "text", "p_password" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_login_with_session_v2"("p_email" "text", "p_password" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."dcc_logout"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_logout"("p_session_token" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_logout"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_logout"("p_session_token" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."dcc_restore_user"("p_session_token" "text", "p_user_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_set_user_active"("p_session_token" "text", "p_user_id" "text", "p_active" boolean) TO "authenticated";



REVOKE ALL ON FUNCTION "public"."dcc_upsert_user"("p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_upsert_user"("p_id" "text", "p_name" "text", "p_email" "text", "p_role" "text", "p_hod_name" "text", "p_hod_email" "text", "p_password" "text", "p_active" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."dcc_validate_session"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."dcc_validate_session"("p_session_token" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."dcc_validate_session"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."dcc_validate_session"("p_session_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."generate_audit_mil_items"("p_audit_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_audit_mil_items"("p_audit_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_audit_mil_items"("p_audit_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_audit_schedule_number"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_audit_schedule_number"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_audit_schedule_number"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_ncr_number"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_ncr_number"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_ncr_number"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_audit_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_audit_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_audit_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_all_ncrs"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_all_ncrs"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_all_ncrs"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_create_ncr"("p_process_function" "text", "p_clause_section" "text", "p_auditee_id" "uuid", "p_standard" "text", "p_ia_no" "text", "p_auditor_id" "uuid", "p_audit_date" "date", "p_finding_statement" "text", "p_requirement_clause_reference" "text", "p_created_by" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_create_ncr"("p_process_function" "text", "p_clause_section" "text", "p_auditee_id" "uuid", "p_standard" "text", "p_ia_no" "text", "p_auditor_id" "uuid", "p_audit_date" "date", "p_finding_statement" "text", "p_requirement_clause_reference" "text", "p_created_by" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_create_ncr"("p_process_function" "text", "p_clause_section" "text", "p_auditee_id" "uuid", "p_standard" "text", "p_ia_no" "text", "p_auditor_id" "uuid", "p_audit_date" "date", "p_finding_statement" "text", "p_requirement_clause_reference" "text", "p_created_by" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_create_user"("p_admin_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid", "p_password_hash" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_create_user"("p_admin_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid", "p_password_hash" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_create_user"("p_admin_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid", "p_password_hash" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_dashboard_data"() TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_dashboard_data"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_dashboard_data"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_delete_ncr"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_delete_user"("p_admin_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_delete_user"("p_admin_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_delete_user"("p_admin_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_ncr_details"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_ncr_details"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_ncr_details"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_set_user_active"("p_admin_id" "uuid", "p_user_id" "uuid", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_set_user_active"("p_admin_id" "uuid", "p_user_id" "uuid", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_set_user_active"("p_admin_id" "uuid", "p_user_id" "uuid", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_statuses"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_statuses"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_statuses"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_admin_update_user"("p_admin_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_update_user"("p_admin_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_update_user"("p_admin_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_role_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_admin_users"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_dcc_all_ncrs"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_dcc_all_ncrs"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_dcc_all_ncrs"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_dcc_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_dcc_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_dcc_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_dcc_dashboard_data"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_dcc_dashboard_data"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_dcc_dashboard_data"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_dcc_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_dcc_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_dcc_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_hod_all_ncrs"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_hod_all_ncrs"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_hod_all_ncrs"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_hod_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_hod_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_hod_approve"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_hod_dashboard_data"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_hod_dashboard_data"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_hod_dashboard_data"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_hod_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_hod_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_hod_reject"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_comments" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_login"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_login"("p_email" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_login"("p_email" "text", "p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_public_dashboard_data"() TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_public_dashboard_data"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_public_dashboard_data"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_roles_list"() TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_roles_list"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_roles_list"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_user_assigned_ncrs"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_user_assigned_ncrs"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_user_assigned_ncrs"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_user_submit_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_user_submit_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_user_submit_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ncr_user_update_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_root_causes" "text", "p_correction" "text", "p_correction_effective_date" "date", "p_corrective_action" "text", "p_corrective_action_effective_date" "date", "p_follow_up_audit_details" "text", "p_follow_up_audit_date" "date", "p_effectiveness_of_corrective_action" "text", "p_effectiveness_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."ncr_user_update_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_root_causes" "text", "p_correction" "text", "p_correction_effective_date" "date", "p_corrective_action" "text", "p_corrective_action_effective_date" "date", "p_follow_up_audit_details" "text", "p_follow_up_audit_date" "date", "p_effectiveness_of_corrective_action" "text", "p_effectiveness_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ncr_user_update_action_plan"("p_user_id" "uuid", "p_ncr_id" "uuid", "p_root_causes" "text", "p_correction" "text", "p_correction_effective_date" "date", "p_corrective_action" "text", "p_corrective_action_effective_date" "date", "p_follow_up_audit_details" "text", "p_follow_up_audit_date" "date", "p_effectiveness_of_corrective_action" "text", "p_effectiveness_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."rename_batch"("p_old_batch_id" "text", "p_new_batch_id" "text", "p_batch_name" "text", "p_description" "text", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."rename_batch"("p_old_batch_id" "text", "p_new_batch_id" "text", "p_batch_name" "text", "p_description" "text", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."rename_batch"("p_old_batch_id" "text", "p_new_batch_id" "text", "p_batch_name" "text", "p_description" "text", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_admin_password"("p_current_password" "text", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_admin_password"("p_current_password" "text", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_admin_password"("p_current_password" "text", "p_new_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_arr_password"("p_current_password" "text", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_arr_password"("p_current_password" "text", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_arr_password"("p_current_password" "text", "p_new_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_audit_master_data_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_audit_master_data_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_audit_master_data_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_audit_schedule_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_audit_schedule_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_audit_schedule_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_audit_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_audit_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_audit_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_ncr_number"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_ncr_number"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_ncr_number"() TO "service_role";



GRANT ALL ON FUNCTION "public"."submit_audit"("p_audit_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."submit_audit"("p_audit_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_audit"("p_audit_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_audit_admin_session"("p_session_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_audit_category_completion"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_audit_category_completion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_audit_category_completion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_audit_checklist_answer"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_audit_checklist_answer"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_audit_checklist_answer"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_audit_mil_item"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_audit_mil_item"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_audit_mil_item"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_audit_times"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_audit_times"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_audit_times"() TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_admin_password"("p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_admin_password"("p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_admin_password"("p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_arr_password"("p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_arr_password"("p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_arr_password"("p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_audit_admin"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_audit_admin"("p_email" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_audit_admin"("p_email" "text", "p_password" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_audit_admin_login"("p_email" "text", "p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_dcc_login"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_dcc_login"("p_email" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_dcc_login"("p_email" "text", "p_password" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."admin_profiles" TO "anon";
GRANT ALL ON TABLE "public"."admin_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."arr_observation_defects" TO "anon";
GRANT ALL ON TABLE "public"."arr_observation_defects" TO "authenticated";
GRANT ALL ON TABLE "public"."arr_observation_defects" TO "service_role";



GRANT ALL ON TABLE "public"."arr_observations" TO "anon";
GRANT ALL ON TABLE "public"."arr_observations" TO "authenticated";
GRANT ALL ON TABLE "public"."arr_observations" TO "service_role";



GRANT ALL ON TABLE "public"."arr_records" TO "anon";
GRANT ALL ON TABLE "public"."arr_records" TO "authenticated";
GRANT ALL ON TABLE "public"."arr_records" TO "service_role";



GRANT ALL ON TABLE "public"."audit_admin_sessions" TO "anon";
GRANT ALL ON TABLE "public"."audit_admin_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_admin_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."audit_admins" TO "anon";
GRANT ALL ON TABLE "public"."audit_admins" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_admins" TO "service_role";



GRANT ALL ON TABLE "public"."audit_category_progress" TO "anon";
GRANT ALL ON TABLE "public"."audit_category_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_category_progress" TO "service_role";



GRANT ALL ON TABLE "public"."audit_checklist_answers" TO "anon";
GRANT ALL ON TABLE "public"."audit_checklist_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_checklist_answers" TO "service_role";



GRANT ALL ON TABLE "public"."audit_mil_items" TO "anon";
GRANT ALL ON TABLE "public"."audit_mil_items" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_mil_items" TO "service_role";



GRANT ALL ON TABLE "public"."audit_schedules" TO "anon";
GRANT ALL ON TABLE "public"."audit_schedules" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_schedules" TO "service_role";



GRANT ALL ON TABLE "public"."audits" TO "anon";
GRANT ALL ON TABLE "public"."audits" TO "authenticated";
GRANT ALL ON TABLE "public"."audits" TO "service_role";



GRANT ALL ON TABLE "public"."batch_defect_categories" TO "anon";
GRANT ALL ON TABLE "public"."batch_defect_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."batch_defect_categories" TO "service_role";



GRANT ALL ON TABLE "public"."batches" TO "anon";
GRANT ALL ON TABLE "public"."batches" TO "authenticated";
GRANT ALL ON TABLE "public"."batches" TO "service_role";



GRANT ALL ON TABLE "public"."category_defect_pairs" TO "anon";
GRANT ALL ON TABLE "public"."category_defect_pairs" TO "authenticated";
GRANT ALL ON TABLE "public"."category_defect_pairs" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_action_evidence" TO "anon";
GRANT ALL ON TABLE "public"."ccr_action_evidence" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_action_evidence" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_action_verifications" TO "anon";
GRANT ALL ON TABLE "public"."ccr_action_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_action_verifications" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_activity_log" TO "anon";
GRANT ALL ON TABLE "public"."ccr_activity_log" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_activity_log" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_assignment_statuses" TO "anon";
GRANT ALL ON TABLE "public"."ccr_assignment_statuses" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_assignment_statuses" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_assignments" TO "anon";
GRANT ALL ON TABLE "public"."ccr_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_attachments" TO "anon";
GRANT ALL ON TABLE "public"."ccr_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_attachments" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_case_team_members" TO "anon";
GRANT ALL ON TABLE "public"."ccr_case_team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_case_team_members" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_cases" TO "anon";
GRANT ALL ON TABLE "public"."ccr_cases" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_cases" TO "service_role";



GRANT ALL ON SEQUENCE "public"."ccr_cases_ccr_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."ccr_cases_ccr_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."ccr_cases_ccr_number_seq" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_closure" TO "anon";
GRANT ALL ON TABLE "public"."ccr_closure" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_closure" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_containment" TO "anon";
GRANT ALL ON TABLE "public"."ccr_containment" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_containment" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_containment_sorting" TO "anon";
GRANT ALL ON TABLE "public"."ccr_containment_sorting" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_containment_sorting" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_corrective_actions" TO "anon";
GRANT ALL ON TABLE "public"."ccr_corrective_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_corrective_actions" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_customer_view" TO "anon";
GRANT ALL ON TABLE "public"."ccr_customer_view" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_customer_view" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_fishbone_categories" TO "anon";
GRANT ALL ON TABLE "public"."ccr_fishbone_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_fishbone_categories" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_fishbone_causes" TO "anon";
GRANT ALL ON TABLE "public"."ccr_fishbone_causes" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_fishbone_causes" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_root_cause_validations" TO "anon";
GRANT ALL ON TABLE "public"."ccr_root_cause_validations" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_root_cause_validations" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_statuses" TO "anon";
GRANT ALL ON TABLE "public"."ccr_statuses" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_statuses" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_supplier_view" TO "anon";
GRANT ALL ON TABLE "public"."ccr_supplier_view" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_supplier_view" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."ccr_team_members" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."ccr_team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_team_members" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."ccr_teams" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."ccr_teams" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_teams" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_users" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_why_analyses" TO "anon";
GRANT ALL ON TABLE "public"."ccr_why_analyses" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_why_analyses" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_why_steps" TO "anon";
GRANT ALL ON TABLE "public"."ccr_why_steps" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_why_steps" TO "service_role";



GRANT ALL ON TABLE "public"."ccr_workflow_stages" TO "anon";
GRANT ALL ON TABLE "public"."ccr_workflow_stages" TO "authenticated";
GRANT ALL ON TABLE "public"."ccr_workflow_stages" TO "service_role";



GRANT ALL ON TABLE "public"."cross_tab_analyses" TO "anon";
GRANT ALL ON TABLE "public"."cross_tab_analyses" TO "authenticated";
GRANT ALL ON TABLE "public"."cross_tab_analyses" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_activities" TO "anon";
GRANT ALL ON TABLE "public"."dcc_activities" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_activities" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_dmr_requests" TO "anon";
GRANT ALL ON TABLE "public"."dcc_dmr_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_dmr_requests" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_document_requests" TO "anon";
GRANT ALL ON TABLE "public"."dcc_document_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_document_requests" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_documents" TO "anon";
GRANT ALL ON TABLE "public"."dcc_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_documents" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_folders" TO "anon";
GRANT ALL ON TABLE "public"."dcc_folders" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_folders" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_master_data" TO "anon";
GRANT ALL ON TABLE "public"."dcc_master_data" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_master_data" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_notifications" TO "anon";
GRANT ALL ON TABLE "public"."dcc_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."dcc_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."dcc_users" TO "service_role";



GRANT ALL ON TABLE "public"."defect_categories" TO "anon";
GRANT ALL ON TABLE "public"."defect_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."defect_categories" TO "service_role";



GRANT ALL ON TABLE "public"."defect_types" TO "anon";
GRANT ALL ON TABLE "public"."defect_types" TO "authenticated";
GRANT ALL ON TABLE "public"."defect_types" TO "service_role";



GRANT ALL ON TABLE "public"."employees" TO "anon";
GRANT ALL ON TABLE "public"."employees" TO "authenticated";
GRANT ALL ON TABLE "public"."employees" TO "service_role";



GRANT ALL ON TABLE "public"."ncr_approval_history" TO "anon";
GRANT ALL ON TABLE "public"."ncr_approval_history" TO "authenticated";
GRANT ALL ON TABLE "public"."ncr_approval_history" TO "service_role";



GRANT ALL ON SEQUENCE "public"."ncr_number_sequence" TO "anon";
GRANT ALL ON SEQUENCE "public"."ncr_number_sequence" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."ncr_number_sequence" TO "service_role";



GRANT ALL ON TABLE "public"."ncr_roles" TO "anon";
GRANT ALL ON TABLE "public"."ncr_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."ncr_roles" TO "service_role";



GRANT ALL ON TABLE "public"."ncr_statuses" TO "anon";
GRANT ALL ON TABLE "public"."ncr_statuses" TO "authenticated";
GRANT ALL ON TABLE "public"."ncr_statuses" TO "service_role";



GRANT ALL ON TABLE "public"."ncr_users" TO "anon";
GRANT ALL ON TABLE "public"."ncr_users" TO "authenticated";
GRANT ALL ON TABLE "public"."ncr_users" TO "service_role";



GRANT ALL ON TABLE "public"."ncrs" TO "anon";
GRANT ALL ON TABLE "public"."ncrs" TO "authenticated";
GRANT ALL ON TABLE "public"."ncrs" TO "service_role";



GRANT ALL ON TABLE "public"."part_defects" TO "anon";
GRANT ALL ON TABLE "public"."part_defects" TO "authenticated";
GRANT ALL ON TABLE "public"."part_defects" TO "service_role";



GRANT ALL ON TABLE "public"."parts" TO "anon";
GRANT ALL ON TABLE "public"."parts" TO "authenticated";
GRANT ALL ON TABLE "public"."parts" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































