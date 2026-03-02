-- Add company_category column to users table
ALTER TABLE public.users 
ADD COLUMN company_category TEXT[];

-- Update the handle_new_user function to handle the new field (optional if it picks up from metadata)
-- However, completeSignup in Flutter handles the insert for email signups, so we mainly need the column.
