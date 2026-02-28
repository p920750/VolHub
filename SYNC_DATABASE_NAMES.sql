-- ==============================================================================
-- SYNC DATABASE NAMES FOR PROJECT VOLHUB
-- Run this in the Supabase SQL Editor to align terminology
-- ==============================================================================

-- 1. Drop old policies that depend on manager_id or host_id
-- This must be done first to allow renaming/dropping columns
DROP POLICY IF EXISTS "Managers view own events" ON public.events;
DROP POLICY IF EXISTS "Hosts see own events" ON public.events;
DROP POLICY IF EXISTS "Hosts insert own events" ON public.events;
DROP POLICY IF EXISTS "Hosts update own events" ON public.events;
DROP POLICY IF EXISTS "Hosts delete own events" ON public.events;
DROP POLICY IF EXISTS "Managers can insert their own events" ON public.events;
DROP POLICY IF EXISTS "Managers can update their own events" ON public.events;

-- 2. Rename columns to match preferred terminology
DO $$ 
BEGIN
  -- Rename host_id if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='events' AND column_name='host_id') THEN
    ALTER TABLE public.events RENAME COLUMN host_id TO organizer_id;
  END IF;

  -- Drop the old redundant/unused manager_id so we can rename assigned_manager_id to it
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='events' AND column_name='manager_id' AND column_name != 'assigned_manager_id') THEN
    ALTER TABLE public.events DROP COLUMN IF EXISTS manager_id;
  END IF;

  -- Rename assigned_manager_id to manager_id
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='events' AND column_name='assigned_manager_id') THEN
    ALTER TABLE public.events RENAME COLUMN assigned_manager_id TO manager_id;
  END IF;
END $$;

-- 3. Fix Foreign Key Constraints for joins (Embedding)
-- Use explicit names to avoid ambiguity
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_organizer_id_fkey;
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_manager_id_fkey;

ALTER TABLE public.events 
ADD CONSTRAINT events_organizer_id_fkey 
FOREIGN KEY (organizer_id) REFERENCES public.users(id);

ALTER TABLE public.events 
ADD CONSTRAINT events_manager_id_fkey 
FOREIGN KEY (manager_id) REFERENCES public.users(id);

-- 4. Fix 'event_applications' table for Volunteers and Managers
-- Ensure constraints are named explicitly for joins
ALTER TABLE public.event_applications DROP CONSTRAINT IF EXISTS event_applications_volunteer_id_fkey;
ALTER TABLE public.event_applications DROP CONSTRAINT IF EXISTS event_applications_manager_id_fkey;

ALTER TABLE public.event_applications 
ADD CONSTRAINT event_applications_volunteer_id_fkey 
FOREIGN KEY (volunteer_id) REFERENCES public.users(id);

ALTER TABLE public.event_applications 
ADD CONSTRAINT event_applications_manager_id_fkey 
FOREIGN KEY (manager_id) REFERENCES public.users(id);

-- 5. Update Policies to use new names
DROP POLICY IF EXISTS "Hosts see own events" ON public.events;
CREATE POLICY "Organizers see own events" ON public.events 
FOR SELECT USING (auth.uid() = organizer_id);

DROP POLICY IF EXISTS "Hosts insert own events" ON public.events;
CREATE POLICY "Organizers insert own events" ON public.events 
FOR INSERT WITH CHECK (auth.uid() = organizer_id);

COMMENT ON TABLE public.events IS 'Organizer ID = Creator, Manager ID = Assigned Manager';
COMMENT ON TABLE public.event_applications IS 'Volunteer ID = User applying as volunteer, Manager ID = User proposing as manager';
