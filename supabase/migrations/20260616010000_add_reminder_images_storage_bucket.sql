-- supabase/migrations/20260616010000_add_reminder_images_storage_bucket.sql
-- Private Storage bucket for reminder photos. Each user's images live under a folder named with
-- their auth.uid(); RLS on storage.objects isolates them. Path convention: "<uid>/<reminder-id>.jpg".
insert into storage.buckets (id, name, public)
values ('reminder-images', 'reminder-images', false)
on conflict (id) do nothing;

drop policy if exists "recall reminder images select own" on storage.objects;
drop policy if exists "recall reminder images insert own" on storage.objects;
drop policy if exists "recall reminder images update own" on storage.objects;
drop policy if exists "recall reminder images delete own" on storage.objects;

create policy "recall reminder images select own"
  on storage.objects for select to authenticated
  using (bucket_id = 'reminder-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recall reminder images insert own"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'reminder-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recall reminder images update own"
  on storage.objects for update to authenticated
  using (bucket_id = 'reminder-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "recall reminder images delete own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'reminder-images' and (storage.foldername(name))[1] = auth.uid()::text);
