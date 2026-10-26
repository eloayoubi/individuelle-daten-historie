part of 'category_detail_cubit.dart';

enum CategoryDetailStatus { loading, ready, missing, failure }

enum CategoryDetailEventKind { trackerAdded, meterAdded, trackerArchived, archived, restored, deleted, addTrackerHidden, failed }

/// Einmaliges Ereignis für Toasts und Navigation. Bewusst nicht `const`.
class CategoryDetailEvent {
  CategoryDetailEvent(this.kind);

  final CategoryDetailEventKind kind;
}

class CategoryDetailState extends Equatable {
  const CategoryDetailState({
    this.status = CategoryDetailStatus.loading,
    this.category,
    this.others = const [],
    this.yearToDate = const {},
    this.period = DashboardPeriod.thisYear,
    this.custom,
    this.span,
    this.figures = const [],
    this.event,
  });

  final CategoryDetailStatus status;
  final Category? category;

  /// Die übrigen aktiven Kategorien – Ziel für „Kosten enthalten in“.
  final List<Category> others;

  /// Kosten (oder Verbrauch) je Tracker-Id im laufenden Jahr; fehlt ohne Daten.
  final Map<String, YearToDate> yearToDate;

  /// Zeitraum der Kennzahlen; [custom] ist der selbst gewählte, [span] der gerade gerechnete.
  final DashboardPeriod period;
  final DateSpan? custom;
  final DateSpan? span;

  /// Kennzahlen der Übersicht im Zeitraum [span].
  final List<DashboardFigure> figures;
  final CategoryDetailEvent? event;

  /// [event] gilt nur für genau einen Zustand und fällt beim nächsten weg.
  CategoryDetailState copyWith({
    CategoryDetailStatus? status,
    Category? category,
    List<Category>? others,
    Map<String, YearToDate>? yearToDate,
    DashboardPeriod? period,
    DateSpan? Function()? custom,
    DateSpan? span,
    List<DashboardFigure>? figures,
    CategoryDetailEvent? event,
  }) => CategoryDetailState(
    status: status ?? this.status,
    category: category ?? this.category,
    others: others ?? this.others,
    yearToDate: yearToDate ?? this.yearToDate,
    period: period ?? this.period,
    custom: custom == null ? this.custom : custom(),
    span: span ?? this.span,
    figures: figures ?? this.figures,
    event: event,
  );

  @override
  List<Object?> get props => [status, category, others, yearToDate, period, custom, span, figures, event];
}
