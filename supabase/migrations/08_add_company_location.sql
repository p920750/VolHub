-- Add company_location column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS company_location TEXT;
