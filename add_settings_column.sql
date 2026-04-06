-- Add settings column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS settings jsonb DEFAULT '{}'::jsonb;
