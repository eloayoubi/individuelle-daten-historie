part of 'update_cubit.dart';

class UpdateState extends Equatable {
  const UpdateState({this.installed, this.release});

  final InstalledApp? installed;

  /// Neuerer Build als der laufende – solange gesetzt, ist die App gesperrt.
  final AppRelease? release;

  bool get required => release != null;

  @override
  List<Object?> get props => [installed, release];
}
