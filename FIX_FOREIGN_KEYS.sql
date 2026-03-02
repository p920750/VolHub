-- ==============================================================================
-- FIX FOREIGN KEYS FOR PROJECT VOLHUB
-- Run this in the Supabase SQL Editor
-- ==============================================================================

-- 1. Fix 'events' table foreign keys to point to public.users instead of auth.users
-- This is critical for Postgrest to allow joins (embedding) between these tables.

-- Drop existing foreign keys if they point to auth.users (check constraints if needed)
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_host_id_fkey;
ALTER TABLE public.events DROP CONSTRAINT IF EXISTS events_assigned_manager_id_fkey;

-- Add them back pointing to public.users
ALTER TABLE public.events 
ADD CONSTRAINT events_host_id_fkey 
FOREIGN KEY (host_id) REFERENCES public.users(id);

ALTER TABLE public.events 
ADD CONSTRAINT events_assigned_manager_id_fkey 
FOREIGN KEY (assigned_manager_id) REFERENCES public.users(id);

-- 2. Fix 'event_applications' ambiguous relationships if needed
-- (The app already handles this by specifying the fkey name, but let's ensure consistency)
ALTER TABLE public.event_applications DROP CONSTRAINT IF EXISTS event_applications_manager_id_fkey;
ALTER TABLE public.event_applications 
ADD CONSTRAINT event_applications_manager_id_fkey 
FOREIGN KEY (manager_id) REFERENCES public.users(id);

-- 3. Verify status consistency
-- Ensure 'active' is a valid status mentioned in queries
COMMENT ON COLUMN public.events.status IS 'pending, confirmed, accepted, active, completed, rejected';
