# 🔐 بنية Authentication في المشروع

## 📂 هيكل الملفات الجديدة

```
lib/
├── features/
│   └── auth/                          ✨ جديد
│       ├── data/
│       │   └── auth_service.dart      # خدمة Supabase (login, logout, session)
│       ├── domain/
│       │   └── models/
│       │       └── user_profile.dart  # موديل المستخدم (owner/rep)
│       └── presentation/
│           ├── login_screen.dart      # الشاشة الرئيسية للتسجيل
│           └── widgets/
│               ├── login_header.dart  # اللوجو والعنوان
│               ├── phone_input_field.dart   # حقل رقم الموبايل
│               ├── pin_input_field.dart     # حقل PIN (4 أرقام)
│               └── login_button.dart        # زر تسجيل الدخول
│
├── core/
│   └── routing/
│       ├── routes.dart               # ✏️ تم تحديثه (إضافة loginScreen)
│       └── app_router.dart           # ✏️ تم تحديثه (route جديد)
│
├── features/splash/
│   └── presentation/
│       └── splash_screen.dart        # ✏️ تم تحديثه (التحقق من session)
│
└── main.dart                          # ✏️ تم تحديثه (تهيئة Supabase)

الملفات في الجذر:
├── .env                               # ✨ جديد (Supabase keys - مش للـ git)
├── .gitignore                         # ✏️ تم تحديثه (ignore .env)
├── pubspec.yaml                       # ✏️ تم تحديثه (+supabase_flutter, +flutter_dotenv)
├── SUPABASE_SETUP.md                  # ✨ جديد (دليل الإعداد الكامل)
├── supabase_schema.sql                # ✨ جديد (SQL للنسخ واللصق)
└── AUTH_STRUCTURE.md                  # ✨ هذا الملف
```

---

## 🔄 Flow تسجيل الدخول

```
┌─────────────┐
│ SplashScreen│
└──────┬──────┘
       │
       │ AuthService.hasActiveSession?
       │
   ┌───┴───┐
   │       │
   ▼       ▼
  نعم      لا
   │       │
   │       │
   │   ┌──────────────┐
   │   │ LoginScreen  │
   │   └──────┬───────┘
   │          │
   │          │ يدخل: phone + PIN
   │          ▼
   │   AuthService.signInWithPhone()
   │          │
   │          │ نجح؟
   │          ▼
   │      ┌───────┐
   └─────►│ Main  │
          │Screen │
          └───────┘
```

---

## 🧩 المكونات (Components)

### 1. `AuthService` (Single Instance)
```dart
// الاستخدام في أي مكان:
import 'package:mivet_app/features/auth/data/auth_service.dart';

// تسجيل دخول
final profile = await AuthService.instance.signInWithPhone('01012345678', '1234');

// جلب المستخدم الحالي
final user = await AuthService.instance.getCurrentUser();

// تسجيل خروج
await AuthService.instance.signOut();

// التحقق من session
bool hasSession = AuthService.instance.hasActiveSession;

// الاستماع للتغييرات
AuthService.instance.authStateChanges.listen((profile) {
  if (profile != null) {
    print('مسجل دخول: ${profile.name}');
  } else {
    print('مش مسجل دخول');
  }
});
```

### 2. `UserProfile` Model
```dart
class UserProfile {
  final String id;           // من auth.users.id
  final String name;         // اسم المستخدم
  final String phone;        // رقم الموبايل (11 رقم)
  final UserRole role;       // owner أو rep
  final int avatarIndex;     // رقم الأفاتار (0-9)
  final bool isActive;       // نشط/معطل
  final DateTime createdAt;
  final DateTime lastLoginAt;
}

enum UserRole { owner, rep }
```

---

## 🔐 آلية التحويل: Phone → Email

Supabase Auth بيعتمد على Email بشكل أساسي، لكن احنا عايزين رقم موبايل.

**الحل**: بنحول الرقم لإيميل صناعي جوه الكود:
- المستخدم يدخل: `01012345678`
- AuthService يحوله داخلياً لـ: `01012345678@mivet.app`
- Supabase يشوفه كإيميل عادي
- المستخدم **مش بيشوف** الإيميل ده خالص

الكود:
```dart
String _phoneToEmail(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  return '$cleaned@mivet.app';
}
```

---

## 🛡️ الأمان (Security)

### ما تم تطبيقه:
1. ✅ **Row Level Security (RLS)** على جدول `profiles`
   - كل مستخدم يقدر يقرا صفه بس
   - الـ Owner بس اللي يقدر يقرا كل الصفوف

2. ✅ **منع التسجيل الذاتي** من إعدادات Supabase
   - المستخدم العادي مش هيقدر يعمل حساب لنفسه
   - بس الـ Owner (عن طريق Edge Function لاحقاً)

3. ✅ **Environment Variables** للـ keys الحساسة
   - `.env` مش بيترفع على git
   - المفاتيح محمية

4. ✅ **PIN قصير لكن آمن**
   - 4 أرقام كافية للموبايل
   - الأمان الحقيقي في منع إنشاء الحسابات

---

## 🚫 ما لم يتم بعد (للمرحلة القادمة)

- ❌ شاشة Owner لإضافة مندوبين (محتاجة Edge Function)
- ❌ Logout button في الـ UI
- ❌ تحديث profile (الاسم، الصورة)
- ❌ Error handling محسن

---

## 📝 ملاحظات مهمة

1. **`rep_session` القديم**: لسه موجود، مش هنمسحه دلوقتي عشان مش يكسر الكود القديم.  
   لكن `SplashScreen` دلوقتي بيروح على `LoginScreen` بدل `RepEntryScreen`.

2. **Flutter Clean**: لو حصل أي مشكلة بعد الإضافات:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Android Manifest**: لو هتشغل على Android حقيقي (مش emulator)،  
   تأكد من إضافة `<uses-permission android:name="android.permission.INTERNET" />`  
   في `android/app/src/main/AndroidManifest.xml`

4. **التطوير المستقبلي**: 
   - لو عايز تضيف "نسيت الباسورد" → هتحتاج Email OTP حقيقي
   - لو عايز تضيف "Social Login" → ممكن تضيف Google/Apple Sign-In

---

## 🔗 الخطوات التالية

1. **اتبع الدليل في**: `SUPABASE_SETUP.md` لإتمام الإعداد
2. **نسخ والصق SQL**: من ملف `supabase_schema.sql`
3. **اختبار التطبيق**: بعد إنشاء أول owner
4. **(اختياري) إضافة Logout**: في Settings أو Profile screen

---

## 📚 Resources

- [Supabase Docs](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
