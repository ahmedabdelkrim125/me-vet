-- ========================================
-- Mivet Complete Database Setup
-- ========================================
-- نفذ الكود ده كله مرة واحدة في Supabase SQL Editor
-- ========================================

-- 1) إنشاء enum للـ roles
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('owner', 'rep');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 2) إنشاء جدول profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  role user_role NOT NULL DEFAULT 'rep',
  avatar_index INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3) تفعيل Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4) Policies: السماح للـ authenticated users بقراءة بروفايلهم
CREATE POLICY "Users can read own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 5) Policy: السماح للـ owners بقراءة كل الـ profiles
CREATE POLICY "Owners can read all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'owner'
    )
  );

-- 6) Policy: السماح للـ owners بإنشاء profiles
CREATE POLICY "Owners can create profiles"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'owner'
    )
  );

-- 7) Policy: السماح للـ owners بتعديل الـ profiles
CREATE POLICY "Owners can update profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'owner'
    )
  );

-- 8) Policy: السماح للـ owners بحذف الـ profiles
CREATE POLICY "Owners can delete profiles"
  ON public.profiles
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'owner'
    )
  );

-- 9) Function: تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10) Trigger: تفعيل التحديث التلقائي
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 11) إنشاء حساب Owner التجريبي
-- ========================================

-- إنشاء المستخدم في auth.users
DO $$
DECLARE
  owner_user_id UUID;
BEGIN
  -- محاولة إنشاء المستخدم
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
    'owner@mivet.com',
    crypt('Owner@2024', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"المدير الرئيسي","role":"owner"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO owner_user_id;

  -- إنشاء الـ profile
  INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
  VALUES (
    owner_user_id,
    'المدير الرئيسي',
    '01000000000',
    'owner',
    0,
    true
  );

  RAISE NOTICE 'Owner account created successfully with ID: %', owner_user_id;

EXCEPTION
  WHEN unique_violation THEN
    -- لو المستخدم موجود، نضيف الـ profile بس
    SELECT id INTO owner_user_id FROM auth.users WHERE email = 'owner@mivet.com';
    
    INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
    VALUES (
      owner_user_id,
      'المدير الرئيسي',
      '01000000000',
      'owner',
      0,
      true
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'owner',
      is_active = true;
    
    RAISE NOTICE 'Owner profile updated for existing user: %', owner_user_id;
END $$;

-- ========================================
-- 12) إنشاء حساب Rep تجريبي
-- ========================================

DO $$
DECLARE
  rep_user_id UUID;
BEGIN
  -- إنشاء المستخدم (الـ email هيكون الموبايل محول)
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
    '01234567890@mivet.app',  -- الموبايل محول لـ email
    crypt('1234', gen_salt('bf')),  -- الـ PIN
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"أحمد محمد","role":"rep"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  ) RETURNING id INTO rep_user_id;

  -- إنشاء الـ profile
  INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
  VALUES (
    rep_user_id,
    'أحمد محمد',
    '01234567890',
    'rep',
    1,
    true
  );

  RAISE NOTICE 'Rep account created successfully with ID: %', rep_user_id;

EXCEPTION
  WHEN unique_violation THEN
    -- لو المستخدم موجود، نضيف الـ profile بس
    SELECT id INTO rep_user_id FROM auth.users WHERE email = '01234567890@mivet.app';
    
    INSERT INTO public.profiles (id, name, phone, role, avatar_index, is_active)
    VALUES (
      rep_user_id,
      'أحمد محمد',
      '01234567890',
      'rep',
      1,
      true
    )
    ON CONFLICT (id) DO UPDATE SET
      role = 'rep',
      is_active = true;
    
    RAISE NOTICE 'Rep profile updated for existing user: %', rep_user_id;
END $$;

-- ========================================
-- 13) التحقق من النجاح
-- ========================================

-- عرض جميع الحسابات
SELECT 
  u.email,
  p.name,
  p.phone,
  p.role,
  p.is_active,
  u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC;

-- ========================================
-- ✅ الحسابات التجريبية:
-- ========================================
-- 
-- 👨‍💼 Owner (المدير):
--   Email: owner@mivet.com
--   Password: Owner@2024
--
-- 👤 Rep (المندوب):
--   Phone: 01234567890
--   PIN: 1234
--
-- ========================================
