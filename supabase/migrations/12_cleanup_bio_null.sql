-- Migration to clean up bio column
UPDATE public.users SET bio = NULL WHERE bio = 'EMPTY';

-- Ensure future defaults are NULL (usually they are, but good to be explicit)
ALTER TABLE public.users ALTER COLUMN bio SET DEFAULT NULL;
