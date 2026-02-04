-- ==============================================================================
-- USER PERMISSIONS & POLICIES
-- Run this script in the Supabase Dashboard SQL Editor
-- ==============================================================================

-- 1. Allow users to update their own profile
-- This is necessary for them to set their 'verification_status' and 'doc_url'
create policy "Users can update own profile"
on users for update
to authenticated
using (
  auth.uid() = id
);

-- 2. Allow users to view their own profile
-- (If not already covered by other policies)
create policy "Users can view own profile"
on users for select
to authenticated
using (
  auth.uid() = id
);
