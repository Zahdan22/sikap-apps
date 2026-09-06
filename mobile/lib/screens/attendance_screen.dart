import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../services/attendance_service.dart';
import '../theme/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isMasuk;
  const AttendanceScreen({super.key, required this.isMasuk});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  File? _foto;
  Position? _position;
  String? _address;
  bool _isLoadingLocation = false;
  bool _isProcessingFoto = false;
  bool _isSubmitting = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'GPS tidak aktif, silakan aktifkan lokasi';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak permanen, aktifkan lewat Settings';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _position = position;
        _isLoadingLocation = false;
      });
      _getAddress();
    } catch (e) {
      setState(() {
        _locationError = 'Gagal ambil lokasi: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _getAddress() async {
    if (_position == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(_position!.latitude, _position!.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality, p.subAdministrativeArea, p.administrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .toList();
        _address = parts.join(', ');
      }
    } catch (_) {
      _address = 'Alamat tidak diketahui';
    }
  }

  String _hariIndo(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[weekday - 1];
  }

  Future<File> _addWatermark(File original) async {
    final bytes = await original.readAsBytes();
    final image = img.decodeImage(bytes)!;

    final now = DateTime.now();
    final dateStr =
        '${_hariIndo(now.weekday)}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final coordStr = '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}';
    final addressStr = _address ?? 'Alamat tidak diketahui';

    final lines = <String>[dateStr, coordStr, addressStr];

    final lineHeight = 22;
    final overlayHeight = 20 + lines.length * lineHeight;

    img.fillRect(
      image,
      x1: 0,
      y1: image.height - overlayHeight,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 160),
    );

    var y = image.height - overlayHeight + 8;
    for (final line in lines) {
      img.drawString(
        image,
        line,
        font: img.arial14,
        x: 12,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += lineHeight;
    }

    final dir = await getTemporaryDirectory();
    final newFile = File('${dir.path}/wm_${now.millisecondsSinceEpoch}.jpg');
    await newFile.writeAsBytes(img.encodeJpg(image, quality: 85));
    return newFile;
  }

  Future<void> _ambilFoto() async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunggu lokasi terdeteksi dulu sebelum ambil foto')),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null) return;

    setState(() => _isProcessingFoto = true);
    final watermarked = await _addWatermark(File(image.path));
    setState(() {
      _foto = watermarked;
      _isProcessingFoto = false;
    });
  }

  Future<void> _submit() async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum didapatkan')),
      );
      return;
    }
    if (_foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto wajib diambil')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final service = AttendanceService();
    final result = widget.isMasuk
        ? await service.absenMasuk(_position!.latitude, _position!.longitude, _foto!)
        : await service.absenPulang(_position!.latitude, _position!.longitude, _foto!);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Berhasil'),
            ],
          ),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _position != null && _foto != null && !_isSubmitting && !_isProcessingFoto;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isMasuk ? 'Absen Masuk' : 'Absen Pulang')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (_locationError != null ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: _locationError != null ? AppColors.danger : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoadingLocation
                                  ? 'Mencari lokasi...'
                                  : _locationError != null
                                      ? 'Lokasi Gagal'
                                      : 'GPS Aktif',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingLocation
                                  ? 'Mohon tunggu sebentar'
                                  : _locationError ?? (_address ?? 'Lokasi terverifikasi'),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (_locationError != null)
                        IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _getLocation),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isMasuk ? 'Modul Kamera' : 'Selfie Wajib untuk Absen Pulang',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: _foto == null ? Colors.grey[900] : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isProcessingFoto
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _foto != null
                          ? Image.file(_foto!, fit: BoxFit.cover)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 56, color: Colors.white.withValues(alpha: 0.4)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada foto',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessingFoto ? null : _ambilFoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_foto == null ? 'AMBIL FOTO' : 'AMBIL ULANG'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.isMasuk ? 'ABSEN MASUK SEKARANG' : 'ABSEN PULANG SEKARANG',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),
              if (_foto == null) ...[
                const SizedBox(height: 8),
                const Text(
                  '*Selesaikan pengambilan foto untuk mengaktifkan tombol absensi.',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}