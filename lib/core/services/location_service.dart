import 'dart:async';
import 'package:geolocator/geolocator.dart';

class DeviceLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? errorMessageBangla;

  const DeviceLocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.errorMessageBangla,
  });
}

/// Real device GNSS/GPS location service wrapping [Geolocator] with safe permission checks.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Checks services & permissions, then reads current device GPS coordinates.
  Future<DeviceLocationResult> getCurrentLocation({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const DeviceLocationResult(
          success: false,
          errorMessageBangla: 'ফোনের লোকেশন (GPS) বন্ধ আছে। অনুগ্রহ করে সেটিংস থেকে GPS চালু করুন।',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const DeviceLocationResult(
            success: false,
            errorMessageBangla: 'লোকেশন অনুমতি (Permission) দেওয়া হয়নি।',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocationResult(
          success: false,
          errorMessageBangla: 'লোকেশন অনুমতি স্থায়ীভাবে বন্ধ করা আছে। অ্যাপ সেটিংস থেকে অনুমতি দিন।',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: timeLimit,
        ),
      );

      return DeviceLocationResult(
        success: true,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } catch (e) {
      return DeviceLocationResult(
        success: false,
        errorMessageBangla: 'ডিভাইস থেকে GPS তথ্য পাওয়া যায়নি: $e',
      );
    }
  }

  /// Continuous live position stream for boundary walk mode.
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    );
  }
}
