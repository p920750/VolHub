-- 1. Create a function to handle new user creation
-- This function runs automatically whenever a new user signs up via Supabase Auth
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.users (id, email, full_name, role, phone_number, created_at)
  values (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name', 
    coalesce(new.raw_user_meta_data->>'role', new.raw_user_meta_data->>'user_type'), -- Support both keys
    coalesce(new.raw_user_meta_data->>'phone_number', new.raw_user_meta_data->>'phone'), -- Support both keys
    new.created_at
  );
  return new;
end;
$$ language plpgsql security definer;

-- 2. Create the trigger
-- This ensures that every time a user is created in auth.users, they are copied to public.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. Backfill existing users (Optional but recommended)
-- This tries to insert any users that are in auth but missing from public.users
insert into public.users (id, email, full_name, role, phone_number, created_at)
select 
  id, 
  email, 
  raw_user_meta_data->>'full_name', 
  coalesce(raw_user_meta_data->>'role', raw_user_meta_data->>'user_type'),
  coalesce(raw_user_meta_data->>'phone_number', raw_user_meta_data->>'phone'),
  created_at
from auth.users
on conflict (id) do nothing;

-- 4. Fix RLS Policies for Admin Visibility
-- Enable RLS just in case
alter table public.users enable row level security;

-- Drop existing policy if it exists to avoid conflicts
drop policy if exists "Admins can view all users" on public.users;

-- Create the Admin View Policy
create policy "Admins can view all users"
on public.users for select
to authenticated
using (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  OR
  (auth.jwt() -> 'user_metadata' ->> 'user_type') = 'admin' -- Support legacy metadata
  OR
  auth.uid() = id
);
