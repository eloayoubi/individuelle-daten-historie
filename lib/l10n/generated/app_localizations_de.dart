// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kostenkurve';

  @override
  String get tabOverview => 'Übersicht';

  @override
  String get tabCategories => 'Kategorien';

  @override
  String get tabInsights => 'Auswertung';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get comingSoon => 'Kommt bald.';

  @override
  String get placeholderCategories =>
      'Hier legst du Kategorien an, wählst Vorlagen und baust eigene Felder und Formeln.';

  @override
  String get placeholderInsights =>
      'Verläufe, Jahresvergleiche und Prognosen für jede Kategorie.';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get errorLoad => 'Deine Daten konnten nicht geladen werden.';

  @override
  String get homeQuickAdd => 'Eintrag erfassen';

  @override
  String homeForecastTitle(String year) {
    return 'Prognose $year';
  }

  @override
  String get homeForecastHint =>
      'Hochrechnung aus deinen Verläufen und den gültigen Preisen.';

  @override
  String homeForecastDelta(String change, String year) {
    return '$change ggü. $year';
  }

  @override
  String homeCurveActual(String year) {
    return 'Ist $year';
  }

  @override
  String homeCurveForecast(String year) {
    return 'Prognose $year';
  }

  @override
  String homeYearToDate(String year) {
    return 'Kosten $year bis heute';
  }

  @override
  String homeYearToDateCompare(String change) {
    return '$change ggü. Vorjahreszeitraum';
  }

  @override
  String get homeCategories => 'Kategorien';

  @override
  String get homeSeeAll => 'Alle';

  @override
  String get homeNext => 'Als Nächstes';

  @override
  String homePerMonth(String amount) {
    return 'Ø $amount pro Monat';
  }

  @override
  String homeConsumptionToDate(String value) {
    return '$value bisher';
  }

  @override
  String homeSharedWith(String name) {
    return 'Geteilt mit $name';
  }

  @override
  String homeReadMeter(String tracker) {
    return '$tracker ablesen';
  }

  @override
  String homeReadMeterDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Letzter Stand vor $days Tagen',
      one: 'Letzter Stand vor einem Tag',
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
      other: 'Am $date · in $days Tagen',
      one: 'Morgen',
      zero: 'Heute',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'Noch keine Kategorien';

  @override
  String get homeEmptyBody =>
      'Starte mit einer Vorlage wie Strom, Wasser oder Miete – oder baue dir eine eigene.';

  @override
  String get quickAddTitle => 'Wofür möchtest du etwas eintragen?';

  @override
  String get quickAddSoon => 'Das Erfassen kommt im nächsten Schritt.';

  @override
  String get categoryDetailsSoon =>
      'Die Detailansicht kommt im nächsten Schritt.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get appearanceSystem => 'Automatisch';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get settingsAppearanceHint =>
      '„Automatisch“ folgt der Einstellung deines Geräts.';

  @override
  String get settingsAbout => 'Über Kostenkurve';

  @override
  String get settingsAboutBody =>
      'Deine Zählerstände, Verträge und Kosten an einem Ort – mit Verlauf, Jahresvergleich und Prognose.';
}
