/// Friendly text for the backend's error messages (Founder 2026-10-15: no
/// raw server English on any screen, in either language).
///
/// The database raises short technical English (`zone name already exists`).
/// [serverMessage] turns each known one into a sentence in the app's
/// language; an unknown one gets the generic [fallback]. Keep the table in
/// step with `raise exception` in supabase/migrations: the test lists every
/// message the migrations raise.
library;

class _M {
  const _M(this.pattern, this.en, this.ms);
  final String pattern;
  final String en, ms;
}

/// Shown when a message is not in the table.
const fallback = (
  en: 'Something went wrong. Please try again.',
  ms: 'Ada masalah. Sila cuba lagi.',
);

const _invalidInput = (
  en: 'Some details are not valid. Check and try again.',
  ms: 'Ada maklumat yang tidak sah. Semak dan cuba lagi.',
);
const _settingInvalid = (
  en: 'That setting is not valid. Check and try again.',
  ms: 'Tetapan itu tidak sah. Semak dan cuba lagi.',
);
const _notFound = (
  en: 'This item is no longer available. Refresh and try again.',
  ms: 'Item ini tiada lagi. Muat semula dan cuba lagi.',
);
const _mediaState = (
  en: 'This file is not ready yet. Try again shortly.',
  ms: 'Fail ini belum sedia. Cuba lagi sebentar lagi.',
);

_M _same(String p, ({String en, String ms}) t) => _M(p, t.en, t.ms);

/// `%` in a pattern matches any value the database fills in.
final List<_M> _table = [
  // Access
  const _M('authentication required', 'Please sign in again.', 'Sila log masuk semula.'),
  const _M('not signed in', 'Please sign in again.', 'Sila log masuk semula.'),
  const _M('forbidden', 'You do not have access to do this.', 'Anda tiada akses untuk melakukan ini.'),
  const _M('invalid access', 'You do not have access to do this.', 'Anda tiada akses untuk melakukan ini.'),
  const _M('rate limited', 'Too many attempts. Wait a moment and try again.', 'Terlalu banyak cubaan. Tunggu sebentar dan cuba lagi.'),
  const _M('too many requests', 'Too many attempts. Wait a moment and try again.', 'Terlalu banyak cubaan. Tunggu sebentar dan cuba lagi.'),
  const _M('idempotency key conflict', 'This was already sent. Refresh to see the latest.', 'Ini sudah dihantar. Muat semula untuk lihat yang terkini.'),
  _same('idempotency key required', fallback),
  _same('invalid idempotency key', fallback),
  // Business, team, invitations
  const _M('business not found', 'Business not found.', 'Perniagaan tidak dijumpai.'),
  const _M('vendor not found', 'Business not found.', 'Perniagaan tidak dijumpai.'),
  const _M('business profile incomplete', 'Complete your Business profile first.', 'Lengkapkan profil Perniagaan anda dahulu.'),
  const _M('business must retain at least one active owner', 'A business needs at least one active owner.', 'Perniagaan mesti ada sekurang-kurangnya seorang pemilik aktif.'),
  const _M('not a team member', 'This person is not on your team.', 'Orang ini bukan ahli pasukan anda.'),
  const _M('only operators and helpers are invited as team members', 'Only Operators and Helpers can be invited to the team.', 'Hanya Operator dan Pembantu boleh dijemput ke pasukan.'),
  const _M('only operators are invited as team members', 'Only Operators can be invited to the team.', 'Hanya Operator boleh dijemput ke pasukan.'),
  const _M('team members cannot apply to their own business', 'Team members cannot apply to their own business.', 'Ahli pasukan tidak boleh memohon kepada perniagaan sendiri.'),
  const _M('helper not available', 'This Helper is not available.', 'Pembantu ini tidak tersedia.'),
  const _M('invalid invitation', 'This invitation is not valid.', 'Jemputan ini tidak sah.'),
  const _M('invitation not available', 'This invitation is no longer available.', 'Jemputan ini tiada lagi.'),
  const _M('invitation expired', 'This invitation has expired. Ask for a new one.', 'Jemputan ini sudah tamat tempoh. Minta jemputan baharu.'),
  const _M('email mismatch', 'This invitation was sent to a different email.', 'Jemputan ini dihantar ke e-mel lain.'),
  // Drivers
  const _M('invalid rider', 'This driver is not available.', 'Pemandu ini tidak tersedia.'),
  const _M('invalid rider context', 'This driver is not available.', 'Pemandu ini tidak tersedia.'),
  const _M('rider not pending', 'This driver was already reviewed.', 'Pemandu ini sudah disemak.'),
  const _M('already picked up: use recover delivery instead', 'This order was already picked up. Use Recover delivery instead.', 'Order ini sudah diambil. Guna Pulihkan penghantaran.'),
  const _M('cannot restrict a platform admin', 'A platform admin account cannot be restricted.', 'Akaun admin platform tidak boleh disekat.'),
  const _M('case not found', 'This case was not found.', 'Kes ini tidak dijumpai.'),
  const _M('case not open', 'This case is not open.', 'Kes ini tidak dibuka.'),
  const _M('contact required', 'Add an email or phone number so we can reply.', 'Tambah emel atau nombor telefon supaya kami boleh membalas.'),
  const _M('day not in this booking', 'That day is not part of this booking.', 'Hari itu bukan sebahagian daripada tempahan ini.'),
  const _M('driver not found', 'This driver was not found.', 'Pemandu ini tidak dijumpai.'),
  const _M('explain the decision', 'Explain the decision (at least 10 characters).', 'Terangkan keputusan (sekurang-kurangnya 10 huruf).'),
  const _M('invalid token', 'This link is not valid.', 'Pautan ini tidak sah.'),
  const _M('invalid tracking token', 'This tracking link is not valid or has expired.', 'Pautan tracking ini tidak sah atau sudah tamat.'),
  const _M('no account to restrict', 'There is no account to restrict for this choice.', 'Tiada akaun untuk disekat bagi pilihan ini.'),
  const _M('no driver on this complaint', 'This complaint has no driver.', 'Aduan ini tiada pemandu.'),
  const _M('not found', 'Not found.', 'Tidak dijumpai.'),
  const _M('not found or already decided', 'Not found, or already decided.', 'Tidak dijumpai, atau sudah diputuskan.'),
  const _M('not found or already lifted', 'Not found, or already lifted.', 'Tidak dijumpai, atau sudah ditarik balik.'),
  const _M('not found or already resolved', 'Not found, or already resolved.', 'Tidak dijumpai, atau sudah diselesaikan.'),
  const _M('not pending', 'This is no longer waiting for review.', 'Ini tidak lagi menunggu semakan.'),
  const _M('note required', 'Write a note first.', 'Tulis nota dahulu.'),
  const _M('reason required', 'Write a reason first.', 'Tulis sebab dahulu.'),
  const _M('business not verified', 'This business can take orders after Cefflo verifies it. Owners: More → Business verification.', 'Bisnes ini boleh menerima order selepas disahkan oleh Cefflo. Pemilik: More → Pengesahan bisnes.'),
  const _M('up to 3 photos', 'You can add up to 3 photos.', 'Anda boleh tambah sehingga 3 gambar.'),
  const _M('platform admins cannot delete their account here', 'A Cefflo admin account cannot be deleted from the app.', 'Akaun admin Cefflo tidak boleh dipadam dari app.'),
  const _M('account not found', 'No account uses that email.', 'Tiada akaun menggunakan emel itu.'),
  const _M('user is banned', 'This account is suspended after a complaint review. Email support@cefflo.com if you think this is a mistake.', 'Akaun ini digantung selepas semakan aduan. Emel support@cefflo.com jika anda rasa ini satu kesilapan.'),
  const _M('complaint closed', 'This complaint is already closed.', 'Aduan ini sudah ditutup.'),
  const _M('reply required', 'Write your side first.', 'Tulis penjelasan anda dahulu.'),
  const _M('up to 5 photos', 'You can add up to 5 photos.', 'Anda boleh tambah sehingga 5 gambar.'),
  const _M('invalid photo', 'One of the photos could not be used. Try again.', 'Salah satu gambar tidak dapat digunakan. Cuba lagi.'),
  const _M('too many complaints for this order', 'This order has already been reported.', 'Order ini sudah dilaporkan.'),
  const _M('business already verified', 'Your business is already verified.', 'Bisnes anda sudah disahkan.'),
  const _M('invalid document', 'A document could not be used. Add it again.', 'Satu dokumen tidak dapat digunakan. Tambah semula.'),
  const _M('driver documents not submitted yet', 'This driver has not uploaded their licence and vehicle yet.', 'Pemandu ini belum memuat naik lesen dan kenderaan.'),
  const _M('rider has active work', 'This driver still has active deliveries. Reassign or finish them first.', 'Pemandu ini masih ada penghantaran aktif. Tukar pemandu atau selesaikan dahulu.'),
  const _M('no drivers selected', 'Choose at least one driver.', 'Pilih sekurang-kurangnya seorang pemandu.'),
  const _M('complete your driver details first', 'Complete your driver details first.', 'Lengkapkan butiran pemandu anda dahulu.'),
  const _M('choose your vehicle first', 'Choose your vehicle first.', 'Pilih kenderaan anda dahulu.'),
  const _M('vehicle is required', 'Choose your vehicle.', 'Pilih kenderaan anda.'),
  const _M('invalid vehicle type', 'Choose a valid vehicle type.', 'Pilih jenis kenderaan yang sah.'),
  const _M('invalid plate', 'Enter a valid plate number.', 'Masukkan nombor plat yang sah.'),
  const _M('vehicle photo not uploaded', 'Upload a photo of your vehicle.', 'Muat naik gambar kenderaan anda.'),
  const _M('vehicle change requires payment', 'Changing your vehicle needs a payment first.', 'Pertukaran kenderaan memerlukan bayaran dahulu.'),
  const _M('finish your active deliveries before changing vehicle', 'Finish your active deliveries before changing vehicle.', 'Selesaikan penghantaran aktif sebelum menukar kenderaan.'),
  const _M('driver reach must be 1-15 km', 'Driver reach must be 1 to 15 km.', 'Jangkauan pemandu mestilah 1 hingga 15 km.'),
  const _M('drops per run must be 1-50', 'Drops per run must be 1 to 50.', 'Hantaran setiap larian mestilah 1 hingga 50.'),
  const _M('phone already used by another driver of a business', 'This phone number is already used by another driver.', 'Nombor telefon ini sudah digunakan oleh pemandu lain.'),
  const _M('this identity is already linked to a different Rider profile', 'This identity is already linked to another driver profile.', 'Identiti ini sudah dipautkan kepada profil pemandu lain.'),
  const _M('marketplace verification required', 'Verify your identity first to apply for jobs.', 'Sahkan identiti anda dahulu untuk memohon kerja.'),
  // Identity and licence
  const _M('invalid IC number', 'Enter a valid IC number.', 'Masukkan nombor IC yang sah.'),
  const _M('IC already registered to another account', 'This IC is already registered to another account.', 'IC ini sudah didaftarkan pada akaun lain.'),
  _same('IC key not configured', fallback),
  const _M('a verified identity cannot be replaced; contact Cefflo support', 'A verified identity cannot be changed. Contact Cefflo support.', 'Identiti yang disahkan tidak boleh ditukar. Hubungi sokongan Cefflo.'),
  const _M('a verified identity cannot be replaced; contact the business', 'A verified identity cannot be changed. Contact the business.', 'Identiti yang disahkan tidak boleh ditukar. Hubungi perniagaan.'),
  const _M('driver has not submitted a licence', 'This driver has not submitted a licence.', 'Pemandu ini belum menghantar lesen.'),
  const _M('driver licence not verified', 'The driver licence is not verified yet.', 'Lesen pemandu belum disahkan.'),
  const _M('licence not found', 'Licence not found.', 'Lesen tidak dijumpai.'),
  const _M('licence front and back photos required', 'Add photos of the front and back of the licence.', 'Tambah gambar depan dan belakang lesen.'),
  const _M('licence photo not uploaded', 'Upload a photo of the licence.', 'Muat naik gambar lesen.'),
  const _M('licence photos not uploaded', 'Upload photos of the licence.', 'Muat naik gambar lesen.'),
  const _M('invalid licence photo', 'That licence photo could not be used. Try another.', 'Gambar lesen itu tidak boleh digunakan. Cuba yang lain.'),
  const _M('invalid licence photos', 'Those licence photos could not be used. Try again.', 'Gambar lesen itu tidak boleh digunakan. Cuba lagi.'),
  const _M('verification already decided', 'This verification was already reviewed.', 'Pengesahan ini sudah disemak.'),
  const _M('verification not found', 'Verification not found.', 'Pengesahan tidak dijumpai.'),
  // Orders
  const _M('order not found', 'Order not found.', 'Pesanan tidak dijumpai.'),
  const _M('order cancelled', 'This order was cancelled.', 'Pesanan ini telah dibatalkan.'),
  const _M('order already approved', 'This order was already approved.', 'Pesanan ini sudah diluluskan.'),
  const _M('order already closed', 'This order is already closed.', 'Pesanan ini sudah ditutup.'),
  const _M('order already dispatched', 'This order is already out for delivery.', 'Pesanan ini sudah dalam penghantaran.'),
  const _M('order not approved', 'Approve this order first.', 'Luluskan pesanan ini dahulu.'),
  const _M('order not in needs review state', 'This order no longer needs review.', 'Pesanan ini tidak perlu disemak lagi.'),
  const _M('order not in this run', 'This order is not in this run.', 'Pesanan ini bukan dalam larian ini.'),
  const _M('orders no longer eligible', 'Some orders changed. Refresh and try again.', 'Sesetengah pesanan telah berubah. Muat semula dan cuba lagi.'),
  const _M('no orders selected', 'Choose at least one order.', 'Pilih sekurang-kurangnya satu pesanan.'),
  const _M('no orders in this group', 'There are no orders in this group.', 'Tiada pesanan dalam kumpulan ini.'),
  const _M('duplicate order ids', 'The same order was chosen twice.', 'Pesanan yang sama dipilih dua kali.'),
  const _M('no rows to import', 'The file has no orders to import.', 'Fail ini tiada pesanan untuk diimport.'),
  const _M('malformed order item', 'An order item is not valid. Check the items.', 'Ada item pesanan yang tidak sah. Semak item.'),
  const _M('invalid item list', 'The item list is not valid. Check the items.', 'Senarai item tidak sah. Semak item.'),
  const _M('invalid quantity', 'Enter a valid quantity.', 'Masukkan kuantiti yang sah.'),
  const _M('invalid customer name', "Enter the customer's name.", 'Masukkan nama pelanggan.'),
  const _M('invalid customer phone', 'Enter a valid customer phone number.', 'Masukkan nombor telefon pelanggan yang sah.'),
  const _M('invalid delivery address', 'Enter a valid delivery address.', 'Masukkan alamat penghantaran yang sah.'),
  const _M('invalid delivery notes', 'The delivery notes are too long or not valid.', 'Nota penghantaran terlalu panjang atau tidak sah.'),
  const _M('name and phone are required', 'Enter a name and phone number.', 'Masukkan nama dan nombor telefon.'),
  const _M('name is required', 'Enter a name.', 'Masukkan nama.'),
  const _M('phone is required', 'Enter a phone number.', 'Masukkan nombor telefon.'),
  const _M('invalid phone', 'Enter a valid phone number.', 'Masukkan nombor telefon yang sah.'),
  const _M('invalid email', 'Enter a valid email.', 'Masukkan e-mel yang sah.'),
  const _M('phone already on file for this business', 'This phone number is already saved for your business.', 'Nombor telefon ini sudah disimpan untuk perniagaan anda.'),
  const _M('pickup time is required', 'Choose a pickup time.', 'Pilih masa ambil.'),
  const _M('invalid transition % -> issue', 'This order can no longer be reported.', 'Pesanan ini tidak boleh dilaporkan lagi.'),
  const _M('invalid transition % -> %', 'This order has moved on. Refresh to see the latest.', 'Pesanan ini sudah berubah. Muat semula untuk lihat yang terkini.'),
  const _M('invalid preparation transition % -> %', 'This order has moved on. Refresh to see the latest.', 'Pesanan ini sudah berubah. Muat semula untuk lihat yang terkini.'),
  const _M('invalid status', 'This order has moved on. Refresh to see the latest.', 'Pesanan ini sudah berubah. Muat semula untuk lihat yang terkini.'),
  const _M('invalid or unavailable order page', 'This order page is not available.', 'Halaman pesanan ini tidak tersedia.'),
  const _M('order page already exists', 'An order page already exists.', 'Halaman pesanan sudah wujud.'),
  const _M('minimum RM3.00 per drop', 'The minimum is RM3.00 per drop.', 'Minimum ialah RM3.00 setiap hantaran.'),
  // Runs, preparation, pickup
  const _M('session not open', 'This run is no longer open.', 'Larian ini tidak dibuka lagi.'),
  const _M('invalid session', 'This run is not available.', 'Larian ini tidak tersedia.'),
  const _M('no assignments in this run', 'This run has no orders.', 'Larian ini tiada pesanan.'),
  const _M('assignment not accepted', 'Accept the run first.', 'Terima larian dahulu.'),
  const _M('assignment not pending', 'This run was already answered.', 'Larian ini sudah dijawab.'),
  const _M('unsettled assignments remain', 'Some orders in this run are not finished yet.', 'Sesetengah pesanan dalam larian ini belum selesai.'),
  const _M('reassignment not allowed after pickup', 'Orders cannot be moved to another driver after pickup.', 'Pesanan tidak boleh ditukar kepada pemandu lain selepas diambil.'),
  const _M('delivery plan locked: sorting has started', 'The plan is locked because sorting has started.', 'Pelan dikunci kerana penyusunan sudah bermula.'),
  const _M('delivery plan locked: use Replace Rider for the whole Run', 'The plan is locked. Use Replace Driver for the whole run.', 'Pelan dikunci. Guna Tukar Pemandu untuk keseluruhan larian.'),
  const _M('vehicle/capacity incompatible: call check_run_vehicle_capacity for details before overriding', "These orders do not fit this driver's vehicle.", 'Pesanan ini tidak muat dalam kenderaan pemandu ini.'),
  const _M('capacity override must be positive', 'Enter a capacity above zero.', 'Masukkan kapasiti melebihi sifar.'),
  const _M('max_active_orders must be positive', 'Enter a number above zero.', 'Masukkan nombor melebihi sifar.'),
  const _M('sequence locked', 'The stop order is already locked.', 'Susunan hentian sudah dikunci.'),
  const _M('sequence not locked', 'Confirm the stop order first.', 'Sahkan susunan hentian dahulu.'),
  const _M('sequence not ready', 'The stop order is not ready yet.', 'Susunan hentian belum sedia.'),
  const _M('invalid sequence set', 'The stop order changed. Refresh and try again.', 'Susunan hentian telah berubah. Muat semula dan cuba lagi.'),
  const _M('sorting requires a run', 'Waiting for a run before sorting.', 'Menunggu larian sebelum menyusun.'),
  const _M('sorting incomplete: % / % sorted', 'Sort every order first.', 'Susun setiap pesanan dahulu.'),
  const _M('packing incomplete: % / % packed', 'Pack every order first.', 'Bungkus setiap pesanan dahulu.'),
  const _M('packing not confirmed', 'Confirm packing first.', 'Sahkan pembungkusan dahulu.'),
  const _M('ready requires sorting confirmation', 'Confirm sorting first.', 'Sahkan penyusunan dahulu.'),
  const _M('not ready for pickup: % / % ready', 'Not every order is ready for pickup yet.', 'Belum semua pesanan sedia untuk diambil.'),
  const _M('not ready for pickup', 'This order is not ready for pickup yet.', 'Pesanan ini belum sedia untuk diambil.'),
  const _M('pickup incomplete', 'Pick up every order first.', 'Ambil setiap pesanan dahulu.'),
  const _M('pickup already started: use delivery recovery', 'Pickup has started. Use delivery recovery instead.', 'Pengambilan sudah bermula. Guna pemulihan penghantaran.'),
  const _M('already handed over', 'This was already handed over.', 'Ini sudah diserahkan.'),
  const _M('no orders to hand over', 'There are no orders to hand over.', 'Tiada pesanan untuk diserahkan.'),
  const _M('complete earlier stop first', 'Complete the earlier stop first.', 'Selesaikan hentian sebelumnya dahulu.'),
  const _M('arrival and POD required', 'Mark arrival and add proof of delivery first.', 'Tandakan ketibaan dan tambah bukti penghantaran dahulu.'),
  const _M('delivery stop not found', 'Delivery stop not found.', 'Hentian penghantaran tidak dijumpai.'),
  const _M('delivery not in a recoverable state (%)', 'This delivery cannot be recovered now.', 'Penghantaran ini tidak boleh dipulihkan sekarang.'),
  const _M('no active assignment to recover from', 'There is nothing to recover.', 'Tiada apa untuk dipulihkan.'),
  const _M('no orders to recover in this run', 'There are no orders to recover in this run.', 'Tiada pesanan untuk dipulihkan dalam larian ini.'),
  const _M('recovery reason required', 'Choose a reason.', 'Pilih sebab.'),
  const _M('reason is required', 'Choose a reason.', 'Pilih sebab.'),
  const _M('run is not outsourced', 'This run is not outsourced.', 'Larian ini bukan diluar sumber.'),
  const _M('task not available', 'This task is no longer available.', 'Tugasan ini tiada lagi.'),
  const _M('unresolved is the default pre-attempt state, not a settable result', 'Choose a delivery result.', 'Pilih keputusan penghantaran.'),
  // Proof of delivery, tracking, rating
  const _M('POD object not found', 'The proof of delivery photo was not uploaded. Try again.', 'Gambar bukti penghantaran tidak dimuat naik. Cuba lagi.'),
  const _M('POD path does not match this delivery', 'The proof of delivery photo was not uploaded. Try again.', 'Gambar bukti penghantaran tidak dimuat naik. Cuba lagi.'),
  const _M('invalid POD path', 'The proof of delivery photo was not uploaded. Try again.', 'Gambar bukti penghantaran tidak dimuat naik. Cuba lagi.'),
  const _M('tracking token not found', 'This tracking link is not valid.', 'Pautan penjejakan ini tidak sah.'),
  const _M('invalid tracking token or delivery incomplete', 'This delivery is not complete yet.', 'Penghantaran ini belum selesai.'),
  const _M('rating already submitted', 'You already rated this delivery.', 'Anda sudah menilai penghantaran ini.'),
  const _M('invalid rating', 'Choose a rating.', 'Pilih penilaian.'),
  // Zones and locations
  const _M('invalid zone', 'This zone is not available.', 'Zon ini tidak tersedia.'),
  const _M('invalid zone name', 'Enter a valid zone name.', 'Masukkan nama zon yang sah.'),
  const _M('zone name already exists', 'A zone with this name already exists.', 'Zon dengan nama ini sudah wujud.'),
  const _M('zone has orders in progress', 'This zone still has orders in progress.', 'Zon ini masih ada pesanan yang sedang berjalan.'),
  const _M('invalid zone boundary', 'Draw a valid zone boundary.', 'Lukis sempadan zon yang sah.'),
  const _M('origin and radius are all required to configure a service area', 'Set a starting point and radius for the service area.', 'Tetapkan titik mula dan jejari untuk kawasan servis.'),
  const _M('radius must be 5, 10, 20, 30 or 50 km', 'Choose a radius of 5, 10, 20, 30 or 50 km.', 'Pilih jejari 5, 10, 20, 30 atau 50 km.'),
  const _M('radius must be positive', 'Enter a radius above zero.', 'Masukkan jejari melebihi sifar.'),
  const _M('location required', 'Set a location first.', 'Tetapkan lokasi dahulu.'),
  const _M('invalid location', 'Set a valid location.', 'Tetapkan lokasi yang sah.'),
  const _M('coordinates required', 'Set a location first.', 'Tetapkan lokasi dahulu.'),
  const _M('both coordinates required', 'Set a location first.', 'Tetapkan lokasi dahulu.'),
  const _M('resolved requires both coordinates', 'Set a location first.', 'Tetapkan lokasi dahulu.'),
  const _M('coordinates out of range', 'That location is not valid.', 'Lokasi itu tidak sah.'),
  const _M('pin outside Malaysia', 'The pin must be in Malaysia.', 'Pin mesti berada di Malaysia.'),
  _same('% must not carry coordinates', _invalidInput),
  // Jobs and openings
  const _M('opening not found', 'This opening is no longer available.', 'Kekosongan ini tiada lagi.'),
  const _M('opening not available', 'This opening is no longer available.', 'Kekosongan ini tiada lagi.'),
  const _M('already requested', 'You already applied.', 'Anda sudah memohon.'),
  const _M('request already decided', 'This request was already answered.', 'Permohonan ini sudah dijawab.'),
  const _M('request not found', 'This request is no longer available.', 'Permohonan ini tiada lagi.'),
  const _M('exactly 7 days required', 'Set all 7 days.', 'Tetapkan kesemua 7 hari.'),
  const _M('invalid weekday', 'Choose a valid day.', 'Pilih hari yang sah.'),
  const _M('title is required', 'Enter a title.', 'Masukkan tajuk.'),
  const _M('message is required', 'Enter a message.', 'Masukkan mesej.'),
  // Products and storefront
  const _M('product not available', 'This product is no longer available.', 'Produk ini tiada lagi.'),
  const _M('invalid product name', 'Enter a valid product name.', 'Masukkan nama produk yang sah.'),
  const _M('invalid price', 'Enter a valid price.', 'Masukkan harga yang sah.'),
  const _M('invalid description', 'The description is too long or not valid.', 'Penerangan terlalu panjang atau tidak sah.'),
  const _M('a product can have at most 5 photos', 'A product can have up to 5 photos.', 'Produk boleh ada sehingga 5 gambar.'),
  const _M('reorder must list every active photo of the product once', 'The photos changed. Refresh and try again.', 'Gambar telah berubah. Muat semula dan cuba lagi.'),
  const _M('category already exists', 'A category with this name already exists.', 'Kategori dengan nama ini sudah wujud.'),
  const _M('category contains products', 'Move or remove the products in this category first.', 'Pindah atau buang produk dalam kategori ini dahulu.'),
  const _M('invalid category name', 'Enter a valid category name.', 'Masukkan nama kategori yang sah.'),
  const _M('invalid category', 'Choose a valid category.', 'Pilih kategori yang sah.'),
  const _M('invalid category order', 'The categories changed. Refresh and try again.', 'Kategori telah berubah. Muat semula dan cuba lagi.'),
  const _M('invalid product order', 'The products changed. Refresh and try again.', 'Produk telah berubah. Muat semula dan cuba lagi.'),
  const _M('storefront not found', 'Storefront not found.', 'Kedai dalam talian tidak dijumpai.'),
  const _M('invalid or unavailable storefront', 'This storefront is not available.', 'Kedai dalam talian ini tidak tersedia.'),
  const _M('slug not available', 'This link name is taken. Try another.', 'Nama pautan ini sudah diambil. Cuba yang lain.'),
  const _M('invalid tagline', 'The tagline is too long or not valid.', 'Slogan terlalu panjang atau tidak sah.'),
  const _M('invalid logo image', 'That logo could not be used. Try another image.', 'Logo itu tidak boleh digunakan. Cuba gambar lain.'),
  const _M('invalid hero image', 'That image could not be used. Try another.', 'Gambar itu tidak boleh digunakan. Cuba yang lain.'),
  _same('invalid theme key %', _settingInvalid),
  _same('invalid theme value %', _settingInvalid),
  _same('invalid theme', _settingInvalid),
  _same('invalid style', _settingInvalid),
  _same('invalid accent', _settingInvalid),
  _same('invalid background', _settingInvalid),
  _same('invalid colour', _settingInvalid),
  _same('invalid font', _settingInvalid),
  _same('invalid position', _settingInvalid),
  // Media
  _same('media not found', _notFound),
  _same('original upload not found', _mediaState),
  _same('display upload not found', _mediaState),
  _same('prepared asset not found', _mediaState),
  _same('no prepared asset to approve', _mediaState),
  _same('media is not awaiting display', _mediaState),
  _same('media is not failed', _mediaState),
  _same('media is not in a failed state', _mediaState),
  _same('media is not processing', _mediaState),
  _same('media is not queued', _mediaState),
  _same('media is not ready for approval', _mediaState),
  const _M('media id already used', 'This file was already uploaded.', 'Fail ini sudah dimuat naik.'),
  _same('invalid media id', _invalidInput),
  _same('invalid asset path', _invalidInput),
  const _M('invalid content type', 'This file type is not supported.', 'Jenis fail ini tidak disokong.'),
  // Integrations and subscription
  const _M('invalid plan', 'Choose a valid plan.', 'Pilih pelan yang sah.'),
  const _M('provider required', 'Choose a provider.', 'Pilih pembekal.'),
  const _M('invalid provider', 'Choose a valid provider.', 'Pilih pembekal yang sah.'),
  const _M('invalid shop domain', 'Enter a valid shop address.', 'Masukkan alamat kedai yang sah.'),
  const _M('invalid store url', 'Enter a valid store link.', 'Masukkan pautan kedai yang sah.'),
  const _M('invalid site url', 'Enter a valid website link.', 'Masukkan pautan laman web yang sah.'),
  const _M('invalid base url', 'Enter a valid link.', 'Masukkan pautan yang sah.'),
  const _M('invalid endpoint', 'Enter a valid link.', 'Masukkan pautan yang sah.'),
  const _M('invalid webhook secret', 'The connection key is not valid.', 'Kunci sambungan tidak sah.'),
  const _M('invalid keys', 'The connection keys are not valid.', 'Kunci sambungan tidak sah.'),
  const _M('too many active keys', 'Too many active keys. Remove one first.', 'Terlalu banyak kunci aktif. Buang satu dahulu.'),
  // Admin / internal (should not reach users; still friendly)
  _same('announcement not found', _notFound),
  _same('maintenance window not found or already ended', _notFound),
  _same('invalid app', _invalidInput),
  _same('invalid audience', _invalidInput),
  _same('invalid decision', _invalidInput),
  _same('invalid policy', _invalidInput),
  _same('invalid severity', _invalidInput),
  _same('flag key is required', _invalidInput),
  _same('rollback condition is required', _invalidInput),
  _same('scope is required', _invalidInput),
];

final _compiled = [
  for (final m in _table)
    (
      RegExp(
        '^${m.pattern.split('%').map(RegExp.escape).join('.+')}\$',
        caseSensitive: false,
      ),
      m,
    ),
];

/// Every pattern in the table (for the coverage test).
List<String> get knownPatterns => [for (final m in _table) m.pattern];

/// The friendly sentence for [raw] in [languageCode] ('en' / 'ms'), or null
/// when [raw] is not a known backend message.
String? knownServerMessage(String raw, String languageCode) {
  final text = raw.trim();
  for (final (re, m) in _compiled) {
    if (re.hasMatch(text)) return languageCode == 'ms' ? m.ms : m.en;
  }
  return null;
}

/// The friendly sentence for [raw]; the generic [fallback] when unknown.
String serverMessage(String raw, String languageCode) =>
    knownServerMessage(raw, languageCode) ??
    (languageCode == 'ms' ? fallback.ms : fallback.en);
