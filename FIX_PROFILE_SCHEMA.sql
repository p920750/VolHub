-- ==============================================================================
-- FIX USER PROFILE SCHEMA
-- Run this script in the Supabase Dashboard SQL Editor (https://supabase.com/dashboard)
-- ==============================================================================

-- 1. Add 'bio' column to the 'users' table if it doesn't already exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS bio text;

-- 2. Ensure 'address' column exists (used for Location/Address)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS address text;

-- Comment:
-- After running this, the "Error saving changes: Could not find the 'bio' column" 
-- will be resolved, and your profile edits will save successfully.
