import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/appbar.dart';
import '../widgets/card.dart';

class PatchNotesScreen extends StatelessWidget {
  const PatchNotesScreen({super.key});

  static const _notes = [
    _PatchNote(
      version: '1.0.4',
      date: '14 Ağustos 2026',
      highlights: [
        'Mobil web yükleme takılması düzeltildi (bildirim init ertelendi, timeout)',
        'iOS mesaj şifre çözme iyileştirildi (erken anahtar init, Keychain)',
        'Görevler sekmesi eklendi (atama, kalan süre paneli)',
        'Roller eklendi: Geliştirici, Yönetici',
        'Yönetici görev atayabilir',
      ],
    ),
    _PatchNote(
      version: '1.0.3',
      date: '13 Ağustos 2026',
      highlights: [
        'Girişten sonra siteden atılma sorunu düzeltildi',
        'Mobilde mesaj şifre çözme / cihazlar arası anahtar yedekleme iyileştirildi',
        'Mesaj yazarken kasma azaltıldı (yerel kuyruk + decrypt cache)',
        'Sohbet loading spinner\'ları kaldırıldı',
        'Karşı taraf yazarken "typing..." göstergesi eklendi',
        'Kayıt ekranından telefon numarası alanı kaldırıldı',
        'Ana ekran: Edge başlığı, arama ve + sağa yaklaştırıldı',
        '"Suggest Contacts" → "Kişiler" olarak güncellendi',
      ],
    ),
    _PatchNote(
      version: '1.0.2',
      date: '13 Ağustos 2026',
      highlights: [
        'Mobil web\'de mesaj şifre çözme düzeltmesi (cihazlar arası anahtar yedekleme)',
        'Kayıtta telefon numarası zorunluluğu kaldırıldı',
        'Mesaj yazarken sayfa kasması / titreme düzeltmesi',
        'Dark mode profil ve kart görünümü iyileştirmeleri',
      ],
    ),
    _PatchNote(
      version: '1.0.1',
      date: '13 Ağustos 2026',
      highlights: [
        'Topluluk detay ekranı ve navigasyon eklendi',
        'Vertex üyelik (isVertex) giriş kontrolü',
        'FCM bildirim token kaydı ve arka plan desteği',
        'Ses mesajı oynatma',
        'Karanlık tema switch düzeltmesi',
        'OAuth kullanıcı profili Cloud Function',
        'Profil ekranı dark mode iyileştirmeleri',
      ],
    ),
    _PatchNote(
      version: '1.0.0',
      date: 'İlk sürüm',
      highlights: [
        'E2EE mesajlaşma',
        'Grup ve topluluk sohbetleri',
        'Google / Apple / e-posta girişi',
        'Dosya ve görsel paylaşımı',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = AppColors.currentTheme == 'dark';
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VertexAppBar(leadingMode: VertexLeadingMode.back),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: _notes.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patch Notes',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vertex Edge güncelleme geçmişi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ],
              );
            }

            final note = _notes[index - 1];
            return VertexCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.senaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'v${note.version}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.senaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        note.date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...note.highlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppColors.senaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.4,
                                color: textColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatchNote {
  final String version;
  final String date;
  final List<String> highlights;

  const _PatchNote({
    required this.version,
    required this.date,
    required this.highlights,
  });
}
