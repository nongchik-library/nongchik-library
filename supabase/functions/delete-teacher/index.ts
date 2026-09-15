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

    const { data: authData, error: authError } = await adminClient.auth.getUser(token);
    if (authError || !authData.user) return json({ error: "เซสชันไม่ถูกต้องหรือหมดอายุ" }, 401);

    const { data: caller, error: callerError } = await adminClient
      .from("profiles")
      .select("role,is_active")
      .eq("id", authData.user.id)
      .maybeSingle();

    if (callerError || caller?.role !== "admin" || caller?.is_active !== true) {
      return json({ error: "เฉพาะ Admin เท่านั้นที่สามารถลบคุณครูได้" }, 403);
    }

    const body = await req.json();
    const targetId = String(body.user_id ?? "").trim();
    if (!targetId) return json({ error: "ไม่พบรหัสผู้ใช้งานที่ต้องการลบ" }, 400);
    if (targetId === authData.user.id) return json({ error: "ไม่สามารถลบบัญชี Admin ที่กำลังใช้งานอยู่ได้" }, 400);

    const { data: target, error: targetError } = await adminClient
      .from("profiles")
      .select("id,role,display_name,email")
      .eq("id", targetId)
      .maybeSingle();

    if (targetError) return json({ error: targetError.message }, 500);
    if (!target) return json({ error: "ไม่พบผู้ใช้งานนี้" }, 404);
    if (target.role === "admin") return json({ error: "ไม่อนุญาตให้ลบบัญชี Admin จากหน้านี้" }, 403);

    // ลบบัญชี Authentication; profiles และข้อมูลที่อ้างอิง auth.users จะถูกจัดการตาม FK ON DELETE CASCADE
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetId);
    if (deleteError) return json({ error: deleteError.message }, deleteError.status ?? 400);

    return json({
      success: true,
      message: "ลบคุณครูเรียบร้อยแล้ว",
      user: {
        id: target.id,
        email: target.email,
        display_name: target.display_name,
      },
    });
  } catch (error) {
    console.error(error);
    return json({ error: "เกิดข้อผิดพลาดในการลบคุณครู" }, 500);
  }
});
