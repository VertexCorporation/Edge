import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/appbar.dart';
import '../widgets/card.dart';

class PatchNotesScreen extends StatelessWidget {
  const PatchNotesScreen({super.key});

  static const _notes = [
    _PatchNote(
      version: '1.0.18',
      date: '18 Ağustos 2026',
      highlights: [
        'Mac/Safari eski giriş ekranını cache’ten tutmayı bırakır',
        'Giriş kartı Safari’de donmaz',
      ],
    ),
    _PatchNote(
      version: '1.0.17',
      date: '18 Ağustos 2026',
      highlights: [
        'main push sonrası otomatik Cloudflare web deploy',
        'Giriş ekranında sürüm numarası (güncelleme kontrolü)',
        'Mobil tarayıcı/PWA önbelleği için cache header düzeltmesi',
      ],
    ),
    _PatchNote(
      version: '1.0.16',
      date: '18 Ağustos 2026',
      highlights: [
        'Hesap ekranında tema değişince arka plan anında güncellenir',
      ],
    ),
    _PatchNote(
      version: '1.0.15',
      date: '18 Ağustos 2026',
      highlights: [
        'Bootstrap Yönetici hesapları artık ekranda Üye olarak kalmaz',
        'Rol birleştirmede users belgesi usernames kaydının önüne geçer',
      ],
    ),
    _PatchNote(
      version: '1.0.14',
      date: '18 Ağustos 2026',
      highlights: [
        'Hesap → Ayarlar: renk temaları ve ayrı koyu mod anahtarı',
        'Aşk + koyu mod: daha koyu arka plan ve bordo kalpler',
        'Sohbet mesaj alanında tema arka planı düzgün görünür',
        'Tema değişince panel anında yenilenir',
        'Görev atama kişi listesi Edge kullanıcılarını doğru çeker',
      ],
    ),
    _PatchNote(
      version: '1.0.13',
      date: '18 Ağustos 2026',
      highlights: [
        'Giriş ekranından tema seçici kaldırıldı',
        'Uzay temasında pikselli yıldızlar ve gezegenler',
        'Aşk temasında temaya uygun pikselli kalpler',
        'Biri mesaj atınca sohbet listesinin en üstüne düşer',
        'Mesajlaşılan kişi listede iki kez görünmez',
      ],
    ),
    _PatchNote(
      version: '1.0.12',
      date: '18 Ağustos 2026',
      highlights: [
        'Edge hesapları kalıcı işaretlenir; Cortex-only kişiler sohbet listesine düşmez',
        'Profil ve arama ikonları birbirine yapışmayı bıraktı',
        'Grup rol atamada Firebase hatası yerine anlaşılır Türkçe mesaj',
        'Hesap → Bildirimler artık aç/kapa anahtarı',
        'Giriş ve kayıt ekranı iki panelli düzene alındı',
        'Giriş sekmesinde uygulama temaları seçilebilir',
        'Son konuşulan kişi sohbet listesinden düşmez',
        'Cortex kullanıcı adı ile de giriş yapılabilir',
      ],
    ),
    _PatchNote(
      version: '1.0.11',
      date: '17 Ağustos 2026',
      highlights: [
        'Sohbetler WhatsApp düzenine alındı: kişi listesi solda, chat sağda açılır',
        'Kişiler açılır-kapanır sekme olmaktan çıktı',
        'Topluluk oluşturma: arama ve + yanına küçük ikon',
        'Hesap ve profil avatarları seçili temanın rengine uyuyor',
      ],
    ),
    _PatchNote(
      version: '1.0.10',
      date: '17 Ağustos 2026',
      highlights: [
        'Sitede mesaj bildirimi: biri yazınca karşı tarafta banner düşer',
        'Görev Oluştur tuşu tepkisiz kalma hatası düzeltildi',
        'E-posta / şifre ile klasik giriş Cortex sonrası da çalışır',
      ],
    ),
    _PatchNote(
      version: '1.0.9',
      date: '17 Ağustos 2026',
      highlights: [
        'Cortex kayıtlı kullanıcı profili Edge girişine bağlandı',
        'Cortex kullanıcı adı (username) hesap ve sohbet isimlerinde görünür',
        'Cortex üyeleri Vertex üyesi olarak işaretlenir',
        'Grup ve görev kişi listeleri Cortex kayıtlı kişileri de çeker',
      ],
    ),
    _PatchNote(
      version: '1.0.8',
      date: '17 Ağustos 2026',
      highlights: [
        'Temalar yenilendi: kart, yazı ve tuşlar artık birbirinden ayrılıyor',
        'Yeni temalar: Adaçayı, Aurora, Nord, Kor, Porselen',
        'Koyu temalarda başlık ve silme tuşu görünürlüğü düzeltildi',
        'Grup oluşturma: yalnızca Yönetici ve Mod Yeni Grup açabilir',
        'Grup açma: yalnızca Yönetici ve Mod grup sohbetine girebilir',
        'Grup silme: Yönetici sohbet listesinden veya grup içinden silebilir',
      ],
    ),
    _PatchNote(
      version: '1.0.7',
      date: '17 Ağustos 2026',
      highlights: [
        'Google ile devam et: Google hesap seçim ekranına yönlendirir',
        'Apple ile devam et: Apple kimliği ile giriş açılır',
        'Mobil web\'de pop-up engellenirse Google/Apple girişine otomatik yönlendirme',
        'Yeni roller: Test, Mod, Support',
        'Mod: Yönetici Paneli\'nden rol atayabilir (Üye, Geliştirici, Test, Mod, Support)',
        'Support: üye olmadığı gruplar dahil tüm grupları görür',
        'Yönetici Paneli Hesap → Ayarlar içinde; atanabilir roller genişletildi',
      ],
    ),
    _PatchNote(
      version: '1.0.6',
      date: '14 Ağustos 2026',
      highlights: [
        'Yönetici Paneli: Hesap ekranından kullanıcı listesi, arama ve Geliştirici / Üye rol atama',
        'Bootstrap Yönetici koruması: sabit admin hesapları panelden düşürülemez, girişte rol geri yüklenir',
        'Temalar: 12 tema seçici (Açık, Koyu, Aşk, Doğa, Okyanus, Cyberpunk vb.) Hesap → Ayarlar',
        'Tema renkleri kart, alt menü ve yüzeylerde tutarlı; sabit mavi tonlar kaldırıldı',
        'Edge başlığı: Koyu temada mavi gradient, diğer temalarda siyah metin',
        'Görev atama: kişi listesi düzeltildi (usernames + users yedek sorgu)',
        'Görev süreleri: bitiş tarihine göre "X gün kaldı", "Bugün", "Süre doldu" gösterimi',
        'Görev detay paneli: Yapılacak → Devam ediyor → Tamamlandı durum güncelleme',
        'Yönetici tüm görevleri görür; atanan kişi yalnızca kendi görevlerini görür',
      ],
    ),
    _PatchNote(
      version: '1.0.5',
      date: '14 Ağustos 2026',
      highlights: [
        'crypto.dart yeniden yazıldı, Cloudflare deploy hatası düzeltildi',
        'Görevler | Sohbetler alt menü navigasyonu eklendi',
        'Görevler: Firestore entegrasyonu, kalan süre paneli, durum güncelleme',
        'Yönetici görev atama (+ butonu, kişi/tarih/öncelik seçimi)',
        'Roller: Üye, Geliştirici, Yönetici',
        'Yönetici rol atama Cloud Functions (claimBootstrapAdmin, assignUserRole)',
        'Mobil web yükleme düzeltmesi (bildirim init ertelendi, timeout)',
        'iOS mesaj şifre çözme iyileştirmesi (Keychain, erken anahtar init)',
        'Web auth session stabilizasyonu',
        'cloud_functions entegrasyonu',
      ],
    ),
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
    final isDarkTheme = AppColors.isDarkUi;
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
