part of 'categories_cubit.dart';

enum CategoriesStatus { loading, ready, failure }

enum CategoriesEventKind { restored, failed }

/// Einmaliges Ereignis für Toasts. Bewusst nicht `const`, damit jedes Ereignis neu ist.
class CategoriesEvent {
  CategoriesEvent(this.kind, [this.name]);

  final CategoriesEventKind kind;
  final String? name;
}

class CategoriesState extends Equatable {
  const CategoriesState({this.status = CategoriesStatus.loading, this.active = const [], this.archived = const [], this.editing = false, this.event});

  final CategoriesStatus status;

  /// In meiner Reihenfolge.
  final List<Category> active;
  final List<Category> archived;

  /// Reihenfolge ändern (Ziehgriffe statt Antippen).
  final bool editing;
  final CategoriesEvent? event;

  /// [event] gilt nur für genau einen Zustand und fällt beim nächsten weg.
  CategoriesState copyWith({CategoriesStatus? status, List<Category>? active, List<Category>? archived, bool? editing, CategoriesEvent? event}) =>
      CategoriesState(
        status: status ?? this.status,
        active: active ?? this.active,
        archived: archived ?? this.archived,
        editing: editing ?? this.editing,
        event: event,
      );

  @override
  List<Object?> get props => [status, active, archived, editing, event];
}
