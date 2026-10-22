part of 'category_detail_cubit.dart';

enum CategoryDetailStatus { loading, ready, missing, failure }

enum CategoryDetailEventKind { trackerAdded, trackerArchived, archived, failed }

/// Einmaliges Ereignis für Toasts und Navigation. Bewusst nicht `const`.
class CategoryDetailEvent {
  CategoryDetailEvent(this.kind);

  final CategoryDetailEventKind kind;
}

class CategoryDetailState extends Equatable {
  const CategoryDetailState({this.status = CategoryDetailStatus.loading, this.category, this.event});

  final CategoryDetailStatus status;
  final Category? category;
  final CategoryDetailEvent? event;

  /// [event] gilt nur für genau einen Zustand und fällt beim nächsten weg.
  CategoryDetailState copyWith({CategoryDetailStatus? status, Category? category, CategoryDetailEvent? event}) =>
      CategoryDetailState(status: status ?? this.status, category: category ?? this.category, event: event);

  @override
  List<Object?> get props => [status, category, event];
}
