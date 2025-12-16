# 🗺️ Mapping - تطبيق رسم الخرائط الزراعية

<div dir="rtl">

تطبيق Flutter متقدم لتحديد ورسم قطع الأراضي الزراعية باستخدام خرائط Mapbox، مع أدوات رسم متطورة ودعم للأشكال الجاهزة والمخصصة.

</div>

---

## 📱 نظرة عامة / Overview

<div dir="rtl">

**Mapping** هو تطبيق مصمم خصيصاً للمزارعين وملاك الأراضي الزراعية لتحديد قطع أراضيهم بدقة عالية على الخرائط. يوفر التطبيق ثلاثة أوضاع للرسم مع أدوات تحكم احترافية وحسابات جغرافية دقيقة.

</div>

**Mapping** is a Flutter application specifically designed for farmers and landowners to accurately define their agricultural parcels on maps. It provides three drawing modes with professional controls and precise geographic calculations.

---

## ✨ الميزات الرئيسية / Key Features

### 🎨 أوضاع الرسم المتعددة / Multiple Drawing Modes

<div dir="rtl">

#### 1. **أشكال جاهزة** (Predefined Shapes)
- دائرة (Circle) ⭕
- مربع (Square) ◻
- شبه منحرف (Trapezoid) ⏢
- بيضاوي (Ellipse) ⬭

**المميزات:**
- قوالب جاهزة للحقول الشائعة (قمح، ذرة، خضروات)
- تحكم كامل بالحجم والتدوير
- إيماءات Pinch للتكبير/التصغير
- سحب لتحريك الشكل

#### 2. **رسم مخصص** (Custom Points)
- رسم نقطة بنقطة
- يدعم أي شكل غير منتظم
- تحديد دقيق للحدود
- مقبض مركزي لتحريك الشكل بالكامل

#### 3. **رسم حر** (Freehand)
- رسم الحدود بحركة مستمرة
- مثالي للأشكال المعقدة
- تتبع حركة الإصبع بدقة

</div>

### 📏 حسابات جغرافية دقيقة / Accurate Geographic Calculations

<div dir="rtl">

- **حساب المساحة** بدقة باستخدام Turf.js
- **دعم وحدات قياس متعددة:**
  - متر مربع (m²)
  - دونم (1000 m²) - شائع في سوريا والأردن والعراق
  - هكتار (10,000 m²) - المعيار الدولي
  - فدان (4,200 m²) - شائع في مصر والسودان

</div>

- **Area calculation** with precision using Turf.js
- **Multiple measurement units support:**
  - Square meters (m²)
  - Donum (1000 m²) - Common in Syria, Jordan, Iraq
  - Hectare (10,000 m²) - International standard
  - Feddan (4,200 m²) - Common in Egypt, Sudan

### 🗺️ خرائط متقدمة / Advanced Maps

<div dir="rtl">

- تكامل كامل مع **Mapbox Maps**
- التبديل بين عرض الخريطة والأقمار الصناعية
- تحديد الموقع التلقائي (GPS)
- بحث عن المواقع
  
</div>

- Full **Mapbox Maps** integration
- Switch between map and satellite views
- Automatic location detection (GPS)
- Location search

### 💾 إدارة البيانات / Data Management

<div dir="rtl">

- حفظ محلي باستخدام **Hive**
- تعديل معلومات الأراضي
- حذف القطع
- عرض قائمة جميع الأراضي المحفوظة
- التنقل السريع إلى أي قطعة على الخريطة

</div>

- Local storage using **Hive**
- Edit parcel information
- Delete parcels
- View list of all saved parcels
- Quick navigation to any parcel on map

---

## 🏗️ البنية المعمارية / Architecture

### 📂 هيكل المشروع / Project Structure

```
lib/
├── config/              # تكوينات التطبيق (Mapbox, etc.)
├── models/              # نماذج البيانات (LandParcel, ShapeTemplate, etc.)
├── providers/           # إدارة الحالة (Provider Pattern)
│   ├── drawing_provider.dart       # منطق الرسم
│   ├── parcels_provider.dart       # إدارة الأراضي
│   ├── location_provider.dart      # خدمات الموقع
│   └── map_state_provider.dart     # حالة الخريطة
├── services/            # الخدمات (Storage, API, Geo calculations)
│   ├── storage_service.dart        # Hive storage
│   ├── turf_service.dart          # حسابات جغرافية
│   └── geo_calculations.dart       # عمليات جيومترية
├── utils/              # أدوات مساعدة (Constants, Colors, Enums)
├── views/              # الشاشات الرئيسية
│   ├── map_screen.dart            # الشاشة الرئيسية
│   └── parcels_list_screen.dart   # قائمة الأراضي
└── widgets/            # مكونات UI قابلة لإعادة الاستخدام
    ├── drawing/        # أدوات الرسم
    │   ├── mode_selector.dart
    │   ├── shape_controls.dart
    │   ├── template_selector.dart
    │   └── drawing_toolbar.dart
    └── map/            # مكونات الخريطة
        ├── mapbox_view.dart
        └── location_search_bar.dart
```

### 🔧 التقنيات المستخدمة / Tech Stack

| التقنية / Technology | الاستخدام / Usage | الإصدار / Version |
|---------------------|-------------------|------------------|
| **Flutter** | إطار العمل الأساسي | SDK >=3.4.0 |
| **Mapbox Maps** | خرائط تفاعلية | ^2.12.0 |
| **Provider** | إدارة الحالة | ^6.1.2 |
| **Hive** | قاعدة بيانات محلية | ^2.2.3 |
| **Turf** | عمليات جيومترية | ^0.0.9 |
| **Geolocator** | خدمات الموقع | ^13.0.2 |
| **FL Chart** | الرسوم البيانية | ^0.69.0 |

---

## 🚀 التثبيت والتشغيل / Installation & Setup

### المتطلبات / Prerequisites

<div dir="rtl">

- Flutter SDK (>= 3.4.0)
- Dart SDK
- Mapbox Access Token
- محرر كود (VS Code / Android Studio)

</div>

### خطوات التثبيت / Installation Steps

```bash
# 1. استنساخ المشروع / Clone repository
git clone https://github.com/Mo-Alshebli/mapping.git
cd mapping

# 2. تثبيت الحزم / Install dependencies
flutter pub get

# 3. توليد الأكواد / Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. إعداد Mapbox Token
# أنشئ ملف في lib/config/mapbox_config.dart وأضف:
class MapboxConfig {
  static const String accessToken = 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';
  static const String streets = 'mapbox://styles/mapbox/streets-v12';
  static const String satelliteStreets = 'mapbox://styles/mapbox/satellite-streets-v12';
}

# 5. تشغيل التطبيق / Run app
flutter run
```

### الحصول على Mapbox Token / Getting Mapbox Token

<div dir="rtl">

1. سجل حساب مجاني على [Mapbox](https://account.mapbox.com/auth/signup/)
2. انتقل إلى [Access Tokens](https://account.mapbox.com/access-tokens/)
3. انسخ Default Public Token أو أنشئ token جديد
4. ضعه في `mapbox_config.dart`

</div>

---

## 📖 دليل الاستخدام / User Guide

### رسم قطعة أرض / Drawing a Parcel

<div dir="rtl">

#### باستخدام الأشكال الجاهزة:

1. اضغط على زر "رسم قطعة أرض"
2. اختر "أشكال جاهزة"
3. اختر الشكل المطلوب (دائرة، مربع، إلخ)
4. اضغط على الخريطة لتحديد المركز
5. استخدم إصبعين للتكبير/التصغير
6. اسحب الشكل لتحريكه
7. اضغط "إكمال" عند الانتهاء

#### باستخدام الرسم المخصص:

1. اختر "رسم مخصص"
2. اضغط على الخريطة لإضافة نقاط (يحب 3 نقاط على الأقل)
3. قم بتحريك الخريطة أو استخدم مقبض المركز للتعديل
4. اضغط "إكمال" للحفظ

#### باستخدام الرسم الحر:

1. اختر "رسم حر"
2. اسحب إصبعك على الخريطة لرسم الحدود
3. اضغط "إكمال" للحفظ

</div>

### أدوات التحكم / Control Tools

<div dir="rtl">

**أثناء الرسم:**
- 🔒 **زر القفل**: تفعيل/تعطيل حركة الخريطة
- ↩️ **تراجع**: التراجع عن آخر نقطة
- 🗑️ **مسح**: حذف جميع النقاط
- ✅ **إكمال**: حفظ القطعة

**للأشكال الجاهزة:**
- 🔍 **Pinch**: التكبير/التصغير
- 🔄 **إصبعين ودوران**: تدوير الشكل
- 👆 **السحب**: تحريك الشكل
- 📏 **Slider**: تعديل الحجم بدقة

</div>

---

## 🎯 الميزات المتقدمة / Advanced Features

### حساب المساحة التلقائي / Automatic Area Calculation

<div dir="rtl">

- حساب فوري للمساحة أثناء الرسم
- عرض المساحة بالوحدة المفضلة
- دقة عالية باستخدام خوارزميات Turf.js

</div>

### القوالب الجاهزة / Pre-defined Templates

<div dir="rtl">

قوالب مخصصة لأنواع المحاصيل الشائعة:
- حقل قمح دائري (100م نصف قطر)
- حقل ذرة مربع (100م ضلع)
- حقل خضروات شبه منحرف
- أرض بيضاوية للأعلاف

</div>

### تحكم بالإيماءات / Gesture Controls

<div dir="rtl">

- **Throttling ذكي**: تحديث الرسومات بمعدل 30fps لأداء سلس
- **تحكم دقيق**: حساسية محسّنة للحركة والتكبير
- **History**: نظام Undo/Redo كامل

</div>

---

## 🧪 الاختبار / Testing

```bash
# تشغيل جميع الاختبارات / Run all tests
flutter test

# تحليل الكود / Analyze code
flutter analyze

# تنسيق الكود / Format code
dart format lib/
```

---

## 📊 الأداء / Performance

<div dir="rtl">

### التحسينات المطبقة:

- ✅ **Throttling**: تحديد معدل التحديثات لمنع التأخير
- ✅ **Lazy Loading**: تحميل البيانات عند الحاجة فقط
- ✅ **Optimized Rendering**: رسومات محسّنة للأشكال المعقدة
- ✅ **Clean Architecture**: كود منظم وسهل الصيانة

### الإحصائيات:

- 📉 حذف **50+ سطر** من التكرارات
- 🎯 دمج **3 دوال** في دالة واحدة محسّنة
- 🚀 أداء سلس على جميع الأجهزة

</div>

---

## 🤝 المساهمة / Contributing

<div dir="rtl">

نرحب بالمساهمات! إذا كنت تريد المساهمة:

1. Fork المشروع
2. أنشئ فرع للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push للفرع (`git push origin feature/AmazingFeature`)
5. افتح Pull Request

</div>

---

## 📝 الترخيص / License

<div dir="rtl">

هذا المشروع مرخص تحت رخصة MIT - انظر ملف [LICENSE](LICENSE) للتفاصiل.

</div>

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 المطور / Developer

**Mohammed Alshebli** - [@Mo-Alshebli](https://github.com/Mo-Alshebli)

---

## 🙏 شكر وتقدير / Acknowledgments

<div dir="rtl">

- [Mapbox](https://www.mapbox.com/) - خدمات الخرائط
- [Turf.js](https://turfjs.org/) - العمليات الجيومترية
- [Flutter Team](https://flutter.dev/) - إطار العمل الرائع

</div>

---

## 📧 التواصل / Contact

<div dir="rtl">

لأي استفسارات أو اقتراحات، يرجى فتح [Issue](https://github.com/Mo-Alshebli/mapping/issues) على GitHub.

</div>

For questions or suggestions, please open an [Issue](https://github.com/Mo-Alshebli/mapping/issues) on GitHub.

---

<div align="center" dir="rtl">

**صُنع بـ ❤️ باستخدام Flutter**

Made with ❤️ using Flutter

</div>
