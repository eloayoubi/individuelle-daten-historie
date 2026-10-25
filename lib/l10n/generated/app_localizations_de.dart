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
  String get homeStartOverline => 'Erste Schritte';

  @override
  String get homeStartTitle =>
      'Deine Kostenkurve wartet auf den ersten Eintrag';

  @override
  String get homeStartBody =>
      'Trag einen Zählerstand, einen Abschlag oder eine Rechnung ein – daraus entstehen deine Kosten seit Januar, der Verlauf und die Prognose.';

  @override
  String get homeStartStepCategories => 'Kategorien angelegt';

  @override
  String get homeStartStepEntry => 'Ersten Stand oder Betrag eintragen';

  @override
  String homeStartStepForecast(String year) {
    return 'Prognose für $year ansehen';
  }

  @override
  String get homeStartAction => 'Ersten Eintrag erfassen';

  @override
  String get quickAddTitle => 'Wofür möchtest du etwas eintragen?';

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

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionArchive => 'Archivieren';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionDone => 'Fertig';

  @override
  String get errorSave =>
      'Das hat nicht geklappt. Bitte versuch es noch einmal.';

  @override
  String get categoriesAdd => 'Kategorie hinzufügen';

  @override
  String get categoriesChooseTemplate => 'Vorlage wählen';

  @override
  String get categoriesReorderHint =>
      'Ziehe Kategorien an die Stelle, an der du sie sehen möchtest.';

  @override
  String get categoriesArchived => 'Archiviert';

  @override
  String get categoriesRestore => 'Wiederherstellen';

  @override
  String categoriesRestored(String name) {
    return '$name ist wieder da.';
  }

  @override
  String categoryTrackers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tracker',
      one: '1 Tracker',
      zero: 'Noch keine Tracker',
    );
    return '$_temp0';
  }

  @override
  String get newCategoryTitle => 'Neue Kategorie';

  @override
  String get newCategoryCustom => 'Eigene Kategorie';

  @override
  String get newCategoryCustomHint =>
      'Name, Symbol und Felder selbst festlegen';

  @override
  String get newCategoryTemplates => 'Vorlagen';

  @override
  String get setupNameHint => 'Name, z. B. Strom';

  @override
  String get setupSymbol => 'Symbol';

  @override
  String get setupColor => 'Farbe';

  @override
  String get setupFields => 'Felder';

  @override
  String get setupFieldsHint =>
      'Abgewählte Felder fehlen nur am Anfang – du kannst später alles ändern und ergänzen.';

  @override
  String get setupCustomHint =>
      'Danach legst du Tracker an – z. B. einen Zähler, einen Vertrag oder ein Auto – und gibst ihnen eigene Felder.';

  @override
  String get setupCreate => 'Kategorie anlegen';

  @override
  String setupCreated(String name) {
    return '$name ist angelegt.';
  }

  @override
  String get detailEditCategory => 'Kategorie bearbeiten';

  @override
  String get detailAddTracker => 'Tracker hinzufügen';

  @override
  String get detailAddField => 'Feld hinzufügen';

  @override
  String get detailEditTracker => 'Tracker bearbeiten';

  @override
  String get detailNoTrackersTitle => 'Noch keine Tracker';

  @override
  String get detailNoTrackersBody =>
      'Ein Tracker ist z. B. ein Zähler, ein Vertrag oder ein Auto – mit eigenen Feldern.';

  @override
  String get detailNoFields => 'Noch keine Felder';

  @override
  String get detailArchive => 'Kategorie archivieren';

  @override
  String detailArchiveTitle(String name) {
    return '„$name“ archivieren?';
  }

  @override
  String get detailArchiveBody =>
      'Die Kategorie verschwindet aus Übersicht und Auswertung. Unter „Archiviert“ kannst du sie jederzeit wiederherstellen.';

  @override
  String detailArchived(String name) {
    return '$name ist archiviert.';
  }

  @override
  String detailReadOnly(String name) {
    return 'Nur lesen – $name hat diese Kategorie mit dir geteilt.';
  }

  @override
  String get detailReadOnlyUnknown =>
      'Nur lesen – diese Kategorie wurde mit dir geteilt.';

  @override
  String get detailMissing => 'Diese Kategorie gibt es nicht mehr.';

  @override
  String get detailTrackerAdded => 'Tracker angelegt.';

  @override
  String get detailTrackerArchived => 'Tracker archiviert.';

  @override
  String get trackerNew => 'Neuer Tracker';

  @override
  String get trackerNameHint => 'Name, z. B. Hauptzähler';

  @override
  String get trackerArchive => 'Tracker archivieren';

  @override
  String trackerArchiveTitle(String name) {
    return '„$name“ archivieren?';
  }

  @override
  String get trackerArchiveBody =>
      'Der Tracker und seine Einträge verschwinden aus Übersicht und Auswertung.';

  @override
  String get fieldNew => 'Neues Feld';

  @override
  String get fieldNameHint => 'Name, z. B. Zählerstand';

  @override
  String get fieldKind => 'Feldtyp';

  @override
  String get fieldRole => 'Zeitverhalten';

  @override
  String get fieldRoleFooter =>
      'Bestimmt, wie Verlauf, Kosten und Prognose mit dem Wert rechnen.';

  @override
  String get fieldKindLocked => 'Passt nicht zu den gespeicherten Werten';

  @override
  String get fieldUnit => 'Einheit';

  @override
  String get fieldUnitHint => 'z. B. kWh';

  @override
  String get fieldMeter => 'Verbrauch';

  @override
  String get fieldConsumptionUnitLabel => 'Verbrauch in';

  @override
  String get fieldConsumptionUnitHint => 'wie Einheit';

  @override
  String get fieldFactorLabel => 'Umrechnungsfaktor';

  @override
  String get fieldFactorFooter =>
      'Gas: Brennwert × Zustandszahl von deiner Abrechnung (meist um 10,5). Sonst 1.';

  @override
  String get fieldFactorInvalid => 'Bitte eine Zahl größer als 0 eingeben.';

  @override
  String get fieldInterval => 'Fällig';

  @override
  String get fieldChoices => 'Auswahlwerte';

  @override
  String get fieldChoiceHint => 'Neuer Wert, z. B. 3 Monate';

  @override
  String fieldChoiceRemove(String choice) {
    return '$choice entfernen';
  }

  @override
  String get fieldChoicesEmpty => 'Mindestens einen Wert hinzufügen.';

  @override
  String get fieldArchive => 'Feld entfernen';

  @override
  String get fieldKeepsBills =>
      'Deine Rechnungen brauchen diesen Arbeitspreis – er bleibt ein Preis je Einheit und lässt sich nicht archivieren.';

  @override
  String fieldArchiveTitle(String name) {
    return '„$name“ entfernen?';
  }

  @override
  String get fieldArchiveBody =>
      'Gespeicherte Werte bleiben erhalten, das Feld erscheint aber nicht mehr.';

  @override
  String get fieldSaved => 'Feld gespeichert.';

  @override
  String get fieldArchived => 'Feld entfernt.';

  @override
  String get kindText => 'Text';

  @override
  String get kindNumber => 'Zahl';

  @override
  String get kindCurrency => 'Betrag (€)';

  @override
  String get kindPercent => 'Prozent';

  @override
  String get kindDate => 'Datum';

  @override
  String get kindToggle => 'Ja/Nein';

  @override
  String get kindChoice => 'Auswahl';

  @override
  String get kindFormula => 'Formel';

  @override
  String get roleInfo => 'Detail';

  @override
  String get roleInfoHint =>
      'Legst du einmal fest, z. B. Anbieter oder Vertragsnummer – nicht bei jedem Eintrag';

  @override
  String get roleSnapshot => 'Momentwert';

  @override
  String get roleSnapshotHint => 'Gilt am Tag des Eintrags, z. B. Füllstand';

  @override
  String get roleMeterReading => 'Zählerstand';

  @override
  String get roleMeterReadingHint =>
      'Verbrauch ist die Differenz zweier Stände';

  @override
  String get roleUnitPrice => 'Preis je Einheit';

  @override
  String get roleUnitPriceHint =>
      'Gilt ab dem Datum – Verbrauch × Preis ergibt die Kosten';

  @override
  String get roleRecurringCost => 'Wiederkehrender Betrag';

  @override
  String get roleRecurringCostHint =>
      'Gilt ab dem Datum, z. B. Miete, Grundpreis oder Abo';

  @override
  String get roleOneOffCost => 'Einmaliger Betrag';

  @override
  String get roleOneOffCostHint =>
      'Zählt am Tag des Eintrags, z. B. Tanken oder Nachzahlung';

  @override
  String get roleDeadline => 'Stichtag';

  @override
  String get roleDeadlineHint =>
      'Legst du einmal fest und wirst rechtzeitig erinnert, z. B. Vertragsende';

  @override
  String get intervalMonthly => 'Monatlich';

  @override
  String get intervalQuarterly => 'Vierteljährlich';

  @override
  String get intervalYearly => 'Jährlich';

  @override
  String intervalMonths(int months) {
    return 'Alle $months Monate';
  }

  @override
  String get unitPerMonth => '€/Monat';

  @override
  String get unitPerYear => '€/Jahr';

  @override
  String get tplStrom => 'Strom';

  @override
  String get tplStromHint =>
      'Zählerstand, Arbeitspreis, Grundpreis und Vertragsende';

  @override
  String get tplHeizung => 'Heizung';

  @override
  String get tplHeizungHint =>
      'Gaszähler mit Umrechnung in kWh, Preise und Vertrag';

  @override
  String get tplWasser => 'Wasser';

  @override
  String get tplWasserHint => 'Wasserzähler und Preis je Kubikmeter';

  @override
  String get tplMiete => 'Miete & Nebenkosten';

  @override
  String get tplMieteHint => 'Kaltmiete, Vorauszahlung und Abrechnungen';

  @override
  String get tplAuto => 'Auto';

  @override
  String get tplAutoHint =>
      'Kilometerstand, Tanken, Versicherung, Steuer und HU';

  @override
  String get tplInternet => 'Internet & Mobilfunk';

  @override
  String get tplInternetHint => 'Verträge mit Preis und Mindestlaufzeit';

  @override
  String get tplVersicherung => 'Versicherungen';

  @override
  String get tplVersicherungHint =>
      'Beiträge, Versicherungsnummer und Fälligkeit';

  @override
  String get tplAbos => 'Abos & Mitgliedschaften';

  @override
  String get tplAbosHint =>
      'Streaming, Fitnessstudio & Co. mit Kündigungsdatum';

  @override
  String get tplTrackerElectricityMeter => 'Stromzähler';

  @override
  String get tplTrackerGasMeter => 'Gaszähler';

  @override
  String get tplTrackerWaterMeter => 'Wasserzähler';

  @override
  String get tplTrackerFlat => 'Wohnung';

  @override
  String get tplTrackerCar => 'Mein Auto';

  @override
  String get tplTrackerInternet => 'Internet';

  @override
  String get tplTrackerMobile => 'Mobilfunk';

  @override
  String get tplTrackerLiability => 'Haftpflicht';

  @override
  String get tplTrackerContents => 'Hausrat';

  @override
  String get tplTrackerStreaming => 'Streaming';

  @override
  String get tplFieldReading => 'Zählerstand';

  @override
  String get tplFieldUnitPrice => 'Arbeitspreis';

  @override
  String get tplFieldBasePrice => 'Grundpreis';

  @override
  String get tplFieldInstalment => 'Abschlag';

  @override
  String get tplFieldProvider => 'Anbieter';

  @override
  String get tplFieldContractEnd => 'Vertragsende';

  @override
  String get tplFieldWaterPrice => 'Wasser & Abwasser';

  @override
  String get tplFieldBaseRent => 'Kaltmiete';

  @override
  String get tplFieldAdvance => 'Nebenkosten-Vorauszahlung';

  @override
  String get tplFieldSettlement => 'Nachzahlung / Guthaben';

  @override
  String get tplFieldLandlord => 'Vermieter';

  @override
  String get tplFieldFuel => 'Tanken / Laden';

  @override
  String get tplFieldFuelAmount => 'Menge (l oder kWh)';

  @override
  String get tplFieldCarInsurance => 'Kfz-Versicherung';

  @override
  String get tplFieldCarTax => 'Kfz-Steuer';

  @override
  String get tplFieldWorkshop => 'Werkstatt';

  @override
  String get tplFieldInspection => 'Hauptuntersuchung';

  @override
  String get tplFieldMonthlyPrice => 'Monatspreis';

  @override
  String get tplFieldMinimumTerm => 'Mindestlaufzeit bis';

  @override
  String get tplFieldPremium => 'Beitrag';

  @override
  String get tplFieldPolicyNumber => 'Versicherungsnummer';

  @override
  String get tplFieldDueDate => 'Hauptfälligkeit';

  @override
  String get tplFieldPrice => 'Preis';

  @override
  String get tplFieldCancelBy => 'Kündbar bis';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get toggleYes => 'Ja';

  @override
  String get toggleNo => 'Nein';

  @override
  String get datePickerTitle => 'Datum wählen';

  @override
  String get entryNew => 'Neuer Eintrag';

  @override
  String get entryEdit => 'Eintrag bearbeiten';

  @override
  String get entryDate => 'Datum';

  @override
  String get entryNote => 'Notiz';

  @override
  String get entryNoteHint => 'Optional, z. B. abgelesen nach dem Urlaub';

  @override
  String entryLast(String value, String date) {
    return 'Zuletzt $value · $date';
  }

  @override
  String entryCurrent(String value, String date) {
    return 'Aktuell $value seit $date – leer lassen, wenn sich nichts ändert';
  }

  @override
  String entryDelta(String delta, String date) {
    return '$delta seit $date';
  }

  @override
  String entryBelowLast(String value) {
    return 'Kleiner als der letzte Stand ($value) – neuer Zähler?';
  }

  @override
  String get entryMeterChange => 'Neuer Zähler ab diesem Stand';

  @override
  String get entryMeterChangeHint =>
      'Der Verbrauch seit dem letzten Stand wird aus dem Zeitraum davor geschätzt.';

  @override
  String get entryInvalidNumber => 'Bitte eine Zahl eingeben.';

  @override
  String get entryNeedsValue => 'Trag mindestens einen Wert ein.';

  @override
  String get entryNoFields =>
      'Dieser Tracker hat noch keine Felder zum Eintragen. Lege sie unter „Bearbeiten“ an.';

  @override
  String get entrySave => 'Eintrag speichern';

  @override
  String get entrySaved => 'Gespeichert.';

  @override
  String get entrySavedOffline =>
      'Gespeichert – wird übertragen, sobald du online bist.';

  @override
  String get entryDelete => 'Eintrag löschen';

  @override
  String entryDeleteTitle(String date) {
    return 'Eintrag vom $date löschen?';
  }

  @override
  String get entryDeleteBody =>
      'Der Eintrag verschwindet aus Verlauf, Kosten und Prognose.';

  @override
  String get entryDeleted => 'Eintrag gelöscht.';

  @override
  String get trackerHistory => 'Verlauf und Einträge';

  @override
  String trackerSince(String date) {
    return 'seit $date';
  }

  @override
  String get trackerLast12 => 'Letzte 12 Monate';

  @override
  String get metricCost => 'Kosten';

  @override
  String get metricConsumption => 'Verbrauch';

  @override
  String trackerThisYear(String year) {
    return '$year bis heute';
  }

  @override
  String get trackerLastYear => 'Vorjahr bis heute';

  @override
  String get trackerChartEmpty => 'Noch zu wenig Daten für einen Verlauf.';

  @override
  String trackerChartValue(String month, String value) {
    return '$month: $value';
  }

  @override
  String get trackerCurrentValues => 'Aktuelle Werte';

  @override
  String get trackerEntries => 'Einträge';

  @override
  String get trackerNoEntriesTitle => 'Noch keine Einträge';

  @override
  String get trackerNoEntriesBody =>
      'Trag den ersten Wert ein – ab einer Rechnung oder dem zweiten Zählerstand entsteht der Verlauf.';

  @override
  String get trackerAddEntry => 'Wert eintragen';

  @override
  String get trackerMeterChanged => 'Neuer Zähler';

  @override
  String homeSyncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge warten auf Verbindung',
      one: '1 Eintrag wartet auf Verbindung',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncPendingHint =>
      'Wird automatisch übertragen, sobald du online bist.';

  @override
  String homeSyncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge wurden abgelehnt',
      one: '1 Eintrag wurde abgelehnt',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncRejectedHint =>
      'Fehlende Rechte oder ein ungültiger Wert. Tippen zum Ausblenden.';

  @override
  String get remindersEnable => 'Erinnerungen aktivieren';

  @override
  String get remindersEnableHint =>
      'Ans Ablesen und an Fristen erinnern lassen';

  @override
  String get settingsReminders => 'Erinnerungen';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsRemindersFooter =>
      'Erinnert ans Ablesen, wenn ein Zähler 30 Tage keinen neuen Stand hat, und 30, 7 und 1 Tag vor Stichtagen wie dem Vertragsende.';

  @override
  String get settingsRemindersDenied =>
      'Benachrichtigungen sind in den Systemeinstellungen ausgeschaltet. Schalte sie dort für Kostenkurve ein.';

  @override
  String get notifyChannel => 'Erinnerungen';

  @override
  String notifyReadBody(int days) {
    return 'Seit $days Tagen kein neuer Stand – trag ihn kurz ein.';
  }

  @override
  String notifyDeadlineBody(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen',
      one: 'Morgen',
    );
    return '$_temp0 ist es so weit: $date.';
  }

  @override
  String entryFieldValue(String field, String value) {
    return '$field $value';
  }

  @override
  String trackerUpcoming(String date, String value) {
    return 'ab $date: $value';
  }

  @override
  String categoryEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'Noch keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get roleInstalment => 'Abschlag';

  @override
  String get roleInstalmentHint =>
      'Vorauszahlung je Monat – keine Kosten, wird im Abschlags-Check mit den Kosten verglichen';

  @override
  String forecastRange(String low, String high) {
    return 'Spanne $low – $high';
  }

  @override
  String insightsCosts(String year) {
    return 'Kosten $year';
  }

  @override
  String get insightsProjected => 'Bis Dezember hochgerechnet';

  @override
  String insightsProjectedValue(String value) {
    return '$value (hochgerechnet)';
  }

  @override
  String get insightsMonthly => 'Kosten je Monat';

  @override
  String get insightsPartMeter => 'Verbrauch × Preis (Zähler)';

  @override
  String get insightsPartFixed => 'Feste Beträge (Miete, Verträge, Abos)';

  @override
  String get insightsPartOneOff => 'Einmaliges (Ø der letzten 12 Monate)';

  @override
  String insightsTrend(String tracker, String change) {
    return '$tracker: $change Verbrauch ggü. Vorjahr eingerechnet';
  }

  @override
  String get insightsForecastExplain =>
      'Zähler rechnen mit dem Verbrauch des Vorjahres in derselben Jahreszeit, angepasst um den Trend. Preise und Beträge gelten so, wie sie dann gelten – auch schon eingetragene Erhöhungen. Die Spanne wächst mit unregelmäßigen Ausgaben.';

  @override
  String insightsComparison(String year, String previous) {
    return '$year gegen $previous';
  }

  @override
  String insightsPrevious(String year, String value) {
    return '$year: $value';
  }

  @override
  String get insightsConsumptionHint =>
      'Bis heute, verglichen mit demselben Zeitraum im Vorjahr.';

  @override
  String get insightsInstalments => 'Abschlags-Check';

  @override
  String insightsInstalmentDetail(String paid, String year, String cost) {
    return 'Ø $paid pro Monat · Kosten $year ≈ $cost';
  }

  @override
  String insightsCredit(String value) {
    return 'Guthaben ≈ $value';
  }

  @override
  String insightsBackPayment(String value) {
    return 'Nachzahlung ≈ $value';
  }

  @override
  String insightsSuggest(String value) {
    return 'Passend wären $value pro Monat.';
  }

  @override
  String get insightsInstalmentFooter =>
      'Abschläge gegen die gerechneten Kosten des ganzen Jahres – im laufenden Jahr mit Hochrechnung bis Dezember.';

  @override
  String insightsIncluded(String tracker, String cost, String category) {
    return '$tracker: $cost stecken in $category und zählen dort.';
  }

  @override
  String get trackerIncludedIn => 'Kosten enthalten in';

  @override
  String get trackerIncludedNone => 'Eigene Kosten';

  @override
  String get trackerIncludedHint =>
      'Z. B. Wasser, das schon in den Nebenkosten steckt: Die Kosten werden gezeigt, aber in keiner Summe doppelt gezählt.';

  @override
  String trackerIncludedNote(String category) {
    return 'Kosten stecken in $category und zählen dort.';
  }

  @override
  String get fieldFormula => 'Formel';

  @override
  String get fieldFormulaHint => 'z. B. verbrauch * arbeitspreis';

  @override
  String get fieldFormulaValues => 'Werte';

  @override
  String get fieldFormulaFunctions => 'Funktionen';

  @override
  String fieldFormulaPreview(String value) {
    return 'Mit dem letzten Eintrag: $value';
  }

  @override
  String get fieldFormulaNoPreview =>
      'Noch kein Eintrag, mit dem sich rechnen lässt.';

  @override
  String get fieldFormulaFooter =>
      'Rechnet je Eintrag mit den Feldern dieses Trackers, dazu verbrauch, tage und monate seit dem vorigen Eintrag. Mehrere Werte in Funktionen mit ; trennen.';

  @override
  String get formulaErrorEmpty => 'Bitte einen Ausdruck eingeben.';

  @override
  String formulaErrorCharacter(String detail, int position) {
    return 'Unerwartetes Zeichen „$detail“ an Stelle $position.';
  }

  @override
  String get formulaErrorEnd => 'Der Ausdruck endet zu früh.';

  @override
  String formulaErrorToken(String detail, int position) {
    return 'Unerwartetes „$detail“ an Stelle $position.';
  }

  @override
  String formulaErrorParenthesis(int position) {
    return 'Hier fehlt eine schließende Klammer (Stelle $position).';
  }

  @override
  String formulaErrorFunction(String detail) {
    return 'Unbekannte Funktion „$detail“.';
  }

  @override
  String formulaErrorArguments(String detail) {
    return 'Falsche Anzahl Werte für „$detail“.';
  }

  @override
  String formulaErrorVariable(String detail) {
    return 'Unbekannter Name „$detail“.';
  }

  @override
  String get formulaErrorDeep => 'Zu tief verschachtelt.';

  @override
  String insightsRangeOnly(String range) {
    return '± $range';
  }

  @override
  String get accountTitle => 'Konto';

  @override
  String get accountSecuredToast => 'Konto gesichert';

  @override
  String get accountSignedInToast => 'Angemeldet';

  @override
  String get accountNameSaved => 'Name gespeichert';

  @override
  String get accountSignedOutToast => 'Abgemeldet';

  @override
  String get accountAlreadyUsedTitle => 'Konto gibt es schon';

  @override
  String get accountAlreadyUsedBody =>
      'Diese Apple-ID gehört schon zu einem Konto. Möchtest du dich dort anmelden? Was du bisher ohne Konto erfasst hast, kommt nicht mit.';

  @override
  String get accountSignIn => 'Anmelden';

  @override
  String get accountInvalidCode => 'Der Code stimmt nicht oder ist abgelaufen.';

  @override
  String get accountSignInTitle => 'Mit bestehendem Konto anmelden?';

  @override
  String get accountSignInBody =>
      'Du wechselst zu deinem Konto. Was du auf diesem Gerät ohne Konto erfasst hast, kommt nicht mit.';

  @override
  String get accountSignOutTitle => 'Abmelden?';

  @override
  String get accountSignOutBody =>
      'Deine Daten bleiben in der Cloud. Auf diesem Gerät wählst du danach neu, wo du speicherst.';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String accountSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Achtung: $count Einträge sind noch nicht gesendet. Sie gehen verloren, wenn du dich nicht wieder mit diesem Konto anmeldest.',
      one:
          'Achtung: 1 Eintrag ist noch nicht gesendet. Er geht verloren, wenn du dich nicht wieder mit diesem Konto anmeldest.',
    );
    return '$_temp0';
  }

  @override
  String get accountAnonymousTitle => 'Nur auf diesem Gerät';

  @override
  String get accountAnonymousBody =>
      'Deine Daten liegen in einem Konto ohne Anmeldung. Sichere es, damit sie ein neues Handy überstehen und du Kategorien teilen kannst.';

  @override
  String get accountSecuredTitle => 'Konto gesichert';

  @override
  String accountSecuredBody(String login) {
    return 'Angemeldet mit $login.';
  }

  @override
  String get accountApple => 'Apple';

  @override
  String get accountSecure => 'Konto sichern';

  @override
  String get accountSecureApple => 'Mit Apple sichern';

  @override
  String get accountSecureEmail => 'Mit E-Mail sichern';

  @override
  String get accountSecureFooter =>
      'Alles, was du schon erfasst hast, bleibt erhalten. Ohne Passwort: Apple oder ein Code per E-Mail.';

  @override
  String get accountExisting => 'Schon ein Konto?';

  @override
  String get accountSignInApple => 'Mit Apple anmelden';

  @override
  String get accountSignInEmail => 'Mit E-Mail anmelden';

  @override
  String get accountName => 'Dein Name';

  @override
  String get accountNameHint => 'z. B. Alex';

  @override
  String get accountNameFooter =>
      'Sehen alle, mit denen du Kategorien teilst – auch an deinen Einträgen.';

  @override
  String get accountEmailHint => 'name@beispiel.de';

  @override
  String accountCodeSent(String email) {
    return 'Code an $email geschickt. Schau auch im Spam-Ordner.';
  }

  @override
  String get accountCodeHint => 'Code aus der E-Mail';

  @override
  String get accountConfirm => 'Bestätigen';

  @override
  String get accountResend => 'Neuen Code senden';

  @override
  String get accountSendCode => 'Code senden';

  @override
  String get shareRemoved => 'Entfernt';

  @override
  String get shareLeft => 'Kategorie verlassen';

  @override
  String get roleOwner => 'Besitzer';

  @override
  String get roleEditor => 'Bearbeiten';

  @override
  String get roleViewer => 'Nur ansehen';

  @override
  String get roleEditorHint => 'Darf Einträge erfassen, ändern und löschen.';

  @override
  String get roleViewerHint => 'Sieht Verlauf und Kosten, ändert aber nichts.';

  @override
  String get shareNoName => 'Ohne Namen';

  @override
  String get shareRemove => 'Entfernen';

  @override
  String shareRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get shareRemoveBody =>
      'Die Person sieht die Kategorie danach nicht mehr. Ihre Einträge bleiben.';

  @override
  String shareLeaveTitle(String category) {
    return '„$category“ verlassen?';
  }

  @override
  String get shareLeaveBody =>
      'Du siehst die Kategorie danach nicht mehr. Deine Einträge bleiben für die anderen.';

  @override
  String get shareLeave => 'Verlassen';

  @override
  String get shareTitle => 'Teilen';

  @override
  String get shareMembers => 'Mitglieder';

  @override
  String get shareYou => 'Du';

  @override
  String shareYouNamed(String name) {
    return '$name (du)';
  }

  @override
  String get shareInvite => 'Einladen';

  @override
  String get shareSecureFirst =>
      'Zum Teilen brauchst du ein gesichertes Konto – so weiß dein Partner, mit wem er teilt, und nichts geht verloren.';

  @override
  String get shareCreateInvite => 'Einladung erstellen';

  @override
  String get shareSend => 'Einladung senden';

  @override
  String shareMessage(String category, String code, String link) {
    return 'Ich teile „$category“ in Kostenkurve mit dir. Öffne den Link oder gib in der App unter Kategorien › + › Einladung annehmen den Code $code ein: $link';
  }

  @override
  String get shareValidity => 'Gilt 7 Tage für eine Person.';

  @override
  String get joinTitle => 'Einladung annehmen';

  @override
  String get joinRowHint => 'Kategorie eines Partners beitreten';

  @override
  String get joinDone => 'Beigetreten';

  @override
  String get joinInvalid => 'Code unbekannt, abgelaufen oder schon benutzt.';

  @override
  String get joinOwnerNoCloud =>
      'Wer die Kategorie geteilt hat, hat gerade kein Cloud-Abo. Der Code bleibt gültig – versuch es später noch einmal.';

  @override
  String get joinBody =>
      'Gib den Code aus der Einladung ein. Danach siehst du die Kategorie und je nach Rolle erfasst du mit.';

  @override
  String get joinHint => 'Code, z. B. K7Q2M9X4TA';

  @override
  String get joinAction => 'Beitreten';

  @override
  String entryBy(String name) {
    return 'von $name';
  }

  @override
  String get accountDelete => 'Konto löschen';

  @override
  String get accountDeleteTitle => 'Konto und alle Daten löschen?';

  @override
  String get accountDeleteBody =>
      'Dein Konto und deine Cloud-Kategorien mit allen Einträgen und Belegen werden sofort gelöscht – auch für alle, mit denen du sie teilst. Das lässt sich nicht rückgängig machen. Ein Cloud-Abo kündigst du separat in den iOS-Einstellungen.';

  @override
  String accountDeletePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Achtung: $count Einträge sind noch nicht gesendet und gehen mit dem Konto verloren.',
      one:
          'Achtung: 1 Eintrag ist noch nicht gesendet und geht mit dem Konto verloren.',
    );
    return '$_temp0';
  }

  @override
  String get accountDeleteFooter =>
      'Exportiere vorher deine Daten, wenn du sie behalten willst (Einstellungen › Daten exportieren).';

  @override
  String get accountDeletedToast => 'Konto gelöscht';

  @override
  String get attachmentsTitle => 'Belege';

  @override
  String get attachmentsAdd => 'Hinzufügen';

  @override
  String get attachmentsAdded => 'Beleg hinzugefügt';

  @override
  String get attachmentsDeleted => 'Beleg gelöscht';

  @override
  String get attachmentsAfterSave =>
      'Nach dem Speichern kannst du Rechnung, Vertrag oder Zählerfoto anhängen.';

  @override
  String get attachmentsEmpty =>
      'Noch keine Belege. Häng Rechnung, Vertrag oder ein Foto vom Zähler an.';

  @override
  String get attachmentsEmptyPlus =>
      'In der Cloud hängst du Rechnungen, Verträge und Zählerfotos direkt an den Eintrag.';

  @override
  String get attachmentsOffline => 'Belege sind gerade nicht erreichbar.';

  @override
  String get attachmentsCamera => 'Foto aufnehmen';

  @override
  String get attachmentsPhotos => 'Aus Fotos wählen';

  @override
  String get attachmentsPdf => 'PDF wählen';

  @override
  String get attachmentsNeedsPlus =>
      'Belege hinzufügen geht mit Plus und Bearbeiten-Rechten.';

  @override
  String get attachmentsTooLarge => 'Die Datei ist größer als 20 MB.';

  @override
  String get attachmentsQuota => 'Dein Speicher für Belege ist voll (5 GB).';

  @override
  String get attachmentsType => 'Nur Fotos (JPEG, PNG, HEIC) und PDFs.';

  @override
  String get attachmentsNotSynced =>
      'Der Eintrag ist noch nicht gesendet – gleich noch mal versuchen.';

  @override
  String get attachmentsNoAccess =>
      'Kein Zugriff – erlaube Kamera oder Fotos in den Einstellungen.';

  @override
  String get attachmentsPhotoTitle => 'Foto';

  @override
  String get attachmentsPdfTitle => 'PDF';

  @override
  String get attachmentsShare => 'Teilen';

  @override
  String get attachmentsOpenPdf => 'Öffnen oder sichern';

  @override
  String get attachmentsDeleteTitle => 'Beleg löschen?';

  @override
  String get attachmentsDeleteBody =>
      'Die Datei wird für alle gelöscht, die die Kategorie sehen.';

  @override
  String get entryPeriod => 'Abrechnungszeitraum';

  @override
  String get entryPeriodFrom => 'Von';

  @override
  String get entryPeriodTo => 'Bis';

  @override
  String get entryPeriodHint =>
      'Nachzahlung oder Guthaben für einen Zeitraum: Der Betrag verteilt sich auf dessen Tage statt auf den Stichtag.';

  @override
  String get entryPeriodInvalid => 'Das Ende liegt vor dem Anfang.';

  @override
  String get entryKindBill => 'Rechnung';

  @override
  String get entryKindReading => 'Zählerstand';

  @override
  String get entryBillConsumption => 'Verbrauch';

  @override
  String entryBillPerMonth(String amount) {
    return '≈ $amount im Monat';
  }

  @override
  String get entryBillHint =>
      'Zeitraum und Verbrauch stehen auf deiner Rechnung.';

  @override
  String get entryBillOverlap =>
      'Überschneidet sich mit einer anderen Rechnung – an diesen Tagen zählt die später endende.';

  @override
  String get contractChange => 'Preise ändern';

  @override
  String get contractEdit => 'Preisänderung';

  @override
  String contractDeleteTitle(String date) {
    return 'Preisänderung vom $date löschen?';
  }

  @override
  String contractDeleteBody(String prices) {
    return '$prices verschwinden aus Vertrag, Kosten und Prognose.';
  }

  @override
  String get contractTitle => 'Vertrag';

  @override
  String get contractSet => 'Eintragen';

  @override
  String get contractMissingPrice =>
      'Ohne Arbeitspreis rechnet die App noch keine Kosten.';

  @override
  String priceHistoryFrom(String date) {
    return 'ab $date';
  }

  @override
  String get priceHistoryPlanned => 'geplant';

  @override
  String get priceHistoryEmpty => 'Noch kein Preis eingetragen.';

  @override
  String entryPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get exportCategory => 'Kategorie';

  @override
  String get exportTracker => 'Tracker';

  @override
  String get exportField => 'Feld';

  @override
  String get exportValue => 'Wert';

  @override
  String get exportUnit => 'Einheit';

  @override
  String get exportNote => 'Notiz';

  @override
  String get exportSubject => 'Kostenkurve-Export';

  @override
  String get exportFailed => 'Export ging nicht – bist du online?';

  @override
  String get legalPrivacy => 'Datenschutz';

  @override
  String get legalTerms => 'Nutzungsbedingungen';

  @override
  String get legalImprint => 'Impressum';

  @override
  String get onboardingWelcomeTitle => 'Alle Kosten.\nEine Kurve.';

  @override
  String get onboardingWelcomeBody =>
      'Zählerstände, Verträge und Abschläge an einem Ort – mit Verlauf und Prognose fürs nächste Jahr.';

  @override
  String get onboardingPointTrack => 'Erfassen in Sekunden';

  @override
  String get onboardingPointTrackBody =>
      'Strom, Gas, Wasser, Miete – mit eigenen Feldern und Formeln.';

  @override
  String get onboardingPointForecast => 'Keine Nachzahlung mehr';

  @override
  String get onboardingPointForecastBody =>
      'Prognose mit Spanne und Abschlags-Check.';

  @override
  String get onboardingPointShare => 'Gemeinsam im Haushalt';

  @override
  String get onboardingPointShareBody => 'Teile Kategorien mit deinem Partner.';

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get onboardingTemplatesTitle => 'Was möchtest du verfolgen?';

  @override
  String get onboardingTemplatesBody =>
      'Wähle Vorlagen – Felder kannst du später jederzeit anpassen.';

  @override
  String onboardingCreate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kategorien anlegen',
      one: '1 Kategorie anlegen',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkip => 'Ohne Vorlage weiter';

  @override
  String get onboardingSelected => 'Ausgewählt';

  @override
  String get onboardingRemindersTitle => 'Nichts vergessen';

  @override
  String get onboardingRemindersBody =>
      'Wir erinnern dich ans Ablesen und an Kündigungsfristen – auf deinem Gerät, ohne Werbung.';

  @override
  String get onboardingRemindersAllow => 'Erinnerungen erlauben';

  @override
  String get onboardingLater => 'Später';

  @override
  String get plusTitle => 'Kostenkurve Cloud';

  @override
  String get plusSubtitle => 'Deine Daten auf jedem Gerät.';

  @override
  String get plusBenefitReceipts => 'Belege am Eintrag';

  @override
  String get plusBenefitReceiptsBody =>
      'Rechnungen, Verträge und Zählerfotos als Foto oder PDF.';

  @override
  String get plusBenefitStorage => '5 GB Speicher';

  @override
  String get plusBenefitStorageBody =>
      'Sicher gespeichert und auf jedem Gerät da.';

  @override
  String get plusBenefitShared => 'Für den ganzen Haushalt';

  @override
  String get plusBenefitSharedBody =>
      'In geteilten Kategorien sieht dein Partner die Belege – ohne eigenes Abo.';

  @override
  String get plusMonthly => 'Monatlich';

  @override
  String plusPerMonth(String price) {
    return '$price/Monat';
  }

  @override
  String get plusMonthlyDetail => 'Monatlich kündbar';

  @override
  String get plusFinePrint =>
      'Verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf kündigst. Abgerechnet über deinen Apple-Account, kündbar in dessen Einstellungen.';

  @override
  String get plusRestore => 'Käufe wiederherstellen';

  @override
  String get plusAppleEula => 'Lizenzvertrag (EULA)';

  @override
  String get plusWelcome => 'Willkommen in der Cloud';

  @override
  String get plusNothingToRestore => 'Kein aktives Abo gefunden.';

  @override
  String get plusPending => 'Kauf wartet auf Freigabe.';

  @override
  String get plusFailed => 'Kauf ging nicht – bitte später noch mal.';

  @override
  String get plusOtherAccount =>
      'Dieses Abo gehört zu einem anderen Kostenkurve-Konto. Melde dich dort an (Einstellungen › Konto).';

  @override
  String get plusUnavailable =>
      'Abos sind gerade nicht erreichbar. Prüfe deine Verbindung und versuch es später noch mal.';

  @override
  String get plusOnlyIos =>
      'Die Cloud buchst du derzeit in der iPhone-App – das Abo gilt dann auch hier.';

  @override
  String get plusActive => 'Cloud ist aktiv.';

  @override
  String plusActiveUntil(String date) {
    return 'Cloud ist aktiv – verlängert sich am $date.';
  }

  @override
  String get plusManage => 'Abo verwalten';

  @override
  String get plusBadge => 'Cloud';

  @override
  String get plusBadgeActive => 'Aktiv';

  @override
  String get settingsAccountAnonymous => 'Nur auf diesem Gerät – jetzt sichern';

  @override
  String get settingsPlusHint => 'Auf allen Geräten, gesichert, teilen';

  @override
  String settingsStorage(String used, String total) {
    return '$used von $total belegt';
  }

  @override
  String get settingsData => 'Daten';

  @override
  String get settingsExport => 'Daten exportieren';

  @override
  String get settingsExportFooter =>
      'Alle Kategorien und Einträge als CSV (für Tabellen) und JSON.';

  @override
  String get settingsLegal => 'Rechtliches';

  @override
  String get whatIfTitle => 'Was wäre wenn …';

  @override
  String get whatIfRowHint =>
      'Neue Preise durchspielen, z. B. vor einem Wechsel';

  @override
  String whatIfBody(String year) {
    return 'Trag neue Preise ein – sie gelten ab 1. Januar. Die Prognose für $year rechnet mit deinem Verbrauch.';
  }

  @override
  String whatIfCurrent(String value) {
    return 'Heute: $value';
  }

  @override
  String whatIfDelta(String change, String before) {
    return '$change ggü. $before mit heutigen Preisen';
  }

  @override
  String get whatIfSame => 'Wie mit heutigen Preisen';

  @override
  String get whatIfEmpty =>
      'Für Was-wäre-wenn braucht es einen Tracker mit Arbeitspreis oder festen Kosten.';

  @override
  String get entryValidFrom => 'Gilt ab';

  @override
  String get detailsTitle => 'Details';

  @override
  String get detailAdd => 'Hinzufügen';

  @override
  String get detailRemove => 'Entfernen';

  @override
  String detailDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen',
      one: 'Morgen',
      zero: 'Heute',
    );
    return '$_temp0';
  }

  @override
  String detailDueInMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'In $months Monaten',
      one: 'In einem Monat',
    );
    return '$_temp0';
  }

  @override
  String get detailOverdue => 'Abgelaufen';

  @override
  String get trackerSetup => 'Felder und Einstellungen';

  @override
  String get trackerSetUpFields => 'Felder festlegen';

  @override
  String get trackerName => 'Name';

  @override
  String get trackerFieldsHistory => 'Werte mit Verlauf';

  @override
  String get trackerFieldsHistoryHint =>
      'Trägst du mit Datum ein – daraus entstehen Verlauf, Kosten und Prognose.';

  @override
  String get trackerFieldsDetailsHint =>
      'Legst du einmal fest und änderst sie nur, wenn sich etwas ändert – z. B. Anbieter oder Vertragsende.';

  @override
  String get startTitle => 'Wo sollen deine Daten liegen?';

  @override
  String get startBody =>
      'Kostenkurve ist kostenlos, solange alles auf diesem Gerät bleibt. Mit einem Konto liegen deine Daten in der Cloud – auf jedem Gerät.';

  @override
  String get startLocalTitle => 'Auf diesem Gerät';

  @override
  String get startLocalPrice => 'Kostenlos · ohne Konto';

  @override
  String get startLocalPointFeatures =>
      'Alle Funktionen: Verlauf, Prognose, Erinnerungen, Export';

  @override
  String get startLocalPointPrivate =>
      'Deine Daten verlassen dieses Gerät nicht';

  @override
  String get startLocalPointLimits =>
      'Kein Teilen, keine Belege, keine Sicherung';

  @override
  String get startLocalAction => 'Kostenlos lokal starten';

  @override
  String get startCloudTitle => 'In der Cloud';

  @override
  String startCloudPrice(String price) {
    return '$price im Monat · mit Konto';
  }

  @override
  String get startCloudPointDevices =>
      'Auf jedem Gerät, auf dem du dich anmeldest';

  @override
  String get startCloudPointBackup => 'Gesichert, auch wenn das Handy weg ist';

  @override
  String get startCloudPointShare => 'Mit dem Partner teilen, Belege anhängen';

  @override
  String get startCloudAction => 'Konto erstellen';

  @override
  String get startSignIn => 'Ich habe schon ein Konto';

  @override
  String get startFooter =>
      'Du kannst jederzeit in den Einstellungen wechseln – deine Daten ziehen mit um.';

  @override
  String get cloudPriceFallback => '2 €';

  @override
  String get authRegisterTab => 'Registrieren';

  @override
  String get authSignInTab => 'Anmelden';

  @override
  String get authRegisterTitle => 'Konto erstellen';

  @override
  String get authRegisterBody =>
      'Mit einem Konto liegen deine Daten in der Cloud und auf jedem Gerät, auf dem du dich anmeldest. Im nächsten Schritt siehst du den Preis – lokal bleibt Kostenkurve kostenlos.';

  @override
  String get authSignInBody =>
      'Melde dich an, um deine Cloud-Daten auf diesem Gerät zu öffnen.';

  @override
  String get authAppleRegister => 'Mit Apple registrieren';

  @override
  String get authOrEmail => 'oder mit E-Mail';

  @override
  String get authNoPassword =>
      'Kein Passwort nötig: Du bekommst einen Code per E-Mail.';

  @override
  String authCodeSentSignIn(String email) {
    return 'Wenn es zu $email ein Konto gibt, ist ein Code unterwegs. Schau auch im Spam-Ordner.';
  }

  @override
  String authResendIn(int seconds) {
    return 'Neuen Code senden ($seconds s)';
  }

  @override
  String get authChangeEmail => 'Andere E-Mail';

  @override
  String get authConsentPrefix => 'Mit dem Registrieren akzeptierst du die';

  @override
  String get authConsentMiddle => 'und hast die Hinweise zum';

  @override
  String get authConsentSuffix => 'gelesen.';

  @override
  String get authRateLimited =>
      'Zu viele Versuche. Bitte warte ein paar Minuten.';

  @override
  String get authNetwork =>
      'Keine Verbindung. Prüfe dein Netz und versuch es noch einmal.';

  @override
  String get authEmailUsed =>
      'Zu dieser E-Mail gibt es schon ein Konto. Melde dich dort an.';

  @override
  String cloudPaywallSubtitle(String price) {
    return 'Kostenkurve bleibt kostenlos, solange deine Daten auf diesem Gerät liegen. Für die Cloud zahlst du $price im Monat.';
  }

  @override
  String get cloudCompareLocal => 'Lokal';

  @override
  String get cloudCompareFree => 'Kostenlos';

  @override
  String get cloudCompareCloud => 'Cloud';

  @override
  String get cloudFeatureAll => 'Alle Funktionen';

  @override
  String get cloudFeatureDevices => 'Auf allen Geräten';

  @override
  String get cloudFeatureBackup => 'Gesichert';

  @override
  String get cloudFeatureShare => 'Mit dem Partner teilen';

  @override
  String get cloudFeatureReceipts => 'Belege, 5 GB';

  @override
  String get cloudIncluded => 'enthalten';

  @override
  String get cloudNotIncluded => 'nicht enthalten';

  @override
  String cloudSubscribe(String price) {
    return 'Cloud abonnieren – $price/Monat';
  }

  @override
  String get cloudStayLocal => 'Kostenlos lokal nutzen';

  @override
  String get cloudStayLocalHint =>
      'Deine Daten bleiben auf diesem Gerät. Die Cloud kannst du später in den Einstellungen buchen.';

  @override
  String get cloudContinue => 'In die Cloud wechseln';

  @override
  String get storageUploading => 'Deine Daten ziehen in die Cloud …';

  @override
  String get storageDownloading => 'Deine Daten kommen aufs Gerät …';

  @override
  String get storageUploaded => 'Alles in der Cloud';

  @override
  String get storageDownloaded => 'Alles auf diesem Gerät';

  @override
  String get storageFailed =>
      'Umzug unterbrochen – deine Daten sind noch da. Versuch es mit Netz noch einmal.';

  @override
  String get storageAskUploadTitle => 'Daten vom Gerät mitnehmen?';

  @override
  String get storageAskUploadBody =>
      'In deinem Konto liegen schon Daten. Sollen die Kategorien von diesem Gerät dazukommen?';

  @override
  String get storageAskUploadYes => 'Hinzufügen';

  @override
  String get storageAskUploadNo => 'Auf dem Gerät lassen';

  @override
  String get cloudPausedTitle => 'Cloud pausiert';

  @override
  String get cloudPausedBody =>
      'Dein Cloud-Abo ist beendet. Deine Daten sind sicher und bleiben lesbar – ändern kannst du sie wieder mit Abo. Oder du holst alles kostenlos auf dieses Gerät.';

  @override
  String get cloudPausedRenew => 'Abo erneuern';

  @override
  String get cloudPausedMove => 'Kostenlos aufs Gerät holen';

  @override
  String get settingsStorageTitle => 'Speicherort';

  @override
  String get settingsStorageLocal => 'Auf diesem Gerät';

  @override
  String get settingsStorageLocalHint => 'Kostenlos · nur dieses Gerät';

  @override
  String get settingsStorageCloud => 'In der Cloud';

  @override
  String get settingsCloudActivate => 'Cloud aktivieren';

  @override
  String settingsCloudActivateHint(String price) {
    return 'Auf allen Geräten, gesichert – $price/Monat';
  }

  @override
  String get settingsMoveLocal => 'Auf dieses Gerät holen';

  @override
  String get settingsMoveLocalTitle => 'Daten aufs Gerät holen?';

  @override
  String get settingsMoveLocalBody =>
      'Alle Kategorien und Einträge werden auf dieses Gerät kopiert, danach speicherst du lokal und kostenlos. Belege bleiben in der Cloud. Dein Abo kündigst du in den iOS-Einstellungen.';

  @override
  String get settingsStorageFooterLocal =>
      'Lokal ist kostenlos. In der Cloud sind deine Daten auf jedem Gerät und gesichert.';

  @override
  String get settingsStorageFooterCloud =>
      'Deine Daten liegen in der Cloud (Rechenzentrum in Frankfurt) und als Kopie auf diesem Gerät.';

  @override
  String get cloudRequiredTitle => 'Dafür brauchst du die Cloud';

  @override
  String get cloudRequiredShare =>
      'Zum Teilen müssen deine Daten in der Cloud liegen. Lokal bleiben sie nur auf diesem Gerät.';

  @override
  String get cloudRequiredAction => 'Cloud ansehen';
}
