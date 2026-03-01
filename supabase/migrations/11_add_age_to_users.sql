-- Migration to add age column and its automatic calculation
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS age INTEGER;

-- Function to calculate age
CREATE OR REPLACE FUNCTION public.calculate_age(dob DATE)
RETURNS INTEGER AS $$
BEGIN
    IF dob IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN date_part('year', age(dob))::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to update age
CREATE OR REPLACE FUNCTION public.update_age_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.age := public.calculate_age(NEW.date_of_birth);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to run before insert or update
DROP TRIGGER IF EXISTS trigger_update_user_age ON public.users;
CREATE TRIGGER trigger_update_user_age
BEFORE INSERT OR UPDATE OF date_of_birth ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.update_age_column();

-- Update existing records
UPDATE public.users SET age = public.calculate_age(date_of_birth);
