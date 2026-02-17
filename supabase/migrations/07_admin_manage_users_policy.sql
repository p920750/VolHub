-- Ensure pgcrypto is enabled for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Helper function to check if the caller is an admin
CREATE OR REPLACE FUNCTION public.check_is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Comprehensive function to create a manager (Auth + Public)
-- This bypasses the Auth server's email rate limits by inserting directly into auth.users
CREATE OR REPLACE FUNCTION public.create_manager_admin(
    in_email TEXT,
    in_password TEXT,
    in_full_name TEXT,
    in_phone TEXT,
    in_company_name TEXT,
    in_company_location TEXT
)
RETURNS UUID AS $$
DECLARE
    new_user_id UUID := gen_random_uuid();
BEGIN
    -- Check permissions
    IF NOT public.check_is_admin() THEN
        RAISE EXCEPTION 'Only admins can create managers';
    END IF;

    -- 1. Insert into auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token,
        is_sso_user,
        is_anonymous
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        new_user_id,
        'authenticated',
        'authenticated',
        in_email,
        crypt(in_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        json_build_object(
            'full_name', in_full_name,
            'role', 'manager',
            'phone_number', in_phone,
            'company_name', in_company_name,
            'company_location', in_company_location
        ),
        now(),
        now(),
        '',
        '',
        '',
        '',
        false, -- is_sso_user
        false  -- is_anonymous
    );

    -- 2. Insert into auth.identities
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id, -- Added this as it's often NOT NULL
        last_sign_in_at,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        new_user_id,
        json_build_object('sub', new_user_id, 'email', in_email),
        'email',
        in_email, -- provider_id is the email for email provider
        now(),
        now(),
        now()
    );

    -- 3. Insert into public.users
    INSERT INTO public.users (
        id,
        email,
        full_name,
        role,
        phone_number,
        country_code,
        company_name,
        company_location,
        is_email_verified,
        is_phone_verified,
        updated_at
    )
    VALUES (
        new_user_id,
        in_email,
        in_full_name,
        'manager',
        in_phone,
        '+91',
        in_company_name,
        in_company_location,
        true,
        true,
        now()
    );

    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Policy update (already exists, but ensuring it)
DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;
CREATE POLICY "Admins can manage all users"
    ON public.users
    FOR ALL
    USING (public.check_is_admin())
    WITH CHECK (public.check_is_admin());
