class MapConstants {
  // Default Map Settings
  static const double defaultZoom = 13.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 20.0;

  // Default Center (Riyadh)
  static const double defaultLatitude = 24.7136;
  static const double defaultLongitude = 46.6753;

  // Drawing Settings
  static const double polygonStrokeWidth = 3.0;
  static const double pointRadius = 8.0;

  // Chart Sizes
  static const double chartWidth = 140.0;
  static const double chartHeight = 140.0;
  static const double chartPadding = 12.0;

  // Marker Sizes
  static const double markerSizeSmall = 20.0;
  static const double markerSizeMedium = 30.0;
  static const double markerSizeLarge = 40.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

class AppStrings {
  // Arabic Strings
  static const String appName = 'نظام الخرائط الزراعي';
  static const String myParcels = 'أراضيني';
  static const String addParcel = 'إضافة أرض';
  static const String drawParcel = 'رسم الأرض';
  static const String cancelDrawing = 'إلغاء';
  static const String completeDrawing = 'إكمال الرسم';
  static const String parcelDetails = 'تفاصيل الأرض';
  static const String statistics = 'الإحصائيات';
  static const String health = 'الصحة';
  static const String moisture = 'الرطوبة';
  static const String lastIrrigation = 'آخر ري';
  static const String area = 'المساحة';
  static const String cropType = 'نوع المحصول';
  static const String loading = 'جاري التحميل...';
  static const String error = 'خطأ';
  static const String retry = 'إعادة المحاولة';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
}
