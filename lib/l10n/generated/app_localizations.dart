import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Kostenkurve'**
  String get appTitle;

  /// No description provided for @tabOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get tabOverview;

  /// No description provided for @tabCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get tabCategories;

  /// No description provided for @tabInsights.
  ///
  /// In de, this message translates to:
  /// **'Auswertung'**
  String get tabInsights;

  /// No description provided for @tabSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get tabSettings;

  /// No description provided for @comingSoon.
  ///
  /// In de, this message translates to:
  /// **'Kommt bald.'**
  String get comingSoon;

  /// No description provided for @placeholderCategories.
  ///
  /// In de, this message translates to:
  /// **'Hier legst du Kategorien an, wählst Vorlagen und baust eigene Felder und Formeln.'**
  String get placeholderCategories;

  /// No description provided for @placeholderInsights.
  ///
  /// In de, this message translates to:
  /// **'Verläufe, Jahresvergleiche und Prognosen für jede Kategorie.'**
  String get placeholderInsights;

  /// No description provided for @actionBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// No description provided for @errorLoad.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten konnten nicht geladen werden.'**
  String get errorLoad;

  /// No description provided for @homeQuickAdd.
  ///
  /// In de, this message translates to:
  /// **'Eintrag erfassen'**
  String get homeQuickAdd;

  /// No description provided for @homeForecastTitle.
  ///
  /// In de, this message translates to:
  /// **'Prognose {year}'**
  String homeForecastTitle(String year);

  /// No description provided for @homeForecastHint.
  ///
  /// In de, this message translates to:
  /// **'Hochrechnung aus deinen Verläufen und den gültigen Preisen.'**
  String get homeForecastHint;

  /// No description provided for @homeForecastDelta.
  ///
  /// In de, this message translates to:
  /// **'{change} ggü. {year}'**
  String homeForecastDelta(String change, String year);

  /// No description provided for @homeCurveActual.
  ///
  /// In de, this message translates to:
  /// **'Ist {year}'**
  String homeCurveActual(String year);

  /// No description provided for @homeCurveForecast.
  ///
  /// In de, this message translates to:
  /// **'Prognose {year}'**
  String homeCurveForecast(String year);

  /// No description provided for @homeYearToDate.
  ///
  /// In de, this message translates to:
  /// **'Kosten {year} bis heute'**
  String homeYearToDate(String year);

  /// No description provided for @homeYearToDateCompare.
  ///
  /// In de, this message translates to:
  /// **'{change} ggü. Vorjahreszeitraum'**
  String homeYearToDateCompare(String change);

  /// No description provided for @homeCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get homeCategories;

  /// No description provided for @homeSeeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get homeSeeAll;

  /// No description provided for @homeNext.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes'**
  String get homeNext;

  /// No description provided for @homePerMonth.
  ///
  /// In de, this message translates to:
  /// **'Ø {amount} pro Monat'**
  String homePerMonth(String amount);

  /// No description provided for @homeConsumptionToDate.
  ///
  /// In de, this message translates to:
  /// **'{value} bisher'**
  String homeConsumptionToDate(String value);

  /// No description provided for @homeSharedWith.
  ///
  /// In de, this message translates to:
  /// **'Geteilt mit {name}'**
  String homeSharedWith(String name);

  /// No description provided for @homeReadMeter.
  ///
  /// In de, this message translates to:
  /// **'{tracker} ablesen'**
  String homeReadMeter(String tracker);

  /// No description provided for @homeReadMeterDue.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, =1{Letzter Stand vor einem Tag} other{Letzter Stand vor {days} Tagen}}'**
  String homeReadMeterDue(int days);

  /// No description provided for @homeDeadlineTitle.
  ///
  /// In de, this message translates to:
  /// **'{field} · {tracker}'**
  String homeDeadlineTitle(String field, String tracker);

  /// No description provided for @homeDeadlineDue.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, =0{Heute} =1{Morgen} other{Am {date} · in {days} Tagen}}'**
  String homeDeadlineDue(int days, String date);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Kategorien'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Starte mit einer Vorlage wie Strom, Wasser oder Miete – oder baue dir eine eigene.'**
  String get homeEmptyBody;

  /// No description provided for @quickAddTitle.
  ///
  /// In de, this message translates to:
  /// **'Wofür möchtest du etwas eintragen?'**
  String get quickAddTitle;

  /// No description provided for @quickAddSoon.
  ///
  /// In de, this message translates to:
  /// **'Das Erfassen kommt im nächsten Schritt.'**
  String get quickAddSoon;

  /// No description provided for @categoryDetailsSoon.
  ///
  /// In de, this message translates to:
  /// **'Die Detailansicht kommt im nächsten Schritt.'**
  String get categoryDetailsSoon;

  /// No description provided for @settingsAppearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get settingsAppearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In de, this message translates to:
  /// **'Automatisch'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get appearanceDark;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In de, this message translates to:
  /// **'„Automatisch“ folgt der Einstellung deines Geräts.'**
  String get settingsAppearanceHint;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über Kostenkurve'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Zählerstände, Verträge und Kosten an einem Ort – mit Verlauf, Jahresvergleich und Prognose.'**
  String get settingsAboutBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
