import 'app_constants.dart';

class UrlUtils {
  static String get backendOrigin {
    final uri = Uri.tryParse(AppConstants.baseUrl);
    if (uri == null) return '';
    // return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return '${uri.scheme}://${uri.authority}';
  }

  static String? normalizeMediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final value = raw.trim();

    // already full URL
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value.replaceAll('http://', 'https://');
    }

    // uploads/image.jpg
    if (value.startsWith('uploads/')) {
      return '$backendOrigin/$value';
    }

    // /uploads/image.jpg
    if (value.startsWith('/uploads/')) {
      return '$backendOrigin$value';
    }

    return '$backendOrigin/$value';
  }
}
