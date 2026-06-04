-- Invoke send-shared-note-push Edge Function on every shared_notes UPDATE.
-- Requires: pg_net extension + deployed Edge Function (verify_jwt = false).

create extension if not exists pg_net with schema extensions;

create or replace function public.trigger_shared_note_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  request_id bigint;
begin
  if TG_OP <> 'UPDATE' then
    return NEW;
  end if;

  if NEW.updated_by is null then
    return NEW;
  end if;

  select net.http_post(
    url := 'https://shvmqegxbuoszpoizdut.supabase.co/functions/v1/send-shared-note-push',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object(
      'type', 'UPDATE',
      'table', 'shared_notes',
      'schema', 'public',
      'record', jsonb_build_object(
        'id', NEW.id,
        'friendship_id', NEW.friendship_id,
        'title', NEW.title,
        'body', NEW.body,
        'updated_by', NEW.updated_by,
        'updated_at', NEW.updated_at
      ),
      'old_record', jsonb_build_object(
        'id', OLD.id,
        'friendship_id', OLD.friendship_id,
        'title', OLD.title,
        'body', OLD.body,
        'updated_by', OLD.updated_by,
        'updated_at', OLD.updated_at
      )
    )
  ) into request_id;

  return NEW;
end;
$$;

drop trigger if exists shared_notes_push_trigger on public.shared_notes;
create trigger shared_notes_push_trigger
  after update on public.shared_notes
  for each row
  execute function public.trigger_shared_note_push();
