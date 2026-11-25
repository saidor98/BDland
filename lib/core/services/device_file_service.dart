import 'package:file_picker/file_picker.dart';

class PickedSheetFile {
  final String path;
  final String name;
  final bool isPdf;

  const PickedSheetFile({
    required this.path,
    required this.name,
    required this.isPdf,
  });
}

/// Real device storage/gallery file picker for Mouza sheets (JPG, PNG, WEBP, PDF).
class DeviceFileService {
  DeviceFileService._();
  static final DeviceFileService instance = DeviceFileService._();

  Future<PickedSheetFile?> pickMouzaSheet() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final path = file.path;
      if (path == null || path.isEmpty) return null;
      final lower = file.name.toLowerCase();
      return PickedSheetFile(
        path: path,
        name: file.name,
        isPdf: lower.endsWith('.pdf'),
      );
    } catch (_) {
      return null;
    }
  }
}
