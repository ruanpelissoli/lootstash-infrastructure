-- Create the d2-items storage bucket for item icons
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'd2-items',
    'd2-items',
    true,  -- public bucket for serving images
    5242880,  -- 5MB max file size
    ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to the bucket
CREATE POLICY "Public read access for d2-items"
ON storage.objects FOR SELECT
USING (bucket_id = 'd2-items');

-- Allow service role to upload/update/delete
CREATE POLICY "Service role can manage d2-items"
ON storage.objects FOR ALL
USING (bucket_id = 'd2-items')
WITH CHECK (bucket_id = 'd2-items');
