# Supabase setup — Notes Widget App

This replaces Firebase Auth, RTDB, and Cloud Functions. **FCM stays free** for Android push; only the *sender* moves to a Supabase Edge Function.

## 1. Create project

1. [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**
2. Copy from **Settings → API**:
   - Project URL
   - **anon** `public` key (Flutter app)
   - **service_role** key (server/CLI only — never commit)

## 2. Apply database schema

**Option A — SQL Editor (fastest)**

1. Dashboard → **SQL Editor** → New query
2. Paste entire file: `supabase/migrations/20250604120000_initial_schema.sql`
3. **Run**

**Option B — Supabase CLI**

```powershell
# Install: scoop install supabase  OR  npm i -g supabase
supabase login
cd d:\flutter\noteswidgetapp
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

## 3. Auth providers

| Provider | Dashboard path |
|----------|----------------|
| Email | Authentication → Providers → Email |
| Google | Authentication → Providers → Google (same OAuth client as before; add Android SHA-1 in Google Cloud) |

Redirect URL for mobile: follow [Supabase Flutter Google auth](https://supabase.com/docs/guides/auth/social-login/auth-google?platform=flutter).

## 4. Realtime

Migration already runs:

```sql
alter publication supabase_realtime add table public.shared_notes;
alter publication supabase_realtime add table public.friendships;
```

Verify: **Database → Replication** → `shared_notes` and `friendships` enabled.

## 5. Edge Function + webhook (widget push)

### Deploy function

```powershell
cd d:\flutter\noteswidgetapp
supabase functions deploy send-shared-note-push --no-verify-jwt
```

Set secrets (FCM HTTP v1 — from a **Firebase/GCP service account** with *Firebase Cloud Messaging API*; you do **not** need Blaze or RTDB):

```powershell
supabase secrets set FCM_PROJECT_ID=your-gcp-project-id
supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-...@....iam.gserviceaccount.com
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically in Edge Functions.

### Database webhook (required for push + background widget sync)

**Without this webhook, updates only sync while the app is open.**

Dashboard → **Database → Webhooks → Create**:

| Field | Value |
|-------|--------|
| Name | `shared_note_push` |
| Table | `shared_notes` |
| Events | **Update** |
| Method | POST |
| URL | `https://YOUR_REF.supabase.co/functions/v1/send-shared-note-push` |
| Headers | `Authorization: Bearer YOUR_SERVICE_ROLE_KEY` |

## 6. Give Cursor access (pick one)

### A — Supabase MCP (recommended)

1. Cursor → **Settings → MCP** → enable [Supabase MCP](https://supabase.com/docs/guides/getting-started/mcp)
2. Create **Personal Access Token**: Supabase → Account → Access Tokens
3. Configure MCP with token + project ref
4. Chat: *“Apply `supabase/migrations/20250604120000_initial_schema.sql` and deploy `send-shared-note-push`.”*

### B — Supabase CLI + terminal

After `supabase login` and `supabase link`, Cursor can run `supabase db push` and `supabase functions deploy` in your terminal.

### C — Manual SQL only

Paste migration into SQL Editor yourself; Cursor only edits Flutter code.

**Never** put `service_role` or DB password in git. Use `.env` locally (see `.env.example`).

## 7. Flutter config (next step)

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```

```powershell
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Dependencies: remove `firebase_core`, `firebase_auth`, `firebase_database`; add `supabase_flutter`. Keep `firebase_messaging` for receiving FCM on device.

## 8. Schema vs old Firebase

| Old (RTDB) | New (Postgres) |
|------------|----------------|
| `/users/{uid}` | `profiles` |
| `/usernames`, `/emails` base64 | `profiles.username`, `profiles.email` UNIQUE |
| `/friendRequests/{to}/{from}` | `friendships` `status = pending` |
| `/friends/{uid}/{friendUid}` | `friendships` `status = accepted` |
| `/sharedNotes/{smaller}_{larger}` | `shared_notes.id` (UUID) + `friendship_id` |
| `/notes/{uid}/{id}` | `personal_notes` |
| `fcmToken` on user | `profiles.fcm_token` |
| Cloud Function | `send-shared-note-push` Edge Function |

**Widget/deep links:** `sharedNoteId` becomes the UUID from `shared_notes.id` (not the old pair string).

**Data migration:** Firebase Auth UIDs ≠ Supabase UUIDs. Easiest path: new sign-ups and re-friend. Importing old RTDB rows requires a one-off script with UID mapping.

## 9. Cursor migration prompt

Paste into Composer when schema is applied:

```text
Migrate d:\flutter\noteswidgetapp from Firebase to Supabase per SUPABASE_SETUP.md.

1. pubspec: remove firebase_core, firebase_auth, firebase_database; add supabase_flutter; keep firebase_messaging.
2. Add lib/core/supabase/ init with dart-define SUPABASE_URL and SUPABASE_ANON_KEY.
3. Rewrite UserProfileRepository, FriendsRepository, SharedNoteRepository, NotesFirebaseDataSource using supabase_flutter.
4. Use friendships + shared_notes UUIDs; rpc accept_friend_request; search_profile for user lookup.
5. Realtime: supabase.from('shared_notes').stream(primaryKey: ['id']) filtered by friendship.
6. notification.dart: save fcm_token to profiles.fcm_token.
7. WidgetPushHandler: sharedNoteId = shared_notes.id UUID.
8. Remove lib/core/firebase/, firebase_options.dart, functions/ when done.

Preserve: Android widget, WidgetSyncPolicy, editor load-then-watch fixes, MyFriends StatefulWidget pattern.
```
