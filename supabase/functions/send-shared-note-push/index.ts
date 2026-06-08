/**
 * Supabase Edge Function — FCM push when a shared note is updated.
 *
 * Trigger: Database Webhook on public.shared_notes UPDATE
 *   URL: https://<project-ref>.supabase.co/functions/v1/send-shared-note-push
 *   Headers: Authorization: Bearer <SERVICE_ROLE_KEY>
 *
 * Secrets (supabase secrets set):
 *   FCM_PROJECT_ID
 *   FCM_CLIENT_EMAIL
 *   FCM_PRIVATE_KEY   (JSON service account private key, newlines as \n)
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const WIDGET_SYNC_TYPE = "widget_sync";
const MAX_FCM_DRAWING_CHARS = 3500;

type WebhookPayload = {
  type: "UPDATE";
  table: string;
  schema: string;
  record: SharedNoteRow;
  old_record: SharedNoteRow;
};

type SharedNoteRow = {
  id: string;
  friendship_id: string;
  title: string;
  body: string;
  note_type?: string | null;
  drawing_data?: string | null;
  updated_by: string | null;
  updated_at: string;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const payload = (await req.json()) as WebhookPayload;
  if (payload.table !== "shared_notes" || payload.type !== "UPDATE") {
    return new Response(JSON.stringify({ skipped: true }), { status: 200 });
  }

  const note = payload.record;
  const editorId = note.updated_by;
  if (!editorId) {
    return new Response(JSON.stringify({ skipped: "no editor" }), { status: 200 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: friendship, error: fErr } = await supabase
    .from("friendships")
    .select("user_id, friend_id")
    .eq("id", note.friendship_id)
    .eq("status", "accepted")
    .single();

  if (fErr || !friendship) {
    return new Response(JSON.stringify({ error: fErr?.message }), { status: 500 });
  }

  const recipientId =
    friendship.user_id === editorId ? friendship.friend_id : friendship.user_id;

  if (recipientId === editorId) {
    return new Response(JSON.stringify({ skipped: "self" }), { status: 200 });
  }

  const { data: recipient } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", recipientId)
    .single();

  const token = recipient?.fcm_token;
  if (!token) {
    return new Response(JSON.stringify({ skipped: "no fcm token" }), { status: 200 });
  }

  const { data: editor } = await supabase
    .from("profiles")
    .select("username, display_name")
    .eq("id", editorId)
    .single();

  const friendLabel =
    editor?.username ?? editor?.display_name ?? "Friend";

  const noteType = note.note_type === "drawing" ? "drawing" : "text";
  const drawingData = note.drawing_data ?? "";

  let notificationBody: string;
  if (noteType === "drawing") {
    const noteTitle = (note.title ?? "").trim();
    notificationBody =
      noteTitle && noteTitle !== "Shared note"
        ? `${noteTitle} (handwriting updated)`
        : "Handwritten note updated";
  } else {
    const preview = (note.body ?? "").trim();
    if (preview) {
      notificationBody =
        preview.length > 80 ? `${preview.substring(0, 80)}…` : preview;
    } else {
      const noteTitle = (note.title ?? "").trim();
      notificationBody =
        noteTitle && noteTitle !== "Shared note"
          ? noteTitle
          : "Your friend updated the shared note";
    }
  }

  const notificationTitle = `${friendLabel} updated your shared note`;
  const updatedAt = Date.parse(note.updated_at) || Date.now();

  const widgetBody =
    noteType === "drawing"
      ? ""
      : (note.body ?? "").trim();

  const dataPayload: Record<string, string> = {
    type: WIDGET_SYNC_TYPE,
    sharedNoteId: note.id,
    title: note.title ?? "Shared note",
    body: widgetBody,
    noteType,
    updatedAt: String(updatedAt),
    friendLabel,
    notificationTitle,
    notificationBody,
  };

  if (
    noteType === "drawing" &&
    drawingData.length > 0 &&
    drawingData.length <= MAX_FCM_DRAWING_CHARS
  ) {
    dataPayload.drawingData = drawingData;
  }

  try {
    await sendFcm(token, dataPayload);
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    console.error("sendFcm failed:", e);
    return new Response(
      JSON.stringify({ skipped: String(e) }),
      { status: 200 },
    );
  }
});

async function sendFcm(
  token: string,
  data: Record<string, string>,
): Promise<void> {
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY")?.replace(/\\n/g, "\n");

  if (!projectId || !clientEmail || !privateKey) {
    console.log("FCM secrets not set — skip push");
    return;
  }

  const accessToken = await getGoogleAccessToken(clientEmail, privateKey);
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          data,
          android: {
            priority: "HIGH",
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: {
              aps: {
                "content-available": 1,
              },
            },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`FCM error ${res.status}: ${text}`);
  }
}

async function getGoogleAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = btoa(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(sig))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const json = await tokenRes.json();
  if (!json.access_token) {
    throw new Error(`OAuth token failed: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
  return buf.buffer;
}

function base64UrlEncode(bytes: Uint8Array): string {
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
