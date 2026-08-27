# 📋 دليل التشغيل والاختبار

## 🔧 الإعداد الأولي

### 1. تشغيل Supabase Setup

افتح [Supabase Dashboard](https://supabase.com/dashboard) → اختر مشروعك → SQL Editor:

```sql
-- انسخ والصق الكود من ملف:
-- supabase_complete_setup.sql
-- ثم اضغط Run
```

**ما يفعله هذا الكود:**
- إنشاء جدول `profiles` مع RLS policies
- إنشاء حساب Owner تجريبي: `owner@mivet.com` / `Owner@2024`
- إنشاء حساب Rep تجريبي: `01234567890` / `1234`

---

### 2. تشغيل التطبيق

```powershell
# نظف المشروع
flutter clean

# احصل على الحزم
flutter pub get

# شغّل التطبيق
flutter run
```

---

## ✅ خطوات الاختبار

### الخطوة 1: شاشة اختيار نوع الحساب

بعد Splash Screen، هتظهر شاشة فيها:
- 📱 **تسجيل دخول مندوب**
- 👨‍💼 **تسجيل دخول مدير**

---

### الخطوة 2: اختبار تسجيل دخول المندوب

1. اضغط على **"تسجيل دخول مندوب"**
2. املأ:
   - **رقم الموبايل**: `01234567890`
   - **PIN**: `1234`
3. اضغط **"تسجيل الدخول"**

**النتيجة المتوقعة:**
✅ الدخول إلى الشاشة الرئيسية للمندوب (MainScreen)

---

### الخطوة 3: تسجيل خروج المندوب

1. من داخل التطبيق، ابحث عن زرار Logout (أو Profile → Logout)
2. اضغط Logout

**النتيجة المتوقعة:**
✅ الرجوع لشاشة اختيار نوع الحساب

---

### الخطوة 4: اختبار تسجيل دخول المدير

1. من شاشة اختيار نوع الحساب، اضغط **"تسجيل دخول مدير"**
2. املأ:
   - **Email**: `owner@mivet.com`
   - **Password**: `Owner@2024`
3. اضغط **"تسجيل الدخول"**

**النتيجة المتوقعة:**
✅ الدخول إلى Owner Dashboard

---

### الخطوة 5: إنشاء حساب مندوب جديد (من Owner Dashboard)

1. من Owner Dashboard، اضغط **"+ إضافة مندوب"**
2. املأ البيانات:
   - **الاسم**: "محمد علي"
   - **رقم الموبايل**: `01111111111` (11 رقم)
   - **PIN**: `5678` (4 أرقام)
3. اضغط **"إضافة"**

**النتيجة المتوقعة:**
✅ ظهور المندوب الجديد في القائمة

---

### الخطوة 6: تسجيل دخول بالحساب الجديد

1. Logout من Owner
2. ارجع لشاشة تسجيل دخول المندوب
3. سجل دخول بـ:
   - **رقم الموبايل**: `01111111111`
   - **PIN**: `5678`

**النتيجة المتوقعة:**
✅ الدخول بنجاح

---

## 🔍 التحقق من Supabase

### في Supabase Dashboard → Table Editor → profiles:

يجب أن تشاهد:

| email | name | phone | role | is_active |
|-------|------|-------|------|-----------|
| owner@mivet.com | المدير الرئيسي | 01000000000 | owner | ✅ |
| 01234567890@mivet.app | أحمد محمد | 01234567890 | rep | ✅ |
| 01111111111@mivet.app | محمد علي | 01111111111 | rep | ✅ |

---

## ❌ حل المشاكل الشائعة

### المشكلة 1: "relation 'profiles' does not exist"
**الحل:** شغّل `supabase_complete_setup.sql` في SQL Editor

### المشكلة 2: الزرار معطل (رمادي) حتى بعد إدخال البيانات
**الحل:** 
- أوقف التطبيق تماماً (Stop)
- شغّله مرة تانية: `flutter run`
- **Hot Reload مش كافي، لازم Hot Restart أو إعادة تشغيل كاملة**

### المشكلة 3: "Invalid login credentials"
**الحل:** 
- تأكد إنك استخدمت البيانات الصحيحة:
  - Owner: `owner@mivet.com` / `Owner@2024`
  - Rep: `01234567890` / `1234`
- تأكد إن SQL script اشتغل بنجاح في Supabase

### المشكلة 4: "خطأ في تسجيل الدخول"
**الحل:** 
- تحقق من `.env` file:
  ```
  SUPABASE_URL=https://gbuildevssbciexvjmtl.supabase.co
  SUPABASE_ANON_KEY=sb_publishable_ddVxW2wyjpe4l0JGE6qOEw_sv59BHQW
  ```
- تأكد إن الـ URL صحيح من Supabase Dashboard → Settings → API

---

## 🏗️ البنية المعمارية

```
lib/
├── features/
│   └── auth/
│       ├── domain/
│       │   ├── models/
│       │   │   └── user_profile.dart          # Model للمستخدم
│       │   └── repositories/
│       │       └── auth_repository.dart       # Interface للـ Repository
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_impl.dart  # Implementation
│       └── presentation/
│           ├── cubit/
│           │   ├── auth_cubit.dart           # Business Logic
│           │   └── auth_state.dart           # States
│           └── screens/
│               ├── login_type_screen.dart    # اختيار نوع الحساب
│               ├── rep_login_screen.dart     # تسجيل دخول المندوب
│               └── owner_login_screen.dart   # تسجيل دخول المدير
```

---

## 🎯 الحسابات التجريبية

### 👨‍💼 Owner (المدير):
```
Email: owner@mivet.com
Password: Owner@2024
```

### 👤 Rep (المندوب):
```
Phone: 01234567890
PIN: 1234
```

---

## 📝 ملاحظات مهمة

1. **Hot Restart vs Hot Reload:**
   - لو غيرت في الـ State Management → Hot Restart (اضغط `r`)
   - لو غيرت UI بس → Hot Reload (اضغط `r` مرتين أو `R`)

2. **إنشاء حسابات جديدة:**
   - المندوبين **لا يمكنهم** إنشاء حسابات جديدة
   - فقط الـ Owner يمكنه إضافة مندوبين جدد

3. **أمان الحسابات:**
   - رقم الموبايل يجب أن يكون **11 رقم**
   - PIN يجب أن يكون **4 أرقام**

4. **Supabase RLS:**
   - الـ Policies مفعلة على جدول profiles
   - المندوب يشوف بياناته فقط
   - المدير يشوف كل المندوبين

---

## ✨ الخطوات القادمة (اختياري)

- [ ] إضافة Forgot Password للـ Owner
- [ ] إضافة Profile Photo upload
- [ ] إضافة إشعارات للمندوبين
- [ ] إضافة Statistics في Owner Dashboard
