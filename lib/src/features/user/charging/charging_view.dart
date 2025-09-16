import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ChargingView extends StatefulWidget {
  const ChargingView({super.key});

  @override
  State<ChargingView> createState() => _ChargingViewState();
}

class _ChargingViewState extends State<ChargingView> {
  late MobileScannerController _cameraController;
  bool _isScannerActive = true;
  String? _scannedQrCodeValue;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() {
        _scannedQrCodeValue = null;
        _isScannerActive = true;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Charging Station",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, // safe space for keyboard
        ),
        child: Column(
          children: [
            // Scanner Section
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.15).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        if (!_isScannerActive || _isDisposed) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final barcode = barcodes.first;
                          if (barcode.rawValue != null &&
                              _scannedQrCodeValue == null) {
                            if (mounted) {
                              setState(() {
                                _scannedQrCodeValue = barcode.rawValue;
                                _isScannerActive = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'QR Scanned: ${barcode.rawValue}',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent.withAlpha((255 * 0.7).round()),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    if (_scannedQrCodeValue == null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            "Align QR code inside the frame",
                            style: TextStyle(
                              color: Colors.white.withAlpha((255 * 0.9).round()),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Manual Entry Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_scannedQrCodeValue != null) ...[
                    Text(
                      "Scanned QR: $_scannedQrCodeValue",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _resumeScanning,
                      icon: const Icon(Icons.refresh, color: Colors.green),
                      label: const Text(
                        "Scan Again",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                  const Text(
                    "Or enter charger ID",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter charger ID",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && _scannedQrCodeValue != null) {
                        if (mounted) {
                          setState(() => _scannedQrCodeValue = null);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // TODO: Proceed logic
                      },
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
