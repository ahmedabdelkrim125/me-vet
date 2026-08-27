# 🔑 كيفية الحصول على Supabase Keys الصحيحة

## ⚠️ المشكلة الحالية
الـ `.env` file يحتوي على مفاتيح **غير صحيحة**.

المفتاح الصحيح لـ `SUPABASE_ANON_KEY` يجب أن:
- يبدأ بـ `eyJ`
- يكون طويل جداً (أكثر من 200 حرف)
- يكون JWT token

---

## ✅ الخطوات الصحيحة

### 1. افتح Supabase Dashboard
اذهب إلى: https://supabase.com/dashboard

### 2. اختر مشروعك
اضغط على المشروع: `mivet-app` (أو أي اسم اخترته)

### 3. اذهب للإعدادات
من القائمة الجانبية:
- **Settings** ⚙️ (في الأسفل)
- ثم **API**

### 4. انسخ المفاتيح

ستجد قسمين:

#### أ) Project URL
```
https://xxxxxxxxxxxxx.supabase.co
```
انسخه بالكامل

#### ب) Project API keys

ستجد عدة مفاتيح، انسخ:
- **`anon` `public`** (المفتاح الأول - سيكون طويل جداً)

**مثال على شكل المفتاح الصحيح:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdidWlsZGV2c3NiY2lleHZqbXRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk5MTc4MDAsImV4cCI6MjAyNTQ5MzgwMH0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 5. حدّث ملف .env

افتح ملف `.env` في جذر المشروع وضع القيم:

```env
SUPABASE_URL=https://gbuildevssbciexvjmtl.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...الباقي
```

---

## 🧪 اختبار الاتصال

بعد تحديث `.env`، شغّل:

```bash
flutter clean
flutter pub get
flutter run
```

إذا ظهرت شاشة Login → ✅ الربط صحيح
إذا حدث crash → ❌ المفاتيح لا تزال خاطئة

---

## 📸 صورة توضيحية للمكان الصحيح

```
Supabase Dashboard
└── Your Project
    └── Settings ⚙️
        └── API
            ├── Project URL: https://xxxxx.supabase.co
            └── Project API keys:
                ├── anon public ← هذا اللي نريده ✅
                ├── service_role secret ← لا تستخدمه في التطبيق ❌
                └── ...
```

---

## ⚠️ تحذير أمني

- ✅ **anon key** - آمن، يُستخدم في التطبيق
- ❌ **service_role key** - **خطر جداً** - لا تضعه في `.env` أبداً!
  - يُستخدم فقط في Edge Functions على السيرفر
  - لو وضعته في التطبيق، أي شخص يمكنه الوصول الكامل لقاعدة البيانات

---

## 🆘 إذا لم تجد المفاتيح

1. تأكد أنك سجلت دخول على الحساب الصحيح
2. تأكد أن المشروع تم إنشاؤه بنجاح (ليس في حالة "Setting up...")
3. جرب Refresh الصفحة
4. إذا استمرت المشكلة، أنشئ مشروع جديد من الصفر
