-- V137: เพิ่มข้อมูลบุคคล/กระบวนการเรียนรู้สำหรับเมนู 1-4, 6-7
-- และเพิ่มข้อมูลอาคาร/เวลาเปิดทำการ/สิ่งอำนวยความสะดวก/ครุภัณฑ์สำหรับทุกเมนู
-- ใช้ ADD COLUMN IF NOT EXISTS เพื่อไม่ลบหรือกระทบข้อมูลเดิม

ALTER TABLE public.learning_resources
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.local_wisdom
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.local_scholars
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.community_book_houses
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.tourist_attractions
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.traditional_foods
    ADD COLUMN IF NOT EXISTS gender text,
    ADD COLUMN IF NOT EXISTS birth_date text,
    ADD COLUMN IF NOT EXISTS education_level text,
    ADD COLUMN IF NOT EXISTS current_occupation text,
    ADD COLUMN IF NOT EXISTS responsible_teacher text,
    ADD COLUMN IF NOT EXISTS learning_process text;


ALTER TABLE public.learning_resources
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.local_wisdom
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.local_scholars
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.community_book_houses
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.subdistrict_learning_centers
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.tourist_attractions
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


ALTER TABLE public.traditional_foods
    ADD COLUMN IF NOT EXISTS building_use text,
    ADD COLUMN IF NOT EXISTS permission_case text,
    ADD COLUMN IF NOT EXISTS independence text,
    ADD COLUMN IF NOT EXISTS weekday_hours text,
    ADD COLUMN IF NOT EXISTS weekend_hours text,
    ADD COLUMN IF NOT EXISTS opening_days text,
    ADD COLUMN IF NOT EXISTS internet text,
    ADD COLUMN IF NOT EXISTS water_supply text,
    ADD COLUMN IF NOT EXISTS electricity text,
    ADD COLUMN IF NOT EXISTS toilet text,
    ADD COLUMN IF NOT EXISTS notebook text,
    ADD COLUMN IF NOT EXISTS desktop text,
    ADD COLUMN IF NOT EXISTS tv text,
    ADD COLUMN IF NOT EXISTS tablet text,
    ADD COLUMN IF NOT EXISTS projector text,
    ADD COLUMN IF NOT EXISTS tables text,
    ADD COLUMN IF NOT EXISTS chairs text;


NOTIFY pgrst, 'reload schema';
