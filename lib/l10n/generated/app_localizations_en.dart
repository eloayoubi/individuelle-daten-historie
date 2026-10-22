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
  String categoryFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields',
      one: '1 field',
      zero: 'no fields',
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
  String detailReadOnly(String name) {
    return 'Read only – $name shared this category with you.';
  }

  @override
  String get detailReadOnlyUnknown =>
      'Read only – this category was shared with you.';

  @override
  String get detailMissing => 'This category no longer exists.';

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
  String get fieldFormulaSoon => 'Coming with insights';

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
  String get roleInfoHint => 'No history, e.g. meter number or provider';

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
  String get roleDeadlineHint => 'Reminds you in time, e.g. contract end';

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
  String get tplTrackerStreaming => 'Streaming';

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
}
