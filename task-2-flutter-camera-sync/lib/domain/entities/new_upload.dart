import 'package:equatable/equatable.dart';

/// An image about to be queued, already stored in app-owned storage.
class NewUpload extends Equatable {
  const NewUpload({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
  });

  final String filePath;
  final String fileName;
  final int sizeBytes;

  @override
  List<Object?> get props => [filePath, fileName, sizeBytes];
}
