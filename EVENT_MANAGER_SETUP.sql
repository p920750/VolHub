-- ==============================================================================
-- EVENT MANAGER SETUP
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Create event_managers table for role-specific data (Organization details, etc.)
CREATE TABLE IF NOT EXISTS public.event_managers (
    id uuid REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    organization_name text,
    organization_website text,
    verification_status text DEFAULT 'pending',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.event_managers ENABLE ROW LEVEL SECURITY;

-- 3. Policies
-- View own profile
CREATE POLICY "Event managers can view their own profile" 
ON public.event_managers FOR SELECT 
USING (auth.uid() = id);

-- Update own profile
CREATE POLICY "Event managers can update their own profile" 
ON public.event_managers FOR UPDATE 
USING (auth.uid() = id);

-- Insert own profile
CREATE POLICY "Event managers can insert their own profile" 
ON public.event_managers FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Public can view basic info (optional, for directory listing)
CREATE POLICY "Public can view basic event manager info" 
ON public.event_managers FOR SELECT 
USING (true);

-- 4. Trigger to automatically create event_managers entry on user creation if user_type is event_manager
-- (This assumes you have a handle_new_user function already. If so, update it. If not, here is a standalone idea)
-- NOTE: It's often safer to handle this in your application logic (SignUp) or a single unified trigger.

-- For now, ensure your 'users' table has the 'user_type' being set correctly.
-- The app currently sets 'user_type' in 'users' table via metadata sync or direct insert.

-- Check if user_type constraint allows 'event_manager' (if you have a check constraint)
-- ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_user_type_check;
-- ALTER TABLE public.users ADD CONSTRAINT users_user_type_check CHECK (user_type IN ('volunteer', 'admin', 'event_manager', 'event_host'));
