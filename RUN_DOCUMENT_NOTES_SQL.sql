-- Paste into Supabase SQL Editor if you prefer not to use migrations CLI.
-- Enables Document notes (text + images + audio) and note-media Storage bucket.

alter table public.personal_notes
  drop constraint if exists personal_notes_note_type_check;

alter table public.personal_notes
  add constraint personal_notes_note_type_check
  check (note_type in ('text', 'drawing', 'document'));

alter table public.personal_notes
  add column if not exists document_data text not null default '';

alter table public.shared_notes
  drop constraint if exists shared_notes_note_type_check;

alter table public.shared_notes
  add constraint shared_notes_note_type_check
  check (note_type in ('text', 'drawing', 'document'));

alter table public.shared_notes
  add column if not exists document_data text not null default '';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'note-media',
  'note-media',
  false,
  10485760,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'audio/mp4',
    'audio/m4a',
    'audio/aac',
    'audio/mpeg',
    'audio/x-m4a',
    'audio/wav',
    'audio/webm'
  ]
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "note_media_select_own" on storage.objects;
drop policy if exists "note_media_insert_own" on storage.objects;
drop policy if exists "note_media_update_own" on storage.objects;
drop policy if exists "note_media_delete_own" on storage.objects;

create policy "note_media_select_own"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "note_media_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "note_media_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "note_media_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
