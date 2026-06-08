-- Handwriting / drawing support for personal and shared notes.

alter table public.personal_notes
  add column if not exists note_type text not null default 'text'
    check (note_type in ('text', 'drawing')),
  add column if not exists drawing_data text not null default '';

alter table public.shared_notes
  add column if not exists note_type text not null default 'text'
    check (note_type in ('text', 'drawing')),
  add column if not exists drawing_data text not null default '';
