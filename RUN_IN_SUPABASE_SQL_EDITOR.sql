-- Paste this into Supabase Dashboard → SQL Editor → Run
-- Fixes: column shared_notes.note_type does not exist / personal_notes.drawing_data

alter table public.personal_notes
  add column if not exists note_type text not null default 'text'
    check (note_type in ('text', 'drawing')),
  add column if not exists drawing_data text not null default '';

alter table public.shared_notes
  add column if not exists note_type text not null default 'text'
    check (note_type in ('text', 'drawing')),
  add column if not exists drawing_data text not null default '';

-- After running: fully restart the app (not just hot reload).
