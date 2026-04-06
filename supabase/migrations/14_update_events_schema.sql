-- Migration to update events table schema
-- 1. Add missing columns for manager event posting
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS volunteers_needed INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS current_volunteers_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES public.users(id);

-- 2. Rename or update category to categories array if needed
-- Note: If 'category' already exists as TEXT, we might want to migrate it or add 'categories'
-- For now, let's add 'categories' as TEXT[] and keep 'category' for backward compatibility or migrate it.
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS categories TEXT[];

-- Update RLS policies (optional but recommended if not already permissive enough)
-- Assuming users table has 'manager' role for manager_id
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Policy for managers to insert their own events
CREATE POLICY "Managers can insert their own events" 
ON public.events FOR INSERT 
WITH CHECK (auth.uid() = manager_id);

-- Policy for everyone to view events
CREATE POLICY "Everyone can view events" 
ON public.events FOR SELECT 
USING (true);

-- Policy for managers to update their own events
CREATE POLICY "Managers can update their own events" 
ON public.events FOR UPDATE 
USING (auth.uid() = manager_id);
