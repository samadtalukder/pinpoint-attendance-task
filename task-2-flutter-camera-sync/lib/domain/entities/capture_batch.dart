import 'package:equatable/equatable.dart';

/// A group of images captured and queued together.
class CaptureBatch extends Equatable {
  const CaptureBatch({required this.id, required this.createdAt});

  final int id;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, createdAt];
}
