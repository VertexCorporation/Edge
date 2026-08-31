// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get vertexMember => 'Vertex Üyesi';

  @override
  String get member => 'Üye';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get continueWithVertex => 'Vertex hesabınız ile devam edin';

  @override
  String get createNewAccount => 'Yeni bir hesap oluşturun';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get exampleName => 'Örn: Ahmet Yılmaz';

  @override
  String get fullNameRequired => 'Ad Soyad gerekli';

  @override
  String get email => 'E-posta';

  @override
  String get exampleEmail => 'isim@vertex.com';

  @override
  String get emailRequired => 'E-posta adresi gerekli';

  @override
  String get enterValidEmail => 'Geçerli bir e-posta adresi girin';

  @override
  String get password => 'Şifre';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get loginError => 'Giriş hatası';

  @override
  String get user => 'Kullanıcı';

  @override
  String get or => 'VEYA';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu? Kayıt Olun';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? Giriş Yapın';

  @override
  String get anonymousUser => 'İsimsiz Kullanıcı';

  @override
  String get appName => 'Edge';

  @override
  String get searchUser => 'Kullanıcı Ara...';

  @override
  String get chats => 'Sohbetler';

  @override
  String get suggestContacts => 'Kişiler';

  @override
  String get noChatsYet =>
      'Henüz kimseyle konuşmadınız, hemen sohbete başlayın.';

  @override
  String encryptedImageLink(String link) {
    return 'Şifreli Görsel (Link: $link...)';
  }

  @override
  String get audioRecord => 'Ses Kaydı';

  @override
  String fileWithFileName(String fileName) {
    return 'Dosya: $fileName';
  }

  @override
  String get unsupportedMediaType => 'Desteklenmeyen Medya Tipi';

  @override
  String get typeMessage => 'Bir mesaj yaz...';

  @override
  String get activeTasks => 'Aktif Görevler';

  @override
  String taskCount(int count) {
    return '$count görev';
  }

  @override
  String helloUser(String name) {
    return 'Merhaba, $name! 👋';
  }

  @override
  String uncompletedTasksToday(int count) {
    return 'Bugün $count tamamlanmamış görevin var.';
  }

  @override
  String get todo => 'Yapılacak';

  @override
  String get inProgress => 'Devam Eden';

  @override
  String get completed => 'Tamamlanan';

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String get priorityMedium => 'Orta';

  @override
  String get priorityLow => 'Düşük';

  @override
  String get statusInProgress => 'Devam Ediyor';

  @override
  String get statusDone => 'Tamamlandı';

  @override
  String get account => 'Hesap';

  @override
  String get tasks => 'Görevler';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get darkTheme => 'Karanlık Tema';

  @override
  String get copyRightText => '© 2026 Vertex Corporation';

  @override
  String get mockTask1Title => 'Cortex v2.0 Arayüz Güncellemesi';

  @override
  String get mockTask1Desc =>
      'Yeni AI model entegrasyonu için arayüz güncellemelerini tamamla.';

  @override
  String get mockTask2Title => 'Solar Browser Performans Testi';

  @override
  String get mockTask2Desc =>
      'WebAssembly modüllerinin render performansını test et ve raporla.';

  @override
  String get mockTask3Title => 'Mergen API Dokümantasyonu';

  @override
  String get mockTask3Desc =>
      'RESTful API endpoint\'lerinin Swagger dokümantasyonunu hazırla.';

  @override
  String get mockTask4Title => 'Haftalık Sprint Raporu';

  @override
  String get mockTask4Desc =>
      'Bu haftaki geliştirme ilerlemesini ve blocker\'ları raporla.';

  @override
  String get mockTask5Title => 'All Star Multiplayer Modülü';

  @override
  String get mockTask5Desc =>
      'Gerçek zamanlı çok oyunculu mod için WebSocket altyapısını kur.';

  @override
  String get august12 => '12 Ağustos 2026';

  @override
  String get august15 => '15 Ağustos 2026';

  @override
  String get august5 => '5 Ağustos 2026';

  @override
  String get august9 => '9 Ağustos 2026';

  @override
  String get august20 => '20 Ağustos 2026';

  @override
  String get logoutConfirmation =>
      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';

  @override
  String get cancel => 'İptal';

  @override
  String get profileInfoAndSettings => 'Profil bilgileri ve ayarlar';

  @override
  String get accountInfo => 'Hesap Bilgileri';

  @override
  String get contactVertexTeam => 'Vertex ekibi ve kanallarıyla iletişime geç';

  @override
  String get teamMembers => 'Ekip Üyeleri';

  @override
  String get communicationChannels => 'İletişim Kanalları';

  @override
  String get onlyAdminsCanMessage => 'Sadece yöneticiler mesaj gönderebilir';

  @override
  String get noGroupsInCommunity => 'Bu toplulukta henüz bir grup yok.';

  @override
  String get sendFailed => 'Gönderilemedi';

  @override
  String get fileSendError => 'Dosya gönderim hatası';

  @override
  String get imageLoadFailed => 'Görsel yüklenemedi';

  @override
  String get createNewCommunity => 'Yeni Topluluk Kur';

  @override
  String get notJoinedAnyCommunity =>
      'Henüz hiçbir topluluğa katılmadınız, hemen yeni bir topluluğa katılın.';

  @override
  String get enterGroupName => 'Lütfen bir grup adı girin';

  @override
  String get selectAtLeastOnePerson => 'En az 1 kişi seçmelisiniz';

  @override
  String get groupCreationError => 'Grup oluşturulamadı';

  @override
  String get groupName => 'Grup Adı';

  @override
  String get searchContact => 'Kişi Ara...';

  @override
  String get error => 'Hata';

  @override
  String get newCommunity => 'Yeni Topluluk';

  @override
  String get communityName => 'Topluluk Adı';

  @override
  String get addContacts => 'Kişileri Ekle';

  @override
  String get announcements => 'Duyurular';

  @override
  String get noTasksYet => 'Henüz görev yok';

  @override
  String get role => 'Rol';

  @override
  String get status => 'Durum';

  @override
  String get verifiedMember => 'Doğrulanmış Üye';

  @override
  String get settings => 'Ayarlar';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get on => 'Açık';

  @override
  String get off => 'Kapalı';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Tema';

  @override
  String get darkMode => 'Koyu mod';

  @override
  String get about => 'Hakkında';

  @override
  String get application => 'Uygulama';

  @override
  String get themeDefault => 'Varsayılan';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLove => 'Aşk';

  @override
  String get themeNature => 'Doğa';

  @override
  String get themePurple => 'Mor';

  @override
  String get themeGray => 'Gri';

  @override
  String get themeOcean => 'Okyanus';

  @override
  String get themeScarlet => 'Scarlet';

  @override
  String get themeCyberpunk => 'Cyberpunk';

  @override
  String get themeSunset => 'Gün Batımı';

  @override
  String get themeCoffee => 'Kahve';

  @override
  String get themeSpace => 'Uzay';

  @override
  String get themeMint => 'Adaçayı';

  @override
  String get themeAurora => 'Aurora';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeEmber => 'Kor';

  @override
  String get themePorcelain => 'Porselen';

  @override
  String get communities => 'Topluluklar';

  @override
  String get youSentMessage => 'Mesaj gönderdin';

  @override
  String get youSentFile => 'Dosya gönderdin';

  @override
  String get noGroupsYet => 'Henüz grup veya topluluk bulunmuyor.';

  @override
  String get sentYouMessage => 'Sana bir mesaj gönderildi';

  @override
  String get sentYouFile => 'Sana bir dosya gönderildi';
}
