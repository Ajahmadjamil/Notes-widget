/**
 * Shared note push: visible notification + widget sync data.
 *
 *   cd functions && npm install && firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const WIDGET_SYNC_TYPE = "widget_sync";
const ANDROID_CHANNEL_ID = "notes_shared_note_updates";

async function editorDisplayName(uid) {
  if (!uid) return "";
  const snap = await admin.database().ref(`users/${uid}`).once("value");
  const u = snap.val();
  if (!u) return "";
  return u.username || u.displayName || "Friend";
}

function previewBody(text) {
  const preview = (text || "").trim();
  if (!preview) return "Your friend updated the shared note";
  return preview.length > 80 ? `${preview.substring(0, 80)}…` : preview;
}

async function sendSharedNotePush(recipientUid, editorUid, payload) {
  if (!recipientUid || recipientUid === editorUid) return;

  const snap = await admin.database().ref(`users/${recipientUid}/fcmToken`).once("value");
  const token = snap.val();
  if (!token) {
    console.log(`No FCM token for ${recipientUid}`);
    return;
  }

  const friendLabel = await editorDisplayName(editorUid);
  const body = previewBody(payload.body);
  const title = `${friendLabel} updated your shared note`;

  await admin.messaging().send({
    token,
    notification: {
      title,
      body,
    },
    data: {
      type: WIDGET_SYNC_TYPE,
      sharedNoteId: String(payload.sharedNoteId),
      title: String(payload.title || "Shared note"),
      body: String(payload.body || ""),
      updatedAt: String(payload.updatedAt || Date.now()),
      friendLabel: String(friendLabel),
      notificationTitle: title,
      notificationBody: body,
    },
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        priority: "high",
        visibility: "public",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
        },
      },
    },
  });
}

exports.onSharedNoteWrite = functions.database
  .ref("/sharedNotes/{noteId}")
  .onWrite(async (change, context) => {
    const after = change.after.val();
    if (!after) return null;

    const { user1, user2, title, body, updatedAt, sharedNoteId, updatedBy } = after;
    const noteId = sharedNoteId || context.params.noteId;

    const payload = {
      sharedNoteId: String(noteId),
      title: String(title || "Shared note"),
      body: String(body || ""),
      updatedAt: String(updatedAt || Date.now()),
    };

    const tasks = [];
    if (user1) tasks.push(sendSharedNotePush(user1, updatedBy, payload));
    if (user2 && user2 !== user1) {
      tasks.push(sendSharedNotePush(user2, updatedBy, payload);
    }

    await Promise.all(tasks);
    return null;
  });
