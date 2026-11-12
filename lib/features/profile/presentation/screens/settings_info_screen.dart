import 'package:flutter/material.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';

class SettingsInfoScreen extends StatefulWidget {
  final bool notifications;

  const SettingsInfoScreen({super.key, required this.notifications});

  @override
  State<SettingsInfoScreen> createState() => _SettingsInfoScreenState();
}

class _SettingsInfoScreenState extends State<SettingsInfoScreen> {
  bool reportUpdates = true;
  bool messages = true;
  bool announcements = true;

  @override
  Widget build(BuildContext context) {
    if (widget.notifications) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preferensi Notifikasi')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Atur pemberitahuan yang ingin Anda terima.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: reportUpdates,
              onChanged: (value) => setState(() => reportUpdates = value),
              title: const Text('Perubahan status laporan'),
              subtitle: const Text('Saat Guru BK meninjau atau menindaklanjuti laporan.'),
            ),
            SwitchListTile.adaptive(
              value: messages,
              onChanged: (value) => setState(() => messages = value),
              title: const Text('Pesan konseling'),
              subtitle: const Text('Pesan baru pada percakapan privat dengan Guru BK.'),
            ),
            SwitchListTile.adaptive(
              value: announcements,
              onChanged: (value) => setState(() => announcements = value),
              title: const Text('Pengumuman sekolah'),
              subtitle: const Text('Konten dan banner baru yang diterbitkan Guru BK.'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privasi & Kode Etik BK')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Privasi Anda adalah prioritas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text(
            'Laporan dan percakapan hanya dapat diakses oleh Anda serta Guru BK berwenang di sekolah Anda. Identitas pelapor tidak ditampilkan kepada siswa lain.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.55),
          ),
          SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text('Akses terbatas'),
            subtitle: Text('Data sekolah dipisahkan untuk setiap sekolah.'),
          ),
          ListTile(
            leading: Icon(Icons.visibility_off_outlined, color: AppColors.primary),
            title: Text('Mode samaran'),
            subtitle: Text('Gunakan mode samaran untuk membatasi tampilan profil Anda.'),
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined, color: AppColors.primary),
            title: Text('Kode etik layanan'),
            subtitle: Text('Gunakan layanan dengan jujur dan hormati privasi semua pihak.'),
          ),
        ],
      ),
    );
  }
}
