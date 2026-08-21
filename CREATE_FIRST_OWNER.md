# 🔧 إنشاء أول Owner من Supabase Dashboard

## الطريقة الموصى بها (الأكثر أماناً)

### 1. افتح Supabase Dashboard
https://supabase.com/dashboard

### 2. اختر مشروعك
`gbuildevssbciexvjmtl`

### 3. اذهب إلى SQL Editor
من القائمة الجانبية → **SQL Editor**

### 4. انسخ والصق هذا الكود:

```sql
-- إنشاء أول owner (صاحب التطبيق)
DO $$
DECLARE
  new_user_id uuid;
BEGIN
  -- إنشاء المستخدم في auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'admin@mivet.com',  -- غيّر الإيميل لو عايز
    crypt('Admin@123', gen_salt('bf')),  -- غيّر الباسورد لو عايز
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"المدير الرئيسي","phone":"01000000000","role":"owner","avatar_index":0}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO new_user_id;

  -- إنشاء profile مقابل (سيتم تلقائياً بواسطة trigger لكن نتأكد)
  INSERT INTO public.profiles (id, name, phone, role, avatar_index)
  VALUES (
    new_user_id,
    'المدير الرئيسي',
    '01000000000',
    'owner',
    0
  )
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Owner created successfully with email: admin@mivet.com';
END $$;
```

### 5. اضغط **Run** (أو Ctrl+Enter)

### 6. تأكد من النجاح
- اذهب إلى **Table Editor** → **profiles**
- هتلاقي صف جديد للـ owner ✅

---

## 🔐 بيانات تسجيل الدخول

بعد إنشاء الـ Owner:

### من التطبيق:
1. افتح التطبيق
2. من شاشة Rep Login → اضغط **"تسجيل دخول كمدير"**
3. سجل دخول بـ:
   - **Email**: `admin@mivet.com`
   - **Password**: `Admin@123`

4. هتفتح Owner Dashboard مباشرة ✅

---

## 🎯 بعد تسجيل الدخول

من Owner Dashboard، تقدر:
- ✅ إضافة مندوبين جدد
- ✅ عرض قائمة المندوبين
- ✅ حذف مندوبين
- ✅ تسجيل الخروج

---

## ⚠️ إذا حدث خطأ

### "Email already registered"
معناها الإيميل موجود مسبقاً. غيّر الإيميل في الكود:
```sql
'admin@mivet.com'  → 'owner@mivet.com'
```

### "Invalid login credentials"
تأكد من:
- الإيميل والباسورد صحيحين
- المستخدم موجود في **Authentication → Users**
- الـ profile موجود في **Table Editor → profiles**

### التطبيق يعمل crash
تأكد من:
- الـ `.env` يحتوي المفاتيح الصحيحة
- عملت `flutter clean` و `flutter pub get`

---

## 📝 ملاحظة

بعد إنشاء أول owner، **لا تحتاج** لإنشاء owners آخرين يدوياً.
الـ Owner يقدر يدير كل شيء من التطبيق.
