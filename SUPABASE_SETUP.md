# دليل إعداد Supabase للمشروع

## ✅ تم إنجازه (Completed)

- ✅ إضافة `supabase_flutter` و `flutter_dotenv` للـ dependencies
- ✅ إنشاء feature/auth كاملة (models, services, screens, widgets)
- ✅ تحديث Routes والـ AppRouter
- ✅ تعديل SplashScreen للتحقق من session
- ✅ تحديث main.dart لتهيئة Supabase
- ✅ إنشاء ملف `.env` و `.gitignore`

---

## 📋 الخطوات المتبقية (TODO)

### 1️⃣ إنشاء مشروع Supabase

1. افتح [https://supabase.com](https://supabase.com)
2. سجل دخول أو أنشئ حساب جديد
3. اضغط "New Project"
4. املأ البيانات:
   - **Organization**: اختر أو أنشئ واحدة
   - **Name**: `mivet-app` (أو أي اسم تفضله)
   - **Database Password**: احفظ الباسورد دي في مكان آمن
   - **Region**: اختر أقرب منطقة (مثلاً Frankfurt لمصر)
   - **Pricing Plan**: Free (كافي للتطوير)
5. اضغط "Create new project"
6. انتظر دقيقتين حتى يكتمل الإعداد

---

### 2️⃣ الحصول على الـ API Keys

بعد إنشاء المشروع:

1. من القائمة الجانبية، اذهب إلى **Settings** ⚙️
2. اختر **API**
3. ستجد:
   - **Project URL** (مثال: `https://xxxxx.supabase.co`)
   - **Project API keys** → **anon public** (مفتاح عام آمن)

---

### 3️⃣ تحديث ملف .env

افتح ملف `.env` في جذر المشروع وضع القيم الحقيقية:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...
```

⚠️ **مهم**: لا ترفع ملف `.env` على GitHub أبداً! (موجود في `.gitignore`)

---

### 4️⃣ إنشاء Database Schema (SQL)

1. في Supabase Dashboard، اذهب إلى **SQL Editor** (أيقونة `</>`)
2. اضغط **New query**
3. انسخ والصق الكود التالي كامل:

\`\`\`sql
-- =========================================================
-- MIVET — Auth Schema (profiles + RLS)
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
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ( auth.uid() = id )
with check ( auth.uid() = id );

-- 5) Trigger: أول ما يتعمل يوزر جديد في auth.users
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
\`\`\`

4. اضغط **Run** (أو Ctrl+Enter)
5. انتظر رسالة "Success" في الأسفل

---

### 5️⃣ إعدادات Authentication

#### أ) تفعيل Email Provider:
1. اذهب إلى **Authentication** → **Providers**
2. اضغط على **Email**
3. تأكد أنه **Enabled** ✅
4. **عطّل** "Confirm email" (مش محتاجينه)
5. اضغط **Save**

#### ب) تعديل Password Policy:
1. اذهب إلى **Authentication** → **Settings** → **Policies**
2. ابحث عن **Minimum password length**
3. غيره من `6` إلى `4` (عشان الـ PIN)
4. اضغط **Save**

#### ج) منع التسجيل الذاتي:
1. اذهب إلى **Authentication** → **Settings**
2. ابحث عن **Enable email signups**
3. **عطّله** (Disable) ❌
4. اضغط **Save**

---

### 6️⃣ إنشاء أول Owner يدوياً

⚠️ **مهم جداً**: أول owner لازم يتعمل يدوي مرة واحدة بس

1. اذهب إلى **Authentication** → **Users**
2. اضغط **Add user** → **Create new user**
3. املأ البيانات:
   - **Email**: `01012345678@mivet.app` (رقم موبايلك + @mivet.app)
   - **Password**: `1234` (أو أي PIN من 4 أرقام)
   - **Auto Confirm User**: ✅ (فعّله)
4. اضغط **Add User Metadata** واكتب:
   ```json
   {
     "name": "أحمد محمد",
     "phone": "01012345678",
     "role": "owner",
     "avatar_index": 0
   }
   ```
5. اضغط **Create user**
6. الآن افتح **Table Editor** → **profiles**
7. هتلاقي صف جديد اتعمل تلقائي بنفس البيانات ✅

---

### 7️⃣ تجربة التطبيق

1. شغل التطبيق:
   ```bash
   flutter run
   ```

2. جرب تسجيل الدخول بالبيانات اللي عملتها:
   - **رقم الموبايل**: `01012345678`
   - **PIN**: `1234`

3. لو نجح، هتروح مباشرة للصفحة الرئيسية ✅

---

## 🔧 الخطوات المتقدمة (اختياري - لاحقاً)

### إضافة Logout من MainScreen

حالياً التطبيق مفيش فيه زرار Logout. عشان تضيفه:

في أي شاشة (مثلاً من Settings لو موجودة):

```dart
import 'package:mivet_app/features/auth/data/auth_service.dart';
import 'package:mivet_app/core/routing/routes.dart';

// داخل أي button:
onPressed: () async {
  await AuthService.instance.signOut();
  if (!mounted) return;
  context.pushReplacementNamed(Routes.loginScreen);
}
```

---

## 🐛 حل المشاكل (Troubleshooting)

### مشكلة: "Invalid login credentials"
- تأكد إن رقم الموبايل مكتوب صح (11 رقم)
- تأكد إن الـ PIN صح
- روح على Supabase → Authentication → Users وتأكد إن اليوزر موجود

### مشكلة: التطبيق بيكراش عند بدء التشغيل
- تأكد إنك حطيت الـ keys الصح في `.env`
- تأكد إنك عملت `flutter pub get`
- جرب تعمل Clean:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

### مشكلة: "Failed to load .env"
- تأكد إن ملف `.env` موجود في جذر المشروع (جنب `pubspec.yaml`)
- تأكد إن السطر `.env` موجود في `assets` في `pubspec.yaml`

---

## 📱 إعداد Android للـ Production

لما تكون جاهز للنشر، افتح:
`android/app/src/main/AndroidManifest.xml`

وتأكد إن السطر ده موجود:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Required to fetch data from the internet. -->
  <uses-permission android:name="android.permission.INTERNET" />
  <!-- ... -->
</manifest>
```

---

## 📚 موارد مفيدة

- [Supabase Flutter Quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)

---

## ✅ الملخص

بعد إتمام كل الخطوات دي:
- ✅ عندك authentication حقيقي بـ Supabase
- ✅ تسجيل دخول برقم موبايل + PIN (4 أرقام)
- ✅ محدش يقدر يعمل حساب لنفسه غير الـ Owner
- ✅ كل مندوب بيشوف بياناته بس (RLS)
- ✅ الـ session بتتحفظ حتى لو قفلت التطبيق

**التالي**: إضافة شاشة Owner لإنشاء حسابات مندوبين (Edge Function)
