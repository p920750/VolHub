-- Create a storage bucket for portfolio media
INSERT INTO storage.buckets (id, name, public)
VALUES ('portfolio_media', 'portfolio_media', true)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for portfolio_media

-- Policy: Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload portfolio media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'portfolio_media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow authenticated users to view all portfolio media
CREATE POLICY "Anyone can view portfolio media"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'portfolio_media'
);

-- Policy: Allow users to update their own files
CREATE POLICY "Users can update their own portfolio media"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'portfolio_media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow users to delete their own files
CREATE POLICY "Users can delete their own portfolio media"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'portfolio_media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
