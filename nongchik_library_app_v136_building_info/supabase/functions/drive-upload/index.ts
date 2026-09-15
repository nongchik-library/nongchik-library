import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

function decodeBase64(input: string): Uint8Array {
  const bin = atob(input);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function driveGet(token: string, url: string) {
  const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) {
    throw new Error(`Google Drive ${r.status}: ${j.error?.message ?? "เรียก Google Drive ไม่สำเร็จ"}`);
  }
  return j;
}

async function accessToken() {
  const refresh = Deno.env.get("GOOGLE_DRIVE_REFRESH_TOKEN");
  const clientId = Deno.env.get("GOOGLE_DRIVE_CLIENT_ID");
  const clientSecret = Deno.env.get("GOOGLE_DRIVE_CLIENT_SECRET");
  if (!refresh || !clientId || !clientSecret) {
    throw new Error("ยังไม่ได้ตั้งค่า Google Drive Secrets ใน Supabase");
  }
  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    refresh_token: refresh,
    grant_type: "refresh_token",
  });
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) {
    throw new Error(`Google OAuth: ${j.error_description ?? j.error ?? "ขอ Access Token ไม่สำเร็จ"}`);
  }
  if (!j.access_token) throw new Error("Google OAuth: ไม่ได้รับ Access Token");
  return j.access_token as string;
}


async function ensureFolder(token: string, name: string, parentId?: string) {
  const rootId = parentId || Deno.env.get("GOOGLE_DRIVE_ROOT_FOLDER_ID");
  if (!rootId) throw new Error("ยังไม่ได้ตั้งค่า GOOGLE_DRIVE_ROOT_FOLDER_ID");

  // Verify the exact root first.
  try {
    await driveGet(
      token,
      `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(rootId)}?fields=id,name,mimeType,trashed,owners(emailAddress,displayName)&supportsAllDrives=true`,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    throw new Error(`เข้าถึงโฟลเดอร์หลักไม่ได้ [Google Drive Root: ${rootId}] — ${message}`);
  }

  // Support paths such as "เกาะเปาะ/ภาพแหล่งเรียนรู้". Each segment is
  // resolved/created under the previous segment, so every subdistrict gets
  // its own Drive branch while preserving the existing folder names.
  const parts = name
    .split('/')
    .map((v) => v.trim())
    .filter((v) => v.length > 0);
  if (!parts.length) return rootId;

  let parent = rootId;
  for (const part of parts) {
    const q = `name = '${part.replaceAll("'", "\\'")}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false and '${parent}' in parents`;
    const search = await fetch(
      `https://www.googleapis.com/drive/v3/files?q=${encodeURIComponent(q)}&fields=files(id,name)&pageSize=1&supportsAllDrives=true&includeItemsFromAllDrives=true`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    const s = await search.json().catch(() => ({}));
    if (!search.ok) {
      throw new Error(`Google Drive ${search.status}: ${s.error?.message ?? "ค้นหาโฟลเดอร์ไม่สำเร็จ"}`);
    }
    if (s.files?.length) {
      parent = s.files[0].id as string;
      continue;
    }

    const create = await fetch(
      "https://www.googleapis.com/drive/v3/files?fields=id,name&supportsAllDrives=true",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({ name: part, mimeType: "application/vnd.google-apps.folder", parents: [parent] }),
      },
    );
    const c = await create.json().catch(() => ({}));
    if (!create.ok) {
      throw new Error(`สร้างโฟลเดอร์ Google Drive ไม่สำเร็จ (${create.status}): ${c.error?.message ?? "unknown"}`);
    }
    parent = c.id as string;
  }
  return parent;
}

async function makePublicWithRetry(token: string, fileId: string) {
  let lastError: unknown;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      await makePublic(token, fileId);
      return;
    } catch (e) {
      lastError = e;
      if (attempt < 2) {
        await new Promise((resolve) => setTimeout(resolve, 700 * (attempt + 1)));
      }
    }
  }
  throw lastError instanceof Error ? lastError : new Error(String(lastError));
}

async function makePublic(token: string, fileId: string) {
  const r = await fetch(`https://www.googleapis.com/drive/v3/files/${fileId}/permissions`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ type: "anyone", role: "reader" }),
  });
  if (!r.ok) {
    const j = await r.json().catch(() => ({}));
    throw new Error(`ตั้งสิทธิ์ไฟล์ไม่สำเร็จ (${r.status}): ${j.error?.message ?? "unknown"}`);
  }
}

async function verifySupabaseUser(req: Request) {
  const auth = req.headers.get("Authorization") || "";
  const jwt = auth.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) throw new Error("กรุณาเข้าสู่ระบบ");

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) throw new Error("Supabase Edge Function ยังไม่ได้ตั้งค่าระบบฐานข้อมูล");

  const r = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${jwt}`,
    },
  });
  const user = await r.json().catch(() => ({}));
  if (!r.ok || !user?.id) {
    throw new Error("เซสชันผู้ใช้ไม่ถูกต้องหรือหมดอายุ กรุณาเข้าสู่ระบบใหม่");
  }
  return { userId: String(user.id), supabaseUrl, serviceKey };
}

async function saveLibraryRow(args: {
  supabaseUrl: string;
  serviceKey: string;
  userId: string;
  title: string;
  description: string;
  fileName: string;
  fileType: string;
  category: string;
  subdistrict?: string | null;
  folderName: string;
  mimeType: string;
  fileSize: number;
  driveFileId: string;
  driveWebUrl: string;
}) {
  const r = await fetch(`${args.supabaseUrl}/rest/v1/library_files`, {
    method: "POST",
    headers: {
      apikey: args.serviceKey,
      Authorization: `Bearer ${args.serviceKey}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
    },
    body: JSON.stringify({
      title: args.title.trim() || args.fileName,
      description: args.description.trim(),
      file_name: args.fileName,
      file_type: args.fileType,
      category: args.category,
      subdistrict: args.subdistrict || null,
      folder_name: args.folderName,
      storage_provider: "google_drive",
      drive_file_id: args.driveFileId,
      drive_web_url: args.driveWebUrl,
      storage_bucket: "google_drive",
      storage_path: args.driveFileId,
      mime_type: args.mimeType,
      file_size: args.fileSize,
      uploaded_by: args.userId,
      status: "pending",
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) {
    throw new Error(`บันทึก library_files ไม่สำเร็จ (${r.status}): ${j?.message ?? j?.details ?? j?.hint ?? "unknown"}`);
  }
  return Array.isArray(j) && j.length ? j[0] : j;
}

async function deleteDriveFile(token: string, fileId: string) {
  try {
    const r = await fetch(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?supportsAllDrives=true`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!r.ok && r.status !== 404) {
      console.warn(`Rollback Drive file failed (${r.status})`);
    }
  } catch (e) {
    console.warn("Rollback Drive file failed:", e);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { userId, supabaseUrl, serviceKey } = await verifySupabaseUser(req);
    const token = await accessToken();
    const body = await req.json();
    const rawBase64 = String(body.content_base64 ?? "");
    if (!rawBase64) throw new Error("ไม่พบข้อมูลไฟล์ (content_base64)");

    const bytes = decodeBase64(rawBase64);
    if (!bytes.length) throw new Error("ไม่พบข้อมูลไฟล์");
    if (bytes.length > 25 * 1024 * 1024) {
      throw new Error("ไฟล์ใหญ่เกิน 25 MB สำหรับการอัปโหลดผ่านเว็บรุ่นนี้");
    }

    const folderName = String(body.folder_name ?? "ทั่วไป").trim() || "ทั่วไป";
    let folderId: string;
    try {
      // The Flutter library folder_id is a Supabase UUID, not a Google Drive folder ID.
      // Always resolve the Google Drive folder by name under the configured Drive root.
      folderId = await ensureFolder(token, folderName);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      throw new Error(`Google Drive folder error: ${message}`);
    }
    const metadata = {
      name: String(body.file_name ?? "file"),
      mimeType: String(body.mime_type ?? "application/octet-stream"),
      parents: [folderId],
    };

    const boundary = `drive_v73_${crypto.randomUUID()}`;
    const head = new TextEncoder().encode(
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(metadata)}\r\n--${boundary}\r\nContent-Type: ${metadata.mimeType}\r\n\r\n`,
    );
    const tail = new TextEncoder().encode(`\r\n--${boundary}--`);
    const multipart = new Uint8Array(head.length + bytes.length + tail.length);
    multipart.set(head, 0);
    multipart.set(bytes, head.length);
    multipart.set(tail, head.length + bytes.length);

    const upload = await fetch(
      "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,mimeType,webViewLink&supportsAllDrives=true",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": `multipart/related; boundary=${boundary}`,
        },
        body: multipart,
      },
    );
    const file = await upload.json().catch(() => ({}));
    if (!upload.ok) {
      throw new Error(`Google Drive Upload ${upload.status}: ${file.error?.message ?? "อัปโหลดไม่สำเร็จ"}`);
    }

    // Public permission is best-effort. The file is already safely uploaded to
    // Drive; transient permission/rate-limit errors must not make the upload fail.
    let publicWarning: string | null = null;
    try {
      await makePublicWithRetry(token, file.id);
    } catch (e) {
      publicWarning = e instanceof Error ? e.message : String(e);
      console.warn("Drive public permission warning:", publicWarning);
    }

    const webViewUrl = `https://drive.google.com/file/d/${file.id}/view`;
    try {
      const row = await saveLibraryRow({
        supabaseUrl,
        serviceKey,
        userId,
        title: String(body.title ?? file.name),
        description: String(body.description ?? ""),
        fileName: String(body.file_name ?? file.name),
        fileType: String(body.file_type ?? "document"),
        category: String(body.category ?? "other"),
        subdistrict: body.subdistrict == null ? null : String(body.subdistrict),
        folderName,
        mimeType: String(body.mime_type ?? file.mimeType ?? "application/octet-stream"),
        fileSize: Number(body.file_size ?? 0),
        driveFileId: String(file.id),
        driveWebUrl: webViewUrl,
      });
      return json({
        id: file.id,
        name: file.name,
        mime_type: file.mimeType,
        web_view_url: webViewUrl,
        view_url: `https://drive.google.com/uc?export=view&id=${file.id}`,
        download_url: `https://drive.google.com/uc?export=download&id=${file.id}`,
        folder_id: folderId,
        public_warning: publicWarning,
        library_file: row,
      });
    } catch (e) {
      // Keep Drive and Supabase consistent: if the DB row cannot be created,
      // remove the newly-created Drive file rather than leaving an orphan.
      await deleteDriveFile(token, String(file.id));
      throw e;
    }
  } catch (e) {
    console.error("drive-upload error:", e);
    return json({ error: e instanceof Error ? e.message : String(e) }, 400);
  }
});
