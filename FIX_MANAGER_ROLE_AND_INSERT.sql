-- ==============================================================================
-- FIX MANAGER ROLE AND INSERT TEST MANAGER
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Enable pgcrypto for password hashing (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Update the role constraint on public.users to allow 'event_manager'
-- The app uses 'event_manager' but the DB might strictly check for 'manager'.
-- We update the check constraint to allow both (and others).
DO $$
BEGIN
    -- Drop the constraint if it exists (name might vary, checking standard names)
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check') THEN
        ALTER TABLE public.users DROP CONSTRAINT users_role_check;
    END IF;
    
    -- Add the new constraint
    ALTER TABLE public.users ADD CONSTRAINT users_role_check 
    CHECK (role IN ('volunteer', 'organizer', 'manager', 'admin', 'event_manager'));
END $$;

-- 3. Insert a Test Manager User
DO $$
DECLARE
    v_user_email text := 'manager@example.com';
    v_user_password text := 'password123';
    v_user_role text := 'event_manager';
    v_user_id uuid := gen_random_uuid();
    v_encrypted_pw text;
BEGIN
    -- Check if user already exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_user_email) THEN
        -- Generate encrypted password
        v_encrypted_pw := crypt(v_user_password, gen_salt('bf'));
        
        -- Insert into auth.users
        -- This should trigger the creation of public.users via 'on_auth_user_created'
        INSERT INTO auth.users (
            id,
            instance_id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at
        ) VALUES (
            v_user_id,
            '00000000-0000-0000-0000-000000000000', -- Standard Default Instance ID
            'authenticated',
            'authenticated',
            v_user_email,
            v_encrypted_pw,
            now(), -- Email confirmed
            '{"provider": "email", "providers": ["email"]}',
            jsonb_build_object('full_name', 'Test Manager', 'role', v_user_role),
            now(),
            now()
        );
        
        RAISE NOTICE 'Created auth user: %', v_user_email;

        -- The trigger 'on_auth_user_created' should have run and inserted into public.users.
        -- However, we also need to ensure the entry exists in 'public.event_managers' 
        -- if that table is being used for manager specific data.
        
        -- Wait a moment for trigger? No, in same transaction it should be visible or we insert if missing.
        -- We'll try to insert into event_managers if it exists.
        
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'event_managers') THEN
             INSERT INTO public.event_managers (id, organization_name, created_at, updated_at)
             VALUES (v_user_id, 'Test Organization', now(), now())
             ON CONFLICT (id) DO NOTHING;
             
             RAISE NOTICE 'Added to event_managers table';
        END IF;

    ELSE
        RAISE NOTICE 'User % already exists. Skipping insert.', v_user_email;
    END IF;
END $$;
