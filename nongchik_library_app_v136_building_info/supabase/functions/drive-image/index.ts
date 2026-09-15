import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Cache-Control": "public, max-age=86400, stale-while-revalidate=604800",
};

function json(message: string, status = 400) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...cors, "Content-Type": "application/json; charset=utf-8" },
  });
}

async function getAccessToken() {
  const refresh = Deno.env.get("GOOGLE_DRIVE_REFRESH_TOKEN");
  const clientId = Deno.env.get("GOOGLE_DRIVE_CLIENT_ID");
  const clientSecret = Deno.env.get("GOOGLE_DRIVE_CLIENT_SECRET");
  if (!refresh || !clientId || !clientSecret) throw new Error("Google Drive Secrets ยังไม่ครบ");

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
  if (!r.ok || !j.access_token) {
    throw new Error(`Google OAuth: ${j.error_description ?? j.error ?? "ขอ Access Token ไม่สำเร็จ"}`);
  }
  return String(j.access_token);
}

function sizedThumbnail(url: string, size: number) {
  // Google Drive thumbnail URLs commonly end in =s220 (or another size).
  // Ask Google for a moderate display size so Flutter Web does not decode
  // the original multi-megapixel file while scrolling.
  return url.replace(/=s\d+$/i, `=s${size}`);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "GET") return json("รองรับเฉพาะ GET", 405);

  try {
    const url = new URL(req.url);
    const fileId = (url.searchParams.get("file_id") ?? "").trim();
    const thumb = url.searchParams.get("thumb") === "1";
    const requestedSize = Number(url.searchParams.get("size") ?? "900");
    const size = Number.isFinite(requestedSize)
      ? Math.min(640, Math.max(320, Math.round(requestedSize)))
      : 900;

    if (!fileId || !/^[A-Za-z0-9_-]+$/.test(fileId)) {
      return json("ไม่พบ Google Drive File ID", 400);
    }

    const token = await getAccessToken();

    // For the normal page view, prefer Google's generated thumbnail.
    // It is dramatically smaller than downloading the original image.
    if (thumb) {
      const metaResponse = await fetch(
        `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?fields=thumbnailLink,mimeType&supportsAllDrives=true`,
        { headers: { Authorization: `Bearer ${token}` } },
      );
      const meta = await metaResponse.json().catch(() => ({}));
      const thumbnailLink = typeof meta.thumbnailLink === "string" ? meta.thumbnailLink : "";

      if (metaResponse.ok && thumbnailLink) {
        const thumbResponse = await fetch(sizedThumbnail(thumbnailLink, size), {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (thumbResponse.ok && thumbResponse.body) {
          return new Response(thumbResponse.body, {
            status: 200,
            headers: {
              ...cors,
              "Content-Type": thumbResponse.headers.get("content-type") || "image/jpeg",
            },
          });
        }
      }
    }

    // Never fall back to the original multi-megapixel file for a thumbnail request.
    // A full-size download during page scrolling can block Flutter Web rendering.
    if (thumb) {
      return json("ไม่สามารถสร้างภาพขนาดย่อจาก Google Drive ได้", 502);
    }

    // Full-size path is used only when the user opens an image.
    const r = await fetch(
      `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?alt=media&supportsAllDrives=true`,
      { headers: { Authorization: `Bearer ${token}` } },
    );

    if (!r.ok) {
      const text = await r.text().catch(() => "");
      return json(`Google Drive ${r.status}: ${text || "ไม่สามารถอ่านไฟล์ได้"}`, r.status >= 400 && r.status < 600 ? r.status : 502);
    }

    const contentType = r.headers.get("content-type") || "application/octet-stream";
    return new Response(r.body, {
      status: 200,
      headers: { ...cors, "Content-Type": contentType },
    });
  } catch (e) {
    console.error("drive-image error:", e);
    return json(e instanceof Error ? e.message : String(e), 500);
  }
});
