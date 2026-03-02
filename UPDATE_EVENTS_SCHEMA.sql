-- ==============================================================================
-- UPDATE EVENTS TABLE FOR ORGANIZER FLOW
-- Run this in the Supabase SQL Editor
-- ==============================================================================

-- 1. Add missing columns to 'events' table
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS category text,
ADD COLUMN IF NOT EXISTS time text,
ADD COLUMN IF NOT EXISTS posted_at text;

-- 2. Ensure existing columns have appropriate types if needed
-- budget, requirements, description are already text/timestamptz as per previous exploration.

-- 3. Comment on columns for clarity
COMMENT ON COLUMN public.events.posted_at IS 'Formatted timestamp: dd-mm-yyyy hh:mm:ss (am/pm)';
COMMENT ON COLUMN public.events.category IS 'Manually entered event category';
COMMENT ON COLUMN public.events.time IS 'Event time string';
