-- Add missing columns to the users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url text;

-- Enable Row Level Security (RLS) on the users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 1. Policy: Allow users to view their own profile
CREATE POLICY "Users can view their own profile" 
ON public.users 
FOR SELECT 
USING (auth.uid() = id);

-- 2. Policy: Allow users to update their own profile
CREATE POLICY "Users can update their own profile" 
ON public.users 
FOR UPDATE 
USING (auth.uid() = id);

-- 3. Policy: Allow users to insert their own profile (if not automatically created by triggers)
CREATE POLICY "Users can insert their own profile" 
ON public.users 
FOR INSERT 
WITH CHECK (auth.uid() = id);
