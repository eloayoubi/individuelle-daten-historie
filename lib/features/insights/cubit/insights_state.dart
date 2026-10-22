part of 'insights_cubit.dart';

enum InsightsStatus { loading, ready, failure }

class InsightsState extends Equatable {
  const InsightsState({this.status = InsightsStatus.loading, this.years = const [], this.year, this.insights});

  final InsightsStatus status;

  /// Wählbare Jahre (älteste zuerst).
  final List<int> years;
  final int? year;
  final Insights? insights;

  InsightsState copyWith({int? year, Insights? insights}) =>
      InsightsState(status: status, years: years, year: year ?? this.year, insights: insights ?? this.insights);

  @override
  List<Object?> get props => [status, years, year, insights];
}
