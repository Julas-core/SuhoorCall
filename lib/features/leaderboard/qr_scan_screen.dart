import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _isHandlingResult = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B28),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060B28),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan Squad QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isHandlingResult) {
                return;
              }

              final rawValue = capture.barcodes
                  .map((barcode) => barcode.rawValue)
                  .whereType<String>()
                  .firstWhere(
                    (value) => value.trim().isNotEmpty,
                    orElse: () => '',
                  );

              if (rawValue.isEmpty) {
                return;
              }

              _isHandlingResult = true;
              Navigator.of(context).pop(rawValue);
            },
          ),
          Container(
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00F58D), width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xCC111822),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Point your camera at a squad QR code to join.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
