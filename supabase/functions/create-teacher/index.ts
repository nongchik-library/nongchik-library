import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return json({ error: "ไม่ได้รับสิทธิ์เข้าสู่ระบบ" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "เซิร์ฟเวอร์ยังไม่ได้ตั้งค่า Supabase" }, 500);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ตรวจสอบว่าผู้เรียกเป็น Admin จริงก่อนสร้างบัญชีใหม่
    const { data: userData, error: userError } = await adminClient.auth.getUser(token);
    if (userError || !userData.user) return json({ error: "เซสชันไม่ถูกต้องหรือหมดอายุ" }, 401);

    const { data: caller, error: callerError } = await adminClient
      .from("profiles")
      .select("role,is_active")
      .eq("id", userData.user.id)
      .maybeSingle();

    if (callerError || caller?.role !== "admin" || caller?.is_active !== true) {
      return json({ error: "เฉพาะ Admin เท่านั้นที่สามารถเพิ่มคุณครูได้" }, 403);
    }

    const body = await req.json();
    const displayName = String(body.display_name ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const phone = String(body.phone ?? "").trim();
    const subdistrict = String(body.subdistrict ?? "").trim();
    const password = String(body.password ?? "");

    if (!displayName) return json({ error: "กรุณาระบุชื่อผู้ใช้งาน" }, 400);
    if (!email || !email.includes("@")) return json({ error: "กรุณาระบุอีเมลให้ถูกต้อง" }, 400);
    if (password.length < 6) return json({ error: "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร" }, 400);

    const { data: created, error: createError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: displayName },
    });

    if (createError || !created.user) {
      const message = createError?.message ?? "สร้างบัญชีไม่สำเร็จ";
      return json({ error: message }, createError?.status ?? 400);
    }

    const newUserId = created.user.id;
    const { error: profileError } = await adminClient.from("profiles").upsert({
      id: newUserId,
      role: "teacher",
      display_name: displayName,
      email,
      phone,
      subdistrict,
      is_active: true,
    });

    if (profileError) {
      // ไม่ปล่อยบัญชีค้างถ้าสร้าง profile ไม่สำเร็จ
      await adminClient.auth.admin.deleteUser(newUserId);
      return json({ error: `สร้างข้อมูลผู้ใช้งานไม่สำเร็จ: ${profileError.message}` }, 500);
    }

    return json({
      success: true,
      message: "เพิ่มคุณครูเรียบร้อยแล้ว",
      user: { id: newUserId, email, display_name: displayName, subdistrict },
    });
  } catch (error) {
    console.error(error);
    return json({ error: "เกิดข้อผิดพลาดในการสร้างบัญชี" }, 500);
  }
});
