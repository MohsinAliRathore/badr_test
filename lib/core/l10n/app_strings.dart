import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ??
        AppStrings(const Locale('en'));
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get appTitle => _t('badrgo Ops Console', 'وحدة عمليات بادر جو');
  String get signIn => _t('Sign in', 'تسجيل الدخول');
  String get email => _t('Email', 'البريد الإلكتروني');
  String get password => _t('Password', 'كلمة المرور');
  String get signOut => _t('Sign out', 'تسجيل الخروج');
  String get navDashboard => _t('Dashboard', 'لوحة المؤشرات');
  String get navTrips => _t('Trips', 'الرحلات');
  String get navMap => _t('Live map', 'الخريطة');
  String get navAlerts => _t('Alerts', 'التنبيهات');
  String get navDrivers => _t('Drivers', 'السائقون');
  String get navRiders => _t('Riders', 'الركاب');
  String get navUsers => _t('Users', 'المستخدمون');
  String get noAccess => _t('No access', 'لا يوجد وصول');
  String get noAccessBody =>
      _t('You do not have access to this page.', 'ليس لديك صلاحية لعرض هذه الصفحة.');
  String get notFound => _t('Not found', 'غير موجود');
  String get maintenance => _t('Maintenance', 'صيانة');
  String get reconnecting => _t('Reconnecting realtime…', 'إعادة الاتصال…');
  String get offline => _t('You are offline', 'أنت غير متصل');
  String get live => _t('Live', 'مباشر');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get language => _t('Language', 'اللغة');
  String get theme => _t('Theme', 'المظهر');
  String get darkMode => _t('Dark mode', 'الوضع الداكن');
  String get lightMode => _t('Light mode', 'الوضع الفاتح');
  String get systemTheme => _t('System', 'النظام');
  String get acknowledge => _t('Acknowledge', 'إقرار');
  String get assignDriver => _t('Assign driver', 'تعيين سائق');
  String get cancel => _t('Cancel', 'إلغاء');
  String get refund => _t('Refund', 'استرداد');
  String get search => _t('Search', 'بحث');
  String get create => _t('Create', 'إنشاء');
  String get save => _t('Save', 'حفظ');
  String get ban => _t('Ban', 'حظر');
  String get unban => _t('Unban', 'رفع الحظر');
  String get chat => _t('Chat', 'محادثة');
  String get send => _t('Send', 'إرسال');
  String get fromDate => _t('From', 'من');
  String get toDate => _t('To', 'إلى');
  String get loadMore => _t('Load more', 'تحميل المزيد');

  String labelFor(String key) {
    switch (key) {
      case 'navDashboard':
        return navDashboard;
      case 'navTrips':
        return navTrips;
      case 'navMap':
        return navMap;
      case 'navAlerts':
        return navAlerts;
      case 'navDrivers':
        return navDrivers;
      case 'navRiders':
        return navRiders;
      case 'navUsers':
        return navUsers;
      default:
        return key;
    }
  }

  String _t(String en, String ar) => isArabic ? ar : en;
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
