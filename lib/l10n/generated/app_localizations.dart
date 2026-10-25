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

  /// No description provided for @homeStartOverline.
  ///
  /// In de, this message translates to:
  /// **'Erste Schritte'**
  String get homeStartOverline;

  /// No description provided for @homeStartTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Kostenkurve wartet auf den ersten Eintrag'**
  String get homeStartTitle;

  /// No description provided for @homeStartBody.
  ///
  /// In de, this message translates to:
  /// **'Trag einen Zählerstand, einen Abschlag oder eine Rechnung ein – daraus entstehen deine Kosten seit Januar, der Verlauf und die Prognose.'**
  String get homeStartBody;

  /// No description provided for @homeStartStepCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien angelegt'**
  String get homeStartStepCategories;

  /// No description provided for @homeStartStepEntry.
  ///
  /// In de, this message translates to:
  /// **'Ersten Stand oder Betrag eintragen'**
  String get homeStartStepEntry;

  /// No description provided for @homeStartStepForecast.
  ///
  /// In de, this message translates to:
  /// **'Prognose für {year} ansehen'**
  String homeStartStepForecast(String year);

  /// No description provided for @homeStartAction.
  ///
  /// In de, this message translates to:
  /// **'Ersten Eintrag erfassen'**
  String get homeStartAction;

  /// No description provided for @quickAddTitle.
  ///
  /// In de, this message translates to:
  /// **'Wofür möchtest du etwas eintragen?'**
  String get quickAddTitle;

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

  /// No description provided for @actionSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// No description provided for @actionArchive.
  ///
  /// In de, this message translates to:
  /// **'Archivieren'**
  String get actionArchive;

  /// No description provided for @actionEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get actionEdit;

  /// No description provided for @actionDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get actionDone;

  /// No description provided for @errorSave.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Bitte versuch es noch einmal.'**
  String get errorSave;

  /// No description provided for @categoriesAdd.
  ///
  /// In de, this message translates to:
  /// **'Kategorie hinzufügen'**
  String get categoriesAdd;

  /// No description provided for @categoriesChooseTemplate.
  ///
  /// In de, this message translates to:
  /// **'Vorlage wählen'**
  String get categoriesChooseTemplate;

  /// No description provided for @categoriesReorderHint.
  ///
  /// In de, this message translates to:
  /// **'Ziehe Kategorien an die Stelle, an der du sie sehen möchtest.'**
  String get categoriesReorderHint;

  /// No description provided for @categoriesArchived.
  ///
  /// In de, this message translates to:
  /// **'Archiviert'**
  String get categoriesArchived;

  /// No description provided for @categoriesRestore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get categoriesRestore;

  /// No description provided for @categoriesRestored.
  ///
  /// In de, this message translates to:
  /// **'{name} ist wieder da.'**
  String categoriesRestored(String name);

  /// No description provided for @categoryTrackers.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Tracker} =1{1 Tracker} other{{count} Tracker}}'**
  String categoryTrackers(int count);

  /// No description provided for @newCategoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Kategorie'**
  String get newCategoryTitle;

  /// No description provided for @newCategoryCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene Kategorie'**
  String get newCategoryCustom;

  /// No description provided for @newCategoryCustomHint.
  ///
  /// In de, this message translates to:
  /// **'Name, Symbol und Felder selbst festlegen'**
  String get newCategoryCustomHint;

  /// No description provided for @newCategoryTemplates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get newCategoryTemplates;

  /// No description provided for @setupNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name, z. B. Strom'**
  String get setupNameHint;

  /// No description provided for @setupSymbol.
  ///
  /// In de, this message translates to:
  /// **'Symbol'**
  String get setupSymbol;

  /// No description provided for @setupColor.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get setupColor;

  /// No description provided for @setupFields.
  ///
  /// In de, this message translates to:
  /// **'Felder'**
  String get setupFields;

  /// No description provided for @setupFieldsHint.
  ///
  /// In de, this message translates to:
  /// **'Abgewählte Felder fehlen nur am Anfang – du kannst später alles ändern und ergänzen.'**
  String get setupFieldsHint;

  /// No description provided for @setupCustomHint.
  ///
  /// In de, this message translates to:
  /// **'Danach legst du Tracker an – z. B. einen Zähler, einen Vertrag oder ein Auto – und gibst ihnen eigene Felder.'**
  String get setupCustomHint;

  /// No description provided for @setupCreate.
  ///
  /// In de, this message translates to:
  /// **'Kategorie anlegen'**
  String get setupCreate;

  /// No description provided for @setupCreated.
  ///
  /// In de, this message translates to:
  /// **'{name} ist angelegt.'**
  String setupCreated(String name);

  /// No description provided for @detailEditCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie bearbeiten'**
  String get detailEditCategory;

  /// No description provided for @detailAddTracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker hinzufügen'**
  String get detailAddTracker;

  /// No description provided for @detailAddField.
  ///
  /// In de, this message translates to:
  /// **'Feld hinzufügen'**
  String get detailAddField;

  /// No description provided for @detailEditTracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker bearbeiten'**
  String get detailEditTracker;

  /// No description provided for @detailNoTrackersTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tracker'**
  String get detailNoTrackersTitle;

  /// No description provided for @detailNoTrackersBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Tracker ist z. B. ein Zähler, ein Vertrag oder ein Auto – mit eigenen Feldern.'**
  String get detailNoTrackersBody;

  /// No description provided for @detailNoFields.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Felder'**
  String get detailNoFields;

  /// No description provided for @detailArchive.
  ///
  /// In de, this message translates to:
  /// **'Kategorie archivieren'**
  String get detailArchive;

  /// No description provided for @detailArchiveTitle.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ archivieren?'**
  String detailArchiveTitle(String name);

  /// No description provided for @detailArchiveBody.
  ///
  /// In de, this message translates to:
  /// **'Die Kategorie verschwindet aus Übersicht und Auswertung. Unter „Archiviert“ kannst du sie jederzeit wiederherstellen.'**
  String get detailArchiveBody;

  /// No description provided for @detailArchived.
  ///
  /// In de, this message translates to:
  /// **'{name} ist archiviert.'**
  String detailArchived(String name);

  /// No description provided for @detailReadOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur lesen – {name} hat diese Kategorie mit dir geteilt.'**
  String detailReadOnly(String name);

  /// No description provided for @detailReadOnlyUnknown.
  ///
  /// In de, this message translates to:
  /// **'Nur lesen – diese Kategorie wurde mit dir geteilt.'**
  String get detailReadOnlyUnknown;

  /// No description provided for @detailMissing.
  ///
  /// In de, this message translates to:
  /// **'Diese Kategorie gibt es nicht mehr.'**
  String get detailMissing;

  /// No description provided for @detailTrackerAdded.
  ///
  /// In de, this message translates to:
  /// **'Tracker angelegt.'**
  String get detailTrackerAdded;

  /// No description provided for @detailTrackerArchived.
  ///
  /// In de, this message translates to:
  /// **'Tracker archiviert.'**
  String get detailTrackerArchived;

  /// No description provided for @trackerNew.
  ///
  /// In de, this message translates to:
  /// **'Neuer Tracker'**
  String get trackerNew;

  /// No description provided for @trackerNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name, z. B. Hauptzähler'**
  String get trackerNameHint;

  /// No description provided for @trackerArchive.
  ///
  /// In de, this message translates to:
  /// **'Tracker archivieren'**
  String get trackerArchive;

  /// No description provided for @trackerArchiveTitle.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ archivieren?'**
  String trackerArchiveTitle(String name);

  /// No description provided for @trackerArchiveBody.
  ///
  /// In de, this message translates to:
  /// **'Der Tracker und seine Einträge verschwinden aus Übersicht und Auswertung.'**
  String get trackerArchiveBody;

  /// No description provided for @fieldNew.
  ///
  /// In de, this message translates to:
  /// **'Neues Feld'**
  String get fieldNew;

  /// No description provided for @fieldNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name, z. B. Zählerstand'**
  String get fieldNameHint;

  /// No description provided for @fieldKind.
  ///
  /// In de, this message translates to:
  /// **'Feldtyp'**
  String get fieldKind;

  /// No description provided for @fieldRole.
  ///
  /// In de, this message translates to:
  /// **'Zeitverhalten'**
  String get fieldRole;

  /// No description provided for @fieldRoleFooter.
  ///
  /// In de, this message translates to:
  /// **'Bestimmt, wie Verlauf, Kosten und Prognose mit dem Wert rechnen.'**
  String get fieldRoleFooter;

  /// No description provided for @fieldKindLocked.
  ///
  /// In de, this message translates to:
  /// **'Passt nicht zu den gespeicherten Werten'**
  String get fieldKindLocked;

  /// No description provided for @fieldUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get fieldUnit;

  /// No description provided for @fieldUnitHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. kWh'**
  String get fieldUnitHint;

  /// No description provided for @fieldMeter.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get fieldMeter;

  /// No description provided for @fieldConsumptionUnitLabel.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch in'**
  String get fieldConsumptionUnitLabel;

  /// No description provided for @fieldConsumptionUnitHint.
  ///
  /// In de, this message translates to:
  /// **'wie Einheit'**
  String get fieldConsumptionUnitHint;

  /// No description provided for @fieldFactorLabel.
  ///
  /// In de, this message translates to:
  /// **'Umrechnungsfaktor'**
  String get fieldFactorLabel;

  /// No description provided for @fieldFactorFooter.
  ///
  /// In de, this message translates to:
  /// **'Gas: Brennwert × Zustandszahl von deiner Abrechnung (meist um 10,5). Sonst 1.'**
  String get fieldFactorFooter;

  /// No description provided for @fieldFactorInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl größer als 0 eingeben.'**
  String get fieldFactorInvalid;

  /// No description provided for @fieldInterval.
  ///
  /// In de, this message translates to:
  /// **'Fällig'**
  String get fieldInterval;

  /// No description provided for @fieldChoices.
  ///
  /// In de, this message translates to:
  /// **'Auswahlwerte'**
  String get fieldChoices;

  /// No description provided for @fieldChoiceHint.
  ///
  /// In de, this message translates to:
  /// **'Neuer Wert, z. B. 3 Monate'**
  String get fieldChoiceHint;

  /// No description provided for @fieldChoiceRemove.
  ///
  /// In de, this message translates to:
  /// **'{choice} entfernen'**
  String fieldChoiceRemove(String choice);

  /// No description provided for @fieldChoicesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Mindestens einen Wert hinzufügen.'**
  String get fieldChoicesEmpty;

  /// No description provided for @fieldArchive.
  ///
  /// In de, this message translates to:
  /// **'Feld entfernen'**
  String get fieldArchive;

  /// No description provided for @fieldKeepsBills.
  ///
  /// In de, this message translates to:
  /// **'Deine Rechnungen brauchen diesen Arbeitspreis – er bleibt ein Preis je Einheit und lässt sich nicht archivieren.'**
  String get fieldKeepsBills;

  /// No description provided for @fieldArchiveTitle.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ entfernen?'**
  String fieldArchiveTitle(String name);

  /// No description provided for @fieldArchiveBody.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Werte bleiben erhalten, das Feld erscheint aber nicht mehr.'**
  String get fieldArchiveBody;

  /// No description provided for @fieldSaved.
  ///
  /// In de, this message translates to:
  /// **'Feld gespeichert.'**
  String get fieldSaved;

  /// No description provided for @fieldArchived.
  ///
  /// In de, this message translates to:
  /// **'Feld entfernt.'**
  String get fieldArchived;

  /// No description provided for @kindText.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get kindText;

  /// No description provided for @kindNumber.
  ///
  /// In de, this message translates to:
  /// **'Zahl'**
  String get kindNumber;

  /// No description provided for @kindCurrency.
  ///
  /// In de, this message translates to:
  /// **'Betrag (€)'**
  String get kindCurrency;

  /// No description provided for @kindPercent.
  ///
  /// In de, this message translates to:
  /// **'Prozent'**
  String get kindPercent;

  /// No description provided for @kindDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get kindDate;

  /// No description provided for @kindToggle.
  ///
  /// In de, this message translates to:
  /// **'Ja/Nein'**
  String get kindToggle;

  /// No description provided for @kindChoice.
  ///
  /// In de, this message translates to:
  /// **'Auswahl'**
  String get kindChoice;

  /// No description provided for @kindFormula.
  ///
  /// In de, this message translates to:
  /// **'Formel'**
  String get kindFormula;

  /// No description provided for @roleInfo.
  ///
  /// In de, this message translates to:
  /// **'Detail'**
  String get roleInfo;

  /// No description provided for @roleInfoHint.
  ///
  /// In de, this message translates to:
  /// **'Legst du einmal fest, z. B. Anbieter oder Vertragsnummer – nicht bei jedem Eintrag'**
  String get roleInfoHint;

  /// No description provided for @roleSnapshot.
  ///
  /// In de, this message translates to:
  /// **'Momentwert'**
  String get roleSnapshot;

  /// No description provided for @roleSnapshotHint.
  ///
  /// In de, this message translates to:
  /// **'Gilt am Tag des Eintrags, z. B. Füllstand'**
  String get roleSnapshotHint;

  /// No description provided for @roleMeterReading.
  ///
  /// In de, this message translates to:
  /// **'Zählerstand'**
  String get roleMeterReading;

  /// No description provided for @roleMeterReadingHint.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch ist die Differenz zweier Stände'**
  String get roleMeterReadingHint;

  /// No description provided for @roleUnitPrice.
  ///
  /// In de, this message translates to:
  /// **'Preis je Einheit'**
  String get roleUnitPrice;

  /// No description provided for @roleUnitPriceHint.
  ///
  /// In de, this message translates to:
  /// **'Gilt ab dem Datum – Verbrauch × Preis ergibt die Kosten'**
  String get roleUnitPriceHint;

  /// No description provided for @roleRecurringCost.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrender Betrag'**
  String get roleRecurringCost;

  /// No description provided for @roleRecurringCostHint.
  ///
  /// In de, this message translates to:
  /// **'Gilt ab dem Datum, z. B. Miete, Grundpreis oder Abo'**
  String get roleRecurringCostHint;

  /// No description provided for @roleOneOffCost.
  ///
  /// In de, this message translates to:
  /// **'Einmaliger Betrag'**
  String get roleOneOffCost;

  /// No description provided for @roleOneOffCostHint.
  ///
  /// In de, this message translates to:
  /// **'Zählt am Tag des Eintrags, z. B. Tanken oder Nachzahlung'**
  String get roleOneOffCostHint;

  /// No description provided for @roleDeadline.
  ///
  /// In de, this message translates to:
  /// **'Stichtag'**
  String get roleDeadline;

  /// No description provided for @roleDeadlineHint.
  ///
  /// In de, this message translates to:
  /// **'Legst du einmal fest und wirst rechtzeitig erinnert, z. B. Vertragsende'**
  String get roleDeadlineHint;

  /// No description provided for @intervalMonthly.
  ///
  /// In de, this message translates to:
  /// **'Monatlich'**
  String get intervalMonthly;

  /// No description provided for @intervalQuarterly.
  ///
  /// In de, this message translates to:
  /// **'Vierteljährlich'**
  String get intervalQuarterly;

  /// No description provided for @intervalYearly.
  ///
  /// In de, this message translates to:
  /// **'Jährlich'**
  String get intervalYearly;

  /// No description provided for @intervalMonths.
  ///
  /// In de, this message translates to:
  /// **'Alle {months} Monate'**
  String intervalMonths(int months);

  /// No description provided for @unitPerMonth.
  ///
  /// In de, this message translates to:
  /// **'€/Monat'**
  String get unitPerMonth;

  /// No description provided for @unitPerYear.
  ///
  /// In de, this message translates to:
  /// **'€/Jahr'**
  String get unitPerYear;

  /// No description provided for @tplStrom.
  ///
  /// In de, this message translates to:
  /// **'Strom'**
  String get tplStrom;

  /// No description provided for @tplStromHint.
  ///
  /// In de, this message translates to:
  /// **'Zählerstand, Arbeitspreis, Grundpreis und Vertragsende'**
  String get tplStromHint;

  /// No description provided for @tplHeizung.
  ///
  /// In de, this message translates to:
  /// **'Heizung'**
  String get tplHeizung;

  /// No description provided for @tplHeizungHint.
  ///
  /// In de, this message translates to:
  /// **'Gaszähler mit Umrechnung in kWh, Preise und Vertrag'**
  String get tplHeizungHint;

  /// No description provided for @tplWasser.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get tplWasser;

  /// No description provided for @tplWasserHint.
  ///
  /// In de, this message translates to:
  /// **'Wasserzähler und Preis je Kubikmeter'**
  String get tplWasserHint;

  /// No description provided for @tplMiete.
  ///
  /// In de, this message translates to:
  /// **'Miete & Nebenkosten'**
  String get tplMiete;

  /// No description provided for @tplMieteHint.
  ///
  /// In de, this message translates to:
  /// **'Kaltmiete, Vorauszahlung und Abrechnungen'**
  String get tplMieteHint;

  /// No description provided for @tplAuto.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get tplAuto;

  /// No description provided for @tplAutoHint.
  ///
  /// In de, this message translates to:
  /// **'Kilometerstand, Tanken, Versicherung, Steuer und HU'**
  String get tplAutoHint;

  /// No description provided for @tplInternet.
  ///
  /// In de, this message translates to:
  /// **'Internet & Mobilfunk'**
  String get tplInternet;

  /// No description provided for @tplInternetHint.
  ///
  /// In de, this message translates to:
  /// **'Verträge mit Preis und Mindestlaufzeit'**
  String get tplInternetHint;

  /// No description provided for @tplVersicherung.
  ///
  /// In de, this message translates to:
  /// **'Versicherungen'**
  String get tplVersicherung;

  /// No description provided for @tplVersicherungHint.
  ///
  /// In de, this message translates to:
  /// **'Beiträge, Versicherungsnummer und Fälligkeit'**
  String get tplVersicherungHint;

  /// No description provided for @tplAbos.
  ///
  /// In de, this message translates to:
  /// **'Abos & Mitgliedschaften'**
  String get tplAbos;

  /// No description provided for @tplAbosHint.
  ///
  /// In de, this message translates to:
  /// **'Streaming, Fitnessstudio & Co. mit Kündigungsdatum'**
  String get tplAbosHint;

  /// No description provided for @tplTrackerElectricityMeter.
  ///
  /// In de, this message translates to:
  /// **'Stromzähler'**
  String get tplTrackerElectricityMeter;

  /// No description provided for @tplTrackerGasMeter.
  ///
  /// In de, this message translates to:
  /// **'Gaszähler'**
  String get tplTrackerGasMeter;

  /// No description provided for @tplTrackerWaterMeter.
  ///
  /// In de, this message translates to:
  /// **'Wasserzähler'**
  String get tplTrackerWaterMeter;

  /// No description provided for @tplTrackerFlat.
  ///
  /// In de, this message translates to:
  /// **'Wohnung'**
  String get tplTrackerFlat;

  /// No description provided for @tplTrackerCar.
  ///
  /// In de, this message translates to:
  /// **'Mein Auto'**
  String get tplTrackerCar;

  /// No description provided for @tplTrackerInternet.
  ///
  /// In de, this message translates to:
  /// **'Internet'**
  String get tplTrackerInternet;

  /// No description provided for @tplTrackerMobile.
  ///
  /// In de, this message translates to:
  /// **'Mobilfunk'**
  String get tplTrackerMobile;

  /// No description provided for @tplTrackerLiability.
  ///
  /// In de, this message translates to:
  /// **'Haftpflicht'**
  String get tplTrackerLiability;

  /// No description provided for @tplTrackerContents.
  ///
  /// In de, this message translates to:
  /// **'Hausrat'**
  String get tplTrackerContents;

  /// No description provided for @tplTrackerStreaming.
  ///
  /// In de, this message translates to:
  /// **'Streaming'**
  String get tplTrackerStreaming;

  /// No description provided for @tplFieldReading.
  ///
  /// In de, this message translates to:
  /// **'Zählerstand'**
  String get tplFieldReading;

  /// No description provided for @tplFieldUnitPrice.
  ///
  /// In de, this message translates to:
  /// **'Arbeitspreis'**
  String get tplFieldUnitPrice;

  /// No description provided for @tplFieldBasePrice.
  ///
  /// In de, this message translates to:
  /// **'Grundpreis'**
  String get tplFieldBasePrice;

  /// No description provided for @tplFieldInstalment.
  ///
  /// In de, this message translates to:
  /// **'Abschlag'**
  String get tplFieldInstalment;

  /// No description provided for @tplFieldProvider.
  ///
  /// In de, this message translates to:
  /// **'Anbieter'**
  String get tplFieldProvider;

  /// No description provided for @tplFieldContractEnd.
  ///
  /// In de, this message translates to:
  /// **'Vertragsende'**
  String get tplFieldContractEnd;

  /// No description provided for @tplFieldWaterPrice.
  ///
  /// In de, this message translates to:
  /// **'Wasser & Abwasser'**
  String get tplFieldWaterPrice;

  /// No description provided for @tplFieldBaseRent.
  ///
  /// In de, this message translates to:
  /// **'Kaltmiete'**
  String get tplFieldBaseRent;

  /// No description provided for @tplFieldAdvance.
  ///
  /// In de, this message translates to:
  /// **'Nebenkosten-Vorauszahlung'**
  String get tplFieldAdvance;

  /// No description provided for @tplFieldSettlement.
  ///
  /// In de, this message translates to:
  /// **'Nachzahlung / Guthaben'**
  String get tplFieldSettlement;

  /// No description provided for @tplFieldLandlord.
  ///
  /// In de, this message translates to:
  /// **'Vermieter'**
  String get tplFieldLandlord;

  /// No description provided for @tplFieldFuel.
  ///
  /// In de, this message translates to:
  /// **'Tanken / Laden'**
  String get tplFieldFuel;

  /// No description provided for @tplFieldFuelAmount.
  ///
  /// In de, this message translates to:
  /// **'Menge (l oder kWh)'**
  String get tplFieldFuelAmount;

  /// No description provided for @tplFieldCarInsurance.
  ///
  /// In de, this message translates to:
  /// **'Kfz-Versicherung'**
  String get tplFieldCarInsurance;

  /// No description provided for @tplFieldCarTax.
  ///
  /// In de, this message translates to:
  /// **'Kfz-Steuer'**
  String get tplFieldCarTax;

  /// No description provided for @tplFieldWorkshop.
  ///
  /// In de, this message translates to:
  /// **'Werkstatt'**
  String get tplFieldWorkshop;

  /// No description provided for @tplFieldInspection.
  ///
  /// In de, this message translates to:
  /// **'Hauptuntersuchung'**
  String get tplFieldInspection;

  /// No description provided for @tplFieldMonthlyPrice.
  ///
  /// In de, this message translates to:
  /// **'Monatspreis'**
  String get tplFieldMonthlyPrice;

  /// No description provided for @tplFieldMinimumTerm.
  ///
  /// In de, this message translates to:
  /// **'Mindestlaufzeit bis'**
  String get tplFieldMinimumTerm;

  /// No description provided for @tplFieldPremium.
  ///
  /// In de, this message translates to:
  /// **'Beitrag'**
  String get tplFieldPremium;

  /// No description provided for @tplFieldPolicyNumber.
  ///
  /// In de, this message translates to:
  /// **'Versicherungsnummer'**
  String get tplFieldPolicyNumber;

  /// No description provided for @tplFieldDueDate.
  ///
  /// In de, this message translates to:
  /// **'Hauptfälligkeit'**
  String get tplFieldDueDate;

  /// No description provided for @tplFieldPrice.
  ///
  /// In de, this message translates to:
  /// **'Preis'**
  String get tplFieldPrice;

  /// No description provided for @tplFieldCancelBy.
  ///
  /// In de, this message translates to:
  /// **'Kündbar bis'**
  String get tplFieldCancelBy;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// No description provided for @toggleYes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get toggleYes;

  /// No description provided for @toggleNo.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get toggleNo;

  /// No description provided for @datePickerTitle.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get datePickerTitle;

  /// No description provided for @entryNew.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get entryNew;

  /// No description provided for @entryEdit.
  ///
  /// In de, this message translates to:
  /// **'Eintrag bearbeiten'**
  String get entryEdit;

  /// No description provided for @entryDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get entryDate;

  /// No description provided for @entryNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get entryNote;

  /// No description provided for @entryNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Optional, z. B. abgelesen nach dem Urlaub'**
  String get entryNoteHint;

  /// No description provided for @entryLast.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {value} · {date}'**
  String entryLast(String value, String date);

  /// No description provided for @entryCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell {value} seit {date} – leer lassen, wenn sich nichts ändert'**
  String entryCurrent(String value, String date);

  /// No description provided for @entryDelta.
  ///
  /// In de, this message translates to:
  /// **'{delta} seit {date}'**
  String entryDelta(String delta, String date);

  /// No description provided for @entryBelowLast.
  ///
  /// In de, this message translates to:
  /// **'Kleiner als der letzte Stand ({value}) – neuer Zähler?'**
  String entryBelowLast(String value);

  /// No description provided for @entryMeterChange.
  ///
  /// In de, this message translates to:
  /// **'Neuer Zähler ab diesem Stand'**
  String get entryMeterChange;

  /// No description provided for @entryMeterChangeHint.
  ///
  /// In de, this message translates to:
  /// **'Der Verbrauch seit dem letzten Stand wird aus dem Zeitraum davor geschätzt.'**
  String get entryMeterChangeHint;

  /// No description provided for @entryInvalidNumber.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl eingeben.'**
  String get entryInvalidNumber;

  /// No description provided for @entryNeedsValue.
  ///
  /// In de, this message translates to:
  /// **'Trag mindestens einen Wert ein.'**
  String get entryNeedsValue;

  /// No description provided for @entryNoFields.
  ///
  /// In de, this message translates to:
  /// **'Dieser Tracker hat noch keine Felder zum Eintragen. Lege sie unter „Bearbeiten“ an.'**
  String get entryNoFields;

  /// No description provided for @entrySave.
  ///
  /// In de, this message translates to:
  /// **'Eintrag speichern'**
  String get entrySave;

  /// No description provided for @entrySaved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert.'**
  String get entrySaved;

  /// No description provided for @entrySavedOffline.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert – wird übertragen, sobald du online bist.'**
  String get entrySavedOffline;

  /// No description provided for @entryDelete.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen'**
  String get entryDelete;

  /// No description provided for @entryDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag vom {date} löschen?'**
  String entryDeleteTitle(String date);

  /// No description provided for @entryDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'Der Eintrag verschwindet aus Verlauf, Kosten und Prognose.'**
  String get entryDeleteBody;

  /// No description provided for @entryDeleted.
  ///
  /// In de, this message translates to:
  /// **'Eintrag gelöscht.'**
  String get entryDeleted;

  /// No description provided for @trackerHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf und Einträge'**
  String get trackerHistory;

  /// No description provided for @trackerSince.
  ///
  /// In de, this message translates to:
  /// **'seit {date}'**
  String trackerSince(String date);

  /// No description provided for @trackerLast12.
  ///
  /// In de, this message translates to:
  /// **'Letzte 12 Monate'**
  String get trackerLast12;

  /// No description provided for @metricCost.
  ///
  /// In de, this message translates to:
  /// **'Kosten'**
  String get metricCost;

  /// No description provided for @metricConsumption.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get metricConsumption;

  /// No description provided for @trackerThisYear.
  ///
  /// In de, this message translates to:
  /// **'{year} bis heute'**
  String trackerThisYear(String year);

  /// No description provided for @trackerLastYear.
  ///
  /// In de, this message translates to:
  /// **'Vorjahr bis heute'**
  String get trackerLastYear;

  /// No description provided for @trackerChartEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch zu wenig Daten für einen Verlauf.'**
  String get trackerChartEmpty;

  /// No description provided for @trackerChartValue.
  ///
  /// In de, this message translates to:
  /// **'{month}: {value}'**
  String trackerChartValue(String month, String value);

  /// No description provided for @trackerCurrentValues.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Werte'**
  String get trackerCurrentValues;

  /// No description provided for @trackerEntries.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get trackerEntries;

  /// No description provided for @trackerNoEntriesTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get trackerNoEntriesTitle;

  /// No description provided for @trackerNoEntriesBody.
  ///
  /// In de, this message translates to:
  /// **'Trag den ersten Wert ein – ab einer Rechnung oder dem zweiten Zählerstand entsteht der Verlauf.'**
  String get trackerNoEntriesBody;

  /// No description provided for @trackerAddEntry.
  ///
  /// In de, this message translates to:
  /// **'Wert eintragen'**
  String get trackerAddEntry;

  /// No description provided for @trackerMeterChanged.
  ///
  /// In de, this message translates to:
  /// **'Neuer Zähler'**
  String get trackerMeterChanged;

  /// No description provided for @homeSyncPending.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Eintrag wartet auf Verbindung} other{{count} Einträge warten auf Verbindung}}'**
  String homeSyncPending(int count);

  /// No description provided for @homeSyncPendingHint.
  ///
  /// In de, this message translates to:
  /// **'Wird automatisch übertragen, sobald du online bist.'**
  String get homeSyncPendingHint;

  /// No description provided for @homeSyncRejected.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Eintrag wurde abgelehnt} other{{count} Einträge wurden abgelehnt}}'**
  String homeSyncRejected(int count);

  /// No description provided for @homeSyncRejectedHint.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Rechte oder ein ungültiger Wert. Tippen zum Ausblenden.'**
  String get homeSyncRejectedHint;

  /// No description provided for @remindersEnable.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen aktivieren'**
  String get remindersEnable;

  /// No description provided for @remindersEnableHint.
  ///
  /// In de, this message translates to:
  /// **'Ans Ablesen und an Fristen erinnern lassen'**
  String get remindersEnableHint;

  /// No description provided for @settingsReminders.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get settingsReminders;

  /// No description provided for @settingsNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get settingsNotifications;

  /// No description provided for @settingsRemindersFooter.
  ///
  /// In de, this message translates to:
  /// **'Erinnert ans Ablesen, wenn ein Zähler 30 Tage keinen neuen Stand hat, und 30, 7 und 1 Tag vor Stichtagen wie dem Vertragsende.'**
  String get settingsRemindersFooter;

  /// No description provided for @settingsRemindersDenied.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen sind in den Systemeinstellungen ausgeschaltet. Schalte sie dort für Kostenkurve ein.'**
  String get settingsRemindersDenied;

  /// No description provided for @notifyChannel.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get notifyChannel;

  /// No description provided for @notifyReadBody.
  ///
  /// In de, this message translates to:
  /// **'Seit {days} Tagen kein neuer Stand – trag ihn kurz ein.'**
  String notifyReadBody(int days);

  /// No description provided for @notifyDeadlineBody.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, =1{Morgen} other{In {days} Tagen}} ist es so weit: {date}.'**
  String notifyDeadlineBody(int days, String date);

  /// No description provided for @entryFieldValue.
  ///
  /// In de, this message translates to:
  /// **'{field} {value}'**
  String entryFieldValue(String field, String value);

  /// No description provided for @trackerUpcoming.
  ///
  /// In de, this message translates to:
  /// **'ab {date}: {value}'**
  String trackerUpcoming(String date, String value);

  /// No description provided for @categoryEntries.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Einträge} =1{1 Eintrag} other{{count} Einträge}}'**
  String categoryEntries(int count);

  /// No description provided for @roleInstalment.
  ///
  /// In de, this message translates to:
  /// **'Abschlag'**
  String get roleInstalment;

  /// No description provided for @roleInstalmentHint.
  ///
  /// In de, this message translates to:
  /// **'Vorauszahlung je Monat – keine Kosten, wird im Abschlags-Check mit den Kosten verglichen'**
  String get roleInstalmentHint;

  /// No description provided for @forecastRange.
  ///
  /// In de, this message translates to:
  /// **'Spanne {low} – {high}'**
  String forecastRange(String low, String high);

  /// No description provided for @insightsCosts.
  ///
  /// In de, this message translates to:
  /// **'Kosten {year}'**
  String insightsCosts(String year);

  /// No description provided for @insightsProjected.
  ///
  /// In de, this message translates to:
  /// **'Bis Dezember hochgerechnet'**
  String get insightsProjected;

  /// No description provided for @insightsProjectedValue.
  ///
  /// In de, this message translates to:
  /// **'{value} (hochgerechnet)'**
  String insightsProjectedValue(String value);

  /// No description provided for @insightsMonthly.
  ///
  /// In de, this message translates to:
  /// **'Kosten je Monat'**
  String get insightsMonthly;

  /// No description provided for @insightsPartMeter.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch × Preis (Zähler)'**
  String get insightsPartMeter;

  /// No description provided for @insightsPartFixed.
  ///
  /// In de, this message translates to:
  /// **'Feste Beträge (Miete, Verträge, Abos)'**
  String get insightsPartFixed;

  /// No description provided for @insightsPartOneOff.
  ///
  /// In de, this message translates to:
  /// **'Einmaliges (Ø der letzten 12 Monate)'**
  String get insightsPartOneOff;

  /// No description provided for @insightsTrend.
  ///
  /// In de, this message translates to:
  /// **'{tracker}: {change} Verbrauch ggü. Vorjahr eingerechnet'**
  String insightsTrend(String tracker, String change);

  /// No description provided for @insightsForecastExplain.
  ///
  /// In de, this message translates to:
  /// **'Zähler rechnen mit dem Verbrauch des Vorjahres in derselben Jahreszeit, angepasst um den Trend. Preise und Beträge gelten so, wie sie dann gelten – auch schon eingetragene Erhöhungen. Die Spanne wächst mit unregelmäßigen Ausgaben.'**
  String get insightsForecastExplain;

  /// No description provided for @insightsComparison.
  ///
  /// In de, this message translates to:
  /// **'{year} gegen {previous}'**
  String insightsComparison(String year, String previous);

  /// No description provided for @insightsPrevious.
  ///
  /// In de, this message translates to:
  /// **'{year}: {value}'**
  String insightsPrevious(String year, String value);

  /// No description provided for @insightsConsumptionHint.
  ///
  /// In de, this message translates to:
  /// **'Bis heute, verglichen mit demselben Zeitraum im Vorjahr.'**
  String get insightsConsumptionHint;

  /// No description provided for @insightsInstalments.
  ///
  /// In de, this message translates to:
  /// **'Abschlags-Check'**
  String get insightsInstalments;

  /// No description provided for @insightsInstalmentDetail.
  ///
  /// In de, this message translates to:
  /// **'Ø {paid} pro Monat · Kosten {year} ≈ {cost}'**
  String insightsInstalmentDetail(String paid, String year, String cost);

  /// No description provided for @insightsCredit.
  ///
  /// In de, this message translates to:
  /// **'Guthaben ≈ {value}'**
  String insightsCredit(String value);

  /// No description provided for @insightsBackPayment.
  ///
  /// In de, this message translates to:
  /// **'Nachzahlung ≈ {value}'**
  String insightsBackPayment(String value);

  /// No description provided for @insightsSuggest.
  ///
  /// In de, this message translates to:
  /// **'Passend wären {value} pro Monat.'**
  String insightsSuggest(String value);

  /// No description provided for @insightsInstalmentFooter.
  ///
  /// In de, this message translates to:
  /// **'Abschläge gegen die gerechneten Kosten des ganzen Jahres – im laufenden Jahr mit Hochrechnung bis Dezember.'**
  String get insightsInstalmentFooter;

  /// No description provided for @insightsIncluded.
  ///
  /// In de, this message translates to:
  /// **'{tracker}: {cost} stecken in {category} und zählen dort.'**
  String insightsIncluded(String tracker, String cost, String category);

  /// No description provided for @trackerIncludedIn.
  ///
  /// In de, this message translates to:
  /// **'Kosten enthalten in'**
  String get trackerIncludedIn;

  /// No description provided for @trackerIncludedNone.
  ///
  /// In de, this message translates to:
  /// **'Eigene Kosten'**
  String get trackerIncludedNone;

  /// No description provided for @trackerIncludedHint.
  ///
  /// In de, this message translates to:
  /// **'Z. B. Wasser, das schon in den Nebenkosten steckt: Die Kosten werden gezeigt, aber in keiner Summe doppelt gezählt.'**
  String get trackerIncludedHint;

  /// No description provided for @trackerIncludedNote.
  ///
  /// In de, this message translates to:
  /// **'Kosten stecken in {category} und zählen dort.'**
  String trackerIncludedNote(String category);

  /// No description provided for @fieldFormula.
  ///
  /// In de, this message translates to:
  /// **'Formel'**
  String get fieldFormula;

  /// No description provided for @fieldFormulaHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. verbrauch * arbeitspreis'**
  String get fieldFormulaHint;

  /// No description provided for @fieldFormulaValues.
  ///
  /// In de, this message translates to:
  /// **'Werte'**
  String get fieldFormulaValues;

  /// No description provided for @fieldFormulaFunctions.
  ///
  /// In de, this message translates to:
  /// **'Funktionen'**
  String get fieldFormulaFunctions;

  /// No description provided for @fieldFormulaPreview.
  ///
  /// In de, this message translates to:
  /// **'Mit dem letzten Eintrag: {value}'**
  String fieldFormulaPreview(String value);

  /// No description provided for @fieldFormulaNoPreview.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Eintrag, mit dem sich rechnen lässt.'**
  String get fieldFormulaNoPreview;

  /// No description provided for @fieldFormulaFooter.
  ///
  /// In de, this message translates to:
  /// **'Rechnet je Eintrag mit den Feldern dieses Trackers, dazu verbrauch, tage und monate seit dem vorigen Eintrag. Mehrere Werte in Funktionen mit ; trennen.'**
  String get fieldFormulaFooter;

  /// No description provided for @formulaErrorEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Ausdruck eingeben.'**
  String get formulaErrorEmpty;

  /// No description provided for @formulaErrorCharacter.
  ///
  /// In de, this message translates to:
  /// **'Unerwartetes Zeichen „{detail}“ an Stelle {position}.'**
  String formulaErrorCharacter(String detail, int position);

  /// No description provided for @formulaErrorEnd.
  ///
  /// In de, this message translates to:
  /// **'Der Ausdruck endet zu früh.'**
  String get formulaErrorEnd;

  /// No description provided for @formulaErrorToken.
  ///
  /// In de, this message translates to:
  /// **'Unerwartetes „{detail}“ an Stelle {position}.'**
  String formulaErrorToken(String detail, int position);

  /// No description provided for @formulaErrorParenthesis.
  ///
  /// In de, this message translates to:
  /// **'Hier fehlt eine schließende Klammer (Stelle {position}).'**
  String formulaErrorParenthesis(int position);

  /// No description provided for @formulaErrorFunction.
  ///
  /// In de, this message translates to:
  /// **'Unbekannte Funktion „{detail}“.'**
  String formulaErrorFunction(String detail);

  /// No description provided for @formulaErrorArguments.
  ///
  /// In de, this message translates to:
  /// **'Falsche Anzahl Werte für „{detail}“.'**
  String formulaErrorArguments(String detail);

  /// No description provided for @formulaErrorVariable.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Name „{detail}“.'**
  String formulaErrorVariable(String detail);

  /// No description provided for @formulaErrorDeep.
  ///
  /// In de, this message translates to:
  /// **'Zu tief verschachtelt.'**
  String get formulaErrorDeep;

  /// No description provided for @insightsRangeOnly.
  ///
  /// In de, this message translates to:
  /// **'± {range}'**
  String insightsRangeOnly(String range);

  /// No description provided for @accountTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get accountTitle;

  /// No description provided for @accountSecuredToast.
  ///
  /// In de, this message translates to:
  /// **'Konto gesichert'**
  String get accountSecuredToast;

  /// No description provided for @accountSignedInToast.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet'**
  String get accountSignedInToast;

  /// No description provided for @accountNameSaved.
  ///
  /// In de, this message translates to:
  /// **'Name gespeichert'**
  String get accountNameSaved;

  /// No description provided for @accountSignedOutToast.
  ///
  /// In de, this message translates to:
  /// **'Abgemeldet'**
  String get accountSignedOutToast;

  /// No description provided for @accountAlreadyUsedTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto gibt es schon'**
  String get accountAlreadyUsedTitle;

  /// No description provided for @accountAlreadyUsedBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Apple-ID gehört schon zu einem Konto. Möchtest du dich dort anmelden? Was du bisher ohne Konto erfasst hast, kommt nicht mit.'**
  String get accountAlreadyUsedBody;

  /// No description provided for @accountSignIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get accountSignIn;

  /// No description provided for @accountInvalidCode.
  ///
  /// In de, this message translates to:
  /// **'Der Code stimmt nicht oder ist abgelaufen.'**
  String get accountInvalidCode;

  /// No description provided for @accountSignInTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit bestehendem Konto anmelden?'**
  String get accountSignInTitle;

  /// No description provided for @accountSignInBody.
  ///
  /// In de, this message translates to:
  /// **'Du wechselst zu deinem Konto. Was du auf diesem Gerät ohne Konto erfasst hast, kommt nicht mit.'**
  String get accountSignInBody;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In de, this message translates to:
  /// **'Abmelden?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben in der Cloud. Auf diesem Gerät wählst du danach neu, wo du speicherst.'**
  String get accountSignOutBody;

  /// No description provided for @accountSignOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get accountSignOut;

  /// No description provided for @accountAnonymousTitle.
  ///
  /// In de, this message translates to:
  /// **'Nur auf diesem Gerät'**
  String get accountAnonymousTitle;

  /// No description provided for @accountAnonymousBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten liegen in einem Konto ohne Anmeldung. Sichere es, damit sie ein neues Handy überstehen und du Kategorien teilen kannst.'**
  String get accountAnonymousBody;

  /// No description provided for @accountSecuredTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto gesichert'**
  String get accountSecuredTitle;

  /// No description provided for @accountSecuredBody.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet mit {login}.'**
  String accountSecuredBody(String login);

  /// No description provided for @accountApple.
  ///
  /// In de, this message translates to:
  /// **'Apple'**
  String get accountApple;

  /// No description provided for @accountSecure.
  ///
  /// In de, this message translates to:
  /// **'Konto sichern'**
  String get accountSecure;

  /// No description provided for @accountSecureApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple sichern'**
  String get accountSecureApple;

  /// No description provided for @accountSecureEmail.
  ///
  /// In de, this message translates to:
  /// **'Mit E-Mail sichern'**
  String get accountSecureEmail;

  /// No description provided for @accountSecureFooter.
  ///
  /// In de, this message translates to:
  /// **'Alles, was du schon erfasst hast, bleibt erhalten. Ohne Passwort: Apple oder ein Code per E-Mail.'**
  String get accountSecureFooter;

  /// No description provided for @accountExisting.
  ///
  /// In de, this message translates to:
  /// **'Schon ein Konto?'**
  String get accountExisting;

  /// No description provided for @accountSignInApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple anmelden'**
  String get accountSignInApple;

  /// No description provided for @accountSignInEmail.
  ///
  /// In de, this message translates to:
  /// **'Mit E-Mail anmelden'**
  String get accountSignInEmail;

  /// No description provided for @accountName.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Alex'**
  String get accountNameHint;

  /// No description provided for @accountNameFooter.
  ///
  /// In de, this message translates to:
  /// **'Sehen alle, mit denen du Kategorien teilst – auch an deinen Einträgen.'**
  String get accountNameFooter;

  /// No description provided for @accountEmailHint.
  ///
  /// In de, this message translates to:
  /// **'name@beispiel.de'**
  String get accountEmailHint;

  /// No description provided for @accountCodeSent.
  ///
  /// In de, this message translates to:
  /// **'Code an {email} geschickt. Schau auch im Spam-Ordner.'**
  String accountCodeSent(String email);

  /// No description provided for @accountCodeHint.
  ///
  /// In de, this message translates to:
  /// **'Code aus der E-Mail'**
  String get accountCodeHint;

  /// No description provided for @accountConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get accountConfirm;

  /// No description provided for @accountResend.
  ///
  /// In de, this message translates to:
  /// **'Neuen Code senden'**
  String get accountResend;

  /// No description provided for @accountSendCode.
  ///
  /// In de, this message translates to:
  /// **'Code senden'**
  String get accountSendCode;

  /// No description provided for @shareRemoved.
  ///
  /// In de, this message translates to:
  /// **'Entfernt'**
  String get shareRemoved;

  /// No description provided for @shareLeft.
  ///
  /// In de, this message translates to:
  /// **'Kategorie verlassen'**
  String get shareLeft;

  /// No description provided for @roleOwner.
  ///
  /// In de, this message translates to:
  /// **'Besitzer'**
  String get roleOwner;

  /// No description provided for @roleEditor.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get roleEditor;

  /// No description provided for @roleViewer.
  ///
  /// In de, this message translates to:
  /// **'Nur ansehen'**
  String get roleViewer;

  /// No description provided for @roleEditorHint.
  ///
  /// In de, this message translates to:
  /// **'Darf Einträge erfassen, ändern und löschen.'**
  String get roleEditorHint;

  /// No description provided for @roleViewerHint.
  ///
  /// In de, this message translates to:
  /// **'Sieht Verlauf und Kosten, ändert aber nichts.'**
  String get roleViewerHint;

  /// No description provided for @shareNoName.
  ///
  /// In de, this message translates to:
  /// **'Ohne Namen'**
  String get shareNoName;

  /// No description provided for @shareRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get shareRemove;

  /// No description provided for @shareRemoveTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen?'**
  String shareRemoveTitle(String name);

  /// No description provided for @shareRemoveBody.
  ///
  /// In de, this message translates to:
  /// **'Die Person sieht die Kategorie danach nicht mehr. Ihre Einträge bleiben.'**
  String get shareRemoveBody;

  /// No description provided for @shareLeaveTitle.
  ///
  /// In de, this message translates to:
  /// **'„{category}“ verlassen?'**
  String shareLeaveTitle(String category);

  /// No description provided for @shareLeaveBody.
  ///
  /// In de, this message translates to:
  /// **'Du siehst die Kategorie danach nicht mehr. Deine Einträge bleiben für die anderen.'**
  String get shareLeaveBody;

  /// No description provided for @shareLeave.
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get shareLeave;

  /// No description provided for @shareTitle.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get shareTitle;

  /// No description provided for @shareMembers.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder'**
  String get shareMembers;

  /// No description provided for @shareYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get shareYou;

  /// No description provided for @shareYouNamed.
  ///
  /// In de, this message translates to:
  /// **'{name} (du)'**
  String shareYouNamed(String name);

  /// No description provided for @shareInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladen'**
  String get shareInvite;

  /// No description provided for @shareSecureFirst.
  ///
  /// In de, this message translates to:
  /// **'Zum Teilen brauchst du ein gesichertes Konto – so weiß dein Partner, mit wem er teilt, und nichts geht verloren.'**
  String get shareSecureFirst;

  /// No description provided for @shareCreateInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladung erstellen'**
  String get shareCreateInvite;

  /// No description provided for @shareSend.
  ///
  /// In de, this message translates to:
  /// **'Einladung senden'**
  String get shareSend;

  /// No description provided for @shareMessage.
  ///
  /// In de, this message translates to:
  /// **'Ich teile „{category}“ in Kostenkurve mit dir. Öffne den Link oder gib in der App unter Kategorien › + › Einladung annehmen den Code {code} ein: {link}'**
  String shareMessage(String category, String code, String link);

  /// No description provided for @shareValidity.
  ///
  /// In de, this message translates to:
  /// **'Gilt 7 Tage für eine Person.'**
  String get shareValidity;

  /// No description provided for @joinTitle.
  ///
  /// In de, this message translates to:
  /// **'Einladung annehmen'**
  String get joinTitle;

  /// No description provided for @joinRowHint.
  ///
  /// In de, this message translates to:
  /// **'Kategorie eines Partners beitreten'**
  String get joinRowHint;

  /// No description provided for @joinDone.
  ///
  /// In de, this message translates to:
  /// **'Beigetreten'**
  String get joinDone;

  /// No description provided for @joinInvalid.
  ///
  /// In de, this message translates to:
  /// **'Code unbekannt, abgelaufen oder schon benutzt.'**
  String get joinInvalid;

  /// No description provided for @joinBody.
  ///
  /// In de, this message translates to:
  /// **'Gib den Code aus der Einladung ein. Danach siehst du die Kategorie und je nach Rolle erfasst du mit.'**
  String get joinBody;

  /// No description provided for @joinHint.
  ///
  /// In de, this message translates to:
  /// **'Code, z. B. K7Q2M9X4TA'**
  String get joinHint;

  /// No description provided for @joinAction.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get joinAction;

  /// No description provided for @entryBy.
  ///
  /// In de, this message translates to:
  /// **'von {name}'**
  String entryBy(String name);

  /// No description provided for @accountDelete.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto und alle Daten löschen?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto und deine Cloud-Kategorien mit allen Einträgen und Belegen werden sofort gelöscht – auch für alle, mit denen du sie teilst. Das lässt sich nicht rückgängig machen. Ein Cloud-Abo kündigst du separat in den iOS-Einstellungen.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteFooter.
  ///
  /// In de, this message translates to:
  /// **'Exportiere vorher deine Daten, wenn du sie behalten willst (Einstellungen › Daten exportieren).'**
  String get accountDeleteFooter;

  /// No description provided for @accountDeletedToast.
  ///
  /// In de, this message translates to:
  /// **'Konto gelöscht'**
  String get accountDeletedToast;

  /// No description provided for @attachmentsTitle.
  ///
  /// In de, this message translates to:
  /// **'Belege'**
  String get attachmentsTitle;

  /// No description provided for @attachmentsAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get attachmentsAdd;

  /// No description provided for @attachmentsAdded.
  ///
  /// In de, this message translates to:
  /// **'Beleg hinzugefügt'**
  String get attachmentsAdded;

  /// No description provided for @attachmentsDeleted.
  ///
  /// In de, this message translates to:
  /// **'Beleg gelöscht'**
  String get attachmentsDeleted;

  /// No description provided for @attachmentsAfterSave.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Speichern kannst du Rechnung, Vertrag oder Zählerfoto anhängen.'**
  String get attachmentsAfterSave;

  /// No description provided for @attachmentsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Belege. Häng Rechnung, Vertrag oder ein Foto vom Zähler an.'**
  String get attachmentsEmpty;

  /// No description provided for @attachmentsEmptyPlus.
  ///
  /// In de, this message translates to:
  /// **'In der Cloud hängst du Rechnungen, Verträge und Zählerfotos direkt an den Eintrag.'**
  String get attachmentsEmptyPlus;

  /// No description provided for @attachmentsOffline.
  ///
  /// In de, this message translates to:
  /// **'Belege sind gerade nicht erreichbar.'**
  String get attachmentsOffline;

  /// No description provided for @attachmentsCamera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get attachmentsCamera;

  /// No description provided for @attachmentsPhotos.
  ///
  /// In de, this message translates to:
  /// **'Aus Fotos wählen'**
  String get attachmentsPhotos;

  /// No description provided for @attachmentsPdf.
  ///
  /// In de, this message translates to:
  /// **'PDF wählen'**
  String get attachmentsPdf;

  /// No description provided for @attachmentsNeedsPlus.
  ///
  /// In de, this message translates to:
  /// **'Belege hinzufügen geht mit Plus und Bearbeiten-Rechten.'**
  String get attachmentsNeedsPlus;

  /// No description provided for @attachmentsTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist größer als 20 MB.'**
  String get attachmentsTooLarge;

  /// No description provided for @attachmentsQuota.
  ///
  /// In de, this message translates to:
  /// **'Dein Speicher für Belege ist voll (5 GB).'**
  String get attachmentsQuota;

  /// No description provided for @attachmentsType.
  ///
  /// In de, this message translates to:
  /// **'Nur Fotos (JPEG, PNG, HEIC) und PDFs.'**
  String get attachmentsType;

  /// No description provided for @attachmentsNotSynced.
  ///
  /// In de, this message translates to:
  /// **'Der Eintrag ist noch nicht gesendet – gleich noch mal versuchen.'**
  String get attachmentsNotSynced;

  /// No description provided for @attachmentsNoAccess.
  ///
  /// In de, this message translates to:
  /// **'Kein Zugriff – erlaube Kamera oder Fotos in den Einstellungen.'**
  String get attachmentsNoAccess;

  /// No description provided for @attachmentsPhotoTitle.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get attachmentsPhotoTitle;

  /// No description provided for @attachmentsPdfTitle.
  ///
  /// In de, this message translates to:
  /// **'PDF'**
  String get attachmentsPdfTitle;

  /// No description provided for @attachmentsShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get attachmentsShare;

  /// No description provided for @attachmentsOpenPdf.
  ///
  /// In de, this message translates to:
  /// **'Öffnen oder sichern'**
  String get attachmentsOpenPdf;

  /// No description provided for @attachmentsDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Beleg löschen?'**
  String get attachmentsDeleteTitle;

  /// No description provided for @attachmentsDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'Die Datei wird für alle gelöscht, die die Kategorie sehen.'**
  String get attachmentsDeleteBody;

  /// No description provided for @entryPeriod.
  ///
  /// In de, this message translates to:
  /// **'Abrechnungszeitraum'**
  String get entryPeriod;

  /// No description provided for @entryPeriodFrom.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get entryPeriodFrom;

  /// No description provided for @entryPeriodTo.
  ///
  /// In de, this message translates to:
  /// **'Bis'**
  String get entryPeriodTo;

  /// No description provided for @entryPeriodHint.
  ///
  /// In de, this message translates to:
  /// **'Nachzahlung oder Guthaben für einen Zeitraum: Der Betrag verteilt sich auf dessen Tage statt auf den Stichtag.'**
  String get entryPeriodHint;

  /// No description provided for @entryPeriodInvalid.
  ///
  /// In de, this message translates to:
  /// **'Das Ende liegt vor dem Anfang.'**
  String get entryPeriodInvalid;

  /// No description provided for @entryKindBill.
  ///
  /// In de, this message translates to:
  /// **'Rechnung'**
  String get entryKindBill;

  /// No description provided for @entryKindReading.
  ///
  /// In de, this message translates to:
  /// **'Zählerstand'**
  String get entryKindReading;

  /// No description provided for @entryBillConsumption.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get entryBillConsumption;

  /// No description provided for @entryBillPerMonth.
  ///
  /// In de, this message translates to:
  /// **'≈ {amount} im Monat'**
  String entryBillPerMonth(String amount);

  /// No description provided for @entryBillHint.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum und Verbrauch stehen auf deiner Rechnung.'**
  String get entryBillHint;

  /// No description provided for @entryBillOverlap.
  ///
  /// In de, this message translates to:
  /// **'Überschneidet sich mit einer anderen Rechnung – an diesen Tagen zählt die später endende.'**
  String get entryBillOverlap;

  /// No description provided for @contractChange.
  ///
  /// In de, this message translates to:
  /// **'Preise ändern'**
  String get contractChange;

  /// No description provided for @contractEdit.
  ///
  /// In de, this message translates to:
  /// **'Preisänderung'**
  String get contractEdit;

  /// No description provided for @contractDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Preisänderung vom {date} löschen?'**
  String contractDeleteTitle(String date);

  /// No description provided for @contractDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'{prices} verschwinden aus Vertrag, Kosten und Prognose.'**
  String contractDeleteBody(String prices);

  /// No description provided for @contractTitle.
  ///
  /// In de, this message translates to:
  /// **'Vertrag'**
  String get contractTitle;

  /// No description provided for @contractSet.
  ///
  /// In de, this message translates to:
  /// **'Eintragen'**
  String get contractSet;

  /// No description provided for @contractMissingPrice.
  ///
  /// In de, this message translates to:
  /// **'Ohne Arbeitspreis rechnet die App noch keine Kosten.'**
  String get contractMissingPrice;

  /// No description provided for @priceHistoryFrom.
  ///
  /// In de, this message translates to:
  /// **'ab {date}'**
  String priceHistoryFrom(String date);

  /// No description provided for @priceHistoryPlanned.
  ///
  /// In de, this message translates to:
  /// **'geplant'**
  String get priceHistoryPlanned;

  /// No description provided for @priceHistoryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Preis eingetragen.'**
  String get priceHistoryEmpty;

  /// No description provided for @entryPeriodRange.
  ///
  /// In de, this message translates to:
  /// **'{from} – {to}'**
  String entryPeriodRange(String from, String to);

  /// No description provided for @exportCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get exportCategory;

  /// No description provided for @exportTracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker'**
  String get exportTracker;

  /// No description provided for @exportField.
  ///
  /// In de, this message translates to:
  /// **'Feld'**
  String get exportField;

  /// No description provided for @exportValue.
  ///
  /// In de, this message translates to:
  /// **'Wert'**
  String get exportValue;

  /// No description provided for @exportUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get exportUnit;

  /// No description provided for @exportNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get exportNote;

  /// No description provided for @exportSubject.
  ///
  /// In de, this message translates to:
  /// **'Kostenkurve-Export'**
  String get exportSubject;

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export ging nicht – bist du online?'**
  String get exportFailed;

  /// No description provided for @legalPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get legalPrivacy;

  /// No description provided for @legalTerms.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get legalTerms;

  /// No description provided for @legalImprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get legalImprint;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Kosten.\nEine Kurve.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Zählerstände, Verträge und Abschläge an einem Ort – mit Verlauf und Prognose fürs nächste Jahr.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingPointTrack.
  ///
  /// In de, this message translates to:
  /// **'Erfassen in Sekunden'**
  String get onboardingPointTrack;

  /// No description provided for @onboardingPointTrackBody.
  ///
  /// In de, this message translates to:
  /// **'Strom, Gas, Wasser, Miete – mit eigenen Feldern und Formeln.'**
  String get onboardingPointTrackBody;

  /// No description provided for @onboardingPointForecast.
  ///
  /// In de, this message translates to:
  /// **'Keine Nachzahlung mehr'**
  String get onboardingPointForecast;

  /// No description provided for @onboardingPointForecastBody.
  ///
  /// In de, this message translates to:
  /// **'Prognose mit Spanne und Abschlags-Check.'**
  String get onboardingPointForecastBody;

  /// No description provided for @onboardingPointShare.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam im Haushalt'**
  String get onboardingPointShare;

  /// No description provided for @onboardingPointShareBody.
  ///
  /// In de, this message translates to:
  /// **'Teile Kategorien mit deinem Partner.'**
  String get onboardingPointShareBody;

  /// No description provided for @onboardingStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get onboardingStart;

  /// No description provided for @onboardingTemplatesTitle.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du verfolgen?'**
  String get onboardingTemplatesTitle;

  /// No description provided for @onboardingTemplatesBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle Vorlagen – Felder kannst du später jederzeit anpassen.'**
  String get onboardingTemplatesBody;

  /// No description provided for @onboardingCreate.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Kategorie anlegen} other{{count} Kategorien anlegen}}'**
  String onboardingCreate(int count);

  /// No description provided for @onboardingSkip.
  ///
  /// In de, this message translates to:
  /// **'Ohne Vorlage weiter'**
  String get onboardingSkip;

  /// No description provided for @onboardingSelected.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählt'**
  String get onboardingSelected;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In de, this message translates to:
  /// **'Nichts vergessen'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersBody.
  ///
  /// In de, this message translates to:
  /// **'Wir erinnern dich ans Ablesen und an Kündigungsfristen – auf deinem Gerät, ohne Werbung.'**
  String get onboardingRemindersBody;

  /// No description provided for @onboardingRemindersAllow.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen erlauben'**
  String get onboardingRemindersAllow;

  /// No description provided for @onboardingLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get onboardingLater;

  /// No description provided for @plusTitle.
  ///
  /// In de, this message translates to:
  /// **'Kostenkurve Cloud'**
  String get plusTitle;

  /// No description provided for @plusSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten auf jedem Gerät.'**
  String get plusSubtitle;

  /// No description provided for @plusBenefitReceipts.
  ///
  /// In de, this message translates to:
  /// **'Belege am Eintrag'**
  String get plusBenefitReceipts;

  /// No description provided for @plusBenefitReceiptsBody.
  ///
  /// In de, this message translates to:
  /// **'Rechnungen, Verträge und Zählerfotos als Foto oder PDF.'**
  String get plusBenefitReceiptsBody;

  /// No description provided for @plusBenefitStorage.
  ///
  /// In de, this message translates to:
  /// **'5 GB Speicher'**
  String get plusBenefitStorage;

  /// No description provided for @plusBenefitStorageBody.
  ///
  /// In de, this message translates to:
  /// **'Sicher gespeichert und auf jedem Gerät da.'**
  String get plusBenefitStorageBody;

  /// No description provided for @plusBenefitShared.
  ///
  /// In de, this message translates to:
  /// **'Für den ganzen Haushalt'**
  String get plusBenefitShared;

  /// No description provided for @plusBenefitSharedBody.
  ///
  /// In de, this message translates to:
  /// **'In geteilten Kategorien sieht dein Partner die Belege – ohne eigenes Abo.'**
  String get plusBenefitSharedBody;

  /// No description provided for @plusMonthly.
  ///
  /// In de, this message translates to:
  /// **'Monatlich'**
  String get plusMonthly;

  /// No description provided for @plusPerMonth.
  ///
  /// In de, this message translates to:
  /// **'{price}/Monat'**
  String plusPerMonth(String price);

  /// No description provided for @plusMonthlyDetail.
  ///
  /// In de, this message translates to:
  /// **'Monatlich kündbar'**
  String get plusMonthlyDetail;

  /// No description provided for @plusFinePrint.
  ///
  /// In de, this message translates to:
  /// **'Verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf kündigst. Abgerechnet über deinen Apple-Account, kündbar in dessen Einstellungen.'**
  String get plusFinePrint;

  /// No description provided for @plusRestore.
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get plusRestore;

  /// No description provided for @plusAppleEula.
  ///
  /// In de, this message translates to:
  /// **'Lizenzvertrag (EULA)'**
  String get plusAppleEula;

  /// No description provided for @plusWelcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen in der Cloud'**
  String get plusWelcome;

  /// No description provided for @plusNothingToRestore.
  ///
  /// In de, this message translates to:
  /// **'Kein aktives Abo gefunden.'**
  String get plusNothingToRestore;

  /// No description provided for @plusPending.
  ///
  /// In de, this message translates to:
  /// **'Kauf wartet auf Freigabe.'**
  String get plusPending;

  /// No description provided for @plusFailed.
  ///
  /// In de, this message translates to:
  /// **'Kauf ging nicht – bitte später noch mal.'**
  String get plusFailed;

  /// No description provided for @plusOtherAccount.
  ///
  /// In de, this message translates to:
  /// **'Dieses Abo gehört zu einem anderen Kostenkurve-Konto. Melde dich dort an (Einstellungen › Konto).'**
  String get plusOtherAccount;

  /// No description provided for @plusUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Abos sind gerade nicht erreichbar. Prüfe deine Verbindung und versuch es später noch mal.'**
  String get plusUnavailable;

  /// No description provided for @plusOnlyIos.
  ///
  /// In de, this message translates to:
  /// **'Die Cloud buchst du derzeit in der iPhone-App – das Abo gilt dann auch hier.'**
  String get plusOnlyIos;

  /// No description provided for @plusActive.
  ///
  /// In de, this message translates to:
  /// **'Cloud ist aktiv.'**
  String get plusActive;

  /// No description provided for @plusActiveUntil.
  ///
  /// In de, this message translates to:
  /// **'Cloud ist aktiv – verlängert sich am {date}.'**
  String plusActiveUntil(String date);

  /// No description provided for @plusManage.
  ///
  /// In de, this message translates to:
  /// **'Abo verwalten'**
  String get plusManage;

  /// No description provided for @plusBadge.
  ///
  /// In de, this message translates to:
  /// **'Cloud'**
  String get plusBadge;

  /// No description provided for @plusBadgeActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get plusBadgeActive;

  /// No description provided for @settingsAccountAnonymous.
  ///
  /// In de, this message translates to:
  /// **'Nur auf diesem Gerät – jetzt sichern'**
  String get settingsAccountAnonymous;

  /// No description provided for @settingsPlusHint.
  ///
  /// In de, this message translates to:
  /// **'Auf allen Geräten, gesichert, teilen'**
  String get settingsPlusHint;

  /// No description provided for @settingsStorage.
  ///
  /// In de, this message translates to:
  /// **'{used} von {total} belegt'**
  String settingsStorage(String used, String total);

  /// No description provided for @settingsData.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get settingsData;

  /// No description provided for @settingsExport.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get settingsExport;

  /// No description provided for @settingsExportFooter.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien und Einträge als CSV (für Tabellen) und JSON.'**
  String get settingsExportFooter;

  /// No description provided for @settingsLegal.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get settingsLegal;

  /// No description provided for @whatIfTitle.
  ///
  /// In de, this message translates to:
  /// **'Was wäre wenn …'**
  String get whatIfTitle;

  /// No description provided for @whatIfRowHint.
  ///
  /// In de, this message translates to:
  /// **'Neue Preise durchspielen, z. B. vor einem Wechsel'**
  String get whatIfRowHint;

  /// No description provided for @whatIfBody.
  ///
  /// In de, this message translates to:
  /// **'Trag neue Preise ein – sie gelten ab 1. Januar. Die Prognose für {year} rechnet mit deinem Verbrauch.'**
  String whatIfBody(String year);

  /// No description provided for @whatIfCurrent.
  ///
  /// In de, this message translates to:
  /// **'Heute: {value}'**
  String whatIfCurrent(String value);

  /// No description provided for @whatIfDelta.
  ///
  /// In de, this message translates to:
  /// **'{change} ggü. {before} mit heutigen Preisen'**
  String whatIfDelta(String change, String before);

  /// No description provided for @whatIfSame.
  ///
  /// In de, this message translates to:
  /// **'Wie mit heutigen Preisen'**
  String get whatIfSame;

  /// No description provided for @whatIfEmpty.
  ///
  /// In de, this message translates to:
  /// **'Für Was-wäre-wenn braucht es einen Tracker mit Arbeitspreis oder festen Kosten.'**
  String get whatIfEmpty;

  /// No description provided for @entryValidFrom.
  ///
  /// In de, this message translates to:
  /// **'Gilt ab'**
  String get entryValidFrom;

  /// No description provided for @detailsTitle.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// No description provided for @detailAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get detailAdd;

  /// No description provided for @detailRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get detailRemove;

  /// No description provided for @detailDueIn.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, =0{Heute} =1{Morgen} other{In {days} Tagen}}'**
  String detailDueIn(int days);

  /// No description provided for @detailDueInMonths.
  ///
  /// In de, this message translates to:
  /// **'{months, plural, =1{In einem Monat} other{In {months} Monaten}}'**
  String detailDueInMonths(int months);

  /// No description provided for @detailOverdue.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen'**
  String get detailOverdue;

  /// No description provided for @trackerSetup.
  ///
  /// In de, this message translates to:
  /// **'Felder und Einstellungen'**
  String get trackerSetup;

  /// No description provided for @trackerSetUpFields.
  ///
  /// In de, this message translates to:
  /// **'Felder festlegen'**
  String get trackerSetUpFields;

  /// No description provided for @trackerName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get trackerName;

  /// No description provided for @trackerFieldsHistory.
  ///
  /// In de, this message translates to:
  /// **'Werte mit Verlauf'**
  String get trackerFieldsHistory;

  /// No description provided for @trackerFieldsHistoryHint.
  ///
  /// In de, this message translates to:
  /// **'Trägst du mit Datum ein – daraus entstehen Verlauf, Kosten und Prognose.'**
  String get trackerFieldsHistoryHint;

  /// No description provided for @trackerFieldsDetailsHint.
  ///
  /// In de, this message translates to:
  /// **'Legst du einmal fest und änderst sie nur, wenn sich etwas ändert – z. B. Anbieter oder Vertragsende.'**
  String get trackerFieldsDetailsHint;

  /// No description provided for @startTitle.
  ///
  /// In de, this message translates to:
  /// **'Wo sollen deine Daten liegen?'**
  String get startTitle;

  /// No description provided for @startBody.
  ///
  /// In de, this message translates to:
  /// **'Kostenkurve ist kostenlos, solange alles auf diesem Gerät bleibt. Mit einem Konto liegen deine Daten in der Cloud – auf jedem Gerät.'**
  String get startBody;

  /// No description provided for @startLocalTitle.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät'**
  String get startLocalTitle;

  /// No description provided for @startLocalPrice.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos · ohne Konto'**
  String get startLocalPrice;

  /// No description provided for @startLocalPointFeatures.
  ///
  /// In de, this message translates to:
  /// **'Alle Funktionen: Verlauf, Prognose, Erinnerungen, Export'**
  String get startLocalPointFeatures;

  /// No description provided for @startLocalPointPrivate.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten verlassen dieses Gerät nicht'**
  String get startLocalPointPrivate;

  /// No description provided for @startLocalPointLimits.
  ///
  /// In de, this message translates to:
  /// **'Kein Teilen, keine Belege, keine Sicherung'**
  String get startLocalPointLimits;

  /// No description provided for @startLocalAction.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos lokal starten'**
  String get startLocalAction;

  /// No description provided for @startCloudTitle.
  ///
  /// In de, this message translates to:
  /// **'In der Cloud'**
  String get startCloudTitle;

  /// No description provided for @startCloudPrice.
  ///
  /// In de, this message translates to:
  /// **'{price} im Monat · mit Konto'**
  String startCloudPrice(String price);

  /// No description provided for @startCloudPointDevices.
  ///
  /// In de, this message translates to:
  /// **'Auf jedem Gerät, auf dem du dich anmeldest'**
  String get startCloudPointDevices;

  /// No description provided for @startCloudPointBackup.
  ///
  /// In de, this message translates to:
  /// **'Gesichert, auch wenn das Handy weg ist'**
  String get startCloudPointBackup;

  /// No description provided for @startCloudPointShare.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Partner teilen, Belege anhängen'**
  String get startCloudPointShare;

  /// No description provided for @startCloudAction.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get startCloudAction;

  /// No description provided for @startSignIn.
  ///
  /// In de, this message translates to:
  /// **'Ich habe schon ein Konto'**
  String get startSignIn;

  /// No description provided for @startFooter.
  ///
  /// In de, this message translates to:
  /// **'Du kannst jederzeit in den Einstellungen wechseln – deine Daten ziehen mit um.'**
  String get startFooter;

  /// No description provided for @cloudPriceFallback.
  ///
  /// In de, this message translates to:
  /// **'2 €'**
  String get cloudPriceFallback;

  /// No description provided for @authRegisterTab.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get authRegisterTab;

  /// No description provided for @authSignInTab.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get authSignInTab;

  /// No description provided for @authRegisterTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterBody.
  ///
  /// In de, this message translates to:
  /// **'Mit einem Konto liegen deine Daten in der Cloud und auf jedem Gerät, auf dem du dich anmeldest. Im nächsten Schritt siehst du den Preis – lokal bleibt Kostenkurve kostenlos.'**
  String get authRegisterBody;

  /// No description provided for @authSignInBody.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, um deine Cloud-Daten auf diesem Gerät zu öffnen.'**
  String get authSignInBody;

  /// No description provided for @authAppleRegister.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple registrieren'**
  String get authAppleRegister;

  /// No description provided for @authOrEmail.
  ///
  /// In de, this message translates to:
  /// **'oder mit E-Mail'**
  String get authOrEmail;

  /// No description provided for @authNoPassword.
  ///
  /// In de, this message translates to:
  /// **'Kein Passwort nötig: Du bekommst einen Code per E-Mail.'**
  String get authNoPassword;

  /// No description provided for @authCodeSentSignIn.
  ///
  /// In de, this message translates to:
  /// **'Wenn es zu {email} ein Konto gibt, ist ein Code unterwegs. Schau auch im Spam-Ordner.'**
  String authCodeSentSignIn(String email);

  /// No description provided for @authResendIn.
  ///
  /// In de, this message translates to:
  /// **'Neuen Code senden ({seconds} s)'**
  String authResendIn(int seconds);

  /// No description provided for @authChangeEmail.
  ///
  /// In de, this message translates to:
  /// **'Andere E-Mail'**
  String get authChangeEmail;

  /// No description provided for @authConsentPrefix.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Registrieren akzeptierst du die'**
  String get authConsentPrefix;

  /// No description provided for @authConsentMiddle.
  ///
  /// In de, this message translates to:
  /// **'und hast die Hinweise zum'**
  String get authConsentMiddle;

  /// No description provided for @authConsentSuffix.
  ///
  /// In de, this message translates to:
  /// **'gelesen.'**
  String get authConsentSuffix;

  /// No description provided for @authRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Bitte warte ein paar Minuten.'**
  String get authRateLimited;

  /// No description provided for @authNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Prüfe dein Netz und versuch es noch einmal.'**
  String get authNetwork;

  /// No description provided for @authEmailUsed.
  ///
  /// In de, this message translates to:
  /// **'Zu dieser E-Mail gibt es schon ein Konto. Melde dich dort an.'**
  String get authEmailUsed;

  /// No description provided for @cloudPaywallSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Kostenkurve bleibt kostenlos, solange deine Daten auf diesem Gerät liegen. Für die Cloud zahlst du {price} im Monat.'**
  String cloudPaywallSubtitle(String price);

  /// No description provided for @cloudCompareLocal.
  ///
  /// In de, this message translates to:
  /// **'Lokal'**
  String get cloudCompareLocal;

  /// No description provided for @cloudCompareFree.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos'**
  String get cloudCompareFree;

  /// No description provided for @cloudCompareCloud.
  ///
  /// In de, this message translates to:
  /// **'Cloud'**
  String get cloudCompareCloud;

  /// No description provided for @cloudFeatureAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Funktionen'**
  String get cloudFeatureAll;

  /// No description provided for @cloudFeatureDevices.
  ///
  /// In de, this message translates to:
  /// **'Auf allen Geräten'**
  String get cloudFeatureDevices;

  /// No description provided for @cloudFeatureBackup.
  ///
  /// In de, this message translates to:
  /// **'Gesichert'**
  String get cloudFeatureBackup;

  /// No description provided for @cloudFeatureShare.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Partner teilen'**
  String get cloudFeatureShare;

  /// No description provided for @cloudFeatureReceipts.
  ///
  /// In de, this message translates to:
  /// **'Belege, 5 GB'**
  String get cloudFeatureReceipts;

  /// No description provided for @cloudIncluded.
  ///
  /// In de, this message translates to:
  /// **'enthalten'**
  String get cloudIncluded;

  /// No description provided for @cloudNotIncluded.
  ///
  /// In de, this message translates to:
  /// **'nicht enthalten'**
  String get cloudNotIncluded;

  /// No description provided for @cloudSubscribe.
  ///
  /// In de, this message translates to:
  /// **'Cloud abonnieren – {price}/Monat'**
  String cloudSubscribe(String price);

  /// No description provided for @cloudStayLocal.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos lokal nutzen'**
  String get cloudStayLocal;

  /// No description provided for @cloudStayLocalHint.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben auf diesem Gerät. Die Cloud kannst du später in den Einstellungen buchen.'**
  String get cloudStayLocalHint;

  /// No description provided for @cloudContinue.
  ///
  /// In de, this message translates to:
  /// **'In die Cloud wechseln'**
  String get cloudContinue;

  /// No description provided for @storageUploading.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten ziehen in die Cloud …'**
  String get storageUploading;

  /// No description provided for @storageDownloading.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten kommen aufs Gerät …'**
  String get storageDownloading;

  /// No description provided for @storageUploaded.
  ///
  /// In de, this message translates to:
  /// **'Alles in der Cloud'**
  String get storageUploaded;

  /// No description provided for @storageDownloaded.
  ///
  /// In de, this message translates to:
  /// **'Alles auf diesem Gerät'**
  String get storageDownloaded;

  /// No description provided for @storageFailed.
  ///
  /// In de, this message translates to:
  /// **'Umzug unterbrochen – deine Daten sind noch da. Versuch es mit Netz noch einmal.'**
  String get storageFailed;

  /// No description provided for @storageAskUploadTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten vom Gerät mitnehmen?'**
  String get storageAskUploadTitle;

  /// No description provided for @storageAskUploadBody.
  ///
  /// In de, this message translates to:
  /// **'In deinem Konto liegen schon Daten. Sollen die Kategorien von diesem Gerät dazukommen?'**
  String get storageAskUploadBody;

  /// No description provided for @storageAskUploadYes.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get storageAskUploadYes;

  /// No description provided for @storageAskUploadNo.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Gerät lassen'**
  String get storageAskUploadNo;

  /// No description provided for @cloudPausedTitle.
  ///
  /// In de, this message translates to:
  /// **'Cloud pausiert'**
  String get cloudPausedTitle;

  /// No description provided for @cloudPausedBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Cloud-Abo ist beendet. Deine Daten sind sicher und bleiben lesbar – ändern kannst du sie wieder mit Abo. Oder du holst alles kostenlos auf dieses Gerät.'**
  String get cloudPausedBody;

  /// No description provided for @cloudPausedRenew.
  ///
  /// In de, this message translates to:
  /// **'Abo erneuern'**
  String get cloudPausedRenew;

  /// No description provided for @cloudPausedMove.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos aufs Gerät holen'**
  String get cloudPausedMove;

  /// No description provided for @settingsStorageTitle.
  ///
  /// In de, this message translates to:
  /// **'Speicherort'**
  String get settingsStorageTitle;

  /// No description provided for @settingsStorageLocal.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät'**
  String get settingsStorageLocal;

  /// No description provided for @settingsStorageLocalHint.
  ///
  /// In de, this message translates to:
  /// **'Kostenlos · nur dieses Gerät'**
  String get settingsStorageLocalHint;

  /// No description provided for @settingsStorageCloud.
  ///
  /// In de, this message translates to:
  /// **'In der Cloud'**
  String get settingsStorageCloud;

  /// No description provided for @settingsCloudActivate.
  ///
  /// In de, this message translates to:
  /// **'Cloud aktivieren'**
  String get settingsCloudActivate;

  /// No description provided for @settingsCloudActivateHint.
  ///
  /// In de, this message translates to:
  /// **'Auf allen Geräten, gesichert – {price}/Monat'**
  String settingsCloudActivateHint(String price);

  /// No description provided for @settingsMoveLocal.
  ///
  /// In de, this message translates to:
  /// **'Auf dieses Gerät holen'**
  String get settingsMoveLocal;

  /// No description provided for @settingsMoveLocalTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten aufs Gerät holen?'**
  String get settingsMoveLocalTitle;

  /// No description provided for @settingsMoveLocalBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien und Einträge werden auf dieses Gerät kopiert, danach speicherst du lokal und kostenlos. Belege bleiben in der Cloud. Dein Abo kündigst du in den iOS-Einstellungen.'**
  String get settingsMoveLocalBody;

  /// No description provided for @settingsStorageFooterLocal.
  ///
  /// In de, this message translates to:
  /// **'Lokal ist kostenlos. In der Cloud sind deine Daten auf jedem Gerät und gesichert.'**
  String get settingsStorageFooterLocal;

  /// No description provided for @settingsStorageFooterCloud.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten liegen in der Cloud (Rechenzentrum in Frankfurt) und als Kopie auf diesem Gerät.'**
  String get settingsStorageFooterCloud;

  /// No description provided for @cloudRequiredTitle.
  ///
  /// In de, this message translates to:
  /// **'Dafür brauchst du die Cloud'**
  String get cloudRequiredTitle;

  /// No description provided for @cloudRequiredShare.
  ///
  /// In de, this message translates to:
  /// **'Zum Teilen müssen deine Daten in der Cloud liegen. Lokal bleiben sie nur auf diesem Gerät.'**
  String get cloudRequiredShare;

  /// No description provided for @cloudRequiredAction.
  ///
  /// In de, this message translates to:
  /// **'Cloud ansehen'**
  String get cloudRequiredAction;
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
