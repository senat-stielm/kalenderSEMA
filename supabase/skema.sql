-- ============================================================
--  Skema Kalender Ormawa untuk Supabase
--  Jalankan seluruh isi file ini di Supabase > SQL Editor > Run.
-- ============================================================

-- 1. Tabel agenda ------------------------------------------------
create table if not exists public.agenda (
  id text primary key,
  judul text not null,
  deskripsi text not null default '',
  tanggal date not null,
  lokasi text not null default '',
  ormawa text not null,
  diperbarui_pada timestamptz not null default now()
);

alter table public.agenda enable row level security;

-- Semua orang (aplikasi anggota) boleh membaca agenda.
drop policy if exists "agenda_baca_publik" on public.agenda;
create policy "agenda_baca_publik"
  on public.agenda
  for select
  to anon, authenticated
  using (true);

-- Penulisan hanya lewat fungsi di bawah, bukan langsung ke tabel.
revoke insert, update, delete on public.agenda from anon, authenticated;

-- 2. Kunci tulis aplikasi ----------------------------------------
-- Nilai ini harus sama dengan `kunciTulisSupabase` di
-- lib/konfigurasi_supabase.dart. Ganti bila ingin kunci sendiri.
create table if not exists public.kunci_aplikasi (
  id integer primary key check (id = 1),
  kunci text not null
);

insert into public.kunci_aplikasi (id, kunci)
values (1, 'senat-kalender-ormawa-2026-kunci-tulis-9f3c')
on conflict (id) do update set kunci = excluded.kunci;

alter table public.kunci_aplikasi enable row level security;
revoke all on public.kunci_aplikasi from anon, authenticated;

-- 2b. Tabel ormawa / UKM / UKK -----------------------------------
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

-- 3. Fungsi simpan (tambah / ubah) agenda -------------------------
create or replace function public.simpan_agenda(kunci text, data jsonb)
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
    raise exception 'Data agenda tidak valid';
  end if;

  insert into public.agenda (
    id, judul, deskripsi, tanggal, lokasi, ormawa, diperbarui_pada
  )
  select
    x ->> 'id',
    x ->> 'judul',
    coalesce(x ->> 'deskripsi', ''),
    (x ->> 'tanggal')::date,
    coalesce(x ->> 'lokasi', ''),
    x ->> 'ormawa',
    now()
  from jsonb_array_elements(data) as x
  where coalesce(x ->> 'id', '') <> ''
  on conflict (id) do update set
    judul = excluded.judul,
    deskripsi = excluded.deskripsi,
    tanggal = excluded.tanggal,
    lokasi = excluded.lokasi,
    ormawa = excluded.ormawa,
    diperbarui_pada = now();
end;
$$;

-- 4. Fungsi hapus agenda -----------------------------------------
create or replace function public.hapus_agenda(kunci text, id_agenda text)
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

  delete from public.agenda where id = id_agenda;
end;
$$;

revoke all on function public.simpan_agenda(text, jsonb) from public;
revoke all on function public.hapus_agenda(text, text) from public;
grant execute on function public.simpan_agenda(text, jsonb)
  to anon, authenticated;
grant execute on function public.hapus_agenda(text, text)
  to anon, authenticated;

-- 4b. Fungsi simpan / hapus ormawa -------------------------------
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

  -- Agenda milik ormawa ini ikut dihapus agar tidak menggantung.
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

-- 4c. Daftar ormawa awal -----------------------------------------
insert into public.ormawa (id, nama, kategori, warna, ikon, urutan)
values
  ('senat',  'Senat Mahasiswa',        'Legislatif', 4289222135, 'gavel',    1),
  ('bem',    'BEM',                    'Eksekutif',  4293870660, 'bank',     2),
  ('hmpsKp', 'HMPS KP',                'Prodi',      4282090230, 'school',   3),
  ('hmpsMn', 'HMPS MN',                'Prodi',      4278630100, 'business', 4),
  ('ukm1',   'UKM Olahraga',           'UKM',        4279286145, 'sports',   5),
  ('ukm2',   'UKM Seni & Musik',       'UKM',        4294286859, 'music',    6),
  ('ukm3',   'UKM Penalaran & Riset',  'UKM',        4279548070, 'science',  7),
  ('ukm4',   'UKM Pers Kampus',        'UKM',        4293675161, 'news',     8),
  ('ukm5',   'UKM Mapala',             'UKM',        4286893078, 'terrain',  9),
  ('ukm6',   'UKM Kerohanian Islam',   'UKM',        4280468830, 'mosque',   10),
  ('ukm7',   'UKM Kewirausahaan',      'UKM',        4284704497, 'store',    11),
  ('ukk1',   'UKK Pramuka',            'UKK',        4292441862, 'explore',  12),
  ('ukk2',   'UKK KSR PMI',            'UKK',        4294197086, 'medical',  13)
on conflict (id) do nothing;

-- 5. Agenda contoh (boleh dihapus / diganti) ---------------------
insert into public.agenda (id, judul, deskripsi, tanggal, lokasi, ormawa)
values
  (
    'contoh-1',
    'Sidang Pleno Kemahasiswaan',
    'Evaluasi program kerja dan anggaran ormawa triwulan berjalan',
    '2026-11-02',
    'Ruang Sidang Utama',
    'senat'
  ),
  (
    'contoh-2',
    'Pekan Raya & Kreativitas BEM',
    'Gebyar pameran inovasi dan bazar mahasiswa kampus',
    '2026-11-05',
    'Lapangan Utama Kampus',
    'bem'
  ),
  (
    'contoh-3',
    'Kajian Manajemen & Kepemimpinan',
    'Diskusi strategi manajemen SDM era transformasi digital',
    '2026-11-09',
    'Auditorium Gedung B',
    'hmpsMn'
  ),
  (
    'contoh-4',
    'Turnamen Futsal & Badminton',
    'Kompetisi olahraga persahabatan antar program studi',
    '2026-11-12',
    'GOR Kampus',
    'ukm1'
  )
on conflict (id) do nothing;

-- 6. Segarkan cache API Supabase --------------------------------
notify pgrst, 'reload schema';
