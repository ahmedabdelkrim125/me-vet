-- ========================================
-- إنشاء أول Owner (Admin) بكود SQL بسيط
-- ========================================
-- شغّل الكود ده في: Supabase Dashboard → SQL Editor
-- ========================================

-- 1) حذف أي owner موجود قبل كده (لو عايز تبدأ من جديد)
-- علّق السطرين دول لو مش عايز تحذف
-- DELETE FROM auth.users WHERE email = 'admin@mivet.com';
-- DELETE FROM public.profiles WHERE phone = '01000000000';

-- 2) إنشاء Owner جديد
DO $$
DECLARE
  owner_id uuid;
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
    'admin@mivet.com',              -- 👈 غيّر الإيميل لو عايز
    crypt('Admin@123', gen_salt('bf')), -- 👈 غيّر الباسورد لو عايز
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"المدير الرئيسي","phone":"01000000000","role":"owner","avatar_index":0}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO owner_id;

  -- التأكد من إنشاء Profile (الـ Trigger المفروض يعملها تلقائي، بس نتأكد)
  INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
  VALUES (
    owner_id,
    'المدير الرئيسي',    -- 👈 غيّر الاسم لو عايز
    '01000000000',        -- 👈 غيّر الرقم لو عايز
    'owner',
    0,
    true
  )
  ON CONFLICT (id) DO NOTHING;

  -- رسالة نجاح
  RAISE NOTICE 'تم إنشاء Owner بنجاح! ✅';
  RAISE NOTICE 'Email: admin@mivet.com';
  RAISE NOTICE 'Password: Admin@123';
  
END $$;

-- 3) التحقق من النجاح
SELECT 
  u.email,
  p.name,
  p.phone,
  p.role,
  p.created_at
FROM auth.users u
JOIN public.profiles p ON u.id = p.id
WHERE p.role = 'owner'
ORDER BY p.created_at DESC
LIMIT 1;

-- ========================================
-- ✅ بعد تشغيل الكود ده:
-- 1. افتح التطبيق
-- 2. اضغط "تسجيل دخول كمدير"
-- 3. سجل دخول بـ:
--    Email: admin@mivet.com
--    Password: Admin@123
-- 4. هتفتح Owner Dashboard ✅
-- ========================================
