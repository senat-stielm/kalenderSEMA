-- ============================================================
--  Tambahan: daftar ormawa/UKM/UKK yang bisa diatur admin.
--  Jalankan sekali di Supabase > SQL Editor > Run pada proyek yang
--  sudah memakai skema.sql sebelumnya. Aman dijalankan ulang.
-- ============================================================

-- 1. Tabel ormawa ------------------------------------------------
create table if not exists public.ormawa (
  id text primary key,
  nama text not null,
  kategori text not null default 'Lainnya',
  warna bigint not null,
  ikon text not null default 'groups',
  urutan integer not null default 0,
  diperbarui_pada timestamptz not null default now()
);

alter table public.ormawa enable row level security;

drop policy if exists "ormawa_baca_publik" on public.ormawa;
create policy "ormawa_baca_publik"
  on public.ormawa
  for select
  to anon, authenticated
  using (true);

revoke insert, update, delete on public.ormawa from anon, authenticated;

-- 2. Fungsi simpan ormawa ----------------------------------------
create or replace function public.simpan_ormawa(kunci text, data jsonb)
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
    raise exception 'Data ormawa tidak valid';
  end if;

  insert into public.ormawa (
    id, nama, kategori, warna, ikon, urutan, diperbarui_pada
  )
  select
    x ->> 'id',
    x ->> 'nama',
    coalesce(x ->> 'kategori', 'Lainnya'),
    (x ->> 'warna')::bigint,
    coalesce(x ->> 'ikon', 'groups'),
    coalesce((select max(o.urutan) from public.ormawa o), 0) + 1,
    now()
  from jsonb_array_elements(data) as x
  where coalesce(x ->> 'id', '') <> ''
  on conflict (id) do update set
    nama = excluded.nama,
    kategori = excluded.kategori,
    warna = excluded.warna,
    ikon = excluded.ikon,
    diperbarui_pada = now();
end;
$$;

-- 3. Fungsi hapus ormawa -----------------------------------------
-- Agenda milik ormawa ini ikut dihapus agar tidak menggantung.
create or replace function public.hapus_ormawa(kunci text, id_ormawa text)
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

  delete from public.agenda where ormawa = id_ormawa;
  delete from public.ormawa where id = id_ormawa;
end;
$$;

revoke all on function public.simpan_ormawa(text, jsonb) from public;
revoke all on function public.hapus_ormawa(text, text) from public;
grant execute on function public.simpan_ormawa(text, jsonb)
  to anon, authenticated;
grant execute on function public.hapus_ormawa(text, text)
  to anon, authenticated;

-- 4. Daftar ormawa awal ------------------------------------------
insert into public.ormawa (id, nama, kategori, warna, ikon, urutan)
values
  ('senat',  'Senat Mahasiswa',        'Legislatif', 4289222135, 'gavel',    1),
  ('bem',    'BEM',                    'Eksekutif',  4294954812, 'bank',     2),
  ('hmpsKp', 'HMPS KP',                'Prodi',      4291101700, 'school',   3),
  ('hmpsMn', 'HMPS MN',                'Prodi',      4278848135, 'business', 4),
  ('ukm1',   'UKM Olahraga',           'UKM',        4279286145, 'sports',   5),
  ('ukm2',   'UKM Musikala',           'UKM',        4284704497, 'music',    6),
  ('ukm3',   'UKM Inteklam',           'UKM',        4279548070, 'science',  7),
  ('ukm4',   'UKM Tari',               'UKM',        4293675161, 'news',     8),
  ('ukm5',   'UKM Himalaya',           'UKM',        4286893078, 'terrain',  9),
  ('ukm6',   'UKM Paduan Suara',       'UKM',        4280468830, 'mosque',   10),
  ('ukm7',   'UKM Kewirausahaan',      'UKM',        4284704497, 'store',    11),
  ('ukk1',   'UKK Pramuka',            'UKK',        4282393860, 'explore',  12),
  ('ukk2',   'UKK Resimen Mahasiswa',  'UKK',        4294538006, 'medical',  13),
  ('ormawa-1793709126563381', 'UKM English Club', 'UKM', 4282090230, 'groups', 14)
on conflict (id) do nothing;

-- 5. Segarkan cache API Supabase --------------------------------
notify pgrst, 'reload schema';
