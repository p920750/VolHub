-- ==============================================================================
-- EVENT DATA SETUP
-- Run this script in the Supabase Dashboard SQL Editor
-- This creates the tables needed for the Event Manager Dashboard to function with real data.
-- ==============================================================================

-- 1. Create 'teams' table
CREATE TABLE IF NOT EXISTS public.teams (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    manager_id uuid REFERENCES public.users(id) NOT NULL,
    description text,
    rating numeric DEFAULT 0,
    members_count int DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- 2. Create 'events' table
CREATE TABLE IF NOT EXISTS public.events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    manager_id uuid REFERENCES public.users(id) NOT NULL,
    description text,
    location text,
    date timestamptz,
    status text DEFAULT 'upcoming', -- upcoming, active, completed
    created_at timestamptz DEFAULT now()
);

-- 3. Create 'applications' table (Volunteers applying to Events)
CREATE TABLE IF NOT EXISTS public.applications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
    volunteer_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    manager_id uuid REFERENCES public.users(id), -- Denormalized for easier querying by manager
    status text DEFAULT 'pending', -- pending, accepted, rejected
    role_applied text,
    created_at timestamptz DEFAULT now()
);

-- 4. Create 'proposals' table (Volunteers proposing new ideas/teams)
CREATE TABLE IF NOT EXISTS public.proposals (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    description text,
    volunteer_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    manager_id uuid REFERENCES public.users(id), -- Who it's sent to (optional, or sent to system)
    status text DEFAULT 'pending',
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proposals ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Adjust as needed)
-- Managers can view/edit their own data
CREATE POLICY "Managers view own teams" ON public.teams FOR SELECT USING (auth.uid() = manager_id);
CREATE POLICY "Managers view own events" ON public.events FOR SELECT USING (auth.uid() = manager_id);
CREATE POLICY "Managers view applications for their events" ON public.applications FOR SELECT USING (auth.uid() = manager_id);
CREATE POLICY "Managers view proposals for them" ON public.proposals FOR SELECT USING (auth.uid() = manager_id);

-- Dummy Data for Testing (Uncomment to insert)
/*
INSERT INTO public.teams (name, manager_id, description, rating, members_count) 
VALUES 
('Alpha Team', auth.uid(), 'The A-Team', 4.8, 12),
('Beta Squad', auth.uid(), 'The B-Team', 4.5, 8);

INSERT INTO public.events (name, manager_id, status)
VALUES ('Charity Gala', auth.uid(), 'upcoming');
*/
