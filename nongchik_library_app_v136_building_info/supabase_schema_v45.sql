-- Nongchik Library V45 - fix content form insert/update
-- รันไฟล์นี้ใน Supabase SQL Editor เพียง 1 ครั้ง
-- ปลอดภัยต่อข้อมูลเดิม: เพิ่มเฉพาะคอลัมน์/นโยบายที่จำเป็น และไม่ลบข้อมูล

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'learning_resources',
    'local_wisdom',
    'local_scholars',
    'community_book_houses',
    'subdistrict_learning_centers',
    'tourist_attractions',
    'traditional_foods'
  ] LOOP
    -- ฟิลด์จากเมนูย่อยที่เพิ่มในระบบ
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS background_history text NOT NULL DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS resource_history text NOT NULL DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS awards text NOT NULL DEFAULT '''';', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS certificate_paths text[] NOT NULL DEFAULT ARRAY[]::text[];', t);

    -- ฟิลด์หลักที่ระบบต้องใช้ (เผื่อฐานข้อมูลเดิมยังขาดบางตัว)
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS photo_paths text[] NOT NULL DEFAULT ARRAY[]::text[];', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS rejection_reason text;', t);
    EXECUTE format('ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();', t);

    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);

    -- ล้าง policy ชื่อเดิมที่อาจมาจาก schema รุ่นก่อน
    EXECUTE format('DROP POLICY IF EXISTS "read approved own admin" ON public.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "insert own" ON public.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "insert own assigned subdistrict" ON public.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "update own admin" ON public.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "update own assigned subdistrict" ON public.%I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "delete admin" ON public.%I;', t);

    -- อ่าน: ข้อมูลที่อนุมัติแล้วอ่านได้, เจ้าของข้อมูลอ่านของตัวเองได้, Admin อ่านได้ทั้งหมด
    EXECUTE format($p$
      CREATE POLICY "read approved own admin" ON public.%I
      FOR SELECT TO authenticated
      USING (
        (status = 'approved' AND EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.is_active = true
        ))
        OR created_by = auth.uid()
        OR public.is_admin()
      )
    $p$, t);

    -- เพิ่ม: ครูเพิ่มได้เฉพาะข้อมูลของตัวเองและตำบลที่รับผิดชอบ
    EXECUTE format($p$
      CREATE POLICY "insert own assigned subdistrict" ON public.%I
      FOR INSERT TO authenticated
      WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.is_active = true
        )
        AND (
          public.is_admin()
          OR subdistrict = COALESCE((
            SELECT p.subdistrict FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_active = true
          ), '')
        )
      )
    $p$, t);

    -- แก้ไข: เจ้าของข้อมูลแก้ได้ และ Admin แก้ได้ทั้งหมด
    EXECUTE format($p$
      CREATE POLICY "update own assigned subdistrict" ON public.%I
      FOR UPDATE TO authenticated
      USING (created_by = auth.uid() OR public.is_admin())
      WITH CHECK (
        public.is_admin()
        OR (
          created_by = auth.uid()
          AND subdistrict = COALESCE((
            SELECT p.subdistrict FROM public.profiles p
            WHERE p.id = auth.uid() AND p.is_active = true
          ), '')
        )
      )
    $p$, t);

    -- ลบ: Admin เท่านั้น
    EXECUTE format($p$
      CREATE POLICY "delete admin" ON public.%I
      FOR DELETE TO authenticated
      USING (public.is_admin())
    $p$, t);

    -- updated_at
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at ON public.%I;', t);
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();', t);

    -- ป้องกันครูเปลี่ยนเจ้าของข้อมูลหรืออนุมัติเอง
    EXECUTE format('DROP TRIGGER IF EXISTS protect_content_fields ON public.%I;', t);
    EXECUTE format('CREATE TRIGGER protect_content_fields BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.protect_content_fields();', t);
  END LOOP;
END $$;

-- Storage policy สำหรับรูปภาพ/เกียรติบัตรของข้อมูล
-- ใช้ bucket library-images และ library-documents เดิม ไม่สร้าง bucket ใหม่
DROP POLICY IF EXISTS "content_certificates_insert" ON storage.objects;
CREATE POLICY "content_certificates_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'library-documents'
  AND (name LIKE auth.uid()::text || '/certificates/%' OR public.is_admin())
);

DROP POLICY IF EXISTS "content_certificates_select" ON storage.objects;
CREATE POLICY "content_certificates_select"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'library-documents'
  AND (
    name LIKE auth.uid()::text || '/certificates/%'
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.library_files f
      WHERE f.storage_bucket = bucket_id
        AND f.storage_path = name
        AND f.status = 'approved'
    )
  )
);

-- ตรวจสอบโครงสร้างหลังรัน
SELECT
  t.table_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=t.table_name AND c.column_name='background_history'
  ) AS has_background_history,
  EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=t.table_name AND c.column_name='resource_history'
  ) AS has_resource_history,
  EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=t.table_name AND c.column_name='awards'
  ) AS has_awards,
  EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=t.table_name AND c.column_name='certificate_paths'
  ) AS has_certificate_paths
FROM (VALUES
  ('learning_resources'),
  ('local_wisdom'),
  ('local_scholars'),
  ('community_book_houses'),
  ('subdistrict_learning_centers'),
  ('tourist_attractions'),
  ('traditional_foods')
) AS t(table_name)
ORDER BY t.table_name;
