-- ==============================================================================
-- UPDATE EVENTS TABLE AND RLS POLICIES
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Add missing columns to 'events' table
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS budget text,
ADD COLUMN IF NOT EXISTS requirements text,
ADD COLUMN IF NOT EXISTS image_url text,
ADD COLUMN IF NOT EXISTS host_name text;

-- 2. Ensure RLS is enabled
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- 3. Update RLS Polices for event isolation

-- Remove existing policies if they conflict
DROP POLICY IF EXISTS "Managers view own events" ON public.events;
DROP POLICY IF EXISTS "Hosts see own events" ON public.events;
DROP POLICY IF EXISTS "Managers see all events" ON public.events;

-- Policy for Hosts: Can only see events they created
-- Using manager_id as the foreign key to users(id) for the creator
CREATE POLICY "Hosts see own events" ON public.events 
FOR SELECT USING (auth.uid() = manager_id);

CREATE POLICY "Hosts insert own events" ON public.events 
FOR INSERT WITH CHECK (auth.uid() = manager_id);

CREATE POLICY "Hosts update own events" ON public.events 
FOR UPDATE USING (auth.uid() = manager_id);

-- Policy for Managers: Can see ALL events
CREATE POLICY "Managers see all events" ON public.events 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND (role = 'manager' OR role = 'event_manager')
  )
);
