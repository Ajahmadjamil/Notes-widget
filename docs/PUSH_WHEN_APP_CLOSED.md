# Push + widget sync when the app is closed

Yes — this uses a **Supabase Edge Function** + **FCM**. The app does not need to be open.

## Flow

```
Device A saves shared note
    → Postgres UPDATE on shared_notes
    → DB trigger (pg_net) calls Edge Function send-shared-note-push
    → Edge Function reads Device B's fcm_token from profiles
    → FCM HTTP v1 sends push to Device B
    → Android runs firebaseMessagingBackgroundHandler (Dart isolate)
    → WidgetPushHandler updates SharedPreferences + refreshes home widget
    → User sees notification + updated widget (without opening app)
```

## Already configured on your project

| Piece | Status |
|-------|--------|
| Edge Function `send-shared-note-push` | Deployed (`verify_jwt: false`) |
| DB trigger `shared_notes_push_trigger` | Applied (calls Edge Function on UPDATE) |
| Flutter background FCM handler | Updates widget from payload (no Supabase network) |

## You must complete: FCM secrets (one-time)

The Edge Function cannot send push until these secrets exist.

### 1. Firebase / GCP service account

1. [Google Cloud Console](https://console.cloud.google.com/) → project **noteswidget-debc2** (or your FCM project).
2. **APIs & Services → Enable** → **Firebase Cloud Messaging API**.
3. **IAM → Service accounts → Create** (or use Firebase Admin SDK account).
4. Create key **JSON** → download.

From the JSON file:

- `project_id` → `FCM_PROJECT_ID`
- `client_email` → `FCM_CLIENT_EMAIL`
- `private_key` → `FCM_PRIVATE_KEY`

### 2. Download service account JSON

**Firebase Console** (fastest):

1. [Firebase Console](https://console.firebase.google.com/) → project **noteswidget-debc2**
2. ⚙️ **Project settings** → **Service accounts**
3. **Generate new private key** → save as e.g. `C:\Users\You\Downloads\noteswidget-debc2-firebase-adminsdk.json`

**Google Cloud** (same key):

1. [Google Cloud Console](https://console.cloud.google.com/) → project **noteswidget-debc2**
2. **APIs & Services → Library** → enable **Firebase Cloud Messaging API**
3. **IAM & Admin → Service accounts** → Firebase Admin SDK account → **Keys → Add key → JSON**

### 3. Set Supabase secrets (automated script)

```powershell
cd d:\flutter\noteswidgetapp
supabase login
supabase link --project-ref shvmqegxbuoszpoizdut

.\scripts\set_fcm_secrets.ps1 -ServiceAccountPath "C:\Users\You\Downloads\noteswidget-debc2-firebase-adminsdk.json"
```

Or manually:

```powershell
supabase secrets set FCM_PROJECT_ID=noteswidget-debc2
supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@noteswidget-debc2.iam.gserviceaccount.com
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
```

**Never commit the JSON file** — it is gitignored.

After setting secrets, Edge Function logs should show `{"ok":true}` instead of `FCM secrets not set — skip push`.

### 3. Verify tokens on both phones

Supabase → **Table Editor → profiles** → each user must have **fcm_token** filled.

- Open app once per device, allow notifications, sign in.
- Check logs: `FCM token saved for <uuid>`.

## Test (app fully closed)

1. Both devices: sign in, allow notifications, pin widget, **Show on widget** for same friend.
2. Device B: swipe app away from recents (force stop optional).
3. Device A: edit shared note, wait for save.
4. Device B should get a **notification** and **widget text updates** without opening the app.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No notification | Set FCM secrets; check Edge Function logs in Supabase Dashboard |
| Notification but widget stale | Re-pin widget; ensure **Show on widget** was used on Device B |
| `no fcm token` in function logs | Open Device B app once after sign-in |
| Works in app only | Trigger/FCM not firing — check `shared_notes_push_trigger` exists |

### Edge Function logs

Supabase Dashboard → **Edge Functions → send-shared-note-push → Logs**

Look for `ok`, `skipped: no fcm token`, or `FCM secrets not set`.

### OEM battery limits

On Xiaomi/Samsung/Huawei: disable battery optimization for **Notes Widget** and allow autostart, or FCM may be delayed.
