-- 1. Rename existing aadhar_pdf to aadhar_doc_url
ALTER TABLE public.users RENAME COLUMN aadhar_pdf TO aadhar_doc_url;

-- 2. Move data from the temp column (verification_doc_url) if it has data and the main one doesn't
UPDATE public.users 
SET aadhar_doc_url = verification_doc_url 
WHERE aadhar_doc_url IS NULL AND verification_doc_url IS NOT NULL;

-- 3. Drop the redundant verification_doc_url column
ALTER TABLE public.users DROP COLUMN IF EXISTS verification_doc_url;
