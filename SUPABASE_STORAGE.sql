-- Create a storage bucket for verification documents
-- Note: 'verification_docs' must match the name used in your Flutter code

-- 1. Create the bucket
insert into storage.buckets (id, name, public)
values ('verification_docs', 'verification_docs', true);

-- 2. Set up RLS (Row Level Security) policies so users can upload their own files

-- Policy: Allow authenticated users to upload files
-- The folder structure is: userId/timestamp.ext
create policy "Authenticated users can upload verification docs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'verification_docs' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow authenticated users to read their own files
-- Even though the bucket is public, we can restrict listing if needed, 
-- but public buckets usually allow public read access if you have the URL.
-- This policy allows users to select (download) their own files via the API.
create policy "Users can view their own verification docs"
on storage.objects for select
to authenticated
using (
  bucket_id = 'verification_docs' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow users to update/delete their own files (optional, but good for cleanup)
create policy "Users can update their own verification docs"
on storage.objects for update
to authenticated
using (
  bucket_id = 'verification_docs' and
  (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete their own verification docs"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'verification_docs' and
  (storage.foldername(name))[1] = auth.uid()::text
);
