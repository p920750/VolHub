-- Disable the automatic user creation trigger
-- Run this in Supabase SQL Editor to prevent automatic user creation during email verification

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
