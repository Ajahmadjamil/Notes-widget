-- Shared note media: friendship members can read/write under shared/{noteId}/

drop policy if exists "note_media_select_shared" on storage.objects;
drop policy if exists "note_media_insert_shared" on storage.objects;
drop policy if exists "note_media_update_shared" on storage.objects;
drop policy if exists "note_media_delete_shared" on storage.objects;

create policy "note_media_select_shared"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = 'shared'
    and exists (
      select 1
      from public.shared_notes sn
      join public.friendships f on f.id = sn.friendship_id
      where sn.id::text = (storage.foldername(name))[2]
        and f.status = 'accepted'
        and (f.user_id = auth.uid() or f.friend_id = auth.uid())
    )
  );

create policy "note_media_insert_shared"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = 'shared'
    and exists (
      select 1
      from public.shared_notes sn
      join public.friendships f on f.id = sn.friendship_id
      where sn.id::text = (storage.foldername(name))[2]
        and f.status = 'accepted'
        and (f.user_id = auth.uid() or f.friend_id = auth.uid())
    )
  );

create policy "note_media_update_shared"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = 'shared'
    and exists (
      select 1
      from public.shared_notes sn
      join public.friendships f on f.id = sn.friendship_id
      where sn.id::text = (storage.foldername(name))[2]
        and f.status = 'accepted'
        and (f.user_id = auth.uid() or f.friend_id = auth.uid())
    )
  )
  with check (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = 'shared'
    and exists (
      select 1
      from public.shared_notes sn
      join public.friendships f on f.id = sn.friendship_id
      where sn.id::text = (storage.foldername(name))[2]
        and f.status = 'accepted'
        and (f.user_id = auth.uid() or f.friend_id = auth.uid())
    )
  );

create policy "note_media_delete_shared"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'note-media'
    and (storage.foldername(name))[1] = 'shared'
    and exists (
      select 1
      from public.shared_notes sn
      join public.friendships f on f.id = sn.friendship_id
      where sn.id::text = (storage.foldername(name))[2]
        and f.status = 'accepted'
        and (f.user_id = auth.uid() or f.friend_id = auth.uid())
    )
  );
