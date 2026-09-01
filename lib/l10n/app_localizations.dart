import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @vertexMember.
  ///
  /// In tr, this message translates to:
  /// **'Vertex Üyesi'**
  String get vertexMember;

  /// No description provided for @member.
  ///
  /// In tr, this message translates to:
  /// **'Üye'**
  String get member;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get signUp;

  /// No description provided for @continueWithVertex.
  ///
  /// In tr, this message translates to:
  /// **'Vertex hesabınız ile devam edin'**
  String get continueWithVertex;

  /// No description provided for @createNewAccount.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir hesap oluşturun'**
  String get createNewAccount;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @exampleName.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ahmet Yılmaz'**
  String get exampleName;

  /// No description provided for @fullNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad gerekli'**
  String get fullNameRequired;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @exampleEmail.
  ///
  /// In tr, this message translates to:
  /// **'isim@vertex.com'**
  String get exampleEmail;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin'**
  String get enterValidEmail;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @loginError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş hatası'**
  String get loginError;

  /// No description provided for @user.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get user;

  /// No description provided for @or.
  ///
  /// In tr, this message translates to:
  /// **'VEYA'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile devam et'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get continueWithApple;

  /// No description provided for @dontHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız yok mu? Kayıt Olun'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabınız var mı? Giriş Yapın'**
  String get alreadyHaveAccount;

  /// No description provided for @anonymousUser.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz Kullanıcı'**
  String get anonymousUser;

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Edge'**
  String get appName;

  /// No description provided for @searchUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Ara...'**
  String get searchUser;

  /// No description provided for @chats.
  ///
  /// In tr, this message translates to:
  /// **'Sohbetler'**
  String get chats;

  /// No description provided for @suggestContacts.
  ///
  /// In tr, this message translates to:
  /// **'Kişiler'**
  String get suggestContacts;

  /// No description provided for @noChatsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimseyle konuşmadınız, hemen sohbete başlayın.'**
  String get noChatsYet;

  /// No description provided for @encryptedImageLink.
  ///
  /// In tr, this message translates to:
  /// **'Şifreli Görsel (Link: {link}...)'**
  String encryptedImageLink(String link);

  /// No description provided for @audioRecord.
  ///
  /// In tr, this message translates to:
  /// **'Ses Kaydı'**
  String get audioRecord;

  /// No description provided for @fileWithFileName.
  ///
  /// In tr, this message translates to:
  /// **'Dosya: {fileName}'**
  String fileWithFileName(String fileName);

  /// No description provided for @unsupportedMediaType.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmeyen Medya Tipi'**
  String get unsupportedMediaType;

  /// No description provided for @typeMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bir mesaj yaz...'**
  String get typeMessage;

  /// No description provided for @activeTasks.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Görevler'**
  String get activeTasks;

  /// No description provided for @taskCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} görev'**
  String taskCount(int count);

  /// No description provided for @helloUser.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}! 👋'**
  String helloUser(String name);

  /// No description provided for @uncompletedTasksToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {count} tamamlanmamış görevin var.'**
  String uncompletedTasksToday(int count);

  /// No description provided for @todo.
  ///
  /// In tr, this message translates to:
  /// **'Yapılacak'**
  String get todo;

  /// No description provided for @inProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam Eden'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get completed;

  /// No description provided for @priorityHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get priorityLow;

  /// No description provided for @statusInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Devam Ediyor'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get statusDone;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// No description provided for @tasks.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get tasks;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @darkTheme.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Tema'**
  String get darkTheme;

  /// No description provided for @copyRightText.
  ///
  /// In tr, this message translates to:
  /// **'© 2026 Vertex Corporation'**
  String get copyRightText;

  /// No description provided for @mockTask1Title.
  ///
  /// In tr, this message translates to:
  /// **'Cortex v2.0 Arayüz Güncellemesi'**
  String get mockTask1Title;

  /// No description provided for @mockTask1Desc.
  ///
  /// In tr, this message translates to:
  /// **'Yeni AI model entegrasyonu için arayüz güncellemelerini tamamla.'**
  String get mockTask1Desc;

  /// No description provided for @mockTask2Title.
  ///
  /// In tr, this message translates to:
  /// **'Solar Browser Performans Testi'**
  String get mockTask2Title;

  /// No description provided for @mockTask2Desc.
  ///
  /// In tr, this message translates to:
  /// **'WebAssembly modüllerinin render performansını test et ve raporla.'**
  String get mockTask2Desc;

  /// No description provided for @mockTask3Title.
  ///
  /// In tr, this message translates to:
  /// **'Mergen API Dokümantasyonu'**
  String get mockTask3Title;

  /// No description provided for @mockTask3Desc.
  ///
  /// In tr, this message translates to:
  /// **'RESTful API endpoint\'lerinin Swagger dokümantasyonunu hazırla.'**
  String get mockTask3Desc;

  /// No description provided for @mockTask4Title.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Sprint Raporu'**
  String get mockTask4Title;

  /// No description provided for @mockTask4Desc.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftaki geliştirme ilerlemesini ve blocker\'ları raporla.'**
  String get mockTask4Desc;

  /// No description provided for @mockTask5Title.
  ///
  /// In tr, this message translates to:
  /// **'All Star Multiplayer Modülü'**
  String get mockTask5Title;

  /// No description provided for @mockTask5Desc.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek zamanlı çok oyunculu mod için WebSocket altyapısını kur.'**
  String get mockTask5Desc;

  /// No description provided for @august12.
  ///
  /// In tr, this message translates to:
  /// **'12 Ağustos 2026'**
  String get august12;

  /// No description provided for @august15.
  ///
  /// In tr, this message translates to:
  /// **'15 Ağustos 2026'**
  String get august15;

  /// No description provided for @august5.
  ///
  /// In tr, this message translates to:
  /// **'5 Ağustos 2026'**
  String get august5;

  /// No description provided for @august9.
  ///
  /// In tr, this message translates to:
  /// **'9 Ağustos 2026'**
  String get august9;

  /// No description provided for @august20.
  ///
  /// In tr, this message translates to:
  /// **'20 Ağustos 2026'**
  String get august20;

  /// No description provided for @logoutConfirmation.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkış yapmak istediğinize emin misiniz?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @profileInfoAndSettings.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgileri ve ayarlar'**
  String get profileInfoAndSettings;

  /// No description provided for @accountInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bilgileri'**
  String get accountInfo;

  /// No description provided for @contactVertexTeam.
  ///
  /// In tr, this message translates to:
  /// **'Vertex ekibi ve kanallarıyla iletişime geç'**
  String get contactVertexTeam;

  /// No description provided for @teamMembers.
  ///
  /// In tr, this message translates to:
  /// **'Ekip Üyeleri'**
  String get teamMembers;

  /// No description provided for @communicationChannels.
  ///
  /// In tr, this message translates to:
  /// **'İletişim Kanalları'**
  String get communicationChannels;

  /// No description provided for @onlyAdminsCanMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sadece yöneticiler mesaj gönderebilir'**
  String get onlyAdminsCanMessage;

  /// No description provided for @noGroupsInCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Bu toplulukta henüz bir grup yok.'**
  String get noGroupsInCommunity;

  /// No description provided for @sendFailed.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilemedi'**
  String get sendFailed;

  /// No description provided for @fileSendError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya gönderim hatası'**
  String get fileSendError;

  /// No description provided for @imageLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yüklenemedi'**
  String get imageLoadFailed;

  /// No description provided for @createNewCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Topluluk Kur'**
  String get createNewCommunity;

  /// No description provided for @notJoinedAnyCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Henüz hiçbir topluluğa katılmadınız, hemen yeni bir topluluğa katılın.'**
  String get notJoinedAnyCommunity;

  /// No description provided for @enterGroupName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir grup adı girin'**
  String get enterGroupName;

  /// No description provided for @selectAtLeastOnePerson.
  ///
  /// In tr, this message translates to:
  /// **'En az 1 kişi seçmelisiniz'**
  String get selectAtLeastOnePerson;

  /// No description provided for @groupCreationError.
  ///
  /// In tr, this message translates to:
  /// **'Grup oluşturulamadı'**
  String get groupCreationError;

  /// No description provided for @groupName.
  ///
  /// In tr, this message translates to:
  /// **'Grup Adı'**
  String get groupName;

  /// No description provided for @searchContact.
  ///
  /// In tr, this message translates to:
  /// **'Kişi Ara...'**
  String get searchContact;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @newCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Topluluk'**
  String get newCommunity;

  /// No description provided for @communityName.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Adı'**
  String get communityName;

  /// No description provided for @addContacts.
  ///
  /// In tr, this message translates to:
  /// **'Kişileri Ekle'**
  String get addContacts;

  /// No description provided for @announcements.
  ///
  /// In tr, this message translates to:
  /// **'Duyurular'**
  String get announcements;

  /// No description provided for @noTasksYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz görev yok'**
  String get noTasksYet;

  /// No description provided for @role.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @verifiedMember.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış Üye'**
  String get verifiedMember;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @on.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get on;

  /// No description provided for @off.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get off;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In tr, this message translates to:
  /// **'Koyu mod'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @application.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get application;

  /// No description provided for @themeDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get themeDefault;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @themeLove.
  ///
  /// In tr, this message translates to:
  /// **'Aşk'**
  String get themeLove;

  /// No description provided for @themeNature.
  ///
  /// In tr, this message translates to:
  /// **'Doğa'**
  String get themeNature;

  /// No description provided for @themePurple.
  ///
  /// In tr, this message translates to:
  /// **'Mor'**
  String get themePurple;

  /// No description provided for @themeGray.
  ///
  /// In tr, this message translates to:
  /// **'Gri'**
  String get themeGray;

  /// No description provided for @themeOcean.
  ///
  /// In tr, this message translates to:
  /// **'Okyanus'**
  String get themeOcean;

  /// No description provided for @themeScarlet.
  ///
  /// In tr, this message translates to:
  /// **'Scarlet'**
  String get themeScarlet;

  /// No description provided for @themeCyberpunk.
  ///
  /// In tr, this message translates to:
  /// **'Cyberpunk'**
  String get themeCyberpunk;

  /// No description provided for @themeSunset.
  ///
  /// In tr, this message translates to:
  /// **'Gün Batımı'**
  String get themeSunset;

  /// No description provided for @themeCoffee.
  ///
  /// In tr, this message translates to:
  /// **'Kahve'**
  String get themeCoffee;

  /// No description provided for @themeSpace.
  ///
  /// In tr, this message translates to:
  /// **'Uzay'**
  String get themeSpace;

  /// No description provided for @themeMint.
  ///
  /// In tr, this message translates to:
  /// **'Adaçayı'**
  String get themeMint;

  /// No description provided for @themeAurora.
  ///
  /// In tr, this message translates to:
  /// **'Aurora'**
  String get themeAurora;

  /// No description provided for @themeNord.
  ///
  /// In tr, this message translates to:
  /// **'Nord'**
  String get themeNord;

  /// No description provided for @themeEmber.
  ///
  /// In tr, this message translates to:
  /// **'Kor'**
  String get themeEmber;

  /// No description provided for @themePorcelain.
  ///
  /// In tr, this message translates to:
  /// **'Porselen'**
  String get themePorcelain;

  /// No description provided for @communities.
  ///
  /// In tr, this message translates to:
  /// **'Topluluklar'**
  String get communities;

  /// No description provided for @youSentMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderdin'**
  String get youSentMessage;

  /// No description provided for @youSentFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya gönderdin'**
  String get youSentFile;

  /// No description provided for @noGroupsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz grup veya topluluk bulunmuyor.'**
  String get noGroupsYet;

  /// No description provided for @sentYouMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sana bir mesaj gönderildi'**
  String get sentYouMessage;

  /// No description provided for @sentYouFile.
  ///
  /// In tr, this message translates to:
  /// **'Sana bir dosya gönderildi'**
  String get sentYouFile;

  /// No description provided for @groupDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Grup silindi.'**
  String get groupDeleted;

  /// No description provided for @groupDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Grup silinemedi'**
  String get groupDeleteError;

  /// No description provided for @selectChat.
  ///
  /// In tr, this message translates to:
  /// **'Bir sohbet seçin'**
  String get selectChat;

  /// No description provided for @selectChatDesc.
  ///
  /// In tr, this message translates to:
  /// **'Soldan bir kişiye tıklayınca sohbet burada açılır.'**
  String get selectChatDesc;

  /// No description provided for @unnamedGroup.
  ///
  /// In tr, this message translates to:
  /// **'İsimsiz Grup'**
  String get unnamedGroup;

  /// No description provided for @patchNotes.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm Notları'**
  String get patchNotes;

  /// No description provided for @updateHistory.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme geçmişi'**
  String get updateHistory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
