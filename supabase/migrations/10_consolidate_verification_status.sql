-- 1. Update existing 'verified' status to 'accepted'
UPDATE public.users SET verification_status = 'accepted' WHERE verification_status = 'verified';

-- 2. Drop the existing manual boolean column
ALTER TABLE public.users DROP COLUMN IF EXISTS is_aadhar_verified;

-- 3. Add the generated boolean column
-- This column will automatically stay in sync with verification_status
ALTER TABLE public.users 
ADD COLUMN is_aadhar_verified BOOLEAN GENERATED ALWAYS AS (verification_status = 'accepted') STORED;
