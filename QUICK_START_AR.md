# 🚀 دليل البدء السريع

## ✅ ما تم إنجازه

تم إنشاء نظام authentication كامل باستخدام Supabase:

### الملفات المضافة:
- ✅ `lib/features/auth/` - Feature كامل للـ Auth
- ✅ `.env` - ملف لحفظ مفاتيح Supabase
- ✅ تحديث `main.dart` لتهيئة Supabase
- ✅ تحديث `Routes` و `AppRouter`
- ✅ تحديث `SplashScreen` للتحقق من Session
- ✅ `pubspec.yaml` - إضافة dependencies جديدة

### التصميم:
- 📱 شاشة Login responsive بنفس theme المشروع
- 🎨 استخدام نفس الألوان والـ text styles
- 📏 Responsive عبر `.w`, `.h`, `.sp`, `.r`
- 🧩 تقسيم الكود لملفات صغيرة (widgets منفصلة)

---

## 📋 الخطوات المتبقية (عليك)

### 1️⃣ إنشاء مشروع Supabase (5 دقائق)

1. افتح [supabase.com](https://supabase.com) وسجل دخول
2. اضغط **New Project**
3. اختر اسم: `mivet-app`
4. احفظ الباسورد في مكان آمن
5. اختر Region قريب منك (مثلاً Frankfurt)
6. انتظر دقيقتين

### 2️⃣ نسخ المفاتيح (دقيقة واحدة)

1. من Supabase Dashboard → **Settings** ⚙️ → **API**
2. انسخ:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJ...`
3. افتح ملف `.env` في المشروع وضع القيم:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3️⃣ إنشاء Database Schema (دقيقتين)

1. من Supabase → **SQL Editor** (أيقونة `</>`)
2. اضغط **New query**
3. افتح ملف `supabase_schema.sql` من المشروع
4. انسخ **كل** المحتوى والصقه
5. اضغط **Run** (Ctrl+Enter)
6. انتظر رسالة "Success" ✅

### 4️⃣ إعدادات Authentication (3 دقائق)

**أ) Email Provider:**
- **Authentication** → **Providers** → **Email**
- تأكد أنه **Enabled** ✅
- **عطّل** "Confirm email" ❌
- **Save**

**ب) Password Policy:**
- **Authentication** → **Settings** → **Policies**
- **Minimum password length**: غيره من `6` إلى `4`
- **Save**

**ج) منع التسجيل الذاتي:**
- **Authentication** → **Settings**
- **Enable email signups**: **عطّله** ❌
- **Save**

### 5️⃣ إنشاء أول Owner (دقيقتين)

1. **Authentication** → **Users** → **Add user**
2. **Create new user**:
   - **Email**: `01012345678@mivet.app` (رقمك + @mivet.app)
   - **Password**: `1234` (أي PIN من 4 أرقام)
   - **Auto Confirm User**: ✅ فعّله
3. اضغط **Add User Metadata**:
   ```json
   {
     "name": "اسمك هنا",
     "phone": "01012345678",
     "role": "owner",
     "avatar_index": 0
   }
   ```
4. **Create user**
5. تأكد من **Table Editor** → **profiles** إن صف جديد ظهر ✅

### 6️⃣ تشغيل التطبيق

```bash
flutter run
```

**تسجيل الدخول**:
- رقم الموبايل: `01012345678`
- PIN: `1234`

---

## 🎯 النتيجة المتوقعة

- ✅ شاشة Splash → تفتيش عن session
- ✅ لو مفيش session → شاشة Login
- ✅ بعد تسجيل دخول صحيح → MainScreen مباشرة
- ✅ لو أغلقت التطبيق وفتحته تاني → مباشرة MainScreen (بدون login)

---

## 🐛 لو حصلت مشكلة

### "Invalid login credentials"
- تأكد من الرقم والـ PIN
- تأكد من إنشاء اليوزر في Supabase

### التطبيق يكراش عند الفتح
```bash
flutter clean
flutter pub get
flutter run
```

### "Failed to load .env"
- تأكد إن `.env` موجود جنب `pubspec.yaml`
- تأكد إن فيه القيم الصحيحة

---

## 📄 ملفات مهمة للمراجعة

- **SUPABASE_SETUP.md** - الدليل الكامل المفصل
- **AUTH_STRUCTURE.md** - شرح بنية الكود
- **supabase_schema.sql** - الـ SQL للنسخ

---

## 💡 ملاحظات

1. ملف `.env` **مش** بيترفع على GitHub (محمي في `.gitignore`)
2. `rep_session` القديم لسه موجود لكن مش بيستخدم دلوقتي
3. شاشة Owner لإضافة مندوبين هتتعمل في مرحلة تانية (Edge Function)

---

**بالتوفيق! 🎉**
