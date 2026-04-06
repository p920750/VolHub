-- ==============================================================================
-- ADD VOLUNTEER PROFILE COLUMNS
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- Add address column
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS address text;

-- Add skills column (array of text)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS skills text[];

-- Add interests column (array of text)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS interests text[];

-- Comment:
-- These columns allow storing detailed volunteer profile information.
