import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../theme/app_colors.dart';

class ReportDetailScreen extends StatelessWidget {
  final String nama;
  final List<dynamic> detail;
  const ReportDetailScreen({super.key, required this.nama, required this.detail});

  String get _uploadBase => ApiConfig.baseUrl.replaceAll('/api', '');

  void _lihatFoto(BuildContext context, String filename) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network('$_uploadBase/uploads/attendance/$filename'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail - $nama')),
      body: SafeArea(
        child: detail.isEmpty
            ? const Center(child: Text('Tidak ada data'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: detail.length,
                itemBuilder: (context, index) {
                  final d = detail[index];
                  final fotoMasuk = d['foto_masuk'];
                  final fotoPulang = d['foto_pulang'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['tanggal'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Jadwal: ${d['jadwal_jam_mulai'].toString().substring(0, 5)} - ${d['jadwal_jam_selesai'].toString().substring(0, 5)}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _FotoBukti(
                                  label: 'Foto Masuk',
                                  filename: fotoMasuk,
                                  uploadBase: _uploadBase,
                                  onTap: fotoMasuk != null ? () => _lihatFoto(context, fotoMasuk) : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FotoBukti(
                                  label: 'Foto Pulang',
                                  filename: fotoPulang,
                                  uploadBase: _uploadBase,
                                  onTap: fotoPulang != null ? () => _lihatFoto(context, fotoPulang) : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FotoBukti extends StatelessWidget {
  final String label;
  final String? filename;
  final String uploadBase;
  final VoidCallback? onTap;

  const _FotoBukti({required this.label, required this.filename, required this.uploadBase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: filename != null
                  ? Image.network('$uploadBase/uploads/attendance/$filename', fit: BoxFit.cover)
                  : Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}