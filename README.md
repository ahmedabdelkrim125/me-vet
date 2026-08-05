# MIVET Sales — Flutter Starter

نسخة بداية (Starter) من متطلبات MIVET بتصميم عصري وبسيط، مبني بخطين عربي: **Cairo** (للنصوص) و **Almarai** (للعناوين والأرقام).

## قبل ما تشغل المشروع

1. انسخ ملفات الخطوط من مشروع Warraq بتاعك (`assets/fonts`) لنفس المكان هنا:
   - `Cairo-ExtraLight.ttf`, `Cairo-Regular.ttf`, `Cairo-Medium.ttf`, `Cairo-Bold.ttf`
   - `Almarai-Regular.ttf` (ولو عندك أوزان تانية لـ Almarai زودها في `pubspec.yaml`)
2. شغّل:
   ```
   flutter pub get
   flutter run
   ```

## هيكل المشروع

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart       ← نظام الألوان
│   │   ├── app_text_styles.dart  ← أنماط النصوص (Cairo + Almarai)
│   │   └── app_theme.dart        ← ThemeData الموحد للتطبيق
│   └── widgets/
│       ├── stat_card.dart        ← كارت إحصائية (KPI)
│       └── shortcut_card.dart    ← كارت اختصار في شبكة الهوم
├── features/
│   ├── auth/presentation/
│   │   └── login_screen.dart     ← شاشة تسجيل الدخول
│   └── home/presentation/
│       └── home_screen.dart      ← الشاشة الرئيسية (Dashboard)
└── main.dart                     ← نقطة الدخول + إعداد RTL
```

## الفلسفة التصميمية

النسخة دي مختلفة عن الـ Prototype الأصلي (اللي كان مصمم كـ Tablet Dashboard مزدحم بالتفاصيل). هنا الهدف تصميم موبايل بسيط ومريح ليوزر عادي:
- مساحات بيضاء أكتر، عناصر أقل زحمة في الشاشة الواحدة
- كروت بحواف دائرية وظلال خفيفة بدل الحدود الحادة
- تدرج لوني (Gradient) في الهيدر وكارت الخط بدل الألوان المسطحة
- الأرقام والعناوين بخط Almarai (أقوى بصريًا) والباقي بخط Cairo

## الخطوة الجاية (مش موجودة في النسخة دي)

- ربط بـ State Management حقيقي (Bloc/Riverpod) بدل الـ mock data
- باقي الشاشات (خط اليوم، كارت العميل، الفاتورة الذكية، المخزون، التنبيهات، الأداء) — راجع ملف `MIVET_Requirements.md` لتفاصيل كل شاشة
- ربط بـ API حقيقي بدل البيانات الوهمية الموجودة في `home_screen.dart`
