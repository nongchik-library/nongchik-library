import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s=200) => new Response(JSON.stringify(b), {status:s, headers:{...cors,"Content-Type":"application/json"}});

async function googleToken() {
  const body = new URLSearchParams({
    client_id: Deno.env.get("GOOGLE_DRIVE_CLIENT_ID")!,
    client_secret: Deno.env.get("GOOGLE_DRIVE_CLIENT_SECRET")!,
    refresh_token: Deno.env.get("GOOGLE_DRIVE_REFRESH_TOKEN")!,
    grant_type: "refresh_token",
  });
  const r = await fetch("https://oauth2.googleapis.com/token", {method:"POST",headers:{"Content-Type":"application/x-www-form-urlencoded"},body});
  const j = await r.json();
  if (!r.ok) throw new Error(j.error_description ?? j.error ?? "Google OAuth failed");
  return j.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", {headers:cors});
  try {
    const auth = req.headers.get("Authorization");
    if (!auth) return json({error:"กรุณาเข้าสู่ระบบ"},401);
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {global:{headers:{Authorization:auth}}});
    const {data:{user},error:userError} = await supabase.auth.getUser();
    if (userError || !user) return json({error:"เซสชันไม่ถูกต้อง"},401);
    const {data:profile} = await supabase.from("profiles").select("role,is_active").eq("id",user.id).maybeSingle();
    if (profile?.role !== "admin" || profile?.is_active === false) return json({error:"เฉพาะ Admin เท่านั้นที่สามารถลบไฟล์ได้"},403);
    const body = await req.json();
    const id = String(body.drive_file_id ?? "").trim();
    if (!id) throw new Error("ไม่พบ Google Drive File ID");
    const token = await googleToken();
    const r = await fetch(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(id)}`, {method:"DELETE",headers:{Authorization:`Bearer ${token}`}});
    if (!r.ok && r.status !== 404) { const j=await r.json().catch(()=>({})); throw new Error(j.error?.message ?? "ลบไฟล์จาก Google Drive ไม่สำเร็จ"); }
    return json({ok:true});
  } catch (e) { return json({error:e instanceof Error?e.message:String(e)},400); }
});
