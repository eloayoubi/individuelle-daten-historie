// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kostenkurve';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabSettings => 'Settings';

  @override
  String get comingSoon => 'Coming soon.';

  @override
  String get placeholderCategories =>
      'Create categories, pick templates and build your own fields and formulas here.';

  @override
  String get placeholderInsights =>
      'Histories, year-over-year comparisons and forecasts for every category.';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Try again';

  @override
  String get errorLoad => 'Your data couldn\'t be loaded.';

  @override
  String get homeQuickAdd => 'Add entry';

  @override
  String homeForecastTitle(String year) {
    return 'Forecast $year';
  }

  @override
  String get homeForecastHint =>
      'Projected from your history and current prices.';

  @override
  String homeForecastDelta(String change, String year) {
    return '$change vs. $year';
  }

  @override
  String homeCurveActual(String year) {
    return 'Actual $year';
  }

  @override
  String homeCurveForecast(String year) {
    return 'Forecast $year';
  }

  @override
  String homeYearToDate(String year) {
    return 'Costs $year to date';
  }

  @override
  String homeYearToDateCompare(String change) {
    return '$change vs. same period last year';
  }

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNext => 'Up next';

  @override
  String homePerMonth(String amount) {
    return 'avg. $amount per month';
  }

  @override
  String homeConsumptionToDate(String value) {
    return '$value so far';
  }

  @override
  String homeSharedWith(String name) {
    return 'Shared with $name';
  }

  @override
  String homeReadMeter(String tracker) {
    return 'Read $tracker';
  }

  @override
  String homeReadMeterDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last reading $days days ago',
      one: 'Last reading one day ago',
    );
    return '$_temp0';
  }

  @override
  String homeDeadlineTitle(String field, String tracker) {
    return '$field · $tracker';
  }

  @override
  String homeDeadlineDue(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'On $date · in $days days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'No categories yet';

  @override
  String get homeEmptyBody =>
      'Start with a template like electricity, water or rent – or build your own.';

  @override
  String get quickAddTitle => 'What would you like to log?';

  @override
  String get quickAddSoon => 'Logging is coming in the next step.';

  @override
  String get categoryDetailsSoon =>
      'The detail view is coming in the next step.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceSystem => 'Automatic';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get settingsAppearanceHint =>
      '“Automatic” follows your device setting.';

  @override
  String get settingsAbout => 'About Kostenkurve';

  @override
  String get settingsAboutBody =>
      'Your meter readings, contracts and costs in one place – with history, year-over-year comparison and forecast.';
}
