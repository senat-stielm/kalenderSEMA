-- ============================================================
--  Help Desk OrmaKta: sumber informasi resmi dari admin.
--  Jalankan sekali di Supabase > SQL Editor > Run.
--  Aman dijalankan ulang; tidak menimpa data yang sudah ada.
-- ============================================================

-- 1. Tabel sumber informasi -------------------------------------
create table if not exists public.sumber_bantuan (
  id text primary key,
  judul text not null,
  kategori text not null default 'Umum',
  isi text not null,
  urutan integer not null default 0,
  diperbarui_pada timestamptz not null default now()
);

alter table public.sumber_bantuan enable row level security;

drop policy if exists "bantuan_baca_publik" on public.sumber_bantuan;
create policy "bantuan_baca_publik"
  on public.sumber_bantuan
  for select
  to anon, authenticated
  using (true);

-- Penulisan hanya lewat fungsi di bawah, bukan langsung ke tabel.
revoke insert, update, delete on public.sumber_bantuan
  from anon, authenticated;
grant select on public.sumber_bantuan to anon, authenticated;

-- 2. Fungsi simpan (tambah / ubah) -------------------------------
create or replace function public.simpan_bantuan(kunci text, data jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if kunci is distinct from
     (select k.kunci from public.kunci_aplikasi k where k.id = 1) then
    raise exception 'Kunci tidak valid';
  end if;

  if data is null or jsonb_typeof(data) <> 'array' then
    raise exception 'Data bantuan tidak valid';
  end if;

  insert into public.sumber_bantuan (
    id, judul, kategori, isi, urutan, diperbarui_pada
  )
  select
    x ->> 'id',
    x ->> 'judul',
    coalesce(x ->> 'kategori', 'Umum'),
    x ->> 'isi',
    coalesce(
      nullif(x ->> 'urutan', '')::integer,
      (select coalesce(max(b.urutan), 0) + 1 from public.sumber_bantuan b)
    ),
    now()
  from jsonb_array_elements(data) as x
  where coalesce(x ->> 'id', '') <> ''
    and coalesce(x ->> 'judul', '') <> ''
    and coalesce(x ->> 'isi', '') <> ''
  on conflict (id) do update set
    judul = excluded.judul,
    kategori = excluded.kategori,
    isi = excluded.isi,
    urutan = excluded.urutan,
    diperbarui_pada = now();
end;
$$;

-- 3. Fungsi hapus ------------------------------------------------
create or replace function public.hapus_bantuan(kunci text, id_bantuan text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if kunci is distinct from
     (select k.kunci from public.kunci_aplikasi k where k.id = 1) then
    raise exception 'Kunci tidak valid';
  end if;

  delete from public.sumber_bantuan where id = id_bantuan;
end;
$$;

revoke all on function public.simpan_bantuan(text, jsonb) from public;
revoke all on function public.hapus_bantuan(text, text) from public;
grant execute on function public.simpan_bantuan(text, jsonb)
  to anon, authenticated;
grant execute on function public.hapus_bantuan(text, text)
  to anon, authenticated;

-- 4. Segarkan cache API Supabase ---------------------------------
notify pgrst, 'reload schema';

-- 5. Verifikasi (opsional, hasilnya harus 1 baris) ---------------
-- select schemaname, tablename, rowsecurity
-- from pg_tables
-- where schemaname = 'public' and tablename = 'sumber_bantuan';
