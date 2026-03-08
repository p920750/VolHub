-- Run this script in your Supabase SQL Editor to add the new fields to the events table

ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS role_description TEXT,
ADD COLUMN IF NOT EXISTS payment_type TEXT DEFAULT 'Unpaid',
ADD COLUMN IF NOT EXISTS payment_amount TEXT,
ADD COLUMN IF NOT EXISTS certificate_provided BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS food_provided BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS skills_required TEXT[] DEFAULT '{}';
