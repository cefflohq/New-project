/// Help Centre questions and answers (Founder 2026-10-16), in English and
/// Bahasa Melayu. Answers describe the app as it is built today.
enum FaqTopic { gettingStarted, orders, zonesDrivers, account }

typedef Faq = ({FaqTopic topic, String q, String a, bool popular});

List<Faq> faqs(String lang) => lang == 'ms' ? _ms : _en;

const List<Faq> _en = [
  (
    topic: FaqTopic.gettingStarted,
    popular: true,
    q: 'How do I set up my business?',
    a: 'After signing up, follow Welcome setup: add your business details and pickup location. You can change them later in More › Business profile.',
  ),
  (
    topic: FaqTopic.orders,
    popular: true,
    q: 'How do I create an order?',
    a: 'Go to Orders and tap +. Choose Manual Entry for one order, or Import Orders to bring in a CSV/Excel file or a Google Sheet link.',
  ),
  (
    topic: FaqTopic.orders,
    popular: false,
    q: 'Can I import from Google Sheets?',
    a: 'Yes. In Import Orders choose Google Sheets and paste the sheet link. Share the sheet as "Anyone with the link can view" first. For Google Drive, choose the file from your phone\'s file picker.',
  ),
  (
    topic: FaqTopic.orders,
    popular: true,
    q: 'What does "No pin" mean on an order?',
    a: 'The customer did not drop a map pin. Directions use the written address instead. You can add a pin in Edit order.',
  ),
  (
    topic: FaqTopic.orders,
    popular: false,
    q: 'How do I report a problem with an order?',
    a: 'Open the order, tap ⋮ at the top right and choose Report issue. The order moves to Issue and appears in Need Attention.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: true,
    q: 'How do I create a delivery zone?',
    a: 'Go to Zones and tap +. Type the area name, pick a suggestion, then check the highlighted area on the map and tap Create Zone.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: false,
    q: 'How do I delete several zones at once?',
    a: 'On Zones tap Select, tick the zones (or Select all), then tap Delete. Zones with orders in progress are kept.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: true,
    q: 'How do I add a driver?',
    a: 'Go to Drivers and tap +. Share your invite link or QR code. The driver joins from the link and waits for your approval.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: false,
    q: 'When can a driver start the pickup checklist?',
    a: 'When the driver has arrived at your pickup location and every order in the run is packed and marked ready.',
  ),
  (
    topic: FaqTopic.account,
    popular: false,
    q: 'How do I change my password?',
    a: 'Go to More › Password and set a new one. You stay signed in on this phone.',
  ),
  (
    topic: FaqTopic.account,
    popular: false,
    q: 'How do I change the app language?',
    a: 'Go to More › Language and choose English or Bahasa Melayu.',
  ),
];

const List<Faq> _ms = [
  (
    topic: FaqTopic.gettingStarted,
    popular: true,
    q: 'Bagaimana saya sediakan bisnes saya?',
    a: 'Selepas daftar, ikut Welcome setup: isi butiran bisnes dan lokasi pickup. Boleh tukar kemudian di More › Business profile.',
  ),
  (
    topic: FaqTopic.orders,
    popular: true,
    q: 'Bagaimana saya buat order?',
    a: 'Pergi ke Orders dan tekan +. Pilih Manual Entry untuk satu order, atau Import Orders untuk fail CSV/Excel atau link Google Sheet.',
  ),
  (
    topic: FaqTopic.orders,
    popular: false,
    q: 'Boleh import dari Google Sheets?',
    a: 'Boleh. Dalam Import Orders pilih Google Sheets dan tampal link sheet. Kongsi sheet sebagai "Sesiapa yang ada link boleh lihat" dahulu. Untuk Google Drive, pilih fail melalui pemilih fail telefon.',
  ),
  (
    topic: FaqTopic.orders,
    popular: true,
    q: 'Apa maksud "No pin" pada order?',
    a: 'Pelanggan tidak letak pin peta. Arah perjalanan guna alamat bertulis. Anda boleh tambah pin di Edit order.',
  ),
  (
    topic: FaqTopic.orders,
    popular: false,
    q: 'Bagaimana lapor masalah order?',
    a: 'Buka order, tekan ⋮ di atas kanan dan pilih Report issue. Order akan pindah ke Issue dan keluar di Need Attention.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: true,
    q: 'Bagaimana buat zon penghantaran?',
    a: 'Pergi ke Zones dan tekan +. Taip nama kawasan, pilih cadangan, semak kawasan di peta dan tekan Create Zone.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: false,
    q: 'Bagaimana padam beberapa zon sekaligus?',
    a: 'Di Zones tekan Select, tanda zon (atau Select all), kemudian tekan Delete. Zon yang ada order sedang berjalan tidak dipadam.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: true,
    q: 'Bagaimana tambah driver?',
    a: 'Pergi ke Drivers dan tekan +. Kongsi link atau kod QR jemputan. Driver sertai melalui link dan menunggu kelulusan anda.',
  ),
  (
    topic: FaqTopic.zonesDrivers,
    popular: false,
    q: 'Bila driver boleh mula senarai semak pickup?',
    a: 'Bila driver sudah sampai di lokasi pickup anda dan semua order dalam run sudah dibungkus dan ditanda siap.',
  ),
  (
    topic: FaqTopic.account,
    popular: false,
    q: 'Bagaimana tukar kata laluan?',
    a: 'Pergi ke More › Password dan tetapkan yang baharu. Anda kekal log masuk di telefon ini.',
  ),
  (
    topic: FaqTopic.account,
    popular: false,
    q: 'Bagaimana tukar bahasa app?',
    a: 'Pergi ke More › Language dan pilih English atau Bahasa Melayu.',
  ),
];
