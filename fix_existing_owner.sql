-- ========================================
-- إصلاح Owner موجود لكن مفيش profile
-- ========================================
-- استخدم ده لو عملت owner قبل كده بس مش شغال
-- ========================================

-- 1) نشوف الـ Owner الموجود
SELECT 
  id,
  email,
  raw_user_meta_data,
  created_at
FROM auth.users 
WHERE email = 'admin@mivet.com';

-- 2) إضافة Profile للـ Owner الموجود
-- (غيّر الـ ID بتاع اليوزر من الخطوة 1)
INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
SELECT 
  u.id,
  'المدير الرئيسي',
  '01000000000',
  'owner'::public.user_role,
  0,
  true
FROM auth.users u
WHERE u.email = 'admin@mivet.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'owner',
  is_active = true;

-- 3) تأكد من النجاح
SELECT 
  u.email,
  p.name,
  p.phone,
  p.role,
  p.is_active
FROM auth.users u
JOIN public.profiles p ON u.id = p.id
WHERE u.email = 'admin@mivet.com';

-- ========================================
-- ✅ بعد تشغيل الكود ده:
-- سجل دخول بـ:
--   Email: admin@mivet.com
--   Password: Admin@123
-- ========================================
