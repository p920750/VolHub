-- ==============================================================================
-- COMPLETE EVENT TABLE SETUP
-- Run this script in the Supabase Dashboard SQL Editor to create the missing table.
-- ==============================================================================

-- 1. Create 'events' table with all required columns
CREATE TABLE IF NOT EXISTS public.events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    manager_id uuid REFERENCES public.users(id) NOT NULL,
    description text,
    location text,
    date timestamptz,
    status text DEFAULT 'upcoming', -- upcoming, active, completed
    budget text,
    requirements text,
    image_url text,
    host_name text,
    created_at timestamptz DEFAULT now()
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- 3. Clear existing policies if any (to avoid conflicts)
DROP POLICY IF EXISTS "Managers view own events" ON public.events;
DROP POLICY IF EXISTS "Hosts see own events" ON public.events;
DROP POLICY IF EXISTS "Hosts insert own events" ON public.events;
DROP POLICY IF EXISTS "Hosts update own events" ON public.events;
DROP POLICY IF EXISTS "Managers see all events" ON public.events;

-- 4. Create Isolation Policies

-- Policy for Hosts: Can only see their own events
CREATE POLICY "Hosts see own events" ON public.events 
FOR SELECT USING (auth.uid() = manager_id);

-- Policy for Hosts: Can only insert events with their own ID
CREATE POLICY "Hosts insert own events" ON public.events 
FOR INSERT WITH CHECK (auth.uid() = manager_id);

-- Policy for Hosts: Can only update their own events
CREATE POLICY "Hosts update own events" ON public.events 
FOR UPDATE USING (auth.uid() = manager_id);

-- Policy for Managers: Can see ALL events from all hosts
CREATE POLICY "Managers see all events" ON public.events 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND (role = 'manager' OR role = 'event_manager')
  )
);

-- 5. Optional: Grant access to authenticated users (standard for Supabase)
GRANT ALL ON public.events TO authenticated;
GRANT ALL ON public.events TO service_role;
