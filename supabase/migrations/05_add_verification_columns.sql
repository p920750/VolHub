-- Add missing verification columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'not_started',
ADD COLUMN IF NOT EXISTS verification_submitted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verification_doc_url TEXT;

-- Recommended: Update existing users to 'not_started' if they have null status
UPDATE public.users SET verification_status = 'not_started' WHERE verification_status IS NULL;

-- If any user already has aadhar_pdf, we can treat them as pending or verified
UPDATE public.users 
SET verification_status = 'verified' 
WHERE is_aadhar_verified = true;

UPDATE public.users 
SET verification_status = 'pending',
    verification_doc_url = aadhar_pdf
WHERE is_aadhar_verified = false AND aadhar_pdf IS NOT NULL;
