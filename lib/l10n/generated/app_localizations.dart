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

  /// No description provided for @categoryFields.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{keine Felder} =1{1 Feld} other{{count} Felder}}'**
  String categoryFields(int count);

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

  /// No description provided for @fieldFormulaSoon.
  ///
  /// In de, this message translates to:
  /// **'Kommt mit der Auswertung'**
  String get fieldFormulaSoon;

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
  /// **'Stammdatum'**
  String get roleInfo;

  /// No description provided for @roleInfoHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne Verlauf, z. B. Zählernummer oder Anbieter'**
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
  /// **'Erinnert rechtzeitig, z. B. Vertragsende'**
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
  /// **'Dieser Tracker hat noch keine Felder. Lege sie in der Kategorie an.'**
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

  /// No description provided for @trackerSince.
  ///
  /// In de, this message translates to:
  /// **'seit {date}'**
  String trackerSince(String date);

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
  /// **'Trag den ersten Wert ein – ab dem zweiten Zählerstand entsteht der Verlauf.'**
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
