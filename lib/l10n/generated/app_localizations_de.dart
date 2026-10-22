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
  String categoryFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Felder',
      one: '1 Feld',
      zero: 'keine Felder',
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
  String get roleInfo => 'Stammdatum';

  @override
  String get roleInfoHint => 'Ohne Verlauf, z. B. Zählernummer oder Anbieter';

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
  String get roleDeadlineHint => 'Erinnert rechtzeitig, z. B. Vertragsende';

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
      'Dieser Tracker hat noch keine Felder. Lege sie in der Kategorie an.';

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
  String trackerSince(String date) {
    return 'seit $date';
  }

  @override
  String get trackerEntries => 'Einträge';

  @override
  String get trackerNoEntriesTitle => 'Noch keine Einträge';

  @override
  String get trackerNoEntriesBody =>
      'Trag den ersten Wert ein – ab dem zweiten Zählerstand entsteht der Verlauf.';

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
}
