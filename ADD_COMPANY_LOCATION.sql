-- 1. Add company_location column if missing
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS company_location TEXT;

-- 2. Robustly update the role constraint
-- This script finds the name of the check constraint on 'role' and drops it
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'public.users'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%role%';

    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.users DROP CONSTRAINT ' || constraint_name;
    END IF;
END $$;

ALTER TABLE public.users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('volunteer', 'organizer', 'manager', 'admin', 'event_manager', 'event_host'));

-- 3. Add policies for Admin to manage all users (including Insert)
DROP POLICY IF EXISTS "Admins can insert any user" ON public.users;
CREATE POLICY "Admins can insert any user" ON public.users 
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can update any user" ON public.users;
CREATE POLICY "Admins can update any user" ON public.users 
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can delete any user" ON public.users;
CREATE POLICY "Admins can delete any user" ON public.users 
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- 4. Update the handle_new_user function to be more reliable
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role,
    phone_number,
    country_code,
    date_of_birth,
    is_email_verified,
    company_name,
    company_location
  )
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name',
    COALESCE(new.raw_user_meta_data->>'role', 'volunteer'),
    new.raw_user_meta_data->>'phone_number',
    COALESCE(new.raw_user_meta_data->>'country_code', '+91'),
    (new.raw_user_meta_data->>'dob')::DATE,
    (new.email_confirmed_at IS NOT NULL),
    new.raw_user_meta_data->>'company_name',
    new.raw_user_meta_data->>'company_location'
  );
  
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'User record not created in public.users: %', SQLERRM;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
