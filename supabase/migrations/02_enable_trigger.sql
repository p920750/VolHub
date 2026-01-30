-- This migration enables the trigger for automatic user creation
-- Run this in your Supabase SQL Editor if the trigger doesn't exist

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Function to handle new user creation from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_dob DATE;
BEGIN
  -- Extract role from metadata, default to 'volunteer' if not provided
  user_role := COALESCE(new.raw_user_meta_data->>'role', 'volunteer');
  
  -- Parse date of birth if provided (format: YYYY-MM-DD)
  BEGIN
    user_dob := (new.raw_user_meta_data->>'dob')::DATE;
  EXCEPTION WHEN OTHERS THEN
    user_dob := NULL;
  END;
  
  -- Insert user record with all metadata
  INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role,
    phone_number,
    country_code,
    date_of_birth
  )
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name',
    user_role,
    new.raw_user_meta_data->>'phone_number',
    COALESCE(new.raw_user_meta_data->>'country_code', '+91'),
    user_dob
  );
  
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the auth.users insert
  RAISE WARNING 'Error creating user in public.users: %', SQLERRM;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
