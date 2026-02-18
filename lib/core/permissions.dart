import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  const PermissionManager._();

  static Future<bool> requestRequiredPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final permissionsToRequest = <Permission>[
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
      Permission.bluetoothScan,
    ];

    final permissionStatuses = await permissionsToRequest.request();

    final hasPermanentlyDeniedPermission = permissionStatuses.values.any(
      (status) => status.isPermanentlyDenied,
    );

    if (hasPermanentlyDeniedPermission && context.mounted) {
      await _showOpenSettingsDialog(context);
      return false;
    }

    final allPermissionsGranted = permissionStatuses.values.every(
      (status) => status.isGranted,
    );

    return allPermissionsGranted;
  }

  static Future<void> _showOpenSettingsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Location, Nearby Wi-Fi Devices, and Bluetooth Scan permissions are permanently denied. '
            'Please open app settings and enable them to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
