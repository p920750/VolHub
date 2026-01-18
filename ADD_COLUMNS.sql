-- ==============================================================================
-- ADD MISSING COLUMNS TO USERS TABLE
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- Add verification_status column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS verification_status text DEFAULT 'unverified';

-- Add verification_doc_url column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS verification_doc_url text;

-- Add verification_submitted_at column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS verification_submitted_at text;

-- Add other potentially missing columns used in the app
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS full_name text;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone text;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS dob text;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS user_type text DEFAULT 'volunteer';

-- Comment:
-- After running this, the 'verification_status' column will exist 
-- and the Admin Dashboard should work correctly.
