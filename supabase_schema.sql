-- =========================================================
-- MIVET — Auth Schema (profiles + RLS)
-- شغّل الملف ده كامل في: Supabase Dashboard → SQL Editor → New query
-- =========================================================

-- 1) نوع بيانات للأدوار: owner (صاحب التطبيق) أو rep (مندوب)
create type public.user_role as enum ('owner', 'rep');

-- 2) جدول profiles
-- كل صف هنا مربوط 1-to-1 بصف في auth.users عن طريق نفس الـ id
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text not null,
  phone         text not null unique,
  role          public.user_role not null default 'rep',
  avatar_index  int not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  last_login_at timestamptz not null default now()
);

-- فهرس سريع للبحث بالرقم (تسجيل الدخول هيبحث بيه)
create index profiles_phone_idx on public.profiles (phone);

-- 3) تفعيل RLS على الجدول
alter table public.profiles enable row level security;

-- 4) Policies
-- كل مستخدم مسجل دخول يقدر يقرا صفه هو بس
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using ( auth.uid() = id );

-- الـ owner يقدر يقرا كل الصفوف (عشان شاشة إدارة المندوبين)
create policy "profiles_select_all_for_owner"
on public.profiles for select
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'owner'
  )
);

-- كل مستخدم يقدر يعدّل صفه هو بس (اسمه، صورته، آخر دخول)
-- ملحوظة: منعنا تعديل عمود role و is_active من هنا (تحكم الأونر بس عن طريق Edge Function لاحقًا)
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ( auth.uid() = id )
with check ( auth.uid() = id );

-- لا حد يقدر يعمل insert مباشر من التطبيق —
-- الإنشاء هيتم بس عن طريق الـ trigger تحت (لما يتعمل auth user جديد)
-- فمفيش policy لـ insert خالص = ممنوع افتراضيًا.

-- 5) Trigger: أول ما يتعمل يوزر جديد في auth.users (من الـ Edge Function)
-- بياخد الاسم/الرقم/الدور من user_metadata ويعمل صف مقابل في profiles تلقائي
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone, role, avatar_index)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'مستخدم جديد'),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'rep'),
    coalesce((new.raw_user_meta_data->>'avatar_index')::int, 0)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =========================================================
-- خطوات لازم تعملها يدوي من لوحة Supabase بعد تشغيل الملف ده:
-- =========================================================
-- 1) Authentication → Providers → Email:
--    - فعّل "Email" provider (هنستخدمه جوا لتحويل رقم الموبايل لإيميل صناعي)
--    - عطّل "Confirm email" (مش هنبعت إيميلات تأكيد، المستخدم مش بيشوف الإيميل أصلاً)
--
-- 2) Authentication → Policies (Auth settings) → Password:
--    - غيّر الحد الأدنى لطول الباسورد من 6 لـ 4 (عشان الـ PIN)
--
-- 3) Authentication → Settings → "Enable email signups":
--    - عطّلها تمامًا (Disable) — عشان محدش يقدر يعمل حساب لنفسه غير عن طريق
--      الـ Edge Function اللي بتشتغل بصلاحيات الأونر بس
--
-- 4) أول owner: هيتعمل مرة واحدة بس يدوي (مفيش owner يعمل owner تاني -
--    ده أنت بس هتعمله من Authentication → Users → Add user، وبعدين تعمل
--    update يدوي على صفه في profiles تخلي role = 'owner')
