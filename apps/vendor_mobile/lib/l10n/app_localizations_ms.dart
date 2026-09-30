// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get paymentsNotAvailableYet => 'Pembayaran belum tersedia.';

  @override
  String get splash => 'Skrin Pembuka';

  @override
  String get sign => 'Log masuk';

  @override
  String get createAccount => 'Cipta akaun';

  @override
  String get accountRecovery => 'Pemulihan akaun';

  @override
  String get resetPassword => 'Tetapkan semula kata laluan';

  @override
  String get welcome => 'Selamat datang';

  @override
  String get businessInformation => 'Maklumat perniagaan';

  @override
  String get pickupLocation => 'Lokasi pengambilan';

  @override
  String get serviceArea => 'Kawasan servis';

  @override
  String get setupComplete => 'Persediaan selesai';

  @override
  String get today => 'Hari Ini';

  @override
  String get orders => 'Pesanan';

  @override
  String get orderDetail => 'Butiran pesanan';

  @override
  String get newOrder => 'Pesanan baharu';

  @override
  String get importOrders => 'Import pesanan';

  @override
  String get editOrder => 'Sunting pesanan';

  @override
  String get zones => 'Zon';

  @override
  String get zone => 'Zon';

  @override
  String get deliveryProgress => 'Kemajuan penghantaran';

  @override
  String get riders => 'Rider';

  @override
  String get riderDetail => 'Butiran rider';

  @override
  String get riderRegistrationLink => 'Pautan pendaftaran rider';

  @override
  String get team => 'Pasukan';

  @override
  String get teamMember => 'Ahli pasukan';

  @override
  String get teamMemberRegistrationLink => 'Pautan pendaftaran ahli pasukan';

  @override
  String get coverage => 'Liputan';

  @override
  String get zoneConfiguration => 'Konfigurasi zon';

  @override
  String get createZone => 'Cipta zon';

  @override
  String get storefront => 'Kedai dalam talian';

  @override
  String get viewStorefront => 'Lihat kedai dalam talian';

  @override
  String get templatePreview => 'Pratonton templat';

  @override
  String get customize => 'Ubah suai';

  @override
  String get products => 'Produk';

  @override
  String get customers => 'Pelanggan';

  @override
  String get customer => 'Pelanggan';

  @override
  String get editProduct => 'Sunting produk';

  @override
  String get addProduct => 'Tambah produk';

  @override
  String get businessProfile => 'Profil perniagaan';

  @override
  String get businessAddress => 'Alamat perniagaan';

  @override
  String get businessHours => 'Waktu perniagaan';

  @override
  String get deliverySettings => 'Tetapan penghantaran';

  @override
  String get profile => 'Profil';

  @override
  String get security => 'Keselamatan';

  @override
  String get changePassword => 'Tukar kata laluan';

  @override
  String get more => 'Lagi';

  @override
  String get notificationPreferences => 'Keutamaan pemberitahuan';

  @override
  String get appearance => 'Paparan';

  @override
  String get subscription => 'Langganan';

  @override
  String get choosePlan => 'Pilih pelan';

  @override
  String get reviewPayment => 'Semakan & Pembayaran';

  @override
  String get billingHistory => 'Sejarah Pengebilan';

  @override
  String get helpSupport => 'Bantuan & sokongan';

  @override
  String get helpCentre => 'Pusat bantuan';

  @override
  String get contactSupport => 'Hubungi sokongan';

  @override
  String get privacyPolicy => 'Dasar privasi';

  @override
  String get termsService => 'Terma perkhidmatan';

  @override
  String get aboutCefflo => 'Perihal Cefflo';

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get pendingApproval => 'Menunggu kelulusan';

  @override
  String get pickup => 'Pengambilan';

  @override
  String get pickedUp => 'Telah diambil';

  @override
  String get way => 'Dalam perjalanan';

  @override
  String get arrived => 'Tiba';

  @override
  String get delivered => 'Dihantar';

  @override
  String get issue => 'Isu';

  @override
  String get cancelled => 'Dibatalkan';

  @override
  String get ongoing => 'Sedang berjalan';

  @override
  String get business => 'Perniagaan';

  @override
  String get approved => 'Diluluskan';

  @override
  String get item => 'Item';

  @override
  String get rider => 'Rider';

  @override
  String get product => 'Produk';

  @override
  String get serviceAreaNotSet => 'Kawasan servis belum ditetapkan';

  @override
  String get awaitingLocation => 'Menunggu lokasi';

  @override
  String get coverage2 => 'Dalam liputan';

  @override
  String get outsideCoverage => 'Luar liputan';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get addressNotYetLocated => 'Alamat belum ditemui';

  @override
  String get addressAmbiguous => 'Alamat tidak jelas';

  @override
  String get addressCouldNotLocated => 'Alamat tidak dapat ditemui';

  @override
  String get noRiderCompatibleVehicleEnoughSpare =>
      'Tiada rider dengan kenderaan yang sesuai dan kapasiti yang mencukupi';

  @override
  String get dispatched => 'Dihantar keluar';

  @override
  String get accepted => 'Diterima';

  @override
  String get pickingUp => 'Sedang mengambil';

  @override
  String get completed => 'Selesai';

  @override
  String get declined => 'Ditolak';

  @override
  String capacityExceededActiveRequestedExceeds(
    Object current_load,
    Object requested,
    Object effective_capacity,
  ) {
    return 'Kapasiti melebihi had: $current_load aktif + $requested diminta melebihi $effective_capacity.';
  }

  @override
  String vehicleIncompatibleNeedsRiderHas(
    Object vehicle_requirement,
    Object rider_vehicle_type,
  ) {
    return 'Kenderaan tidak sesuai: memerlukan $vehicle_requirement, rider menggunakan $rider_vehicle_type.';
  }

  @override
  String get experienceCefflo => 'Rasai Cefflo.';

  @override
  String get t100DeliveriesMonth => '100 penghantaran sebulan';

  @override
  String get up3Riders2Zones => 'Sehingga 3 rider · 2 zon';

  @override
  String get customerTrackingProofDelivery =>
      'Penjejakan pelanggan dan bukti penghantaran';

  @override
  String get businessesRunningLocalDeliveriesRegularly =>
      'Untuk perniagaan yang kerap menjalankan penghantaran tempatan.';

  @override
  String get t500DeliveriesMonth => '500 penghantaran sebulan';

  @override
  String get up10Riders5Zones => 'Sehingga 10 rider · 5 zon';

  @override
  String get up3TeamMembers => 'Sehingga 3 ahli pasukan';

  @override
  String get standardReportingSupport => 'Laporan dan sokongan standard';

  @override
  String get runLocalDeliveryOperationOnePlace =>
      'Jalankan operasi penghantaran tempatan anda di satu tempat.';

  @override
  String get t1500DeliveriesMonth => '1,500 penghantaran sebulan';

  @override
  String get unlimitedRidersZones => 'Rider dan zon tanpa had';

  @override
  String get up10TeamMembers => 'Sehingga 10 ahli pasukan';

  @override
  String get advancedOperationalReporting => 'Laporan operasi lanjutan';

  @override
  String get prioritySupport => 'Sokongan keutamaan';

  @override
  String get highVolumeComplexOperations =>
      'Untuk operasi volum tinggi yang kompleks.';

  @override
  String get t5000DeliveriesMonth => '5,000 penghantaran sebulan';

  @override
  String get up25TeamMembers => 'Sehingga 25 ahli pasukan';

  @override
  String get advancedControlsIntegrations => 'Kawalan dan integrasi lanjutan';

  @override
  String get modernInter => 'Moden (Inter)';

  @override
  String get boldInter => 'Tebal (Inter)';

  @override
  String get elegantInterItalic => 'Elegan (Inter Italik)';

  @override
  String get classicInterCaps => 'Klasik (Inter Huruf Besar)';

  @override
  String get orderWasNotCreatedBackendReturned =>
      'Pesanan tidak dicipta: backend tidak memulangkan id.';

  @override
  String get removingDeliveryFromTodaysPlanNot =>
      'Mengeluarkan penghantaran daripada pelan hari ini belum tersedia.';

  @override
  String get runNotFound => 'Larian tidak ditemui.';

  @override
  String get uiPrototypeModeHasNoBackend =>
      'Mod prototaip UI tiada sambungan backend.';

  @override
  String actionNeedsBackendContractThatNot(Object message) {
    return 'Tindakan ini memerlukan kontrak backend yang belum tersedia di sini ($message).';
  }

  @override
  String get unexpectedBackendResponseShape =>
      'Bentuk respons backend tidak dijangka.';

  @override
  String get updatingPassword => 'Mengemas kini kata laluan…';

  @override
  String get savingNewPassword => 'Menyimpan kata laluan baharu anda.';

  @override
  String get passwordUpdated => 'Kata laluan dikemas kini';

  @override
  String get canNowSignNewPassword =>
      'Anda kini boleh log masuk dengan kata laluan baharu anda.';

  @override
  String get operateTodayGrowTomorrow =>
      'Beroperasi Hari Ini.\nBerkembang Esok.';

  @override
  String get back => 'Kembali';

  @override
  String get emailPasswordIncorrectTryAgain =>
      'E-mel atau kata laluan salah. Cuba lagi.';

  @override
  String get tooManyAttemptsPleaseWaitBefore =>
      'Terlalu banyak cubaan. Sila tunggu sebelum cuba lagi.';

  @override
  String get unableConnectCheckConnectionTryAgain =>
      'Tidak dapat menyambung. Semak sambungan anda dan cuba lagi.';

  @override
  String get unableConnect => 'Tidak dapat menyambung';

  @override
  String get tooManyAttempts => 'Terlalu banyak cubaan';

  @override
  String get continueApple => 'Teruskan dengan Apple';

  @override
  String get continueGoogle => 'Teruskan dengan Google';

  @override
  String get continueEmail => 'Teruskan dengan E-mel';

  @override
  String get haveInvite => 'Ada jemputan? ';

  @override
  String get getStarted => 'Mulakan';

  @override
  String get language => 'Bahasa';

  @override
  String get signEmail => 'Log masuk dengan E-mel';

  @override
  String get enterEmailPasswordContinue =>
      'Masukkan e-mel dan kata laluan anda untuk teruskan.';

  @override
  String get email => 'E-mel';

  @override
  String get password => 'Kata laluan';

  @override
  String get enterPassword => 'Masukkan kata laluan anda';

  @override
  String get forgotPassword => 'Lupa kata laluan?';

  @override
  String get tryAgain => 'Cuba lagi';

  @override
  String get signing => 'Sedang log masuk…';

  @override
  String get dontHaveAccount => 'Belum ada akaun? ';

  @override
  String get signUp => 'Daftar';

  @override
  String get passwordsDoNotMatch => 'Kata laluan tidak sepadan.';

  @override
  String get createAccount2 => 'Cipta akaun anda';

  @override
  String get startManagingDeliveries => 'Mula mengurus penghantaran anda.';

  @override
  String get useLeast8Characters => 'Gunakan sekurang-kurangnya 8 aksara.';

  @override
  String get confirmPassword => 'Sahkan kata laluan';

  @override
  String get confirmPassword2 => 'Sahkan kata laluan anda';

  @override
  String get creatingAccount => 'Sedang mencipta akaun…';

  @override
  String get alreadyHaveAccount => 'Sudah ada akaun? ';

  @override
  String get enterEmailWellSendResetLink =>
      'Masukkan e-mel anda dan kami akan menghantar kod 6 digit.';

  @override
  String get sendResetLink => 'Hantar kod';

  @override
  String get sending => 'Sedang menghantar…';

  @override
  String get backSign => 'Kembali ke log masuk';

  @override
  String get checkEmail => 'Semak e-mel anda';

  @override
  String get ifAccountExistsEmailYoullReceive =>
      'Jika akaun wujud untuk e-mel ini, anda akan menerima pautan tetapan semula kata laluan.';

  @override
  String get checkSpamFolderToo => 'Semak juga folder spam anda.';

  @override
  String get tryAnotherEmail => 'Cuba e-mel lain';

  @override
  String verificationEmailSent(Object email) {
    return 'E-mel pengesahan dihantar ke $email.';
  }

  @override
  String get verifyEmail => 'Sahkan e-mel anda';

  @override
  String get openVerificationLinkEmailConfirmAccount =>
      'Buka pautan pengesahan dalam e-mel anda untuk mengesahkan akaun anda.';

  @override
  String get resendVerificationEmail => 'Hantar semula e-mel pengesahan';

  @override
  String get useDifferentEmail => 'Gunakan e-mel lain';

  @override
  String get emailVerified => 'E-mel disahkan';

  @override
  String get emailConfirmedSignContinue =>
      'E-mel anda telah disahkan.\nLog masuk untuk teruskan.';

  @override
  String get continueSign => 'Teruskan ke log masuk';

  @override
  String verificationEmailSent2(Object trim) {
    return 'E-mel pengesahan dihantar ke $trim.';
  }

  @override
  String get verificationLinkExpired => 'Pautan pengesahan tamat tempoh';

  @override
  String get linkHasExpiredInvalidRequestNew =>
      'Pautan ini telah tamat tempoh atau tidak sah.\nMinta e-mel pengesahan baharu.';

  @override
  String get sendNewVerificationEmail => 'Hantar e-mel pengesahan baharu';

  @override
  String get setNewPassword => 'Tetapkan kata laluan baharu';

  @override
  String get chooseStrongPasswordAccount =>
      'Pilih kata laluan yang kukuh untuk akaun anda.';

  @override
  String get newPassword => 'Kata laluan baharu';

  @override
  String get enterNewPassword => 'Masukkan kata laluan baharu';

  @override
  String get updatePassword => 'Kemas kini kata laluan';

  @override
  String get updating => 'Sedang mengemas kini…';

  @override
  String get noBusinessLinked => 'Tiada perniagaan dipautkan.';

  @override
  String zones2(Object zonesCount) {
    return 'Zon ($zonesCount)';
  }

  @override
  String get noZonesYetTapCreateFirst =>
      'Belum ada zon. Ketik + untuk mencipta zon pertama anda.';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Tidak aktif';

  @override
  String get theseZonesDefineWhereDeliverAdd =>
      'Zon ini menentukan kawasan penghantaran anda. Tambah, sunting atau nyahaktifkan zon pada bila-bila masa.';

  @override
  String get searchZones => 'Cari zon...';

  @override
  String get noZonesConfiguredYet => 'Belum ada zon dikonfigurasikan.';

  @override
  String get zoneNotFound => 'Zon tidak ditemui';

  @override
  String get zoneOptions => 'Pilihan zon';

  @override
  String get editZoneName => 'Sunting nama zon';

  @override
  String get deleteZone => 'Padam zon';

  @override
  String get cancel => 'Batal';

  @override
  String zoneRenamed(Object updated) {
    return 'Nama zon ditukar kepada $updated';
  }

  @override
  String couldNotRename(Object e) {
    return 'Tidak dapat menukar nama: $e';
  }

  @override
  String delete(Object zone) {
    return 'Padam $zone?';
  }

  @override
  String get willRemoveZoneFromDeliverySetup =>
      'Ini akan mengeluarkan zon daripada persediaan penghantaran anda.';

  @override
  String get delete2 => 'Padam';

  @override
  String removedFromDeliverySetup(Object zone) {
    return '$zone dikeluarkan daripada persediaan penghantaran anda';
  }

  @override
  String couldNotDelete(Object e) {
    return 'Tidak dapat memadam: $e';
  }

  @override
  String get zoneNameRequired => 'Nama zon diperlukan.';

  @override
  String get zoneName => 'Nama zon';

  @override
  String get save => 'Simpan';

  @override
  String get t0Km => '0 km';

  @override
  String km(Object distance) {
    return '$distance km';
  }

  @override
  String get totalDistance => 'Jumlah jarak';

  @override
  String get totalOrders => 'Jumlah pesanan';

  @override
  String get todaysDeliveries => 'Penghantaran hari ini';

  @override
  String get noDeliveriesPlannedZoneToday =>
      'Tiada penghantaran dirancang di zon ini hari ini.';

  @override
  String get dispatch => 'Hantar keluar';

  @override
  String get unassignedRider => 'Rider belum ditugaskan';

  @override
  String order(Object count, Object s) {
    return '$count pesanan';
  }

  @override
  String km2(Object distanceKm) {
    return '$distanceKm km';
  }

  @override
  String min(Object travelMinutes) {
    return '$travelMinutes min';
  }

  @override
  String removedFromToday(Object delivery) {
    return '$delivery dikeluarkan daripada hari ini';
  }

  @override
  String get processing => 'Sedang diproses...';

  @override
  String get creatingZone => 'Mencipta zon anda';

  @override
  String get successful => 'Berjaya';

  @override
  String get newZoneHasBeenCreatedSuccessfully =>
      'Zon baharu anda telah berjaya dicipta.';

  @override
  String get createZone2 => 'Cipta Zon';

  @override
  String get zoneWillCoverHighlightedAreaMap =>
      'Zon ini akan meliputi kawasan yang diserlahkan pada peta. Anda boleh menyuntingnya kemudian.';

  @override
  String get zoneDetails => 'Butiran zon';

  @override
  String get nameAreaDeliver => 'Namakan kawasan penghantaran anda';

  @override
  String get enterZoneName => 'Masukkan nama zon';

  @override
  String get all => 'Semua';

  @override
  String get offline => 'Luar talian';

  @override
  String get pending => 'Belum selesai';

  @override
  String get noRidersYet => 'Belum ada rider.';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mac';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'Mei';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Ogo';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Okt';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dis';

  @override
  String get riderNotFound => 'Rider tidak ditemui';

  @override
  String get pendingReview => 'Menunggu Semakan';

  @override
  String get riderApplicant => 'Pemohon rider';

  @override
  String get reject => 'Tolak';

  @override
  String get rejectingRiders => 'Menolak rider';

  @override
  String get approveRider => 'Luluskan Rider';

  @override
  String get approvingRiders => 'Meluluskan rider';

  @override
  String get customerRating => 'Penilaian pelanggan';

  @override
  String get joined => 'Menyertai';

  @override
  String get drivingLicence => 'Lesen Memandu';

  @override
  String get noLicenceDocumentAvailable => 'Tiada dokumen lesen tersedia';

  @override
  String get additionalInformation => 'Maklumat Tambahan';

  @override
  String get noAdditionalInformationAvailable =>
      'Tiada maklumat tambahan tersedia.';

  @override
  String get searchTeamMembers => 'Cari ahli pasukan...';

  @override
  String get noTeamMembersYet => 'Belum ada ahli pasukan.';

  @override
  String get teamMemberNotFound => 'Ahli pasukan tidak ditemui';

  @override
  String get notProvided => 'Tidak diberikan';

  @override
  String get roleAccess => 'Peranan & akses';

  @override
  String get accountStatus => 'Status akaun';

  @override
  String get businessOwnerAlwaysKeepsFullAccess =>
      'Pemilik perniagaan sentiasa mempunyai akses penuh dan tidak boleh dikeluarkan daripada pasukan.';

  @override
  String get removeFromTeam => 'Keluarkan daripada Pasukan';

  @override
  String get canManageDailyOperationsOrdersRiders =>
      'Boleh mengurus operasi harian, pesanan, rider dan ahli pasukan. Tidak boleh mengurus pengebilan atau langganan.';

  @override
  String get canAccessDailyOperationsOrdersRiders =>
      'Boleh mengakses operasi harian, pesanan dan rider. Tidak boleh mengurus pengebilan atau langganan.';

  @override
  String remove(Object userId) {
    return 'Keluarkan $userId?';
  }

  @override
  String get theyWillLoseAccessBusinessImmediately =>
      'Mereka akan kehilangan akses kepada perniagaan ini serta-merta.';

  @override
  String get remove2 => 'Keluarkan';

  @override
  String get searchProducts => 'Cari produk...';

  @override
  String get noProductsCatalogueYet => 'Belum ada produk dalam katalog.';

  @override
  String rm(Object displayPrice, Object status) {
    return 'RM $displayPrice · $status';
  }

  @override
  String get searchCustomers => 'Cari pelanggan...';

  @override
  String orders2(Object count) {
    return 'Pesanan ($count)';
  }

  @override
  String get account => 'Akaun';

  @override
  String get businessProfile2 => 'Profil Perniagaan';

  @override
  String get support => 'Sokongan';

  @override
  String get helpSupport2 => 'Bantuan & Sokongan';

  @override
  String get privacy => 'Privasi';

  @override
  String get signOut => 'Log keluar';

  @override
  String get version100 => 'Versi 1.0.0';

  @override
  String get businessInformation2 => 'Maklumat Perniagaan';

  @override
  String get nameTypeContactDetails => 'Nama, jenis dan butiran hubungan';

  @override
  String get pickupLocation2 => 'Lokasi Pengambilan';

  @override
  String get whereDeliveriesStartFrom => 'Tempat penghantaran bermula';

  @override
  String get serviceArea2 => 'Kawasan Servis';

  @override
  String get howFarDeliver => 'Sejauh mana anda menghantar';

  @override
  String get letsSetUpBusiness => 'Jom sediakan perniagaan anda';

  @override
  String get justFewDetailsBeforeStartDelivering =>
      'Hanya beberapa butiran sebelum anda mula menghantar dengan Cefflo. Mengambil masa kira-kira 2 minit.';

  @override
  String get getStarted2 => 'Mulakan';

  @override
  String step(Object step, Object totalSteps) {
    return 'Langkah $step daripada $totalSteps';
  }

  @override
  String get foodBeverage => 'Makanan & Minuman';

  @override
  String get homeLiving => 'Rumah & Gaya Hidup';

  @override
  String get retail => 'Runcit';

  @override
  String get groceries => 'Barangan Dapur';

  @override
  String get other => 'Lain-lain';

  @override
  String get businessNameRequired => 'Nama bisnes diperlukan.';

  @override
  String get enterValidPhoneNumber => 'Masukkan nombor telefon yang sah.';

  @override
  String get continueText => 'Teruskan';

  @override
  String get tellUsAboutBusiness => 'Beritahu kami tentang perniagaan anda';

  @override
  String get appearsDeliveryOrdersReceipts =>
      'Ini akan dipaparkan pada pesanan penghantaran dan resit anda.';

  @override
  String get businessName => 'Nama Perniagaan';

  @override
  String get eGKopiKita => 'cth. Kopi Kita';

  @override
  String get businessType => 'Jenis Perniagaan';

  @override
  String get contactPhone => 'Telefon Hubungan';

  @override
  String get pickupAddressRequired => 'Alamat pengambilan diperlukan.';

  @override
  String get whereDoDeliveriesStartFrom => 'Dari mana penghantaran bermula?';

  @override
  String get ridersPickUpOrdersFromLocation =>
      'Rider mengambil pesanan dari lokasi ini.';

  @override
  String get pickupAddress => 'Alamat Pengambilan';

  @override
  String get searchEnterAddress => 'Cari atau masukkan alamat anda';

  @override
  String get postcode => 'Poskod';

  @override
  String get city => 'Bandar';

  @override
  String get howFarDoDeliver => 'Sejauh mana anda menghantar?';

  @override
  String get ceffloUsesDecideWhichOrdersCan =>
      'Cefflo menggunakan ini untuk menentukan pesanan yang boleh anda terima.';

  @override
  String get finishSetup => 'Selesaikan Persediaan';

  @override
  String get configured => 'Dikonfigurasikan';

  @override
  String get teamRiders => 'Pasukan & Rider';

  @override
  String get ready => 'Sedia';

  @override
  String get preferences => 'Keutamaan';

  @override
  String get setText => 'Ditetapkan';

  @override
  String get business2 => 'Perniagaan Anda\n';

  @override
  String get ready2 => 'Sudah Sedia!';

  @override
  String get deliverySetupCompleteLetsStartDelivering =>
      'Persediaan penghantaran anda sudah lengkap.\nJom mula menghantar dengan Cefflo.';

  @override
  String get goToday => 'Pergi ke Hari Ini';

  @override
  String get noBusinessLinkedAccountYet =>
      'Belum ada perniagaan dipautkan ke akaun ini.';

  @override
  String noOrders(Object toLowerCase) {
    return 'Tiada pesanan $toLowerCase.';
  }

  @override
  String todayItem(Object createdAt, Object itemsCount, Object s) {
    return 'Hari ini, $createdAt · $itemsCount item';
  }

  @override
  String get editOrder2 => 'Sunting Pesanan';

  @override
  String get deliver => 'Hantar ke';

  @override
  String get directions => 'Arah';

  @override
  String get notSet => 'Belum ditetapkan';

  @override
  String get deliveryInstruction => 'Arahan Penghantaran';

  @override
  String items(Object itemsCount) {
    return 'Item ($itemsCount)';
  }

  @override
  String get viewReceipt => 'Lihat resit';

  @override
  String get receiptView => 'Paparan resit';

  @override
  String get noItemsOrder => 'Tiada item dalam pesanan ini.';

  @override
  String viewAllItems(Object itemsCount) {
    return 'Lihat kesemua $itemsCount item';
  }

  @override
  String zoneSet(Object z) {
    return 'Zon ditetapkan kepada $z';
  }

  @override
  String couldNotSetZone(Object e) {
    return 'Tidak dapat menetapkan zon: $e';
  }

  @override
  String get orderApproved => 'Pesanan diluluskan';

  @override
  String couldNotApprove(Object e) {
    return 'Tidak dapat meluluskan: $e';
  }

  @override
  String get approveOrder => 'Luluskan Pesanan';

  @override
  String get approving => 'Sedang meluluskan…';

  @override
  String get manualEntry => 'Kemasukan Manual';

  @override
  String get createSingleOrderStepByStep =>
      'Cipta satu pesanan langkah demi langkah';

  @override
  String get importOrders2 => 'Import Pesanan';

  @override
  String get importMultipleOrdersFromFiles =>
      'Import berbilang pesanan daripada fail anda';

  @override
  String get recentImports => 'Import Terkini';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get importHistory => 'Sejarah import';

  @override
  String get connected => 'Disambungkan';

  @override
  String get openingImport => 'Membuka import ini';

  @override
  String get googleSheets => 'Google Sheets';

  @override
  String get importFromGoogleSheets => 'Import daripada Google Sheets anda';

  @override
  String get mealPrepOrders => 'Pesanan Meal Prep';

  @override
  String get t16Sep2026 => '16 Sep 2026';

  @override
  String get excel => 'Excel';

  @override
  String get uploadExcelFileXlsxXls => 'Muat naik fail Excel (.xlsx, .xls)';

  @override
  String get cateringSept => 'Katering Sept';

  @override
  String get t14Sep2026 => '14 Sep 2026';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get importFromFilesGoogleDrive =>
      'Import daripada fail dalam Google Drive anda';

  @override
  String get hamperOrders => 'Pesanan Hamper';

  @override
  String get t12Sep2026 => '12 Sep 2026';

  @override
  String get selectSource => 'Pilih sumber anda';

  @override
  String get googleSheetsExcelGoogleDrive =>
      'Google Sheets, Excel atau Google Drive';

  @override
  String get chooseFile => 'Pilih fail';

  @override
  String get pickConnectedSheet => 'Atau pilih helaian yang disambungkan';

  @override
  String get mapColumns => 'Padankan lajur';

  @override
  String get previewOrders => 'Dan pratonton pesanan anda';

  @override
  String get importText => 'Import';

  @override
  String get reviewOrders => 'Dan semak pesanan';

  @override
  String get chooseSourceImportMultipleOrders =>
      'Pilih sumber untuk mengimport berbilang pesanan.';

  @override
  String get howWorks => 'Bagaimana ia berfungsi?';

  @override
  String get sources => 'Sumber';

  @override
  String importingFrom(Object source) {
    return 'Mengimport daripada $source';
  }

  @override
  String get customerNameRequired => 'Nama pelanggan diperlukan.';

  @override
  String get deliveryAddressRequired => 'Alamat penghantaran diperlukan.';

  @override
  String get creatingOrder => 'Mencipta pesanan anda';

  @override
  String get updatingOrder => 'Mengemas kini pesanan anda';

  @override
  String get newOrderHasBeenCreatedSuccessfully =>
      'Pesanan baharu anda telah berjaya dicipta.';

  @override
  String get orderHasBeenUpdatedSuccessfully =>
      'Pesanan anda telah berjaya dikemas kini.';

  @override
  String get reviewCreate => 'Semak & Cipta';

  @override
  String get updateOrder => 'Kemas Kini Pesanan';

  @override
  String get createNewOrderStepByStep =>
      'Cipta pesanan baharu langkah demi langkah.';

  @override
  String get updateOrderDetails => 'Kemas kini butiran pesanan.';

  @override
  String get selectExistingCustomerAddNewOne =>
      'Pilih pelanggan sedia ada atau tambah yang baharu.';

  @override
  String get customerName => 'Nama pelanggan';

  @override
  String get searchCustomerByNamePhoneEmail =>
      'Cari pelanggan mengikut nama, telefon atau e-mel...';

  @override
  String get phoneNumber => 'Nombor telefon';

  @override
  String get enterPhoneNumber => 'Masukkan nombor telefon...';

  @override
  String get address => 'Alamat';

  @override
  String get deliveryAddress => 'Alamat penghantaran';

  @override
  String get enterDeliveryAddress => 'Masukkan alamat penghantaran...';

  @override
  String get items2 => 'Item';

  @override
  String get addOrderItems => 'Tambah item pesanan';

  @override
  String get addItemsOrder => 'Tambah item ke pesanan ini';

  @override
  String get addingOrderItems => 'Menambah item pesanan';

  @override
  String get instructions => 'Arahan';

  @override
  String get specialRequestsOptional => 'Permintaan khas (pilihan)';

  @override
  String get instruction => 'Arahan';

  @override
  String get addDeliveryNotes => 'Tambah nota penghantaran...';

  @override
  String get productNameRequired => 'Nama produk diperlukan.';

  @override
  String get enterValidPrice => 'Masukkan harga yang sah.';

  @override
  String get addingProduct => 'Menambah produk anda';

  @override
  String get updatingProduct => 'Mengemas kini produk anda';

  @override
  String get newProductHasBeenAddedSuccessfully =>
      'Produk baharu anda telah berjaya ditambah.';

  @override
  String get productHasBeenUpdatedSuccessfully =>
      'Produk anda telah berjaya dikemas kini.';

  @override
  String get addProduct2 => 'Tambah Produk';

  @override
  String get saveChanges => 'Simpan Perubahan';

  @override
  String get productPhoto => 'Foto Produk';

  @override
  String get productDetails => 'Butiran Produk';

  @override
  String get productName => 'Nama produk';

  @override
  String get enterProductName => 'Masukkan nama produk';

  @override
  String get description => 'Penerangan';

  @override
  String get enterProductDescription => 'Masukkan penerangan produk';

  @override
  String get priceRm => 'Harga (RM)';

  @override
  String get rm000 => 'RM 0.00';

  @override
  String get available => 'Tersedia';

  @override
  String get showProductStorefront =>
      'Paparkan produk ini di kedai dalam talian anda';

  @override
  String get way2 => 'Dalam Perjalanan';

  @override
  String get addProductPhoto => 'Tambah foto produk';

  @override
  String get deliveryRun => 'Larian penghantaran';

  @override
  String delivered2(Object done, Object total) {
    return '$done daripada $total dihantar';
  }

  @override
  String remaining(Object done) {
    return '$done berbaki';
  }

  @override
  String get nextStop => 'Hentian seterusnya';

  @override
  String get next => 'Seterusnya';

  @override
  String get upcomingStops => 'Hentian akan datang';

  @override
  String get everyStopRunFinished =>
      'Semua hentian dalam larian ini telah selesai.';

  @override
  String run(Object zone) {
    return 'Larian $zone';
  }

  @override
  String dispatched2(Object rider) {
    return 'Dihantar keluar kepada $rider';
  }

  @override
  String dispatchOrder(Object count, Object s) {
    return 'Hantar keluar $count pesanan';
  }

  @override
  String chooseRider(Object zone) {
    return 'Pilih rider untuk $zone.';
  }

  @override
  String get noActiveRidersYet => 'Belum ada rider aktif.';

  @override
  String get checkingVehicleCapacity => 'Menyemak kenderaan dan kapasiti…';

  @override
  String get dispatching => 'Sedang menghantar keluar…';

  @override
  String get savingServiceArea => 'Menyimpan kawasan servis anda';

  @override
  String get serviceAreaHasBeenSaved => 'Kawasan servis anda telah disimpan.';

  @override
  String get coverageConfiguredCeffloDecidesEachOrders =>
      'Liputan telah dikonfigurasikan. Cefflo menentukan liputan setiap pesanan berdasarkan ini.';

  @override
  String get noServiceAreaConfiguredYetOrders =>
      'Belum ada kawasan servis dikonfigurasikan. Pesanan akan menunjukkan “Belum ditetapkan” dan bukannya keputusan liputan.';

  @override
  String get saveServiceArea => 'Simpan kawasan servis';

  @override
  String get manageZones => 'Urus zon';

  @override
  String get seeConfigureZonesDeliver =>
      'Lihat dan konfigurasikan zon penghantaran anda';

  @override
  String get deliveryRadius => 'Radius penghantaran';

  @override
  String km3(Object round) {
    return '$round km';
  }

  @override
  String sf(Object padLeft) {
    return 'SF-$padLeft';
  }

  @override
  String get cart => 'Troli Anda';

  @override
  String get cartEmpty => 'Troli anda kosong.';

  @override
  String rm2(Object price) {
    return 'RM $price';
  }

  @override
  String get addNoteOptional => 'Tambah nota (pilihan)';

  @override
  String get subtotal => 'Jumlah kecil';

  @override
  String get deliveryFee => 'Caj Penghantaran';

  @override
  String get total => 'Jumlah';

  @override
  String get proceedCheckout => 'Teruskan ke Pembayaran';

  @override
  String rm3(Object toStringAsFixed) {
    return 'RM $toStringAsFixed';
  }

  @override
  String get checkout => 'Pembayaran';

  @override
  String get customerInfo => 'Maklumat Pelanggan';

  @override
  String get fullName => 'Nama penuh';

  @override
  String get deliveryAddress2 => 'Alamat Penghantaran';

  @override
  String get deliveryOption => 'Pilihan Penghantaran';

  @override
  String get standardDelivery => 'Penghantaran standard';

  @override
  String get t3045Min => '30-45 min';

  @override
  String get expressDelivery => 'Penghantaran ekspres';

  @override
  String get t1520MinRm300 => '15-20 min · +RM 3.00';

  @override
  String get paymentMethod => 'Kaedah Pembayaran';

  @override
  String get cashDelivery => 'Tunai Semasa Penghantaran';

  @override
  String get payWhenOrderArrives => 'Bayar apabila pesanan anda tiba';

  @override
  String get card => 'Kad';

  @override
  String get prototypeOnlyNoRealPaymentProcessed =>
      'Prototaip sahaja -- tiada pembayaran sebenar diproses';

  @override
  String get orderSummary => 'Ringkasan Pesanan';

  @override
  String get placeOrder => 'Buat Pesanan';

  @override
  String get orderPlaced => 'Pesanan dibuat!';

  @override
  String orderHasBeenCreatedPrototypeFlow(Object orderRef) {
    return 'Pesanan $orderRef telah dicipta. Ini ialah aliran prototaip -- tiada pesanan atau pembayaran sebenar diproses.';
  }

  @override
  String get continueShopping => 'Teruskan Membeli-belah';

  @override
  String get store => 'Kedai anda';

  @override
  String get defaultText => 'Lalai';

  @override
  String get white => 'Putih';

  @override
  String get warm => 'Hangat';

  @override
  String get cool => 'Sejuk';

  @override
  String get discardChanges => 'Buang perubahan?';

  @override
  String get storefrontStaysChangesMadeHereNot =>
      'Kedai dalam talian anda kekal seperti sedia ada. Perubahan yang anda buat di sini tidak disimpan.';

  @override
  String get keepEditing => 'Teruskan menyunting';

  @override
  String get discard => 'Buang';

  @override
  String get saving => 'Sedang menyimpan...';

  @override
  String get updatingStorefront => 'Mengemas kini kedai dalam talian anda';

  @override
  String live(Object def) {
    return '$def kini aktif';
  }

  @override
  String get storefrontUpdated => 'Kedai dalam talian dikemas kini';

  @override
  String productsNowShowLayout(Object def) {
    return 'Produk anda kini dipaparkan dalam susun atur $def.';
  }

  @override
  String get customersNowSeeChanges =>
      'Pelanggan kini dapat melihat perubahan anda.';

  @override
  String get couldntOpenPhotosPleaseTryAgain =>
      'Tidak dapat membuka foto anda. Sila cuba lagi.';

  @override
  String customize2(Object def) {
    return 'Ubah suai $def';
  }

  @override
  String get adjustColoursStyleMatchBrand =>
      'Laraskan warna dan gaya mengikut jenama anda.';

  @override
  String get resetTemplateDefaults =>
      'Tetapkan semula ke tetapan lalai templat';

  @override
  String get brandColour => 'Warna jenama';

  @override
  String get customColour => 'Warna tersuai';

  @override
  String get background => 'Latar belakang';

  @override
  String get custom => 'Tersuai';

  @override
  String get heroImage => 'Imej utama';

  @override
  String get shownBehindStorefrontBanner =>
      'Dipaparkan di belakang sepanduk kedai dalam talian anda.';

  @override
  String get upload => 'Muat naik';

  @override
  String get change => 'Tukar';

  @override
  String get storeName => 'Nama kedai';

  @override
  String get fromBusinessProfile => 'Daripada Profil Perniagaan anda.';

  @override
  String get taglineOptional => 'Slogan (pilihan)';

  @override
  String colour(Object hex) {
    return 'Warna $hex';
  }

  @override
  String background2(Object label) {
    return 'Latar belakang $label';
  }

  @override
  String get pickColour => 'Pilih Warna';

  @override
  String get done => 'Selesai';

  @override
  String get exploreTemplates => 'Terokai Templat';

  @override
  String get previewAnyLayoutOwnProducts =>
      'Pratonton mana-mana susun atur dengan produk anda sendiri.';

  @override
  String get noTemplatesHereYet => 'Belum ada templat di sini.';

  @override
  String get everyTemplateShowsTheseProducts =>
      'Setiap templat memaparkan produk ini';

  @override
  String get comingSoon => 'Akan datang';

  @override
  String customize3(Object join) {
    return 'Ubah suai: $join';
  }

  @override
  String get useTemplate => 'Gunakan Templat Ini';

  @override
  String get close => 'Tutup';

  @override
  String get storefront2 => 'Kedai dalam talian anda';

  @override
  String rm4(Object amount) {
    return 'RM$amount';
  }

  @override
  String get deliveries => 'Penghantaran';

  @override
  String get teamMembers => 'Ahli pasukan';

  @override
  String plan(Object plan) {
    return 'Pelan $plan';
  }

  @override
  String nextRenewal(Object nextRenewal) {
    return 'Pembaharuan seterusnya pada $nextRenewal';
  }

  @override
  String get currentUsage => 'Penggunaan semasa';

  @override
  String get cycle => 'Kitaran ini';

  @override
  String get changePlan => 'Tukar pelan';

  @override
  String get paymentMethod2 => 'Kaedah pembayaran';

  @override
  String get paymentMethods => 'Kaedah pembayaran';

  @override
  String get billingHistory2 => 'Sejarah pengebilan';

  @override
  String unlimited(Object used) {
    return '$used · Tanpa had';
  }

  @override
  String get currentPlan => 'Pelan semasa';

  @override
  String get selectPlanThatFitsBusiness =>
      'Pilih pelan yang sesuai dengan perniagaan anda.';

  @override
  String get plansPricesCurrentPricingCandidate =>
      'Pelan dan harga ialah calon harga semasa.';

  @override
  String get monthly => 'Bulanan';

  @override
  String get yearly => 'Tahunan';

  @override
  String get t2MonthsFree => '2 bulan percuma';

  @override
  String get mostPopular => 'Paling Popular';

  @override
  String get current => 'Semasa';

  @override
  String get processingPayment => 'Memproses pembayaran';

  @override
  String get pleaseWaitWhileWeConfirmPayment =>
      'Sila tunggu sementara kami mengesahkan pembayaran anda.';

  @override
  String get subscriptionActive => 'Langganan aktif';

  @override
  String get paymentUnsuccessful => 'Pembayaran tidak berjaya';

  @override
  String get weCouldntProcessPaymentNoCharge =>
      'Kami tidak dapat memproses pembayaran anda.\nTiada caj dikenakan.';

  @override
  String get changePaymentMethod => 'Tukar kaedah pembayaran';

  @override
  String get subscribe => 'Langgan';

  @override
  String get billingCycle => 'Kitaran pengebilan';

  @override
  String get creditDebitCard => 'Kad Kredit / Debit';

  @override
  String get fpxOnlineBanking => 'Perbankan dalam talian FPX';

  @override
  String get demoNoRealPaymentProcessed =>
      'Demo — tiada pembayaran sebenar diproses.';

  @override
  String get noInvoicesYet => 'Belum ada invois.';

  @override
  String get paid => 'Dibayar';

  @override
  String get due => 'Perlu dibayar';

  @override
  String get downloadInvoice => 'Muat turun invois';

  @override
  String get invoiceDownload => 'Muat turun invois';

  @override
  String get ahmadRazi => 'Ahmad Razi';

  @override
  String get vfy7281 => 'VFY 7281';

  @override
  String get bangsar => 'Bangsar';

  @override
  String get t224Pm => '2:24 PM';

  @override
  String get sitiAminah => 'Siti Aminah';

  @override
  String get bmd4120 => 'BMD 4120';

  @override
  String get sentul => 'Sentul';

  @override
  String get t156Pm => '1:56 PM';

  @override
  String get jasonLim => 'Jason Lim';

  @override
  String get vdt3302 => 'VDT 3302';

  @override
  String get setapak => 'Setapak';

  @override
  String get t1241Pm => '12:41 PM';

  @override
  String get nurIman => 'Nur Iman';

  @override
  String get vfe9812 => 'VFE 9812';

  @override
  String get shahAlam => 'Shah Alam';

  @override
  String get t1128Am => '11:28 AM';

  @override
  String get danielTan => 'Daniel Tan';

  @override
  String get bpl6683 => 'BPL 6683';

  @override
  String get petalingJaya => 'Petaling Jaya';

  @override
  String get t1054Am => '10:54 AM';

  @override
  String get farahLee => 'Farah Lee';

  @override
  String get vds7721 => 'VDS 7721';

  @override
  String get putrajaya => 'Putrajaya';

  @override
  String get t0917Am => '09:17 AM';

  @override
  String get hafizKhan => 'Hafiz Khan';

  @override
  String get bpq3091 => 'BPQ 3091';

  @override
  String get klang => 'Klang';

  @override
  String get t0836Am => '08:36 AM';

  @override
  String get totalOrders2 => 'Jumlah Pesanan';

  @override
  String get recentDelivery => 'Penghantaran Terkini';

  @override
  String get noCompletedDeliveriesYet => 'Belum ada penghantaran yang selesai.';

  @override
  String get needAttention => 'Perlu Perhatian';

  @override
  String needAttention2(Object issuesCount) {
    return 'Perlu Perhatian ($issuesCount)';
  }

  @override
  String get nothingNeedsAttention =>
      'Tiada apa-apa yang perlu perhatian anda.';

  @override
  String get needsAction => 'Perlukan tindakan anda';

  @override
  String get activeRun => 'Larian aktif';

  @override
  String get inviteRider => 'Jemput rider';

  @override
  String get inviteTeamMember => 'Jemput ahli pasukan';

  @override
  String get online => 'Dalam talian';

  @override
  String get youreOfflineNewOrdersPaused =>
      'Anda di luar talian. Pesanan baharu dijeda.';

  @override
  String get youreOnline => 'Anda dalam talian.';

  @override
  String get businesses => 'Perniagaan anda';

  @override
  String get goodMorning => 'Selamat Pagi,';

  @override
  String get goodAfternoon => 'Selamat Tengah Hari,';

  @override
  String get goodEvening => 'Selamat Petang,';

  @override
  String get heresWhatsHappeningToday => 'Ini perkembangan hari ini.';

  @override
  String get searchOrderNumberCustomer =>
      'Cari nombor pesanan atau pelanggan...';

  @override
  String get searchRiders => 'Cari rider...';

  @override
  String get addOrder => 'Tambah pesanan';

  @override
  String get addZone => 'Tambah zon';

  @override
  String get notificationOptions => 'Pilihan pemberitahuan';

  @override
  String get markAllRead => 'Tandakan semua sebagai dibaca';

  @override
  String get clearAllNotifications => 'Kosongkan semua pemberitahuan';

  @override
  String get search => 'Cari';

  @override
  String notWiredUpYet(Object action) {
    return '$action belum disambungkan.';
  }

  @override
  String get showPassword => 'Tunjukkan kata laluan';

  @override
  String get hidePassword => 'Sembunyikan kata laluan';

  @override
  String get filter => 'Tapis';

  @override
  String get phoneApp => 'aplikasi telefon';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String couldNotOpen(Object target) {
    return 'Tidak dapat membuka $target.';
  }

  @override
  String get call => 'Panggil';

  @override
  String call2(Object phone) {
    return 'Panggil $phone';
  }

  @override
  String whatsapp2(Object phone) {
    return 'WhatsApp $phone';
  }

  @override
  String get contact => 'Hubungan';

  @override
  String get loading => 'Memuatkan';

  @override
  String get somethingWentWrong => 'Sesuatu tidak kena';

  @override
  String get weCouldntCompleteActionRightNow =>
      'Kami tidak dapat menyelesaikan tindakan ini sekarang. Sila cuba lagi.';

  @override
  String get delivery => 'Penghantaran';

  @override
  String get activeTeamMemberCanAccessBusiness =>
      'Aktif · Ahli pasukan ini kini boleh mengakses perniagaan anda.';

  @override
  String get fullAccessIncludingBillingSubscription =>
      'Akses penuh ke setiap bahagian perniagaan, termasuk pengebilan dan langganan.';

  @override
  String importSampleSubtitle(Object label, Object count, Object date) {
    return '$label · $count pesanan\n$date';
  }

  @override
  String get nextSetHowFarDeliver =>
      'Seterusnya: tetapkan sejauh mana anda menghantar';

  @override
  String get reservedLaterApprovedDeliverySettingsPass =>
      'Dikhaskan untuk fasa tetapan penghantaran yang diluluskan kemudian.';

  @override
  String get edit => 'Sunting';

  @override
  String get rating => 'Penilaian';

  @override
  String get nameContactDescription => 'Nama, hubungan, penerangan';

  @override
  String get businessAddress2 => 'Alamat Perniagaan';

  @override
  String get storeAddressServiceArea => 'Alamat kedai dan kawasan servis';

  @override
  String get businessHours2 => 'Waktu Perniagaan';

  @override
  String get setOperatingHours => 'Tetapkan waktu operasi anda';

  @override
  String get storeReady => 'Kedai anda sudah sedia';

  @override
  String get keepBusinessInformationUpDate =>
      'Pastikan maklumat perniagaan anda sentiasa terkini.';

  @override
  String get editingBusinessDetailsAppNotConnected =>
      'Menyunting butiran perniagaan dalam aplikasi belum disambungkan.';

  @override
  String get businessDetails => 'Butiran perniagaan';

  @override
  String get howCustomersRidersSeeBusiness =>
      'Cara pelanggan dan rider melihat perniagaan anda.';

  @override
  String get taglineOptional2 => 'Slogan (Pilihan)';

  @override
  String get shortDescription => 'Penerangan Ringkas';

  @override
  String get whereCustomersRidersCanReach =>
      'Tempat pelanggan dan rider boleh menghubungi anda.';

  @override
  String get code => 'Kod';

  @override
  String get businessEmail => 'E-mel Perniagaan';

  @override
  String get editingBusinessAddressAppNotConnected =>
      'Menyunting alamat perniagaan dalam aplikasi belum disambungkan.';

  @override
  String get saveAddress => 'Simpan Alamat';

  @override
  String get addressDetails => 'Butiran alamat';

  @override
  String get addressLine1 => 'Alamat Baris 1';

  @override
  String get addressLine2Optional => 'Alamat Baris 2 (Pilihan)';

  @override
  String get state => 'Negeri';

  @override
  String get businessHoursNotConnectedYet =>
      'Waktu perniagaan belum disambungkan.';

  @override
  String get monday => 'Isnin';

  @override
  String get tuesday => 'Selasa';

  @override
  String get wednesday => 'Rabu';

  @override
  String get thursday => 'Khamis';

  @override
  String get friday => 'Jumaat';

  @override
  String get saturday => 'Sabtu';

  @override
  String get sunday => 'Ahad';

  @override
  String get saveHours => 'Simpan Waktu';

  @override
  String get operatingHours => 'Waktu Operasi';

  @override
  String get letCustomersKnowWhenBusinessOpen =>
      'Beritahu pelanggan bila perniagaan anda dibuka.';

  @override
  String get applyMondaysHoursAllDays => 'Guna waktu Isnin untuk semua hari';

  @override
  String get personalDetails => 'Butiran peribadi';

  @override
  String get nameShownTeam =>
      'Nama anda seperti yang dipaparkan kepada pasukan anda.';

  @override
  String get fullName2 => 'Nama Penuh';

  @override
  String get signEmailRole => 'E-mel log masuk dan peranan.';

  @override
  String get emailAddress => 'Alamat E-mel';

  @override
  String get emailCannotChangedApp =>
      'E-mel tidak boleh ditukar dalam aplikasi.';

  @override
  String get role => 'Peranan';

  @override
  String get managedByBusiness => 'Diurus oleh perniagaan anda.';

  @override
  String get keepAccountSafe => 'Pastikan akaun anda selamat';

  @override
  String get manageHowSignBusinessAccount =>
      'Urus cara anda log masuk ke akaun perniagaan anda.';

  @override
  String get signAccess => 'Log masuk & akses';

  @override
  String get changePassword2 => 'Tukar kata laluan anda';

  @override
  String get twoFactorAuthentication => 'Pengesahan Dua Faktor';

  @override
  String get useLeast8CharactersLetterNumber =>
      'Gunakan sekurang-kurangnya 8 aksara dengan huruf dan nombor.';

  @override
  String get updatingPassword2 => 'Mengemas kini kata laluan anda';

  @override
  String get passwordHasBeenUpdatedSuccessfully =>
      'Kata laluan anda telah berjaya dikemas kini.';

  @override
  String get updatePassword2 => 'Kemas Kini Kata Laluan';

  @override
  String get useStrongPasswordKeepAccountSecure =>
      'Gunakan kata laluan yang kukuh untuk memastikan akaun anda selamat.';

  @override
  String get newPassword2 => 'Kata Laluan Baharu';

  @override
  String get enterNewPassword2 => 'Masukkan kata laluan baharu';

  @override
  String get minimum8Characters => 'Sekurang-kurangnya 8 aksara';

  @override
  String get includeLeastOneLetterOneNumber =>
      'Sertakan sekurang-kurangnya satu huruf dan satu nombor';

  @override
  String get confirmNewPassword => 'Sahkan Kata Laluan Baharu';

  @override
  String get confirmNewPassword2 => 'Sahkan kata laluan baharu';

  @override
  String get notificationSettingsNotConnectedYet =>
      'Tetapan pemberitahuan belum disambungkan.';

  @override
  String get always => 'Sentiasa aktif';

  @override
  String get issuesDeliveryProgressAccountSecurityAlerts =>
      'Amaran isu, kemajuan penghantaran dan keselamatan akaun memastikan operasi anda berjalan, jadi ia tidak boleh dimatikan.';

  @override
  String get orderIssues => 'Isu pesanan';

  @override
  String get accountSecurity => 'Akaun & keselamatan';

  @override
  String get optional => 'Pilihan';

  @override
  String get newOrders => 'Pesanan baharu';

  @override
  String get whenNewOrderComes => 'Apabila pesanan baharu masuk.';

  @override
  String get riderStatus => 'Status rider';

  @override
  String get whenRidersGoOnlineOffline =>
      'Apabila rider dalam talian atau luar talian.';

  @override
  String get productNews => 'Berita produk';

  @override
  String get tipsNewCeffloFeatures => 'Tip dan ciri baharu Cefflo.';

  @override
  String get blue => 'Biru';

  @override
  String get navy => 'Biru Laut';

  @override
  String get red => 'Merah';

  @override
  String get green => 'Hijau';

  @override
  String get yellow => 'Kuning';

  @override
  String get orange => 'Oren';

  @override
  String get black => 'Hitam';

  @override
  String get accentColour => 'Warna aksen';

  @override
  String get chooseAccentColourApp => 'Pilih warna aksen untuk aplikasi.';

  @override
  String get hue => 'Rona';

  @override
  String get lightness => 'Kecerahan';

  @override
  String get apply => 'Guna';

  @override
  String get closed => 'Tutup';

  @override
  String get wereHereHelp => 'Kami sedia membantu';

  @override
  String get howCanWeHelp => 'Bagaimana kami boleh membantu?';

  @override
  String get searchHelpArticlesTopics => 'Cari bantuan, artikel atau topik...';

  @override
  String get helpCentre2 => 'Pusat Bantuan';

  @override
  String get browseArticlesGuidesFaqs =>
      'Layari artikel, panduan dan Soalan Lazim';

  @override
  String get contactSupport2 => 'Hubungi Sokongan';

  @override
  String get chatSendSupportRequest =>
      'Sembang atau hantar permintaan sokongan';

  @override
  String get popularTopics => 'Topik Popular';

  @override
  String get accountSecurity2 => 'Akaun & Keselamatan';

  @override
  String get loginProfileSecuritySettings =>
      'Log masuk, profil, tetapan keselamatan';

  @override
  String get ordersDelivery => 'Pesanan & Penghantaran';

  @override
  String get orderManagementDeliveryIssues =>
      'Pengurusan pesanan, isu penghantaran';

  @override
  String get ridersTeam => 'Rider & Pasukan';

  @override
  String get riderInvitesApprovalsTeamAccess =>
      'Jemputan rider, kelulusan, akses pasukan';

  @override
  String get subscriptionBilling => 'Langganan & Pengebilan';

  @override
  String get plansPaymentsInvoices => 'Pelan, pembayaran, invois';

  @override
  String get appGuides => 'Panduan Aplikasi';

  @override
  String get stepByStepTutorials => 'Tutorial langkah demi langkah';

  @override
  String get findAnswers => 'Cari jawapan';

  @override
  String get searchOurHelpCentreBrowseTopics =>
      'Cari di pusat bantuan kami atau layari topik di bawah.';

  @override
  String get searchHelpEGZonesRiders => 'Cari bantuan, cth. zon, rider...';

  @override
  String get browseTopics => 'Layari topik';

  @override
  String get gettingStarted => 'Bermula';

  @override
  String get setUpAccountBusiness => 'Sediakan akaun dan perniagaan anda';

  @override
  String get manageOrdersRunsZones => 'Urus pesanan, larian dan zon';

  @override
  String get zonesRiders => 'Zon & Rider';

  @override
  String get coverageRidersDispatch => 'Liputan, rider dan penghantaran keluar';

  @override
  String get profileSecuritySettings => 'Profil, keselamatan dan tetapan';

  @override
  String get plansPaymentsInvoices2 => 'Pelan, pembayaran dan invois';

  @override
  String get popularQuestions => 'Soalan Popular';

  @override
  String get howDoICreateDeliveryZone =>
      'Bagaimana saya mencipta zon penghantaran?';

  @override
  String get howDoIAddRider => 'Bagaimana saya menambah rider?';

  @override
  String get canIChangeMyPlanLater => 'Bolehkah saya menukar pelan kemudian?';

  @override
  String get howDoesRouteOptimizationWork =>
      'Bagaimana pengoptimuman laluan berfungsi?';

  @override
  String get whereCanMyCustomersTrackTheir =>
      'Di mana pelanggan saya boleh menjejak pesanan mereka?';

  @override
  String get viewingAllQuestions => 'Memaparkan semua soalan';

  @override
  String get sendingSupportRequestsFromAppNot =>
      'Menghantar permintaan sokongan dari aplikasi belum disambungkan.';

  @override
  String get wereHereHelp2 => 'Kami sedia membantu.';

  @override
  String get getTouch => 'Hubungi kami';

  @override
  String get tellUsAboutIssueOurTeam =>
      'Beritahu kami tentang isu anda dan pasukan kami akan menghubungi anda.';

  @override
  String get issueCategory => 'Kategori Isu';

  @override
  String get selectCategory => 'Pilih kategori';

  @override
  String get subject => 'Subjek';

  @override
  String get brieflyDescribeIssue => 'Terangkan isu anda secara ringkas';

  @override
  String get message => 'Mesej';

  @override
  String get tellUsMoreAboutIssue =>
      'Beritahu kami lebih lanjut tentang isu anda...';

  @override
  String get addScreenshotsOptional => 'Tambah Tangkapan Skrin (Pilihan)';

  @override
  String get pngJpgUp10mbEach => 'PNG, JPG sehingga 10MB setiap satu';

  @override
  String get tapAttachImages => 'Ketik untuk melampirkan imej';

  @override
  String get whereWeWillReply => 'Tempat kami akan membalas anda.';

  @override
  String get contactEmail => 'E-mel Hubungan';

  @override
  String get sendRequest => 'Hantar Permintaan';

  @override
  String get sendingRequest => 'Menghantar permintaan anda';

  @override
  String get supportRequestHasBeenSent =>
      'Permintaan sokongan anda telah dihantar.';

  @override
  String get ourSupportTeamWillGetBack =>
      'ⓘ Pasukan sokongan kami akan menghubungi anda secepat mungkin.';

  @override
  String get trustTransparency => 'Amanah & Ketelusan';

  @override
  String get wereCommittedProtectingDataPrivacy =>
      'Kami komited melindungi data dan privasi anda.';

  @override
  String get termsThatGuideUseCefflo =>
      'Terma yang mengawal penggunaan Cefflo oleh anda.';

  @override
  String get lastUpdated12Sep2026 => 'Kemas kini terakhir: 12 Sep 2026';

  @override
  String get page => 'Dalam halaman ini';

  @override
  String get t1Introduction2InformationWeCollect =>
      '1.  Pengenalan\n2.  Maklumat Yang Kami Kumpul\n3.  Cara Kami Menggunakan Maklumat Anda\n4.  Perkongsian Data\n5.  Keselamatan Data\n6.  Hak Anda\n7.  Kuki dan Teknologi Penjejakan\n8.  Perubahan pada Dasar Ini\n9.  Hubungi Kami';

  @override
  String get t1AcceptanceTerms2AccountResponsibilities =>
      '1.  Penerimaan Terma\n2.  Tanggungjawab Akaun\n3.  Penggunaan Yang Dibenarkan\n4.  Langganan dan Pengebilan\n5.  Harta Intelek\n6.  Ketersediaan Perkhidmatan\n7.  Had Liabiliti\n8.  Perubahan pada Terma Ini\n9.  Hubungi Kami';

  @override
  String get t1Introduction => '1. Pengenalan';

  @override
  String get t1AcceptanceTerms => '1. Penerimaan Terma';

  @override
  String get ceffloWeUsOurValuesPrivacy =>
      'Cefflo (“kami”) menghargai privasi anda. Dasar ini menerangkan cara kami mengumpul, menggunakan, mendedahkan dan melindungi maklumat anda apabila anda menggunakan perkhidmatan kami.';

  @override
  String get byAccessingUsingCeffloAgreeThese =>
      'Dengan mengakses atau menggunakan Cefflo, anda bersetuju dengan terma ini dan akan menggunakan perkhidmatan secara bertanggungjawab mengikut undang-undang yang terpakai.';

  @override
  String get t2InformationWeCollect => '2. Maklumat Yang Kami Kumpul';

  @override
  String get t2AccountResponsibilities => '2. Tanggungjawab Akaun';

  @override
  String get weCollectInformationThatProvideDirectly =>
      'Kami mengumpul maklumat yang anda berikan terus kepada kami, bersama data operasi terhad yang diperlukan untuk menyampaikan dan menambah baik perkhidmatan.';

  @override
  String get responsibleMaintainingAccurateAccountInformationProtecting =>
      'Anda bertanggungjawab memastikan maklumat akaun anda tepat dan melindungi akses ke akaun anda.';

  @override
  String get moreOrdersLessWorkSmootherDelivery =>
      'Lebih banyak pesanan. Kurang kerja. Hari penghantaran yang lebih lancar.';

  @override
  String get ourPurpose => 'Tujuan kami';

  @override
  String get operateTodayGrowTomorrow2 =>
      'Beroperasi Hari Ini. Berkembang Esok.';

  @override
  String get localSameDayDeliveryOperatingSystem =>
      'Sistem operasi penghantaran tempatan pada hari yang sama, dibina untuk perniagaan.';

  @override
  String get appInformation => 'Maklumat aplikasi';

  @override
  String get version => 'Versi';

  @override
  String get privacyPolicy2 => 'Dasar Privasi';

  @override
  String get readPolicy => 'Baca dasar';

  @override
  String get termsService2 => 'Terma Perkhidmatan';

  @override
  String get readTerms => 'Baca terma';

  @override
  String get notificationDeleted => 'Pemberitahuan dipadam';

  @override
  String get undo => 'Buat asal';

  @override
  String get markUnread => 'Tandakan belum dibaca';

  @override
  String get markRead => 'Tandakan sudah dibaca';

  @override
  String get youreAllCaughtUp => 'Tiada pemberitahuan baharu.';

  @override
  String get enterValidEmailAddress => 'Masukkan alamat e-mel yang sah.';

  @override
  String get nameRequired => 'Nama diperlukan.';

  @override
  String get linkCopied => 'Pautan disalin';

  @override
  String get scanJoin => 'Imbas untuk menyertai';

  @override
  String get invitedPersonCanScanCodeOpen =>
      'Orang yang dijemput boleh mengimbas kod ini untuk membuka jemputan.';

  @override
  String get generateInviteLink => 'Jana pautan jemputan';

  @override
  String get copyLink => 'Salin pautan';

  @override
  String get inviteRidersBusiness => 'Jemput rider ke perniagaan anda';

  @override
  String get inviteTeamMember2 => 'Jemput ahli pasukan';

  @override
  String get theyOpenLinkJoinTeamComplete =>
      'Mereka membuka pautan untuk menyertai pasukan anda dan melengkapkan profil, kenderaan dan dokumen mereka.';

  @override
  String get theyOpenLinkHelpRunDeliveries =>
      'Mereka membuka pautan untuk membantu menjalankan penghantaran dan mengurus pesanan.';

  @override
  String get riderName => 'Nama rider';

  @override
  String get operatorText => 'Operator';

  @override
  String get owner => 'Pemilik';

  @override
  String get ownerAccessFullBusinessOwnershipIncluding =>
      'Akses Pemilik ialah pemilikan penuh perniagaan, termasuk pengebilan dan pengurusan pasukan.';

  @override
  String get invitationLink => 'Pautan jemputan';

  @override
  String get showQrCode => 'Tunjukkan kod QR';

  @override
  String get scanOpenInvitation => 'Imbas untuk membuka jemputan';

  @override
  String get linkShownOnlyOnceExpires7 =>
      'Pautan ini dipaparkan sekali sahaja dan tamat tempoh dalam 7 hari. Rider yang dijemput akan muncul dalam senarai Rider anda sebagai Menunggu Semakan setelah mereka melengkapkan pendaftaran.';

  @override
  String get linkShownOnlyOnceExpires72 =>
      'Pautan ini dipaparkan sekali sahaja dan tamat tempoh dalam 7 hari. Ahli pasukan yang dijemput akan muncul dalam senarai Pasukan anda setelah mereka menerima jemputan.';

  @override
  String get backSettings => 'Kembali ke Tetapan';

  @override
  String active2(Object def, Object style) {
    return '$def, $style, aktif';
  }

  @override
  String zoneOrdersRiders(int orders, int riders) {
    return '$orders pesanan · $riders rider';
  }

  @override
  String get perMonth => '/ bulan';

  @override
  String get perYear => '/ tahun';

  @override
  String get roleOwner => 'Pemilik';

  @override
  String get roleOperator => 'Operator';

  @override
  String get tagFood => 'Makanan';

  @override
  String get tagFashion => 'Fesyen';

  @override
  String get tagBeauty => 'Kecantikan';

  @override
  String get tagGifts => 'Hadiah';

  @override
  String get locatingBusinessAddress =>
      'Mencari lokasi alamat perniagaan anda…';

  @override
  String get businessAddressLocated => 'Alamat perniagaan ditemui';

  @override
  String get pickupLocationRequired =>
      'Lokasi pengambilan anda diperlukan. Kami tidak dapat mencari alamat perniagaan anda; pastikan ia lengkap, kemudian cuba lagi.';

  @override
  String get tryLocatingAgain => 'Cuba cari semula';

  @override
  String get helperText => 'Pembantu';

  @override
  String get operatorRoleDescription =>
      'Bantu urus operasi penghantaran harian. Memerlukan akaun Vendor.';

  @override
  String get helperRoleDescription =>
      'Bantu sediakan, bungkus dan serahkan pesanan. Guna aplikasi Cefflo Vendor.';

  @override
  String get ownerCanRunAlone =>
      'Anda boleh menjalankan perniagaan sebagai Pemilik sahaja. Operator dan Pembantu adalah pilihan.';

  @override
  String get helperWorkspaceTitle => 'Pembantu';

  @override
  String get toPrepare => 'Untuk disediakan';

  @override
  String get stagePreparing => 'Sedang disediakan';

  @override
  String get stagePacked => 'Dibungkus';

  @override
  String get stageReady => 'Sedia untuk diambil';

  @override
  String get startPreparing => 'Mula sediakan';

  @override
  String get markPacked => 'Tanda dibungkus';

  @override
  String get markReady => 'Tanda sedia';

  @override
  String get readyForHandover => 'Sedia untuk diserahkan';

  @override
  String handoverTo(String rider) {
    return 'Serahkan kepada $rider';
  }

  @override
  String runStop(String run, String stop) {
    return '$run · hentian $stop';
  }

  @override
  String get noTasksInStage => 'Tiada pesanan di sini.';

  @override
  String get newTasksAppearHere =>
      'Pesanan baharu untuk disediakan akan muncul di sini.';

  @override
  String get stageSorted => 'Diisih';

  @override
  String get markSorted => 'Tanda diisih';

  @override
  String get packingNotConfirmed => 'Pembungkusan belum disahkan';

  @override
  String confirmPackingGroup(String zone, String done, String total) {
    return 'Sahkan pembungkusan · $zone · $done / $total dibungkus';
  }

  @override
  String confirmSortingGroup(String zone, String done, String total) {
    return 'Sahkan pengisihan · $zone · $done / $total diisih';
  }

  @override
  String pickedUpBy(String rider, String time) {
    return 'Diambil • $rider • $time';
  }

  @override
  String get stagePickedUp => 'Diambil';

  @override
  String get noZone => 'Tiada zon';

  @override
  String handoverToProvider(String provider) {
    return 'Serahkan kepada $provider';
  }

  @override
  String get operatorAccess => 'Akses Operator';

  @override
  String get welcomeBack => 'Selamat kembali';

  @override
  String get signInStoreOperations => 'Log masuk ke operasi kedai anda';

  @override
  String get noOperatorAccessYet =>
      'Akaun ini belum ada akses Operator. Terima pautan jemputan daripada pemilik perniagaan, kemudian log masuk dengan alamat e-mel yang menerima jemputan itu.';

  @override
  String get helperAccess => 'Akses Pembantu';

  @override
  String get signInPreparationTasks => 'Log masuk ke tugasan penyediaan anda';

  @override
  String get noHelperAccessYet =>
      'Akaun ini belum ada akses Pembantu. Terima pautan jemputan daripada pemilik perniagaan, kemudian log masuk dengan alamat e-mel yang menerima jemputan itu.';

  @override
  String get hwPreparation => 'Penyediaan';

  @override
  String get hwZones => 'Zon';

  @override
  String get hwPacking => 'Bungkus';

  @override
  String get hwSorting => 'Isih';

  @override
  String get hwMore => 'Lagi';

  @override
  String get hwOrders => 'pesanan';

  @override
  String get hwItems => 'item';

  @override
  String get hwRequiredItems => 'Item Diperlukan';

  @override
  String hwNOrders(int n) {
    return '$n pesanan';
  }

  @override
  String hwNItems(int n) {
    return '$n item';
  }

  @override
  String hwNItem(int n) {
    return '$n item';
  }

  @override
  String get hwPacked => 'dibungkus';

  @override
  String get hwPending => 'Belum';

  @override
  String get hwPackingStatus => 'Membungkus';

  @override
  String get hwPackedStatus => 'Dibungkus';

  @override
  String get hwSortingStatus => 'Mengisih';

  @override
  String get hwSortedStatus => 'Diisih';

  @override
  String get hwReadyStatus => 'Sedia';

  @override
  String get hwSlideConfirmPickup => 'Leret untuk Sahkan Pengambilan';

  @override
  String get hwPickupTime => 'Masa Pengambilan';

  @override
  String get hwReadyForPickup => 'Sedia untuk Diambil';

  @override
  String get hwZoneReady => 'Zon ini sedia untuk diambil oleh rider.';

  @override
  String get hwPickupRider => 'RIDER PENGAMBILAN';

  @override
  String get hwRiderNotAssigned => 'Rider belum ditetapkan';

  @override
  String get hwMotorcycle => 'Motosikal';

  @override
  String get hwCar => 'Kereta';

  @override
  String get hwVan => 'Van';

  @override
  String get hwNoZoneToPack => 'Tiada zon untuk dibungkus sekarang.';

  @override
  String get hwNoZoneToSort => 'Tiada zon untuk diisih sekarang.';

  @override
  String get hwNoWork => 'Tiada kerja penyediaan sekarang.';

  @override
  String get hwPackFirst => 'Sahkan pembungkusan zon ini dahulu.';

  @override
  String get hwExternalProvider => 'Penyedia luar';

  @override
  String get hwPasswordSecurity => 'Kata Laluan & Keselamatan';

  @override
  String get hwNotifNewWork => 'Kerja penyediaan baharu';

  @override
  String get hwNotifNewWorkSub =>
      'Apabila pesanan baharu ditambah ke beban kerja anda.';

  @override
  String get hwNotifChanges => 'Perubahan beban kerja';

  @override
  String get hwNotifChangesSub =>
      'Apabila beban kerja hari ini atau esok dikemas kini.';

  @override
  String ntNewCustomerOrder(Object ref) {
    return 'Pesanan pelanggan baharu $ref';
  }

  @override
  String get ntNewCustomerOrderBody =>
      'Pelanggan membuat pesanan dari halaman pesanan anda.';

  @override
  String ntDeliveryIssue(Object ref) {
    return 'Isu penghantaran pada $ref';
  }

  @override
  String get ntRunDeclined => 'Rider menolak satu run';

  @override
  String get ntRunDeclinedBody =>
      'Tugaskan semula pesanan supaya boleh dihantar.';

  @override
  String get ntRiderJoined => 'Rider menerima jemputan anda';

  @override
  String get ntRiderJoinedBody => 'Semak dan luluskan sebelum menugaskan run.';

  @override
  String get ntRunCompleted => 'Run selesai';

  @override
  String get ntRunCompletedBody => 'Semua hentian dalam run telah selesai.';

  @override
  String get ntJustNow => 'baru sahaja';

  @override
  String ntMinutesAgo(Object n) {
    return '$n min lalu';
  }

  @override
  String ntHoursAgo(Object n) {
    return '$n jam lalu';
  }

  @override
  String get ntPrefLead => 'Terpakai pada akaun anda di semua aplikasi Cefflo.';

  @override
  String get ntPrefEnabled => 'Notifikasi';

  @override
  String get ntPrefEnabledSub =>
      'Tunjukkan makluman semasa Cefflo dibuka. Semuanya tetap disimpan di pusat notifikasi.';

  @override
  String get ntPrefSound => 'Bunyi';

  @override
  String get ntPrefSoundSub => 'Mainkan bunyi bersama makluman.';

  @override
  String get ntPushDeferred =>
      'Makluman semasa aplikasi ditutup belum tersedia.';

  @override
  String get ntCouldNotUpdate =>
      'Tidak dapat mengemas kini notifikasi. Cuba lagi.';

  @override
  String get ntDismiss => 'Tutup';

  @override
  String get linkNoLongerValid => 'Pautan ini tidak lagi sah';

  @override
  String get linkExpiredOrUsedRequestNew =>
      'Pautan telah tamat tempoh atau telah digunakan. Minta e-mel pengesahan baharu, atau pautan tetapan semula kata laluan baharu.';

  @override
  String get sendNewResetLink => 'Hantar pautan tetapan semula baharu';

  @override
  String get supportSendOpensEmailApp =>
      'Hantar membuka app e-mel anda dengan mesej ini kepada support@cefflo.com. Lampirkan tangkapan skrin di sana jika membantu.';

  @override
  String get writeMessageFirst => 'Tulis mesej dahulu.';

  @override
  String get emailApp => 'app e-mel anda';

  @override
  String get otpLead => 'Masukkan kod 6 digit yang kami hantar ke';

  @override
  String get otpVerify => 'Sahkan';

  @override
  String get otpVerifying => 'Mengesahkan…';

  @override
  String get otpNoCode => 'Tidak menerima kod?';

  @override
  String get otpResend => 'Hantar semula kod';

  @override
  String otpResendIn(int seconds) {
    return 'Hantar semula kod dalam ${seconds}s';
  }

  @override
  String otpResent(String email) {
    return 'Kod baharu sedang dihantar ke $email.';
  }

  @override
  String get otpIncorrect =>
      'Kod itu salah atau telah tamat tempoh. Semak digit atau minta kod baharu.';

  @override
  String get otpExpired =>
      'Kod ini telah tamat tempoh. Minta kod baharu untuk teruskan.';

  @override
  String get otpSendNew => 'Hantar kod baharu';

  @override
  String get otpVerifiedLead =>
      'E-mel anda telah disahkan. Anda boleh teruskan.';

  @override
  String get otpContinue => 'Teruskan';

  @override
  String get otpCodeLabel => 'Kod pengesahan 6 digit';

  @override
  String get otpRecoveryTitle => 'Tetapkan semula kata laluan';

  @override
  String get connectedSources => 'Sumber bersambung';

  @override
  String get noConnectedSourcesYet =>
      'Belum ada sumber bersambung. Google Sheets dan fail Drive yang disambung akan dipaparkan di sini.';

  @override
  String get createOrder => 'Cipta pesanan';

  @override
  String get howStepSource => 'Pilih sumber';

  @override
  String get howStepFile => 'Pilih fail';

  @override
  String get howStepMap => 'Padankan lajur';

  @override
  String get howStepImport => 'Import';

  @override
  String get importExcelCsv => 'Excel / CSV';

  @override
  String get importExcelCsvHint => 'Muat naik fail CSV atau Excel (.xlsx)';

  @override
  String get connectGoogle => 'Sambung Google';

  @override
  String get googleConnectPending =>
      'Sambungan Google belum tersedia. Buat masa ini, muat turun helaian sebagai CSV atau .xlsx dan guna Excel / CSV.';

  @override
  String get importReadingFile => 'Membaca fail';

  @override
  String get importReadFailed =>
      'Fail ini tidak dapat dibaca. Guna fail CSV atau .xlsx yang ada baris tajuk.';

  @override
  String get importNoRows =>
      'Tiada baris pesanan ditemui di bawah baris tajuk.';

  @override
  String get importMatchHint =>
      'Kami padankan apa yang boleh. Semak setiap medan dan pilih lajur yang betul.';

  @override
  String get importNotMapped => 'Tidak dipadankan';

  @override
  String get importRequiredTag => 'Wajib';

  @override
  String importMatchRequired(Object fields) {
    return 'Padankan medan wajib: $fields';
  }

  @override
  String get importContinueReview => 'Semak baris';

  @override
  String get importReviewTitle => 'Semakan';

  @override
  String get importRowsDetected => 'Baris dikesan';

  @override
  String get importRowsValid => 'Sedia';

  @override
  String get importRowsInvalid => 'Perlu semakan';

  @override
  String get importMappedFields => 'Medan dipadankan';

  @override
  String importRowMissing(Object row, Object fields) {
    return 'Baris $row: tiada $fields';
  }

  @override
  String get importInvalidNote =>
      'Baris yang perlu semakan tidak akan diimport. Betulkan dalam fail dan import semula.';

  @override
  String importCountOrders(Object count) {
    return 'Import $count pesanan';
  }

  @override
  String get importingOrders => 'Mengimport pesanan';

  @override
  String get importResultDone => 'Import selesai';

  @override
  String get importResultPartial => 'Import separa selesai';

  @override
  String get importResultNone => 'Tiada yang diimport';

  @override
  String importCommittedCount(Object count) {
    return '$count pesanan dicipta';
  }

  @override
  String importRejectedCount(Object count) {
    return '$count baris ditolak oleh Cefflo';
  }

  @override
  String importSkippedCount(Object count) {
    return '$count baris tidak dihantar (perlu semakan)';
  }

  @override
  String importRowReason(Object row, Object reason) {
    return 'Baris $row: $reason';
  }

  @override
  String get importViewOrders => 'Lihat pesanan';

  @override
  String get importAnotherFile => 'Import fail lain';

  @override
  String get importChangeFile => 'Pilih fail lain';

  @override
  String get importBackToMatch => 'Kembali ke padanan';

  @override
  String get importFieldPhone => 'Telefon pelanggan';

  @override
  String get importFieldZone => 'Zon';

  @override
  String get importFieldItems => 'Barang';

  @override
  String get importFieldNotes => 'Nota';

  @override
  String get importKpiCreated => 'Dicipta';

  @override
  String get importKpiRejected => 'Ditolak';

  @override
  String get importKpiNotSent => 'Tidak dihantar';

  @override
  String get appearanceStandard => 'Standard Cefflo';

  @override
  String get appearanceBackground => 'Latar belakang';

  @override
  String get appearancePlain => 'Biasa';

  @override
  String get appearanceGradient => 'Gradien';

  @override
  String get appearanceSaved => 'Penampilan disimpan pada peranti ini.';

  @override
  String get appearanceDeviceOnly =>
      'Hanya untuk peranti ini. Tekan Simpan untuk kekalkan.';

  @override
  String get purple => 'Ungu';

  @override
  String get yourInviteLink => 'Pautan jemputan anda';

  @override
  String get shareMessage => 'Mesej untuk dikongsi';

  @override
  String get shareVia => 'Kongsi melalui';

  @override
  String get copyText => 'Salin';

  @override
  String get messageCopied => 'Mesej disalin';

  @override
  String inviteMsgRider(Object business, Object link) {
    return 'Hai, anda dijemput menyertai $business sebagai rider. Daftar di sini: $link';
  }

  @override
  String inviteMsgTeam(Object business, Object link) {
    return 'Hai, anda dijemput menyertai $business di Cefflo. Buka pautan ini: $link';
  }

  @override
  String get noPendingRidersYet => 'Tiada rider menunggu kelulusan lagi.';

  @override
  String inviteShareMessage(Object business) {
    return 'Hai, anda dijemput menyertai $business. Klik pautan di bawah untuk mendaftar.';
  }

  @override
  String get resetLink => 'Set semula pautan';

  @override
  String get resetLinkTitle => 'Set semula pautan jemputan ini?';

  @override
  String get resetLinkBody =>
      'Pautan semasa terus tidak berfungsi. Kongsi pautan baharu dengan sesiapa yang belum menyertai.';

  @override
  String get linkResetDone => 'Pautan jemputan baharu sudah sedia.';

  @override
  String get inviteLinkPermanent =>
      'Pautan ini kekal sama sehingga anda set semula. Semua yang menyertai perlu menunggu kelulusan anda.';

  @override
  String get moreText => 'Lagi';

  @override
  String get scanToJoinBody =>
      'Imbas dengan kamera telefon untuk membuka jemputan.';

  @override
  String get joinRequests => 'Permintaan menyertai';

  @override
  String get approveText => 'Luluskan';

  @override
  String get requestApproved => 'Permintaan diluluskan.';

  @override
  String get requestRejected => 'Permintaan ditolak.';

  @override
  String get riderApproved => 'Rider diluluskan.';

  @override
  String get riderRejected => 'Rider ditolak.';

  @override
  String joinTitle(Object business) {
    return 'Sertai $business';
  }

  @override
  String get joinBody =>
      'Lengkapkan butiran anda. Bisnes akan meluluskan setiap permintaan sebelum anda mendapat akses.';

  @override
  String get joinSubmit => 'Hantar permintaan';

  @override
  String get joinPendingTitle => 'Menunggu kelulusan';

  @override
  String joinPendingBody(Object business) {
    return 'Permintaan anda telah dihantar kepada $business. Anda akan mendapat akses setelah diluluskan.';
  }

  @override
  String get joinLinkUnavailable =>
      'Pautan jemputan ini tidak lagi sah. Minta pautan baharu daripada bisnes.';

  @override
  String messageCopiedPasteIn(Object app) {
    return 'Mesej disalin. Tampal dalam $app.';
  }

  @override
  String get shareInviteLink => 'Kongsi pautan jemputan';

  @override
  String get operatingAreaLabel => 'Kawasan operasi';

  @override
  String get operatingAreaHint =>
      'Kawasan penghantaran anda, cth. Bangsar, Mont Kiara';

  @override
  String get businessSaved => 'Butiran bisnes disimpan.';

  @override
  String get profileSaved => 'Profil disimpan.';

  @override
  String get photoFormat => 'Pilih foto JPG, PNG atau WebP.';

  @override
  String get photoTooLarge =>
      'Foto ini lebih besar daripada 2 MB. Pilih yang lebih kecil.';

  @override
  String get photoUpdated => 'Foto profil dikemas kini.';

  @override
  String get photoRemoved => 'Foto profil dibuang.';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get changePhoto => 'Tukar foto';

  @override
  String get removePhoto => 'Buang';

  @override
  String get emailChanged => 'Emel log masuk anda telah ditukar.';

  @override
  String get confirmCurrentEmail => 'Sahkan emel semasa anda';

  @override
  String get confirmNewEmail => 'Sahkan emel baharu anda';

  @override
  String get changeEmail => 'Tukar emel';

  @override
  String get changeEmailBody =>
      'Kami akan hantar kod ke emel semasa dan emel baharu anda. Emel anda hanya bertukar selepas kedua-duanya disahkan.';

  @override
  String get newEmail => 'Emel baharu';

  @override
  String get sendCodes => 'Hantar kod';

  @override
  String get sameEmail => 'Ini sudah emel anda.';

  @override
  String get subscriptionManagedTitle => 'Diurus oleh Cefflo';

  @override
  String get subscriptionUnavailable =>
      'Butiran pelan anda belum tersedia dalam app. Hubungi sokongan Cefflo untuk pelan semasa anda.';

  @override
  String get subscriptionStatus => 'Status';

  @override
  String trialEnds(Object date) {
    return 'Percubaan tamat $date';
  }

  @override
  String get planQuestionSubject => 'Soalan langganan';

  @override
  String get emailSupportTeam => 'E-mel pasukan sokongan Cefflo';

  @override
  String get yourStorefront => 'Kedai dalam talian anda';

  @override
  String get storefrontPublished => 'Diterbitkan';

  @override
  String get storefrontUnpublished => 'Belum diterbitkan';

  @override
  String get storefrontUnpublishedNote =>
      'Pelanggan tidak boleh membuka pautan ini sehingga anda menerbitkan kedai anda.';

  @override
  String get storefrontPublishedNote =>
      'Pelanggan boleh membuka pautan ini dan membuat pesanan. Pautan kekal sama, jadi anda boleh letak di laman web atau media sosial.';

  @override
  String get storefrontLink => 'Pautan kedai';

  @override
  String get shareStorefront => 'Kongsi kedai';

  @override
  String storefrontShareMessage(Object business) {
    return 'Pesan daripada $business secara dalam talian:';
  }

  @override
  String get scanToOrder => 'Imbas untuk memesan';

  @override
  String get scanToOrderBody =>
      'Pelanggan imbas dengan kamera telefon untuk membuka kedai anda.';

  @override
  String get storefrontLoadFailed => 'Kedai anda tidak dapat dimuatkan.';

  @override
  String get hoursSaved => 'Waktu operasi disimpan.';

  @override
  String get overnightHint => 'Tutup pada hari berikutnya';

  @override
  String get open24h => 'Buka 24 jam';

  @override
  String get photosMax5 => 'Satu produk boleh ada sehingga 5 foto.';

  @override
  String get photoOver5mb =>
      'Foto ini lebih besar daripada 5 MB selepas dimampatkan. Pilih yang lebih kecil.';

  @override
  String photoN(Object n) {
    return 'Foto $n';
  }

  @override
  String get moveEarlier => 'Alih ke depan';

  @override
  String get moveLater => 'Alih ke belakang';

  @override
  String get photosRules =>
      'Sehingga 5 foto · JPG, PNG atau WebP · 5 MB setiap satu. Foto pertama ialah kulit.';

  @override
  String get subTrial => 'Percubaan';

  @override
  String get subActive => 'Aktif';

  @override
  String get subPastDue => 'Bayaran tertunggak';

  @override
  String get subSuspended => 'Digantung';

  @override
  String get subCancelled => 'Dibatalkan';
}
