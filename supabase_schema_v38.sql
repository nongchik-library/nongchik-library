-- NONGCHIK LIBRARY v38
-- Clean rebuild of library_files because the current table is confirmed empty (0 rows).
-- This script intentionally stops if data already exists.

DO $$
DECLARE c bigint;
BEGIN
  SELECT count(*) INTO c FROM public.library_files;
  IF c > 0 THEN
    RAISE EXCEPTION 'หยุดเพื่อป้องกันข้อมูลหาย: library_files มี % รายการ', c;
  END IF;
END $$;

DROP TABLE IF EXISTS public.library_files;

CREATE TABLE public.library_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  file_name text NOT NULL,
  file_type text NOT NULL DEFAULT 'document',
  category text NOT NULL DEFAULT 'other',
  subdistrict text,
  folder_name text NOT NULL DEFAULT 'ทั่วไป',
  storage_bucket text NOT NULL,
  storage_path text NOT NULL,
  mime_type text,
  file_size bigint,
  uploaded_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX library_files_folder_name_idx ON public.library_files(folder_name);
CREATE INDEX library_files_status_idx ON public.library_files(status);
CREATE INDEX library_files_uploaded_by_idx ON public.library_files(uploaded_by);
CREATE INDEX library_files_created_at_idx ON public.library_files(created_at DESC);

ALTER TABLE public.library_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "library_files_select" ON public.library_files;
DROP POLICY IF EXISTS "library_files_insert" ON public.library_files;
DROP POLICY IF EXISTS "library_files_update" ON public.library_files;
DROP POLICY IF EXISTS "library_files_delete" ON public.library_files;

CREATE POLICY "library_files_select"
ON public.library_files FOR SELECT TO authenticated
USING (status = 'approved' OR uploaded_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_files_insert"
ON public.library_files FOR INSERT TO authenticated
WITH CHECK (uploaded_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_files_update"
ON public.library_files FOR UPDATE TO authenticated
USING (uploaded_by = auth.uid() OR public.is_admin())
WITH CHECK (uploaded_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_files_delete"
ON public.library_files FOR DELETE TO authenticated
USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.library_files_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS library_files_updated_at ON public.library_files;
CREATE TRIGGER library_files_updated_at
BEFORE UPDATE ON public.library_files
FOR EACH ROW EXECUTE FUNCTION public.library_files_set_updated_at();

-- Folders
CREATE TABLE IF NOT EXISTS public.library_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS library_folders_owner_name_idx
ON public.library_folders(created_by, lower(name));

ALTER TABLE public.library_folders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "library_folders_select" ON public.library_folders;
DROP POLICY IF EXISTS "library_folders_insert" ON public.library_folders;
DROP POLICY IF EXISTS "library_folders_update" ON public.library_folders;
DROP POLICY IF EXISTS "library_folders_delete" ON public.library_folders;

CREATE POLICY "library_folders_select"
ON public.library_folders FOR SELECT TO authenticated
USING (created_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_folders_insert"
ON public.library_folders FOR INSERT TO authenticated
WITH CHECK (created_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_folders_update"
ON public.library_folders FOR UPDATE TO authenticated
USING (created_by = auth.uid() OR public.is_admin())
WITH CHECK (created_by = auth.uid() OR public.is_admin());

CREATE POLICY "library_folders_delete"
ON public.library_folders FOR DELETE TO authenticated
USING (public.is_admin());

-- Storage policies for both buckets.
DROP POLICY IF EXISTS "library_images_insert" ON storage.objects;
DROP POLICY IF EXISTS "library_images_select" ON storage.objects;
DROP POLICY IF EXISTS "library_images_delete" ON storage.objects;
DROP POLICY IF EXISTS "library_documents_insert" ON storage.objects;
DROP POLICY IF EXISTS "library_documents_select" ON storage.objects;
DROP POLICY IF EXISTS "library_documents_delete" ON storage.objects;

CREATE POLICY "library_images_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'library-images' AND (name LIKE auth.uid()::text || '/%' OR public.is_admin()));

CREATE POLICY "library_images_select"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'library-images' AND (name LIKE auth.uid()::text || '/%' OR public.is_admin() OR EXISTS (
  SELECT 1 FROM public.library_files f WHERE f.storage_bucket = bucket_id AND f.storage_path = name AND f.status = 'approved'
)));

CREATE POLICY "library_images_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'library-images' AND public.is_admin());

CREATE POLICY "library_documents_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'library-documents' AND (name LIKE auth.uid()::text || '/%' OR public.is_admin()));

CREATE POLICY "library_documents_select"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'library-documents' AND (name LIKE auth.uid()::text || '/%' OR public.is_admin() OR EXISTS (
  SELECT 1 FROM public.library_files f WHERE f.storage_bucket = bucket_id AND f.storage_path = name AND f.status = 'approved'
)));

CREATE POLICY "library_documents_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'library-documents' AND public.is_admin());

SELECT 'library_files' AS table_name, count(*) AS total FROM public.library_files
UNION ALL
SELECT 'library_folders', count(*) FROM public.library_folders;
