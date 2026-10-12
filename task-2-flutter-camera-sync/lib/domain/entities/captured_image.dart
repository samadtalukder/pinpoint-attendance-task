import 'package:equatable/equatable.dart';

/// A photo just taken, still in the camera's temporary location.
class CapturedImage extends Equatable {
  const CapturedImage({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;

  @override
  List<Object?> get props => [path, name, sizeBytes];
}
