# ⚡ البدء السريع - طريقة SQL (الأسهل)

## 🎯 خطوتين بس!

---

## الخطوة 1️⃣: شغّل الـ SQL Script

### 1. افتح Supabase Dashboard
https://supabase.com/dashboard

### 2. اختر مشروعك
`gbuildevssbciexvjmtl` (أو أي اسم مشروعك)

### 3. اذهب إلى SQL Editor
من القائمة الجانبية اليسار → **SQL Editor** (أيقونة `</>`)

### 4. اضغط "New query"

### 5. انسخ والصق الكود الكامل
افتح ملف **`create_owner.sql`** (في نفس المجلد)

انسخ **كل** المحتوى والصقه في SQL Editor

### 6. اضغط "Run" (أو Ctrl+Enter)

### 7. ✅ انتظر النتيجة
هتظهر رسالة:
```
✅ تم إنشاء Owner بنجاح!
Email: admin@mivet.com
Password: Admin@123
```

وتحتها جدول صغير بمعلومات الـ Owner

---

## الخطوة 2️⃣: شغّل التطبيق وسجل دخول

### 1. شغّل التطبيق
```bash
flutter run
```

### 2. من شاشة Rep Login
اضغط الزرار في الأسفل:
**"تسجيل دخول كمدير →"**

### 3. سجل دخول بالبيانات
```
Email: admin@mivet.com
Password: Admin@123
```

### 4. ✅ هتفتح Owner Dashboard!

---

## 🎉 تم! الآن تقدر:

- ✅ إضافة مندوبين من التطبيق
- ✅ حذف مندوبين
- ✅ عرض قائمة المندوبين
- ✅ تسجيل الخروج

---

## 🔄 لو عايز تضيف مندوب

### من Owner Dashboard:
1. اضغط **"إضافة مندوب"** (الزرار الأخضر)
2. املأ:
   - **الاسم**: أحمد محمد
   - **رقم الموبايل**: `01012345678` (11 رقم)
   - **PIN**: `1234` (4 أرقام)
3. اضغط **"إضافة"**
4. ✅ المندوب اتضاف!

---

## 🔐 تسجيل دخول المندوب

1. سجل خروج من Owner Dashboard (أيقونة Logout)
2. من شاشة Rep Login:
   - رقم الموبايل: `01012345678`
   - PIN: `1234`
3. اضغط **"تسجيل الدخول"**
4. ✅ يدخل على Main Screen!

---

## 💡 نصائح

### لو عايز تغيّر الإيميل أو الباسورد:
افتح ملف `create_owner.sql` وغيّر السطور:
```sql
'admin@mivet.com',              -- 👈 غيّر ده
crypt('Admin@123', gen_salt('bf')), -- 👈 وده
```

ثم شغّل الـ SQL مرة تانية.

### لو عايز تحذف Owner القديم وتعمل جديد:
افتح ملف `create_owner.sql` وشيل الـ `--` من أول السطرين:
```sql
DELETE FROM auth.users WHERE email = 'admin@mivet.com';
DELETE FROM public.profiles WHERE phone = '01000000000';
```

---

## 🐛 لو حصلت مشكلة

### "Email already registered"
معناها الإيميل موجود مسبقاً. 

**الحل**: غيّر الإيميل في الـ SQL أو احذف القديم:
```sql
DELETE FROM auth.users WHERE email = 'admin@mivet.com';
```

### "relation auth.users does not exist"
معناها الـ schema مش اتنفذ.

**الحل**: شغّل ملف `supabase_schema.sql` الأول.

### التطبيق يقول "Invalid credentials"
**الحل**: 
1. تأكد إن الكود اتنفذ بنجاح (فيه رسالة ✅)
2. تأكد إنك بتكتب نفس الإيميل والباسورد بالظبط
3. تأكد إن فيه owner في **Table Editor** → **profiles**

---

## ✅ الملخص

```
1. SQL Editor → شغّل create_owner.sql
2. flutter run
3. تسجيل دخول كمدير
4. إضافة مندوبين
5. ✅ تم!
```

**أسهل من كده مافيش! 🚀**
