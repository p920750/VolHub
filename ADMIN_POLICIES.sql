-- ==============================================================================
-- ADMIN PERMISSIONS & POLICIES
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Enable RLS on users (ensure it's on)
-- Note: 'users' table is likely the one managed by your application.
-- Generally, if you created a separate table for user data, it's this one.
alter table users enable row level security;

-- 2. Allow Admins to see ALL users
-- We use the 'user_type' stored in the user's JWT metadata to avoid recursion
create policy "Admins can view all users"
on users for select
to authenticated
using (
  (auth.jwt() -> 'user_metadata' ->> 'user_type') = 'admin'
    OR
  auth.uid() = id -- Keep allowing users to see their own profile
);

-- 3. Allow Admins to update users (for verification approvals)
create policy "Admins can update users"
on users for update
to authenticated
using (
  (auth.jwt() -> 'user_metadata' ->> 'user_type') = 'admin'
);

-- ==============================================================================
-- STORAGE PERMISSIONS
-- ==============================================================================

-- 4. Allow Admins to view all files in 'verification_docs' bucket
create policy "Admins can view all verification docs"
on storage.objects for select
to authenticated
using (
  bucket_id = 'verification_docs' AND
  (
    (auth.jwt() -> 'user_metadata' ->> 'user_type') = 'admin'
      OR
    (storage.foldername(name))[1] = auth.uid()::text -- Keep allowing users to see their own files
  )
);
