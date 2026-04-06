-- Create manager_portfolios table
CREATE TABLE IF NOT EXISTS public.manager_portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manager_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    role_handled TEXT NOT NULL,
    outcome_summary TEXT,
    photos TEXT[] DEFAULT '{}',
    videos TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.manager_portfolios ENABLE ROW LEVEL SECURITY;

-- Policies for manager_portfolios
CREATE POLICY "Managers can manage their own portfolios"
ON public.manager_portfolios
FOR ALL
TO authenticated
USING (auth.uid() = manager_id)
WITH CHECK (auth.uid() = manager_id);

CREATE POLICY "Anyone can view portfolios"
ON public.manager_portfolios
FOR SELECT
TO authenticated
USING (true);

-- Function to handle updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.manager_portfolios
FOR EACH ROW
EXECUTE FUNCTION handle_updated_at();
