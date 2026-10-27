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
  String get homeStartOverline => 'Getting started';

  @override
  String get homeStartTitle => 'Your cost curve is waiting for its first entry';

  @override
  String get homeStartBody =>
      'Add a meter reading, a payment or a bill – that\'s what your costs since January, your history and your forecast are built from.';

  @override
  String get homeStartStepCategories => 'Categories set up';

  @override
  String get homeStartStepEntry => 'Add your first reading or amount';

  @override
  String homeStartStepForecast(String year) {
    return 'See your forecast for $year';
  }

  @override
  String get homeStartAction => 'Add first entry';

  @override
  String get quickAddTitle => 'What would you like to log?';

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

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDone => 'Done';

  @override
  String get errorSave => 'That didn\'t work. Please try again.';

  @override
  String get categoriesAdd => 'Add category';

  @override
  String get categoriesChooseTemplate => 'Choose a template';

  @override
  String get categoriesReorderHint =>
      'Drag categories into the order you like.';

  @override
  String get categoriesArchived => 'Archived';

  @override
  String get categoriesRestore => 'Restore';

  @override
  String categoriesRestored(String name) {
    return '$name is back.';
  }

  @override
  String categoryTrackers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trackers',
      one: '1 tracker',
      zero: 'No trackers yet',
    );
    return '$_temp0';
  }

  @override
  String get newCategoryTitle => 'New category';

  @override
  String get newCategoryCustom => 'Custom category';

  @override
  String get newCategoryCustomHint => 'Choose name, symbol and fields yourself';

  @override
  String get newCategoryTemplates => 'Templates';

  @override
  String get setupNameHint => 'Name, e.g. Electricity';

  @override
  String get setupSymbol => 'Symbol';

  @override
  String get setupColor => 'Colour';

  @override
  String get setupFields => 'Fields';

  @override
  String get setupFieldsHint =>
      'Deselected fields are just left out for now – you can change and add everything later.';

  @override
  String get setupCustomHint =>
      'Next, add trackers – e.g. a meter, a contract or a car – and give them their own fields.';

  @override
  String get setupCreate => 'Create category';

  @override
  String setupCreated(String name) {
    return '$name has been created.';
  }

  @override
  String get detailAppearance => 'Appearance';

  @override
  String get detailAppearanceHint => 'Name, icon and colour';

  @override
  String get detailEditCategory => 'Edit category';

  @override
  String get detailAddTracker => 'Add tracker';

  @override
  String get detailAddField => 'Add field';

  @override
  String get detailEditTracker => 'Edit tracker';

  @override
  String get detailNoTrackersTitle => 'No trackers yet';

  @override
  String get detailNoTrackersBody =>
      'A tracker is e.g. a meter, a contract or a car – with its own fields.';

  @override
  String get detailNoFields => 'No fields yet';

  @override
  String get detailArchive => 'Archive category';

  @override
  String detailArchiveTitle(String name) {
    return 'Archive “$name”?';
  }

  @override
  String get detailArchiveBody =>
      'The category disappears from overview and insights. You can restore it under “Archived” at any time.';

  @override
  String detailArchived(String name) {
    return '$name has been archived.';
  }

  @override
  String get detailDelete => 'Delete category';

  @override
  String detailDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get detailDeleteBody =>
      'All entries and receipts in it are deleted permanently. This cannot be undone – if you want to keep them, archive the category instead.';

  @override
  String get detailDeleteBodyShared =>
      'All entries and receipts in it are deleted permanently, also for everyone you share it with. This cannot be undone – if you want to keep them, archive the category instead.';

  @override
  String detailDeleted(String name) {
    return '$name has been deleted.';
  }

  @override
  String get detailArchivedNote =>
      'Archived – missing from overview and insights until you restore it.';

  @override
  String detailReadOnly(String name) {
    return 'Read only – $name shared this category with you.';
  }

  @override
  String get detailReadOnlyUnknown =>
      'Read only – this category was shared with you.';

  @override
  String get detailMissing => 'This category no longer exists.';

  @override
  String get trackerMissing => 'This tracker no longer exists.';

  @override
  String get detailTrackerAdded => 'Tracker added.';

  @override
  String get detailTrackerArchived => 'Tracker archived.';

  @override
  String get trackerNew => 'New tracker';

  @override
  String get trackerNameHint => 'Name, e.g. Main meter';

  @override
  String get trackerArchive => 'Archive tracker';

  @override
  String trackerArchiveTitle(String name) {
    return 'Archive “$name”?';
  }

  @override
  String get trackerArchiveBody =>
      'The tracker and its entries disappear from overview and insights.';

  @override
  String get fieldNew => 'New field';

  @override
  String get fieldNameHint => 'Name, e.g. Meter reading';

  @override
  String get fieldKind => 'Field type';

  @override
  String get fieldRole => 'Behaviour over time';

  @override
  String get fieldRoleFooter =>
      'Decides how history, costs and forecast use the value.';

  @override
  String get fieldKindLocked => 'Doesn\'t fit the saved values';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldUnitHint => 'e.g. kWh';

  @override
  String get fieldMeter => 'Consumption';

  @override
  String get fieldConsumptionUnitLabel => 'Consumption in';

  @override
  String get fieldConsumptionUnitHint => 'same as unit';

  @override
  String get fieldFactorLabel => 'Conversion factor';

  @override
  String get fieldFactorFooter =>
      'Gas: calorific value × conversion number from your bill (usually around 10.5). Otherwise 1.';

  @override
  String get fieldFactorInvalid => 'Please enter a number greater than 0.';

  @override
  String get fieldInterval => 'Due';

  @override
  String get fieldChoices => 'Options';

  @override
  String get fieldChoiceHint => 'New option, e.g. 3 months';

  @override
  String fieldChoiceRemove(String choice) {
    return 'Remove $choice';
  }

  @override
  String get fieldChoicesEmpty => 'Add at least one option.';

  @override
  String get fieldArchive => 'Remove field';

  @override
  String get fieldKeepsBills =>
      'Your bills need this unit price – it stays a price per unit and can\'t be archived.';

  @override
  String get fieldKeepsMeter =>
      'This meter reading already has values – it stays a meter reading, otherwise all readings would change meaning.';

  @override
  String get trackerNoEntriesViewer =>
      'As soon as someone adds a value, it shows up here.';

  @override
  String fieldArchiveTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get fieldArchiveBody =>
      'Saved values are kept, but the field no longer appears.';

  @override
  String get fieldSaved => 'Field saved.';

  @override
  String get fieldArchived => 'Field removed.';

  @override
  String get kindText => 'Text';

  @override
  String get kindNumber => 'Number';

  @override
  String get kindCurrency => 'Amount (€)';

  @override
  String get kindPercent => 'Percent';

  @override
  String get kindDate => 'Date';

  @override
  String get kindToggle => 'Yes/No';

  @override
  String get kindChoice => 'Choice';

  @override
  String get kindFormula => 'Formula';

  @override
  String get roleInfo => 'Detail';

  @override
  String get roleInfoHint =>
      'Set once, e.g. provider or contract number – not with every entry';

  @override
  String get roleSnapshot => 'Snapshot';

  @override
  String get roleSnapshotHint =>
      'Valid on the day of the entry, e.g. tank level';

  @override
  String get roleMeterReading => 'Meter reading';

  @override
  String get roleMeterReadingHint =>
      'Consumption is the difference between two readings';

  @override
  String get roleUnitPrice => 'Price per unit';

  @override
  String get roleUnitPriceHint =>
      'Applies from the date – consumption × price gives the cost';

  @override
  String get roleRecurringCost => 'Recurring amount';

  @override
  String get roleRecurringCostHint =>
      'Applies from the date, e.g. rent, standing charge or subscription';

  @override
  String get roleOneOffCost => 'One-off amount';

  @override
  String get roleOneOffCostHint =>
      'Counts on the day of the entry, e.g. fuel or a back payment';

  @override
  String get roleDeadline => 'Deadline';

  @override
  String get roleDeadlineHint =>
      'Set once and get reminded in time, e.g. contract end';

  @override
  String get intervalMonthly => 'Monthly';

  @override
  String get intervalQuarterly => 'Quarterly';

  @override
  String get intervalYearly => 'Yearly';

  @override
  String intervalMonths(int months) {
    return 'Every $months months';
  }

  @override
  String get unitPerMonth => '€/month';

  @override
  String get unitPerYear => '€/year';

  @override
  String get tplStrom => 'Electricity';

  @override
  String get tplStromHint =>
      'Meter reading, unit price, standing charge and contract end';

  @override
  String get tplHeizung => 'Heating';

  @override
  String get tplHeizungHint =>
      'Gas meter converted to kWh, prices and contract';

  @override
  String get tplWasser => 'Water';

  @override
  String get tplWasserHint => 'Water meter and price per cubic metre';

  @override
  String get tplMiete => 'Rent & utilities';

  @override
  String get tplMieteHint => 'Base rent, advance payments and statements';

  @override
  String get tplAuto => 'Car';

  @override
  String get tplAutoHint => 'Mileage, fuel, insurance, tax and inspection';

  @override
  String get tplInternet => 'Internet & mobile';

  @override
  String get tplInternetHint => 'Contracts with price and minimum term';

  @override
  String get tplVersicherung => 'Insurance';

  @override
  String get tplVersicherungHint => 'Premiums, policy number and renewal date';

  @override
  String get tplAbos => 'Subscriptions';

  @override
  String get tplAbosHint => 'Streaming, gym & co. with cancellation date';

  @override
  String get tplTrackerElectricityMeter => 'Electricity meter';

  @override
  String get tplTrackerGasMeter => 'Gas meter';

  @override
  String get tplTrackerWaterMeter => 'Water meter';

  @override
  String get tplTrackerFlat => 'Flat';

  @override
  String get tplTrackerCar => 'My car';

  @override
  String get tplTrackerInternet => 'Internet';

  @override
  String get tplTrackerMobile => 'Mobile';

  @override
  String get tplTrackerLiability => 'Liability';

  @override
  String get tplTrackerContents => 'Home contents';

  @override
  String get tplFieldReading => 'Meter reading';

  @override
  String get tplFieldUnitPrice => 'Unit price';

  @override
  String get tplFieldBasePrice => 'Standing charge';

  @override
  String get tplFieldInstalment => 'Monthly instalment';

  @override
  String get tplFieldProvider => 'Provider';

  @override
  String get tplFieldContractEnd => 'Contract end';

  @override
  String get tplFieldWaterPrice => 'Water & sewage';

  @override
  String get tplFieldBaseRent => 'Base rent';

  @override
  String get tplFieldAdvance => 'Utility advance payment';

  @override
  String get tplFieldSettlement => 'Balance due / credit';

  @override
  String get tplFieldLandlord => 'Landlord';

  @override
  String get tplFieldFuel => 'Fuel / charging';

  @override
  String get tplFieldFuelAmount => 'Amount (l or kWh)';

  @override
  String get tplFieldCarInsurance => 'Car insurance';

  @override
  String get tplFieldCarTax => 'Vehicle tax';

  @override
  String get tplFieldWorkshop => 'Repairs';

  @override
  String get tplFieldInspection => 'Inspection due';

  @override
  String get tplFieldMonthlyPrice => 'Monthly price';

  @override
  String get tplFieldMinimumTerm => 'Minimum term until';

  @override
  String get tplFieldPremium => 'Premium';

  @override
  String get tplFieldPolicyNumber => 'Policy number';

  @override
  String get tplFieldDueDate => 'Renewal date';

  @override
  String get tplFieldPrice => 'Price';

  @override
  String get tplFieldCancelBy => 'Cancel by';

  @override
  String get actionDelete => 'Delete';

  @override
  String get toggleYes => 'Yes';

  @override
  String get toggleNo => 'No';

  @override
  String get datePickerTitle => 'Choose date';

  @override
  String get entryNew => 'New entry';

  @override
  String get entryEdit => 'Edit entry';

  @override
  String get entryDate => 'Date';

  @override
  String get entryNote => 'Note';

  @override
  String get entryNoteHint => 'Optional, e.g. read after the holiday';

  @override
  String entryLast(String value, String date) {
    return 'Last $value · $date';
  }

  @override
  String entryCurrent(String value, String date) {
    return 'Currently $value since $date – leave empty if nothing changes';
  }

  @override
  String entryDelta(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String entryBelowLast(String value) {
    return 'Lower than the last reading ($value) – new meter?';
  }

  @override
  String get entryMeterChange => 'New meter from this reading';

  @override
  String get entryMeterChangeHint =>
      'Consumption since the last reading is estimated from the period before.';

  @override
  String get entryInvalidNumber => 'Please enter a number.';

  @override
  String get entryNeedsValue => 'Enter at least one value.';

  @override
  String get wordAnd => 'and';

  @override
  String get entryNoteHintBill => 'Optional, e.g. invoice number';

  @override
  String get entryNoteHintContract => 'Optional, e.g. price increase letter';

  @override
  String get entryNeedsConsumption => 'Enter the consumption from your bill.';

  @override
  String get entryNeedsPrice => 'Enter at least one price.';

  @override
  String get entryNeedsReading => 'Enter the meter reading.';

  @override
  String get contractSave => 'Save prices';

  @override
  String get entryNoFields =>
      'This tracker has no fields to enter yet. Add them under “Edit”.';

  @override
  String get entrySave => 'Save entry';

  @override
  String get entrySaved => 'Saved.';

  @override
  String get entrySavedOffline => 'Saved – it will sync once you\'re online.';

  @override
  String get entryDelete => 'Delete entry';

  @override
  String entryDeleteTitle(String date) {
    return 'Delete entry from $date?';
  }

  @override
  String get entryDeleteBody =>
      'The entry disappears from history, costs and forecast.';

  @override
  String get entryDeleted => 'Entry deleted.';

  @override
  String get trackerHistory => 'History and entries';

  @override
  String trackerSince(String date) {
    return 'since $date';
  }

  @override
  String get trackerLast12 => 'Last 12 months';

  @override
  String get metricCost => 'Costs';

  @override
  String get metricConsumption => 'Consumption';

  @override
  String trackerThisYear(String year) {
    return '$year to date';
  }

  @override
  String get trackerLastYear => 'Last year to date';

  @override
  String get trackerChartEmpty => 'Not enough data for a history yet.';

  @override
  String trackerChartValue(String month, String value) {
    return '$month: $value';
  }

  @override
  String get trackerCurrentValues => 'Current values';

  @override
  String get trackerEntries => 'Entries';

  @override
  String trackerAllEntries(int count) {
    return 'All $count';
  }

  @override
  String get trackerNoEntriesTitle => 'No entries yet';

  @override
  String get trackerNoEntriesBody =>
      'Add your first value – a bill or a second meter reading starts the history.';

  @override
  String get trackerAddEntry => 'Add value';

  @override
  String get trackerAddEntryFor => 'Add a value for …';

  @override
  String get trackerMeterChanged => 'New meter';

  @override
  String homeSyncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries are waiting for a connection',
      one: '1 entry is waiting for a connection',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncPendingHint =>
      'It syncs automatically once you\'re online.';

  @override
  String homeSyncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries were rejected',
      one: '1 entry was rejected',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncRejectedHint =>
      'Missing rights or an invalid value. Tap to dismiss.';

  @override
  String homeSyncHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries are on hold',
      one: '1 entry is on hold',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncHeldHint =>
      'No write access anymore or the category\'s cloud subscription has ended. It will be sent again as soon as possible.';

  @override
  String get homeSyncDiscard => 'Discard';

  @override
  String homeSyncDiscardTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Discard $count entries on hold?',
      one: 'Discard entry on hold?',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncDiscardBody =>
      'They will be removed from this device and won\'t reach the cloud.';

  @override
  String get remindersEnable => 'Turn on reminders';

  @override
  String get remindersEnableHint => 'Get reminded about readings and deadlines';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsRemindersFooter =>
      'Reminds you to read a meter after 30 days without a reading, and 30, 7 and 1 day before deadlines such as a contract end.';

  @override
  String get settingsRemindersDenied =>
      'Notifications are turned off in system settings. Turn them on there for Kostenkurve.';

  @override
  String get notifyChannel => 'Reminders';

  @override
  String notifyReadBody(int days) {
    return 'No new reading for $days days – add it quickly.';
  }

  @override
  String notifyDeadlineBody(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'Tomorrow',
    );
    return '$_temp0: $date.';
  }

  @override
  String entryFieldValue(String field, String value) {
    return '$field $value';
  }

  @override
  String trackerUpcoming(String date, String value) {
    return 'from $date: $value';
  }

  @override
  String categoryEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries yet',
    );
    return '$_temp0';
  }

  @override
  String get roleInstalment => 'Instalment';

  @override
  String get roleInstalmentHint =>
      'Monthly prepayment – not a cost, compared with the costs in the instalment check';

  @override
  String forecastRange(String low, String high) {
    return 'Range $low – $high';
  }

  @override
  String insightsCosts(String year) {
    return 'Costs $year';
  }

  @override
  String get insightsProjected => 'Projected to December';

  @override
  String insightsProjectedValue(String value) {
    return '$value (projected)';
  }

  @override
  String get insightsMonthly => 'Costs per month';

  @override
  String get insightsPartMeter => 'Consumption × price (meters)';

  @override
  String get insightsPartFixed =>
      'Fixed amounts (rent, contracts, subscriptions)';

  @override
  String get insightsPartOneOff => 'One-off (avg. of the last 12 months)';

  @override
  String insightsTrend(String tracker, String change) {
    return '$tracker: $change consumption vs. last year included';
  }

  @override
  String get insightsForecastExplain =>
      'Meters use last year\'s consumption for the same season, adjusted for the trend. Prices and amounts apply as they will then – including increases you already entered. The range grows with irregular spending.';

  @override
  String insightsComparison(String year, String previous) {
    return '$year vs. $previous';
  }

  @override
  String insightsPrevious(String year, String value) {
    return '$year: $value';
  }

  @override
  String get insightsConsumptionHint =>
      'To date, compared with the same period last year.';

  @override
  String get insightsInstalments => 'Instalment check';

  @override
  String insightsInstalmentDetail(String paid, String year, String cost) {
    return 'Instalment $paid per month · costs $year ≈ $cost';
  }

  @override
  String insightsCredit(String value) {
    return 'Credit ≈ $value';
  }

  @override
  String insightsBackPayment(String value) {
    return 'Back payment ≈ $value';
  }

  @override
  String insightsSuggest(String value) {
    return 'About $value per month would fit.';
  }

  @override
  String get insightsInstalmentFooter =>
      'Instalments against the calculated costs of the whole year – projected to December for the current year.';

  @override
  String insightsIncluded(String tracker, String cost, String category) {
    return '$tracker: $cost are part of $category and count there.';
  }

  @override
  String get trackerIncludedIn => 'Costs included in';

  @override
  String get trackerIncludedNone => 'Own costs';

  @override
  String get trackerIncludedHint =>
      'E.g. water that is already part of the utility costs: costs are shown but never counted twice.';

  @override
  String trackerIncludedNote(String category) {
    return 'Costs are part of $category and count there.';
  }

  @override
  String get fieldFormula => 'Formula';

  @override
  String get fieldFormulaHint => 'e.g. consumption * unit_price';

  @override
  String get fieldFormulaValues => 'Values';

  @override
  String get fieldFormulaFunctions => 'Functions';

  @override
  String fieldFormulaPreview(String value) {
    return 'With the latest entry: $value';
  }

  @override
  String get fieldFormulaNoPreview => 'No entry to calculate with yet.';

  @override
  String get fieldFormulaFooter =>
      'Calculates per entry with this tracker\'s fields, plus consumption, days and months since the previous entry. Separate several values in functions with ;.';

  @override
  String get formulaErrorEmpty => 'Please enter an expression.';

  @override
  String formulaErrorCharacter(String detail, int position) {
    return 'Unexpected character “$detail” at position $position.';
  }

  @override
  String get formulaErrorEnd => 'The expression ends too early.';

  @override
  String formulaErrorToken(String detail, int position) {
    return 'Unexpected “$detail” at position $position.';
  }

  @override
  String formulaErrorParenthesis(int position) {
    return 'A closing parenthesis is missing (position $position).';
  }

  @override
  String formulaErrorFunction(String detail) {
    return 'Unknown function “$detail”.';
  }

  @override
  String formulaErrorArguments(String detail) {
    return 'Wrong number of values for “$detail”.';
  }

  @override
  String formulaErrorVariable(String detail) {
    return 'Unknown name “$detail”.';
  }

  @override
  String get formulaErrorDeep => 'Nested too deeply.';

  @override
  String insightsRangeOnly(String range) {
    return '± $range';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSecuredToast => 'Account secured';

  @override
  String get accountSignedInToast => 'Signed in';

  @override
  String get accountNameSaved => 'Name saved';

  @override
  String get accountSignedOutToast => 'Signed out';

  @override
  String get accountAlreadyUsedTitle => 'Account already exists';

  @override
  String get accountAlreadyUsedBody =>
      'This Apple ID already belongs to an account. Do you want to sign in there? What you have recorded without an account so far will not be moved.';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountInvalidCode => 'The code is wrong or has expired.';

  @override
  String get accountSignInTitle => 'Sign in with an existing account?';

  @override
  String get accountSignInBody =>
      'You will switch to your account. What you have recorded on this device without an account will not be moved.';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutBody =>
      'Your data stays in the cloud. On this device you’ll choose again where to store.';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Note: $count entries haven\'t been sent yet. They will be lost unless you sign in with this account again.',
      one:
          'Note: 1 entry hasn\'t been sent yet. It will be lost unless you sign in with this account again.',
    );
    return '$_temp0';
  }

  @override
  String get accountAnonymousTitle => 'Only on this device';

  @override
  String get accountAnonymousBody =>
      'Your data lives in an account without sign-in. Secure it so it survives a new phone and you can share categories.';

  @override
  String get accountSecuredTitle => 'Account secured';

  @override
  String accountSecuredBody(String login) {
    return 'Signed in with $login.';
  }

  @override
  String get accountApple => 'Apple';

  @override
  String get accountSecure => 'Secure account';

  @override
  String get accountSecureApple => 'Secure with Apple';

  @override
  String get accountSecureEmail => 'Secure with email';

  @override
  String get accountSecureFooter =>
      'Everything you have recorded stays. No password: Apple or a code by email.';

  @override
  String get accountExisting => 'Already have an account?';

  @override
  String get accountSignInApple => 'Sign in with Apple';

  @override
  String get accountSignInEmail => 'Sign in with email';

  @override
  String get accountName => 'Your name';

  @override
  String get accountNameHint => 'e.g. Alex';

  @override
  String get accountNameFooter =>
      'Visible to everyone you share categories with – also on your entries.';

  @override
  String get accountEmailHint => 'name@example.com';

  @override
  String accountCodeSent(String email) {
    return 'Code sent to $email. Check your spam folder too.';
  }

  @override
  String get accountCodeHint => 'Code from the email';

  @override
  String get accountConfirm => 'Confirm';

  @override
  String get accountResend => 'Send new code';

  @override
  String get accountSendCode => 'Send code';

  @override
  String get shareRemoved => 'Removed';

  @override
  String get shareLeft => 'Left category';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleEditor => 'Can edit';

  @override
  String get roleViewer => 'View only';

  @override
  String get roleEditorHint => 'Can add, change and delete entries.';

  @override
  String get roleViewerHint => 'Sees history and costs but changes nothing.';

  @override
  String get shareNoName => 'No name';

  @override
  String get shareRemove => 'Remove';

  @override
  String shareRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get shareRemoveBody =>
      'They will no longer see the category. Their entries stay.';

  @override
  String shareLeaveTitle(String category) {
    return 'Leave “$category”?';
  }

  @override
  String get shareLeaveBody =>
      'You will no longer see the category. Your entries stay for the others.';

  @override
  String get shareLeave => 'Leave';

  @override
  String get shareTitle => 'Share';

  @override
  String get shareMembers => 'Members';

  @override
  String get shareYou => 'You';

  @override
  String shareYouNamed(String name) {
    return '$name (you)';
  }

  @override
  String get shareInvite => 'Invite';

  @override
  String get shareSecureFirst =>
      'To share you need a secured account – so your partner knows who they share with and nothing gets lost.';

  @override
  String get shareCreateInvite => 'Create invite';

  @override
  String get shareSend => 'Send invite';

  @override
  String shareMessage(String category, String code, String link) {
    return 'I\'m sharing “$category” with you in Kostenkurve. Open the link or enter the code $code in the app under Categories › + › Accept invite: $link';
  }

  @override
  String get shareValidity => 'Valid for 7 days, for one person.';

  @override
  String get joinTitle => 'Accept invite';

  @override
  String get joinRowHint => 'Join a partner\'s category';

  @override
  String get joinDone => 'Joined';

  @override
  String get joinInvalid => 'Code unknown, expired or already used.';

  @override
  String get joinOwnerNoCloud =>
      'The person who shared this category has no cloud subscription right now. The code stays valid – try again later.';

  @override
  String get joinBody =>
      'Enter the code from the invite. Afterwards you see the category and, depending on your role, record along.';

  @override
  String get joinHint => 'Code, e.g. K7Q2M9X4TA';

  @override
  String get joinAction => 'Join';

  @override
  String entryBy(String name) {
    return 'by $name';
  }

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete account and all data?';

  @override
  String get accountDeleteBody =>
      'Your account and your cloud categories with all entries and receipts are deleted immediately – also for everyone you share them with. This cannot be undone. Cancel a cloud subscription separately in iOS Settings.';

  @override
  String accountDeletePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Note: $count entries haven\'t been sent yet and will be lost with the account.',
      one:
          'Note: 1 entry hasn\'t been sent yet and will be lost with the account.',
    );
    return '$_temp0';
  }

  @override
  String get accountDeleteFooter =>
      'Export your data first if you want to keep it (Settings › Export data).';

  @override
  String get accountDeletedToast => 'Account deleted';

  @override
  String get attachmentsTitle => 'Receipts';

  @override
  String get attachmentsAdd => 'Add';

  @override
  String get attachmentsAdded => 'Receipt added';

  @override
  String get attachmentsDeleted => 'Receipt deleted';

  @override
  String get attachmentsAfterSave =>
      'After saving you can attach a bill, contract or meter photo.';

  @override
  String get attachmentsEmpty =>
      'No receipts yet. Attach a bill, contract or a photo of the meter.';

  @override
  String get attachmentsEmptyPlus =>
      'In the cloud you can attach bills, contracts and meter photos right to the entry.';

  @override
  String get attachmentsOffline => 'Receipts are not available right now.';

  @override
  String get attachmentsCamera => 'Take photo';

  @override
  String get attachmentsPhotos => 'Choose from Photos';

  @override
  String get attachmentsPdf => 'Choose PDF';

  @override
  String get attachmentsNeedsPlus =>
      'Adding receipts needs Plus and edit rights.';

  @override
  String get attachmentsTooLarge => 'The file is larger than 20 MB.';

  @override
  String get attachmentsQuota => 'Your receipt storage is full (5 GB).';

  @override
  String get attachmentsType => 'Only photos (JPEG, PNG, HEIC) and PDFs.';

  @override
  String get attachmentsNotSynced =>
      'The entry has not been sent yet – try again in a moment.';

  @override
  String get attachmentsNoAccess =>
      'No access – allow camera or photos in Settings.';

  @override
  String get attachmentsPhotoTitle => 'Photo';

  @override
  String get attachmentsPdfTitle => 'PDF';

  @override
  String get attachmentsShare => 'Share';

  @override
  String get attachmentsOpenPdf => 'Open or save';

  @override
  String get attachmentsDeleteTitle => 'Delete receipt?';

  @override
  String get attachmentsDeleteBody =>
      'The file is deleted for everyone who sees the category.';

  @override
  String get entryPeriod => 'Billing period';

  @override
  String get entryPeriodFrom => 'From';

  @override
  String get entryPeriodTo => 'To';

  @override
  String get entryPeriodHint =>
      'Back payment or credit for a period: the amount is spread over its days instead of the entry date.';

  @override
  String get entryPeriodInvalid => 'The end is before the start.';

  @override
  String get entryKindBill => 'Bill';

  @override
  String get entryKindReading => 'Meter reading';

  @override
  String get entryBillConsumption => 'Consumption';

  @override
  String entryBillPerMonth(String amount) {
    return '≈ $amount per month';
  }

  @override
  String get entryBillHint => 'Period and consumption are on your bill.';

  @override
  String get entryBillOverlap =>
      'Overlaps another bill – on those days the one ending later counts.';

  @override
  String get contractChange => 'Change prices';

  @override
  String get contractEdit => 'Price change';

  @override
  String contractDeleteTitle(String date) {
    return 'Delete price change from $date?';
  }

  @override
  String contractDeleteBody(int count, String prices) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$prices will be removed',
      one: '$prices will be removed',
    );
    return '$_temp0 from contract, costs and forecast.';
  }

  @override
  String get contractTitle => 'Contract';

  @override
  String get contractSet => 'Add';

  @override
  String get contractMissingPrice =>
      'Without a unit price the app can\'t calculate costs yet.';

  @override
  String get contractMissingTitle => 'No prices yet';

  @override
  String get contractMissingBody =>
      'Add the unit price, standing charge and instalment from your contract – then the app calculates your costs and checks your instalment.';

  @override
  String get contractEnterPrices => 'Add prices';

  @override
  String priceHistoryFrom(String date) {
    return 'from $date';
  }

  @override
  String get priceHistoryPlanned => 'planned';

  @override
  String get priceHistoryEmpty => 'No price entered yet.';

  @override
  String entryPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get exportCategory => 'Category';

  @override
  String get exportTracker => 'Tracker';

  @override
  String get exportField => 'Field';

  @override
  String get exportValue => 'Value';

  @override
  String get exportUnit => 'Unit';

  @override
  String get exportNote => 'Note';

  @override
  String get exportSubject => 'Kostenkurve export';

  @override
  String get exportFailed => 'Export failed – are you online?';

  @override
  String get legalPrivacy => 'Privacy';

  @override
  String get legalTerms => 'Terms of Use';

  @override
  String get legalImprint => 'Legal notice';

  @override
  String get onboardingWelcomeTitle => 'All your costs.\nOne curve.';

  @override
  String get onboardingWelcomeBody =>
      'Meter readings, contracts and instalments in one place – with history and a forecast for next year.';

  @override
  String get onboardingPointTrack => 'Record in seconds';

  @override
  String get onboardingPointTrackBody =>
      'Electricity, gas, water, rent – with your own fields and formulas.';

  @override
  String get onboardingPointForecast => 'No more surprise bills';

  @override
  String get onboardingPointForecastBody =>
      'Forecast with range and instalment check.';

  @override
  String get onboardingPointShare => 'Together at home';

  @override
  String get onboardingPointShareBody => 'Share categories with your partner.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingTemplatesTitle => 'What do you want to track?';

  @override
  String get onboardingTemplatesBody =>
      'Pick templates – you can adjust the fields any time later.';

  @override
  String onboardingCreate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Create $count categories',
      one: 'Create 1 category',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkip => 'Continue without template';

  @override
  String get onboardingSelected => 'Selected';

  @override
  String get onboardingRemindersTitle => 'Never forget';

  @override
  String get onboardingRemindersBody =>
      'We remind you to read your meters and about notice periods – on your device, without ads.';

  @override
  String get onboardingRemindersAllow => 'Allow reminders';

  @override
  String get onboardingLater => 'Later';

  @override
  String get plusTitle => 'Kostenkurve Cloud';

  @override
  String get plusSubtitle => 'Your data on every device.';

  @override
  String get plusBenefitReceipts => 'Receipts on entries';

  @override
  String get plusBenefitReceiptsBody =>
      'Bills, contracts and meter photos as photo or PDF.';

  @override
  String get plusBenefitStorage => '5 GB storage';

  @override
  String get plusBenefitStorageBody =>
      'Stored securely and available on every device.';

  @override
  String get plusBenefitShared => 'For the whole household';

  @override
  String get plusBenefitSharedBody =>
      'In shared categories your partner sees the receipts – without their own subscription.';

  @override
  String get plusMonthly => 'Monthly';

  @override
  String plusPerMonth(String price) {
    return '$price/month';
  }

  @override
  String get plusMonthlyDetail => 'Cancel monthly';

  @override
  String get plusFinePrint =>
      'Renews automatically unless cancelled at least 24 hours before the end of the period. Charged to your Apple account, cancel in its settings.';

  @override
  String get plusRestore => 'Restore purchases';

  @override
  String get plusAppleEula => 'License agreement (EULA)';

  @override
  String get plusWelcome => 'Welcome to the cloud';

  @override
  String get plusNothingToRestore => 'No active subscription found.';

  @override
  String get plusPending => 'Purchase is waiting for approval.';

  @override
  String get plusFailed => 'Purchase failed – please try again later.';

  @override
  String get plusOtherAccount =>
      'This subscription belongs to another Kostenkurve account. Sign in there (Settings › Account).';

  @override
  String get plusUnavailable =>
      'Subscriptions are not available right now. Check your connection and try again later.';

  @override
  String get plusOnlyIos =>
      'You can currently subscribe to the cloud in the iPhone app – it then works here too.';

  @override
  String get plusActive => 'Cloud is active.';

  @override
  String plusActiveUntil(String date) {
    return 'Cloud is active – renews on $date.';
  }

  @override
  String get plusManage => 'Manage subscription';

  @override
  String get plusBadge => 'Cloud';

  @override
  String get plusBadgeActive => 'Active';

  @override
  String get settingsAccountAnonymous => 'Only on this device – secure now';

  @override
  String get settingsPlusHint => 'On all devices, backed up, shared';

  @override
  String settingsStorage(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportFooter =>
      'All categories and entries as CSV (for spreadsheets) and JSON.';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get whatIfTitle => 'What if …';

  @override
  String get whatIfRowHint => 'Try new prices, e.g. before switching';

  @override
  String whatIfBody(String year) {
    return 'Enter new prices – they apply from 1 January. The forecast for $year uses your consumption.';
  }

  @override
  String whatIfCurrent(String value) {
    return 'Today: $value';
  }

  @override
  String whatIfDelta(String change, String before) {
    return '$change vs. $before at today\'s prices';
  }

  @override
  String get whatIfSame => 'Same as at today\'s prices';

  @override
  String get whatIfEmpty =>
      'What if needs a tracker with a unit price or fixed costs.';

  @override
  String get entryValidFrom => 'Valid from';

  @override
  String get detailsTitle => 'Details';

  @override
  String get detailAdd => 'Add';

  @override
  String get detailRemove => 'Remove';

  @override
  String detailDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String detailDueInMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'In $months months',
      one: 'In one month',
    );
    return '$_temp0';
  }

  @override
  String get detailOverdue => 'Expired';

  @override
  String get trackerSetup => 'Fields and settings';

  @override
  String get trackerSetUpFields => 'Set up fields';

  @override
  String get trackerName => 'Name';

  @override
  String get trackerFieldsHistory => 'Values with history';

  @override
  String get trackerFieldsHistoryHint =>
      'You enter these with a date – they make up history, costs and forecast.';

  @override
  String get trackerFieldsDetailsHint =>
      'Set once and change only when something changes – e.g. provider or contract end.';

  @override
  String get startTitle => 'Where should your data live?';

  @override
  String get startBody =>
      'Kostenkurve is free as long as everything stays on this device. With an account, your data lives in the cloud – on every device.';

  @override
  String get startLocalTitle => 'On this device';

  @override
  String get startLocalPrice => 'Free · no account';

  @override
  String get startLocalPointFeatures =>
      'Every feature: history, forecast, reminders, export';

  @override
  String get startLocalPointPrivate => 'Your data never leaves this device';

  @override
  String get startLocalPointLimits => 'No sharing, no receipts, no backup';

  @override
  String get startLocalAction => 'Start locally for free';

  @override
  String get startCloudTitle => 'In the cloud';

  @override
  String startCloudPrice(String price) {
    return '$price per month · with account';
  }

  @override
  String get startCloudPointDevices => 'On every device you sign in on';

  @override
  String get startCloudPointBackup => 'Backed up, even if you lose your phone';

  @override
  String get startCloudPointShare => 'Share with your partner, attach receipts';

  @override
  String get startCloudAction => 'Create account';

  @override
  String get startSignIn => 'I already have an account';

  @override
  String get startFooter =>
      'You can switch any time in Settings – your data moves with you.';

  @override
  String get cloudPriceFallback => '€2';

  @override
  String get authRegisterTab => 'Sign up';

  @override
  String get authSignInTab => 'Sign in';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterBody =>
      'With an account, your data lives in the cloud and on every device you sign in on. You’ll see the price in the next step – on this device alone, Kostenkurve stays free.';

  @override
  String get authSignInBody =>
      'Sign in to open your cloud data on this device.';

  @override
  String get authAppleRegister => 'Sign up with Apple';

  @override
  String get authOrEmail => 'or with email';

  @override
  String get authNoPassword => 'No password needed: we’ll email you a code.';

  @override
  String authCodeSentSignIn(String email) {
    return 'If there’s an account for $email, a code is on its way. Check your spam folder too.';
  }

  @override
  String authResendIn(int seconds) {
    return 'Send new code (${seconds}s)';
  }

  @override
  String get authChangeEmail => 'Different email';

  @override
  String get authConsentPrefix => 'By signing up you accept the';

  @override
  String get authConsentMiddle => 'and have read the';

  @override
  String get authConsentSuffix => 'notice.';

  @override
  String get authRateLimited => 'Too many attempts. Please wait a few minutes.';

  @override
  String get authNetwork => 'No connection. Check your network and try again.';

  @override
  String get authEmailUsed =>
      'This email already has an account. Sign in instead.';

  @override
  String cloudPaywallSubtitle(String price) {
    return 'Kostenkurve stays free while your data lives on this device. The cloud costs $price per month.';
  }

  @override
  String get cloudCompareLocal => 'Local';

  @override
  String get cloudCompareFree => 'Free';

  @override
  String get cloudCompareCloud => 'Cloud';

  @override
  String get cloudFeatureAll => 'Every feature';

  @override
  String get cloudFeatureDevices => 'On all devices';

  @override
  String get cloudFeatureBackup => 'Backed up';

  @override
  String get cloudFeatureShare => 'Share with your partner';

  @override
  String get cloudFeatureReceipts => 'Receipts, 5 GB';

  @override
  String get cloudIncluded => 'included';

  @override
  String get cloudNotIncluded => 'not included';

  @override
  String cloudSubscribe(String price) {
    return 'Subscribe – $price/month';
  }

  @override
  String get cloudStayLocal => 'Use locally for free';

  @override
  String get cloudStayLocalHint =>
      'Your data stays on this device. You can turn on the cloud later in Settings.';

  @override
  String get cloudContinue => 'Switch to the cloud';

  @override
  String get storageUploading => 'Moving your data to the cloud …';

  @override
  String get storageDownloading => 'Copying your data to this device …';

  @override
  String get storageUploaded => 'Everything is in the cloud';

  @override
  String get storageDownloaded => 'Everything is on this device';

  @override
  String get storageFailed =>
      'Move interrupted – your data is safe. Try again with a connection.';

  @override
  String get storageAskUploadTitle => 'Bring your data from this device?';

  @override
  String get storageAskUploadBody =>
      'Your account already has data. Add the categories from this device?';

  @override
  String get storageAskUploadYes => 'Add';

  @override
  String get storageAskUploadNo => 'Keep on device';

  @override
  String get cloudPausedTitle => 'Cloud paused';

  @override
  String get cloudPausedBody =>
      'Your cloud subscription has ended. Your data is stored safely – renew to view and edit it again. Or move everything to this device for free.';

  @override
  String get cloudPausedRenew => 'Renew subscription';

  @override
  String get cloudPausedMove => 'Move to this device for free';

  @override
  String get settingsStorageTitle => 'Storage';

  @override
  String get settingsStorageLocal => 'On this device';

  @override
  String get settingsStorageLocalHint => 'Free · this device only';

  @override
  String get settingsStorageCloud => 'In the cloud';

  @override
  String get settingsCloudActivate => 'Turn on cloud';

  @override
  String settingsCloudActivateHint(String price) {
    return 'On all devices, backed up – $price/month';
  }

  @override
  String get settingsMoveLocal => 'Move to this device';

  @override
  String get settingsMoveLocalTitle => 'Move your data to this device?';

  @override
  String get settingsMoveLocalBody =>
      'All categories and entries are copied to this device; from then on you store locally for free. Receipts stay in the cloud. Cancel your subscription in iOS Settings.';

  @override
  String get settingsStorageFooterLocal =>
      'Local is free. In the cloud your data is on every device and backed up.';

  @override
  String get settingsStorageFooterCloud =>
      'Your data lives in the cloud (data centre in Frankfurt) with a copy on this device.';

  @override
  String get cloudRequiredTitle => 'This needs the cloud';

  @override
  String get cloudRequiredShare =>
      'To share, your data needs to be in the cloud. Local data stays on this device only.';

  @override
  String get cloudRequiredAction => 'See cloud';

  @override
  String get fieldSummary => 'Summary';

  @override
  String get fieldSummaryFooter =>
      'How the category overview sums up a period – e.g. consumption as the new minus the old meter reading.';

  @override
  String get summarySum => 'Sum';

  @override
  String get summarySumHint =>
      'Values in the period added up – recurring amounts in full per month';

  @override
  String get summaryDifference => 'Difference';

  @override
  String get summaryDifferenceHint =>
      'New minus old value, e.g. consumption from meter readings';

  @override
  String get summaryAverage => 'Average';

  @override
  String get summaryAverageHint => 'Mean of the values in the period';

  @override
  String get summaryLatest => 'Latest value';

  @override
  String get summaryLatestHint => 'The most recently entered value';

  @override
  String get summaryMin => 'Lowest value';

  @override
  String get summaryMinHint => 'The lowest value in the period';

  @override
  String get summaryMax => 'Highest value';

  @override
  String get summaryMaxHint => 'The highest value in the period';

  @override
  String get dashboardTitle => 'Overview';

  @override
  String get dashboardCustomize => 'Customize';

  @override
  String get dashboardCost => 'Costs';

  @override
  String get dashboardConsumption => 'Consumption';

  @override
  String dashboardFromField(String field) {
    return 'from $field';
  }

  @override
  String get dashboardNoValue => 'No values';

  @override
  String dashboardVsLastYear(String change) {
    return '$change vs. last year';
  }

  @override
  String dashboardVsLastMonth(String change) {
    return '$change vs. last month';
  }

  @override
  String dashboardVsBefore(String change) {
    return '$change vs. before';
  }

  @override
  String dashboardRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get dashboardEmpty => 'No key figures selected.';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodThisYear => 'This year';

  @override
  String get periodLastYear => 'Last year';

  @override
  String get periodLast12Months => '12 months';

  @override
  String get periodAll => 'All time';

  @override
  String get periodCustom => 'Range …';

  @override
  String get periodPickFrom => 'Start of range';

  @override
  String get periodPickTo => 'End of range';

  @override
  String get metricsTitle => 'Choose key figures';

  @override
  String get metricsFooter =>
      'How a field is summed up – sum, difference, average … – is set in the field settings under “Summary”.';

  @override
  String get metricsReset => 'Choose automatically';

  @override
  String get metricsCostAll => 'Category costs';

  @override
  String get detailAddTrackerHide => 'Hide “Add tracker”';

  @override
  String get detailAddTrackerHidden =>
      'Add more trackers with the pencil at the top';

  @override
  String get detailAddAnotherTracker => 'Add another tracker';

  @override
  String get meterAdd => 'Add meter';

  @override
  String get meterAddAnother => 'Add another meter';

  @override
  String get meterSetupTitle => 'Which meter do you read?';

  @override
  String get meterSetupBody =>
      'Add your meter first, e.g. flat or bathroom cold. Then enter readings and prices and add more meters.';

  @override
  String get meterSetupHint => 'Add the meter first, then enter readings.';

  @override
  String get meterEdit => 'Edit meter';

  @override
  String get meterAddHint =>
      'More meters, e.g. bathroom and toilet or cold and hot water – their usage adds up.';

  @override
  String get meterPlace => 'Location';

  @override
  String get meterPlaceBath => 'Bathroom';

  @override
  String get meterPlaceKitchen => 'Kitchen';

  @override
  String get meterPlaceToilet => 'Toilet';

  @override
  String get meterPlaceGuestToilet => 'Guest toilet';

  @override
  String get meterPlaceBasement => 'Basement';

  @override
  String get meterPlaceGarden => 'Garden';

  @override
  String get meterPlaceFlat => 'Flat';

  @override
  String get meterPlaceGarage => 'Garage';

  @override
  String get meterGroup => 'Group';

  @override
  String get meterGroupNone => 'None';

  @override
  String get meterGroupCold => 'Cold water';

  @override
  String get meterGroupWarm => 'Hot water';

  @override
  String get meterGroupHint => 'Custom group';

  @override
  String get meterGroupFieldHint => 'e.g. Cold water';

  @override
  String get meterGroupFooter =>
      'Meters in one group appear as one card in the overview, e.g. cold and hot water separately. Under “Customize” you can also show the usage of all meters together.';

  @override
  String get meterShortCold => 'cold';

  @override
  String get meterShortWarm => 'hot';

  @override
  String get meterName => 'Name';

  @override
  String get meterNameHint => 'Name, e.g. Bathroom hot';

  @override
  String get meterFirstTitle => 'Existing meter';

  @override
  String meterFirstBody(String name) {
    return 'Give “$name” a group and a name too, so the overview can tell them apart.';
  }

  @override
  String get detailMeterAdded => 'Meter added.';

  @override
  String metersAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count meters',
      two: 'Both meters',
      one: '1 meter',
    );
    return '$_temp0';
  }

  @override
  String metersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meters',
      one: '1 meter',
    );
    return '$_temp0';
  }

  @override
  String get metricsCustomAdd => 'Custom total';

  @override
  String get metricsCustomAddHint =>
      'Usage of selected meters combined, e.g. everything in the bathroom';

  @override
  String get metricsCustomTitle => 'Custom total';

  @override
  String get metricsCustomNameHint => 'Name, e.g. Bathroom';

  @override
  String get metricsCustomFooter =>
      'The usage of the chosen meters is added up. Only meters with the same unit can be combined.';

  @override
  String get itemGroup => 'Type';

  @override
  String get itemAboAdd => 'Add subscription';

  @override
  String get itemAboNameHint => 'Name, e.g. Netflix';

  @override
  String get itemAboList => 'Your subscriptions';

  @override
  String get itemAboEmptyTitle => 'No subscriptions yet';

  @override
  String get itemAboEmptyBody =>
      'Add each subscription on its own – Netflix, gym, newspaper … So you see what you pay per month and until when you can cancel.';

  @override
  String get itemAboGroupVideo => 'Streaming';

  @override
  String get itemAboGroupMusic => 'Music & audiobooks';

  @override
  String get itemAboGroupFitness => 'Fitness & sports';

  @override
  String get itemAboGroupSoftware => 'Software & cloud';

  @override
  String get itemAboGroupNews => 'News & magazines';

  @override
  String get itemAboGroupGaming => 'Gaming';

  @override
  String get itemAboGroupOther => 'Other';

  @override
  String get itemAboSuggestVideo =>
      'Netflix|Disney+|Amazon Prime|YouTube Premium|Apple TV+|WOW|DAZN|RTL+|Joyn PLUS+|Paramount+';

  @override
  String get itemAboSuggestMusic =>
      'Spotify|Apple Music|Amazon Music Unlimited|YouTube Music|Deezer|Audible';

  @override
  String get itemAboSuggestFitness =>
      'Gym|Urban Sports Club|Sports club|Gymondo';

  @override
  String get itemAboSuggestSoftware =>
      'iCloud+|Google One|Microsoft 365|Adobe Creative Cloud|ChatGPT Plus|Dropbox';

  @override
  String get itemAboSuggestNews => 'Newspaper|Magazine|SPIEGEL+|Readly';

  @override
  String get itemAboSuggestGaming =>
      'PlayStation Plus|Xbox Game Pass|Nintendo Switch Online';

  @override
  String get itemAboSuggestOther =>
      'Deutschlandticket|BahnCard|ADAC|Club membership';

  @override
  String get itemInsuranceAdd => 'Add insurance';

  @override
  String get itemInsuranceNameHint => 'Name, e.g. car insurance';

  @override
  String get itemInsuranceList => 'Your insurances';

  @override
  String get itemInsuranceEmptyTitle => 'No insurances yet';

  @override
  String get itemInsuranceEmptyBody =>
      'Add each insurance on its own – with premium and renewal date.';

  @override
  String get itemInsuranceSuggestions =>
      'Liability|Contents|Car insurance|Legal protection|Disability|Accident|Dental|Building|Travel|Pet liability|Term life';

  @override
  String get itemSuggestions => 'Suggestions';

  @override
  String get itemSince => 'Since';

  @override
  String get itemAmountFooter =>
      'Optional – applies from “Since” until you enter a new value.';

  @override
  String itemAdded(String name) {
    return '“$name” added';
  }

  @override
  String get itemOtherGroup => 'More';

  @override
  String get itemNoAmount => 'No amount yet';

  @override
  String itemDeadline(String name, String date) {
    return '$name $date';
  }

  @override
  String get forceUpdateTitle => 'New version available';

  @override
  String get forceUpdateBodyTestFlight =>
      'Kostenkurve is getting better almost every day. Install the new build in TestFlight to keep going – your data stays where it is.';

  @override
  String get forceUpdateBodyAppStore =>
      'This version is no longer supported. Update Kostenkurve in the App Store to keep going – your data stays where it is.';

  @override
  String get forceUpdateTestFlight => 'Update in TestFlight';

  @override
  String get forceUpdateAppStore => 'Update in the App Store';

  @override
  String forceUpdateBuilds(String installed, String latest) {
    return 'Build $installed → $latest';
  }
}
