"""Single source for Cefflo's Privacy Policy and Terms of Service (EN + BM).
Run: python3 shared/legal/build_legal.py  -> writes legal.json and every
surface's generated copy (website, Vendor Web, Vendor & Driver apps), so all
surfaces always show the same text. Founder 2026-10-16."""
import json, os, html
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENTITY = "Cefflo Technologies (PG0592731-P)"
EMAIL = "support@cefflo.com"
UPDATED = {"en": "16 October 2026", "ms": "16 Oktober 2026"}
ADDRESS = {"en": "[business address — to be updated]", "ms": "[alamat perniagaan — akan dikemas kini]"}

PRIVACY = {
"en": [
("Who we are", f"Cefflo is operated by {ENTITY}, {ADDRESS['en']}. For any privacy question or request, email {EMAIL}. This policy covers the Cefflo website, the Cefflo Vendor app and Vendor Web (business owners, operators and helpers), the Cefflo Driver app, Storefront ordering pages, driver invitation pages and customer tracking links."),
("Laws we follow", "We process personal data under Malaysia's Personal Data Protection Act 2010 as amended by the Personal Data Protection (Amendment) Act 2024, including its notice, consent, security, retention, data-integrity, access and data-portability principles. If you are outside Malaysia, you also keep the rights your own country's law gives you, for example the EU/UK GDPR, Singapore's PDPA 2012, Indonesia's Personal Data Protection Law (UU 27/2022), Thailand's PDPA 2019 or the Philippines' Data Privacy Act 2012. Where those laws give you more protection, we apply it to you."),
("Our two roles", "For accounts, team access, subscriptions and the Driver marketplace, Cefflo decides how data is used (data user / controller). For delivery orders, the business you order from decides how your order data is used and Cefflo processes it on that business's behalf (data processor). Each business is responsible for telling its own customers how it uses their data."),
("What we collect", "Business owners, operators and helpers: name, email, phone, sign-in details (including Google sign-in), business details, role and actions taken. Drivers: name, phone, date of birth, address, emergency contact, vehicle type and plate, profile photo, schedule and jobs applied for, live location only while a run is active, proof-of-delivery photos and delivery records. Drivers using Find Jobs: identity card number (stored only as a protected code plus the last 4 digits, never in full), driving licence and vehicle photos. Customers: name, phone, delivery address, map pin and notes, items ordered, proof-of-delivery photo, rating and feedback. Everyone: device and app information needed for sign-in, notifications and security, and records of actions taken in the system. We do not collect biometric data."),
("Why we use it", "To create and secure accounts; to plan, assign and complete deliveries; to show delivery progress to the business and its customer; to verify marketplace Drivers; to send service notifications (including push notifications); to provide support; to prevent fraud and misuse; to meet legal, tax and accounting duties; and to improve Cefflo using aggregated information. We rely on your consent, on performing our contract with you, on our legal obligations and on our legitimate interests in running a safe service."),
("Location data", "The Driver app collects precise location only while a delivery run is active, including when the app is in the background, so the business and its customer can follow the delivery and so the pickup checklist can open when the Driver arrives at the pickup point. Location is not collected when no run is active. You can turn location permission off in your phone settings, but runs cannot be started without it."),
("Camera, photos and notifications", "The apps use the camera only when you choose to: to scan an invitation QR code, to photograph proof of delivery, and to photograph documents for Driver verification. Push notifications are sent through Google Firebase Cloud Messaging and only contain the information needed to tell you about your work; you can turn them off at any time."),
("Who we share it with", "We share data only as needed to run Cefflo: the business you work with or order from and its team; a Driver sees only the stops assigned to them; whoever holds a tracking link sees that order's status. Our service providers: Supabase (database, sign-in and file storage), Vercel (web hosting), Google (sign-in with Google, Maps, Places and Firebase Cloud Messaging). They may only use the data to provide their service to us. We may disclose data where the law requires it. We never sell personal data and we do not use it for third-party advertising."),
("Transfers outside Malaysia", "Our providers may store or process data outside Malaysia (our database is planned to be hosted in Singapore). We transfer data only to providers bound by contract to protect it to a standard comparable to Malaysian law, as permitted by section 129 of the PDPA."),
("How long we keep it", "Accounts: while active and 30 days after closure. Orders and delivery records: 7 years, for tax and accounting duties. Proof-of-delivery photos: 12 months. Driver live location: 30 days. Driver verification documents: while the account is active and 30 days after. Security logs: 12 months. After these periods data is deleted or anonymised."),
("Your rights", f"You may ask to access, correct or delete your personal data, withdraw consent, limit or object to processing, or receive your data in a portable format. Email {EMAIL}; we reply within 21 days. For a delivery order you can also contact the business you ordered from. If you are not satisfied, you may complain to Malaysia's Personal Data Protection Commissioner, or to the authority in your own country."),
("Security and breaches", "Access is restricted by role, documents are kept in private storage, identity numbers are never stored in full, connections are encrypted and administrator access requires two-factor authentication. If a breach is likely to cause significant harm, we notify the Commissioner within 72 hours and affected people without undue delay, as the 2024 amendment requires."),
("Children", "Cefflo is for people aged 18 and above. We do not knowingly collect data from children."),
("Changes", "We will post updates here with a new date and tell account holders in the app about material changes."),
],
"ms": [
("Siapa kami", f"Cefflo dikendalikan oleh {ENTITY}, {ADDRESS['ms']}. Untuk sebarang pertanyaan atau permintaan privasi, emel {EMAIL}. Polisi ini meliputi laman web Cefflo, app Cefflo Vendor dan Vendor Web (pemilik bisnes, operator dan helper), app Cefflo Driver, halaman pesanan Storefront, halaman jemputan driver dan pautan penjejakan pelanggan."),
("Undang-undang yang kami patuhi", "Kami memproses data peribadi di bawah Akta Perlindungan Data Peribadi 2010 Malaysia seperti yang dipinda oleh Akta Perlindungan Data Peribadi (Pindaan) 2024, termasuk prinsip notis, persetujuan, keselamatan, penyimpanan, integriti data, akses dan kemudahalihan data. Jika anda berada di luar Malaysia, anda juga mengekalkan hak yang diberi oleh undang-undang negara anda, contohnya GDPR EU/UK, PDPA 2012 Singapura, Undang-undang Perlindungan Data Peribadi Indonesia (UU 27/2022), PDPA 2019 Thailand atau Data Privacy Act 2012 Filipina. Jika undang-undang itu memberi perlindungan lebih, kami gunakannya untuk anda."),
("Dua peranan kami", "Untuk akaun, akses pasukan, langganan dan pasaran Driver, Cefflo menentukan cara data digunakan (pengguna data / pengawal). Untuk pesanan penghantaran, bisnes tempat anda membuat pesanan menentukan cara data pesanan digunakan dan Cefflo memprosesnya bagi pihak bisnes itu (pemproses data). Setiap bisnes bertanggungjawab memaklumkan pelanggannya sendiri cara data mereka digunakan."),
("Data yang kami kumpul", "Pemilik bisnes, operator dan helper: nama, emel, telefon, butiran log masuk (termasuk log masuk Google), butiran bisnes, peranan dan tindakan yang dibuat. Driver: nama, telefon, tarikh lahir, alamat, kenalan kecemasan, jenis dan plat kenderaan, gambar profil, jadual dan kerja yang dipohon, lokasi langsung hanya semasa run aktif, gambar bukti penghantaran dan rekod penghantaran. Driver yang guna Find Jobs: nombor kad pengenalan (disimpan hanya sebagai kod dilindungi serta 4 digit akhir, tidak pernah penuh), lesen memandu dan gambar kenderaan. Pelanggan: nama, telefon, alamat penghantaran, pin peta dan nota, barang dipesan, gambar bukti penghantaran, penilaian dan maklum balas. Semua: maklumat peranti dan app yang perlu untuk log masuk, notifikasi dan keselamatan, serta rekod tindakan dalam sistem. Kami tidak mengumpul data biometrik."),
("Mengapa kami menggunakannya", "Untuk mencipta dan melindungi akaun; merancang, menugaskan dan menyiapkan penghantaran; menunjukkan kemajuan penghantaran kepada bisnes dan pelanggannya; mengesahkan Driver pasaran; menghantar notifikasi perkhidmatan (termasuk notifikasi push); memberi sokongan; mencegah penipuan dan salah guna; memenuhi kewajipan undang-undang, cukai dan perakaunan; dan menambah baik Cefflo menggunakan maklumat agregat. Kami bergantung pada persetujuan anda, pelaksanaan kontrak dengan anda, kewajipan undang-undang kami dan kepentingan sah kami untuk menjalankan perkhidmatan yang selamat."),
("Data lokasi", "App Driver mengumpul lokasi tepat hanya semasa run penghantaran aktif, termasuk ketika app di latar belakang, supaya bisnes dan pelanggannya boleh mengikuti penghantaran dan supaya senarai semak pickup boleh dibuka apabila Driver tiba di lokasi pickup. Lokasi tidak dikumpul apabila tiada run aktif. Anda boleh mematikan kebenaran lokasi dalam tetapan telefon, tetapi run tidak boleh dimulakan tanpanya."),
("Kamera, gambar dan notifikasi", "App menggunakan kamera hanya apabila anda pilih: untuk mengimbas kod QR jemputan, mengambil gambar bukti penghantaran, dan mengambil gambar dokumen untuk pengesahan Driver. Notifikasi push dihantar melalui Google Firebase Cloud Messaging dan hanya mengandungi maklumat yang perlu tentang kerja anda; anda boleh mematikannya pada bila-bila masa."),
("Dengan siapa kami berkongsi", "Kami berkongsi data hanya setakat perlu untuk menjalankan Cefflo: bisnes tempat anda bekerja atau membuat pesanan serta pasukannya; Driver hanya melihat hentian yang ditugaskan kepadanya; sesiapa yang memegang pautan penjejakan melihat status pesanan itu. Pembekal perkhidmatan kami: Supabase (pangkalan data, log masuk dan storan fail), Vercel (hos web), Google (log masuk Google, Maps, Places dan Firebase Cloud Messaging). Mereka hanya boleh menggunakan data untuk memberi perkhidmatan kepada kami. Kami mungkin mendedahkan data jika dikehendaki undang-undang. Kami tidak pernah menjual data peribadi dan tidak menggunakannya untuk iklan pihak ketiga."),
("Pemindahan ke luar Malaysia", "Pembekal kami mungkin menyimpan atau memproses data di luar Malaysia (pangkalan data kami dirancang dihoskan di Singapura). Kami memindahkan data hanya kepada pembekal yang terikat dengan kontrak untuk melindunginya pada tahap setanding undang-undang Malaysia, seperti yang dibenarkan oleh seksyen 129 PDPA."),
("Berapa lama kami simpan", "Akaun: selagi aktif dan 30 hari selepas ditutup. Pesanan dan rekod penghantaran: 7 tahun, untuk kewajipan cukai dan perakaunan. Gambar bukti penghantaran: 12 bulan. Lokasi langsung Driver: 30 hari. Dokumen pengesahan Driver: selagi akaun aktif dan 30 hari selepas itu. Log keselamatan: 12 bulan. Selepas tempoh ini data dipadam atau dijadikan tanpa nama."),
("Hak anda", f"Anda boleh meminta untuk mengakses, membetulkan atau memadam data peribadi anda, menarik balik persetujuan, menghadkan atau membantah pemprosesan, atau menerima data anda dalam format mudah alih. Emel {EMAIL}; kami membalas dalam 21 hari. Untuk pesanan penghantaran anda juga boleh menghubungi bisnes tempat anda membuat pesanan. Jika tidak berpuas hati, anda boleh membuat aduan kepada Pesuruhjaya Perlindungan Data Peribadi Malaysia, atau pihak berkuasa di negara anda."),
("Keselamatan dan pelanggaran data", "Akses dihadkan mengikut peranan, dokumen disimpan dalam storan peribadi, nombor pengenalan tidak pernah disimpan penuh, sambungan disulitkan dan akses pentadbir memerlukan pengesahan dua faktor. Jika pelanggaran berkemungkinan menyebabkan kemudaratan ketara, kami memaklumkan Pesuruhjaya dalam 72 jam dan individu terjejas tanpa kelewatan, seperti yang dikehendaki oleh pindaan 2024."),
("Kanak-kanak", "Cefflo adalah untuk individu berumur 18 tahun ke atas. Kami tidak mengumpul data kanak-kanak secara sengaja."),
("Perubahan", "Kami akan menyiarkan kemas kini di sini dengan tarikh baharu dan memaklumkan pemegang akaun dalam app tentang perubahan penting."),
],
}

TERMS = {
"en": [
("Agreement", f"These terms are an agreement between you and {ENTITY} (\"Cefflo\"). They apply to everyone who uses Cefflo: business owners, operators and helpers, Drivers, and customers using Storefront pages or tracking links. By creating an account or using Cefflo you agree to them and to our Privacy Policy. You must be at least 18."),
("The service", "Cefflo is software for running local delivery: orders, delivery zones, multi-drop runs, Drivers, customer tracking links and Storefront ordering pages. Cefflo is not a courier, does not deliver goods, is not the seller of any goods and is not a payment processor. Contracts for goods are between the business and its customer."),
("Accounts and security", "Give accurate details and keep your sign-in secure. You are responsible for what happens under your account. Tell us at once at " + EMAIL + " if you suspect unauthorised use."),
("Business owners", "You are responsible for the orders you accept, the goods you sell and deliver, your prices, collecting payment from your customers, food-safety and product rules that apply to you, and your arrangements with your Drivers. You must have a lawful basis to give us your customers' and Drivers' data and must tell them how it is used. You are responsible for the operators and helpers you invite and the access you give them."),
("Operators and helpers", "Operators and helpers act for the business that invited them and only within the access the owner gives. Business and customer data you see is confidential to that business; do not copy or use it for any other purpose. The business owner can change or remove your access at any time."),
("Drivers", "Drivers work for the businesses that invite or hire them and are not employees or agents of Cefflo. Cefflo does not set your pay; pay and working terms are agreed with each business. You must hold a valid driving licence, road tax and insurance for your vehicle, follow road traffic laws, handle goods with care, keep customers' data private and use the app's location sharing during runs. Information you give for verification must be true. Releasing a booked slot or declining a run must be done in the app before the run starts."),
("Customers", "Tracking links and Storefront pages are provided for the business you order from. Questions about goods, prices, payment, refunds or delivery times go to that business. Ratings and feedback must be honest and must not contain abusive content."),
("Plans and fees", "Business plans are priced monthly in Malaysian Ringgit: FREE RM0 (150 completed deliveries), GROW RM99 (500), OPERATE RM199 (1,500), SCALE RM499 (5,000), and ENTERPRISE on custom pricing. Only completed deliveries count toward the limit. Fees exclude taxes where applicable. When online payment is available, plans renew monthly until cancelled; cancellation takes effect at the end of the paid month and fees already paid are not refundable except where the law requires. A Driver vehicle or plate change costs RM50 per change once payments are available."),
("Acceptable use", "Do not use Cefflo for unlawful goods or activities, to harass anyone, to send spam, to upload harmful code, to access data of other businesses or users, to reverse-engineer the service or to overload it. We may remove content or suspend access that breaks these terms or the law."),
("Your content and our service", "You keep ownership of the data you put into Cefflo and give us permission to use it only to provide and improve the service, as set out in the Privacy Policy. Cefflo, its software, brand and design remain ours. Feedback you give may be used freely to improve Cefflo."),
("Availability and changes", "We work to keep Cefflo available and secure but do not guarantee uninterrupted or error-free service. We may change or remove features; we will give reasonable notice of material changes to these terms in the app or by email."),
("Liability", "To the extent the law allows, Cefflo is not liable for indirect or consequential loss, lost profits, lost goods in transit, or acts of businesses, Drivers or customers. Our total liability for any claim is limited to the fees the business paid Cefflo in the 12 months before the claim (or RM100 if no fees were paid). Nothing in these terms limits rights you have under the Consumer Protection Act 1999 or other law that cannot be excluded."),
("Ending use", "You can stop using Cefflo and close your account at any time by contacting " + EMAIL + ". We may suspend or close accounts that break these terms. After closure you may request an export of your data within 30 days; data is then handled as stated in the Privacy Policy."),
("Law and disputes", "These terms are governed by the laws of Malaysia, including the Contracts Act 1950 and the Electronic Commerce Act 2006. We will first try to resolve any dispute with you in good faith; otherwise the courts of Malaysia have jurisdiction. If you use Cefflo outside Malaysia, mandatory consumer protections of your country still apply."),
("Contact", f"{ENTITY}, {ADDRESS['en']}. Email: {EMAIL}."),
],
"ms": [
("Perjanjian", f"Terma ini ialah perjanjian antara anda dan {ENTITY} (\"Cefflo\"). Ia terpakai kepada semua yang menggunakan Cefflo: pemilik bisnes, operator dan helper, Driver, dan pelanggan yang menggunakan halaman Storefront atau pautan penjejakan. Dengan mencipta akaun atau menggunakan Cefflo anda bersetuju dengannya dan dengan Polisi Privasi kami. Anda mesti berumur sekurang-kurangnya 18 tahun."),
("Perkhidmatan", "Cefflo ialah perisian untuk menjalankan penghantaran tempatan: pesanan, zon penghantaran, run berbilang hentian, Driver, pautan penjejakan pelanggan dan halaman pesanan Storefront. Cefflo bukan kurier, tidak menghantar barang, bukan penjual mana-mana barang dan bukan pemproses pembayaran. Kontrak jual beli adalah antara bisnes dan pelanggannya."),
("Akaun dan keselamatan", "Berikan butiran yang tepat dan jaga log masuk anda. Anda bertanggungjawab atas apa yang berlaku di bawah akaun anda. Maklumkan kami segera di " + EMAIL + " jika anda mengesyaki penggunaan tanpa kebenaran."),
("Pemilik bisnes", "Anda bertanggungjawab atas pesanan yang anda terima, barang yang anda jual dan hantar, harga anda, kutipan bayaran daripada pelanggan, peraturan keselamatan makanan dan produk yang terpakai kepada anda, dan urusan anda dengan Driver anda. Anda mesti mempunyai asas sah untuk memberi kami data pelanggan dan Driver anda dan mesti memaklumkan mereka cara ia digunakan. Anda bertanggungjawab atas operator dan helper yang anda jemput dan akses yang anda beri."),
("Operator dan helper", "Operator dan helper bertindak bagi pihak bisnes yang menjemput mereka dan hanya dalam akses yang diberi oleh pemilik. Data bisnes dan pelanggan yang anda lihat adalah sulit kepada bisnes itu; jangan salin atau gunakannya untuk tujuan lain. Pemilik bisnes boleh menukar atau membuang akses anda pada bila-bila masa."),
("Driver", "Driver bekerja untuk bisnes yang menjemput atau mengupah mereka dan bukan pekerja atau ejen Cefflo. Cefflo tidak menetapkan bayaran anda; bayaran dan syarat kerja dipersetujui dengan setiap bisnes. Anda mesti memiliki lesen memandu, cukai jalan dan insurans yang sah untuk kenderaan anda, mematuhi undang-undang jalan raya, mengendalikan barang dengan berhati-hati, menjaga privasi data pelanggan dan menggunakan perkongsian lokasi app semasa run. Maklumat yang anda beri untuk pengesahan mesti benar. Melepaskan slot yang ditempah atau menolak run mesti dibuat dalam app sebelum run bermula."),
("Pelanggan", "Pautan penjejakan dan halaman Storefront disediakan untuk bisnes tempat anda membuat pesanan. Soalan tentang barang, harga, bayaran, bayaran balik atau masa penghantaran hendaklah diajukan kepada bisnes itu. Penilaian dan maklum balas mesti jujur dan tidak mengandungi kandungan kesat."),
("Pelan dan yuran", "Pelan bisnes berharga bulanan dalam Ringgit Malaysia: FREE RM0 (150 penghantaran selesai), GROW RM99 (500), OPERATE RM199 (1,500), SCALE RM499 (5,000), dan ENTERPRISE harga khas. Hanya penghantaran selesai dikira dalam had. Yuran tidak termasuk cukai jika berkenaan. Apabila bayaran dalam talian tersedia, pelan diperbaharui setiap bulan sehingga dibatalkan; pembatalan berkuat kuasa pada akhir bulan berbayar dan yuran yang telah dibayar tidak dikembalikan kecuali jika dikehendaki undang-undang. Pertukaran kenderaan atau plat Driver dikenakan RM50 setiap kali apabila bayaran tersedia."),
("Penggunaan yang dibenarkan", "Jangan gunakan Cefflo untuk barang atau aktiviti yang menyalahi undang-undang, mengganggu sesiapa, menghantar spam, memuat naik kod berbahaya, mengakses data bisnes atau pengguna lain, merungkai perisian atau membebankan perkhidmatan. Kami boleh membuang kandungan atau menggantung akses yang melanggar terma ini atau undang-undang."),
("Kandungan anda dan perkhidmatan kami", "Anda kekal memiliki data yang anda masukkan ke dalam Cefflo dan memberi kami kebenaran menggunakannya hanya untuk menyediakan dan menambah baik perkhidmatan, seperti dalam Polisi Privasi. Cefflo, perisian, jenama dan rekaannya kekal milik kami. Maklum balas anda boleh digunakan secara bebas untuk menambah baik Cefflo."),
("Ketersediaan dan perubahan", "Kami berusaha memastikan Cefflo tersedia dan selamat tetapi tidak menjamin perkhidmatan tanpa gangguan atau ralat. Kami boleh menukar atau membuang ciri; kami akan memberi notis munasabah tentang perubahan penting pada terma ini dalam app atau melalui emel."),
("Liabiliti", "Setakat yang dibenarkan undang-undang, Cefflo tidak bertanggungjawab atas kerugian tidak langsung atau berbangkit, kehilangan keuntungan, kehilangan barang dalam perjalanan, atau perbuatan bisnes, Driver atau pelanggan. Jumlah liabiliti kami bagi sebarang tuntutan terhad kepada yuran yang dibayar oleh bisnes kepada Cefflo dalam 12 bulan sebelum tuntutan (atau RM100 jika tiada yuran dibayar). Tiada apa dalam terma ini mengehadkan hak anda di bawah Akta Pelindungan Pengguna 1999 atau undang-undang lain yang tidak boleh dikecualikan."),
("Menamatkan penggunaan", "Anda boleh berhenti menggunakan Cefflo dan menutup akaun anda pada bila-bila masa dengan menghubungi " + EMAIL + ". Kami boleh menggantung atau menutup akaun yang melanggar terma ini. Selepas ditutup anda boleh meminta eksport data anda dalam tempoh 30 hari; data kemudian dikendalikan seperti dalam Polisi Privasi."),
("Undang-undang dan pertikaian", "Terma ini ditadbir oleh undang-undang Malaysia, termasuk Akta Kontrak 1950 dan Akta Perdagangan Elektronik 2006. Kami akan cuba menyelesaikan sebarang pertikaian dengan anda secara baik terlebih dahulu; jika tidak, mahkamah Malaysia mempunyai bidang kuasa. Jika anda menggunakan Cefflo di luar Malaysia, perlindungan pengguna wajib di negara anda masih terpakai."),
("Hubungi", f"{ENTITY}, {ADDRESS['ms']}. Emel: {EMAIL}."),
],
}

TITLES = {"en": {"privacy": "Privacy Policy", "terms": "Terms of Service", "updated": "Last updated"},
          "ms": {"privacy": "Polisi Privasi", "terms": "Terma Perkhidmatan", "updated": "Kemas kini terakhir"}}

def data():
    return {lang: {"updated": UPDATED[lang], "titles": TITLES[lang],
                   "privacy": [{"h": h, "p": p} for h, p in PRIVACY[lang]],
                   "terms": [{"h": h, "p": p} for h, p in TERMS[lang]]} for lang in ("en", "ms")}

def dart_file():
    d = data()
    out = ["// GENERATED by shared/legal/build_legal.py -- do not edit by hand.",
           "// One Privacy Policy and Terms of Service for every Cefflo surface.", "",
           "typedef LegalSection = ({String h, String p});", "",
           "const legalUpdated = <String, String>" + json.dumps({l: d[l]['updated'] for l in d}, ensure_ascii=False) + ";", ""]
    for doc in ("privacy", "terms"):
        out.append(f"const legal{doc.capitalize()} = <String, List<LegalSection>>{{")
        for l in d:
            out.append(f"  '{l}': [")
            for s in d[l][doc]:
                out.append(f"    (h: {json.dumps(s['h'], ensure_ascii=False).replace('$', chr(92)+'$')}, p: {json.dumps(s['p'], ensure_ascii=False).replace('$', chr(92)+'$')}),")
            out.append("  ],")
        out.append("};\n")
    return "\n".join(out)

def html_page(lang, doc, head):
    d = data()[lang]
    other = "ms" if lang == "en" else "en"
    name = doc if lang == "en" else f"{doc}-ms"
    other_name = doc if other == "en" else f"{doc}-ms"
    title = d["titles"][doc]
    body = "".join(f"<h2>{i}. {html.escape(s['h'])}</h2><p>{html.escape(s['p'])}</p>" for i, s in enumerate(d[doc], 1))
    switch = "Bahasa Melayu" if lang == "en" else "English"
    return (f"<!doctype html><html lang=\"{lang}\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            f"<title>{html.escape(title)} — Cefflo</title>{head}</head><body>"
            f"<header><a href=\"./\"><img src=\"img/logo_mark.png\" alt=\"\">Cefflo</a></header>"
            f"<main><h1>{html.escape(title)}</h1><p class=\"meta\">{d['titles']['updated']}: {d['updated']} · <a href=\"{other_name}.html\">{switch}</a></p>{body}</main>"
            f"<footer><a href=\"./\">Home</a> · <a href=\"privacy{'' if lang=='en' else '-ms'}.html\">{d['titles']['privacy']}</a> · <a href=\"terms{'' if lang=='en' else '-ms'}.html\">{d['titles']['terms']}</a><br>© 2026 {ENTITY}</footer></body></html>")

if __name__ == "__main__":
    d = data()
    json.dump(d, open(os.path.join(ROOT, "shared/legal/legal.json"), "w"), ensure_ascii=False, indent=1)
    for app in ("vendor_mobile", "rider_mobile"):
        open(os.path.join(ROOT, f"apps/{app}/lib/core/legal_content.dart"), "w").write(dart_file())
    open(os.path.join(ROOT, "apps/vendor_web/js/legal.js"), "w").write(
        "// GENERATED by shared/legal/build_legal.py -- do not edit by hand.\nwindow.CEFFLO_LEGAL = " + json.dumps(d, ensure_ascii=False) + ";\n")
    import re
    src = open(os.path.join(ROOT, "shared/legal/page_style.html")).read()
    head = "".join(re.findall(r"<style>.*?</style>", src, re.S)) + "<style>.meta{color:#5b6577;font-size:14px;margin:0 0 24px}.meta a{color:#0057e7}</style>"
    for lang in ("en", "ms"):
        for doc in ("privacy", "terms"):
            name = doc if lang == "en" else f"{doc}-ms"
            open(os.path.join(ROOT, f"website/{name}.html"), "w").write(html_page(lang, doc, head))
    print("ok")
