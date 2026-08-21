# 🚀 كيف تبدأ - دليل شامل

## ✅ تم إنجازه

- ✅ ربط Flutter بـ Supabase
- ✅ شاشة Login للمندوبين (رقم + PIN)
- ✅ شاشة Login للمدير (Email + Password)
- ✅ Owner Dashboard لإدارة المندوبين
- ✅ إضافة/حذف مندوبين
- ✅ Routing تلقائي حسب الدور

---

## 📋 الخطوات للبدء

### 1️⃣ إنشاء أول Owner (Admin) - **مرة واحدة فقط**

#### الطريقة 1: من Supabase Dashboard (الأسهل)

1. **افتح**: https://supabase.com/dashboard
2. **اختر مشروعك**: `gbuildevssbciexvjmtl`
3. **اذهب إلى**: Authentication → Users
4. **اضغط**: Add user → Create new user
5. **املأ البيانات**:
   ```
   Email: admin@mivet.com
   Password: Admin@123
   ✅ Auto Confirm User (مهم!)
   ```
6. **اضغط User Metadata** واكتب:
   ```json
   {
     "name": "المدير",
     "phone": "01000000000",
     "role": "owner",
     "avatar_index": 0
   }
   ```
7. **اضغط**: Create user
8. **تأكد**: Table Editor → profiles → لازم يكون فيه صف جديد

---

#### الطريقة 2: SQL Script (للمحترفين)

1. **اذهب إلى**: SQL Editor في Supabase
2. **انسخ والصق** الكود من ملف `CREATE_FIRST_OWNER.md`
3. **اضغط**: Run

---

### 2️⃣ تشغيل التطبيق

```bash
flutter clean
flutter pub get
flutter run
```

---

### 3️⃣ تسجيل دخول Owner (المدير)

#### من التطبيق:
1. **ستفتح شاشة**: Rep Login (رقم موبايل + PIN)
2. **لاحظ في الأسفل**: زرار **"تسجيل دخول كمدير →"**
3. **اضغط عليه**
4. **سجل دخول**:
   - Email: `admin@mivet.com`
   - Password: `Admin@123`
5. ✅ **ستفتح**: Owner Dashboard

---

### 4️⃣ إضافة مندوب من Owner Dashboard

1. **اضغط**: "إضافة مندوب" (زرار أخضر)
2. **املأ البيانات**:
   - الاسم: `أحمد محمد`
   - رقم الموبايل: `01012345678` (11 رقم)
   - PIN: `1234` (4 أرقام)
3. **اضغط**: إضافة
4. ✅ **المندوب اتضاف** وظهر في القائمة

---

### 5️⃣ تسجيل دخول المندوب

1. **اضغط**: Logout (أيقونة الخروج في Owner Dashboard)
2. **ستفتح**: شاشة Rep Login
3. **سجل دخول بالبيانات اللي كتبتها**:
   - رقم الموبايل: `01012345678`
   - PIN: `1234`
4. ✅ **سيدخل**: Main Screen (الصفحة الرئيسية للمندوب)

---

## 🎯 الـ Flow الكامل

```
📱 التطبيق يفتح
    │
    ↓
🔍 Splash Screen (يفحص session)
    │
    ├─ لا يوجد session → Rep Login
    │   │
    │   ├─ تسجيل دخول عادي (رقم + PIN) → Main Screen
    │   │
    │   └─ زرار "تسجيل دخول كمدير" → Owner Login
    │       │
    │       └─ Email + Password → Owner Dashboard
    │           │
    │           ├─ إضافة مندوبين
    │           ├─ حذف مندوبين
    │           ├─ عرض قائمة
    │           └─ Logout
    │
    └─ يوجد session → فحص role
        │
        ├─ owner → Owner Dashboard
        │
        └─ rep → Main Screen
```

---

## 🔧 التحقق من الربط

### اختبار سريع:
```bash
flutter run
```

#### ✅ إذا فتحت شاشة Login → الربط تمام
#### ❌ إذا حدث Crash:

1. **تأكد من `.env`**:
   ```env
   SUPABASE_URL=https://gbuildevssbciexvjmtl.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_ddVxW2wyjpe4l0JGE6qOEw_sv59BHQW
   ```

2. **شغّل**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **تأكد من Supabase**:
   - افتح: https://supabase.com/dashboard
   - تأكد إن المشروع **نشط** (مش Paused)
   - تأكد إن الـ SQL schema **اتنفذ** (Table Editor → profiles موجود)

---

## 📱 شاشات التطبيق

### 1. **Rep Login** (تسجيل دخول المندوب)
- حقل: رقم الموبايل (11 رقم)
- حقل: PIN (4 أرقام)
- زرار: تسجيل الدخول
- زرار: تسجيل دخول كمدير ← (للتبديل)

### 2. **Owner Login** (تسجيل دخول المدير)
- حقل: Email
- حقل: Password
- زرار: تسجيل الدخول
- زرار: تسجيل دخول كمندوب ← (للرجوع)

### 3. **Owner Dashboard** (لوحة تحكم المدير)
- بطاقة المدير (الاسم + "صاحب التطبيق")
- عداد المندوبين: `المندوبين (X)`
- زرار: إضافة مندوب
- قائمة المندوبين:
  - كل مندوب: الاسم، الرقم، تاريخ الانضمام
  - زرار حذف (🗑️) لكل مندوب
- Pull to Refresh (اسحب لأسفل للتحديث)
- زرار Logout في AppBar

### 4. **Main Screen** (الصفحة الرئيسية للمندوب)
- الصفحة الحالية للتطبيق
- Bottom Navigation Bar
- كل الميزات الحالية

---

## 🐛 حل المشاكل الشائعة

### "Invalid login credentials"
✅ **الحل**:
- تأكد من الإيميل والباسورد صح
- تأكد من عمل **Auto Confirm User** ✅
- تأكد من وجود الـ User Metadata

### "Email already registered" عند إضافة مندوب
✅ **الحل**:
- الرقم مسجل قبل كده
- استخدم رقم موبايل مختلف

### التطبيق يعمل Crash عند الفتح
✅ **الحل**:
```bash
flutter clean
flutter pub get
flutter run
```

### مش لاقي زرار "تسجيل دخول كمدير"
✅ **الحل**:
```bash
git pull origin feature/owner-dashboard
flutter clean
flutter pub get
flutter run
```

### "Failed to load .env"
✅ **الحل**:
- تأكد إن ملف `.env` موجود جنب `pubspec.yaml`
- تأكد من القيم الصحيحة

### Supabase يرجع "403 Forbidden"
✅ **الحل**:
- تأكد إن الـ SQL schema اتنفذ
- تأكد إن RLS Policies موجودة
- افتح Table Editor → profiles → RLS مفعّل ✅

---

## 📚 ملفات مهمة

- **OWNER_LOGIN_GUIDE_AR.md** - دليل تفصيلي لتسجيل دخول Owner
- **CREATE_FIRST_OWNER.md** - SQL script لإنشاء owner
- **SUPABASE_SETUP.md** - دليل إعداد Supabase الكامل
- **AUTH_STRUCTURE.md** - شرح بنية الكود
- **supabase_schema.sql** - الـ SQL للنسخ واللصق

---

## ✅ الملخص

1. ✅ **إنشاء Owner** من Supabase Dashboard (مرة واحدة)
2. ✅ **تشغيل التطبيق**: `flutter run`
3. ✅ **تسجيل دخول Owner**: Email + Password
4. ✅ **إضافة مندوبين** من Owner Dashboard
5. ✅ **تسجيل دخول المندوب**: رقم + PIN
6. ✅ **المندوب يستخدم** التطبيق العادي

---

## 🎉 تم بنجاح!

الآن التطبيق جاهز للاستخدام مع:
- ✅ Authentication حقيقي
- ✅ إدارة المندوبين
- ✅ Roles (Owner/Rep)
- ✅ Security (RLS)

**بالتوفيق! 🚀**
