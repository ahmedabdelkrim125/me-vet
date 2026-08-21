# 🚀 دليل تسجيل الدخول كـ Owner (Admin)

## ⚡ الخطوات السريعة

### 1️⃣ إنشاء حساب Owner (مرة واحدة فقط)

#### الطريقة الأسهل: من Supabase Dashboard

1. افتح: https://supabase.com/dashboard
2. اختر مشروعك: `gbuildevssbciexvjmtl`
3. من القائمة: **Authentication** → **Users**
4. اضغط **Add user** → **Create new user**

5. املأ البيانات:
   ```
   Email: admin@mivet.com
   Password: Admin@123
   ```
   
   ✅ فعّل **Auto Confirm User**

6. اضغط **User Metadata** واكتب:
   ```json
   {
     "name": "المدير",
     "phone": "01000000000",
     "role": "owner",
     "avatar_index": 0
   }
   ```

7. اضغط **Create user**

8. ✅ تأكد من **Table Editor** → **profiles** إن الصف اتعمل

---

### 2️⃣ تسجيل الدخول من التطبيق

1. شغّل التطبيق:
   ```bash
   flutter run
   ```

2. من شاشة Rep Login (رقم موبايل + PIN)
   
   👇 **اضغط على الزرار في الأسفل:**
   
   **"تسجيل دخول كمدير →"**

3. هتفتح شاشة Owner Login

4. سجل دخول بـ:
   - **Email**: `admin@mivet.com`
   - **Password**: `Admin@123`

5. ✅ هتفتح **Owner Dashboard** مباشرة!

---

## 🎯 من Owner Dashboard

الآن تقدر:

### ➕ إضافة مندوب جديد:
1. اضغ "**إضافة مندوب**"
2. املأ:
   - **الاسم**: مثلاً "أحمد محمد"
   - **رقم الموبايل**: `01012345678` (11 رقم)
   - **PIN**: `1234` (4 أرقام)
3. اضغط **إضافة**

### 👀 عرض المندوبين:
- القائمة تظهر تلقائياً
- كل مندوب يظهر اسمه، رقمه، تاريخ انضمامه

### 🗑️ حذف مندوب:
- اضغط أيقونة **🗑️** بجانب المندوب
- أكد الحذف

### 🔄 Refresh:
- اسحب الشاشة لأسفل للتحديث

### 🚪 تسجيل خروج:
- اضغط أيقونة **Logout** في AppBar

---

## 🔄 تسجيل دخول المندوب

بعد ما تضيف مندوب:

1. سجل خروج من Owner Dashboard
2. هترجع لشاشة تسجيل دخول المندوب
3. سجل دخول بـ:
   - **رقم الموبايل**: اللي كتبته (مثلاً `01012345678`)
   - **PIN**: اللي كتبته (مثلاً `1234`)
4. ✅ هيدخل على **Main Screen** (الصفحة الرئيسية للمندوب)

---

## 🐛 حل المشاكل

### "Invalid login credentials"
✅ تأكد من:
- الإيميل والباسورد صح
- عملت **Auto Confirm User** ✅
- الـ User Metadata موجود

### التطبيق يعمل Crash
✅ شغّل:
```bash
flutter clean
flutter pub get
flutter run
```

### "Email already registered" عند إضافة مندوب
✅ الرقم ده مسجل قبل كده. جرب رقم تاني.

### مش لاقي زرار "تسجيل دخول كمدير"
✅ تأكد إنك على آخر نسخة من الكود:
```bash
git pull origin feature/owner-dashboard
```

---

## 📱 الـ Flow الكامل

```
1. إنشاء Owner (Supabase Dashboard) ← مرة واحدة فقط
2. تسجيل دخول Owner (Email + Password)
3. إضافة مندوبين من Owner Dashboard
4. تسجيل خروج Owner
5. تسجيل دخول المندوب (رقم + PIN)
6. المندوب يستخدم التطبيق العادي
```

---

## ✅ تأكد من الربط

### اختبار سريع:
1. افتح التطبيق
2. لو ظهرت شاشة Login → ✅ التطبيق شغال
3. لو حصل Crash → ❌ مشكلة في الربط

### لو فيه مشكلة في الربط:
1. تأكد من `.env`:
   ```env
   SUPABASE_URL=https://gbuildevssbciexvjmtl.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_ddVxW2wyjpe4l0JGE6qOEw_sv59BHQW
   ```

2. شغّل:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

**بالتوفيق! 🎉**
