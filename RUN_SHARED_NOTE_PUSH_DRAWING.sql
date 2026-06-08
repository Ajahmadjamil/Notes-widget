-- Run in Supabase SQL Editor, then deploy edge function:
--   supabase functions deploy send-shared-note-push

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
        'note_type', coalesce(NEW.note_type, 'text'),
        'drawing_data', coalesce(NEW.drawing_data, ''),
        'updated_by', NEW.updated_by,
        'updated_at', NEW.updated_at
      ),
      'old_record', jsonb_build_object(
        'id', OLD.id,
        'friendship_id', OLD.friendship_id,
        'title', OLD.title,
        'body', OLD.body,
        'note_type', coalesce(OLD.note_type, 'text'),
        'drawing_data', coalesce(OLD.drawing_data, ''),
        'updated_by', OLD.updated_by,
        'updated_at', OLD.updated_at
      )
    )
  ) into request_id;

  return NEW;
end;
$$;
