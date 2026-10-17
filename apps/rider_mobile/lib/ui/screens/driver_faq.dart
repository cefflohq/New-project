import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets.dart';

import 'package:cefflo_rider_mobile/l10n/l10n.dart';

/// Driver Help answers (Founder 2026-10-17): each Help & Support topic
/// opens its questions and answers; "Still need help?" goes on to Contact
/// Support. English and Malay, following the app language.
typedef _QA = (String q, String a);

const _faq = <String, List<List<_QA>>>{
  // [topic index] -> [en, ms]
  'en': [
    [
      (
        'How do I start a run?',
        'Open Runs, choose today\'s run and tap Start. Location must be on while a run is active.',
      ),
      (
        'When does the pickup checklist open?',
        'When you are within 200 m of the pickup point and every order in the run is packed.',
      ),
      (
        'How do I confirm a delivery?',
        'At the stop, take the proof-of-delivery photo and slide Complete. The customer sees it on their tracking page.',
      ),
    ],
    [
      (
        'The customer is not there',
        'Call or WhatsApp the customer from the stop. If you still cannot deliver, use Report issue and choose the reason.',
      ),
      (
        'The customer wants another time',
        'Report issue → Customer rescheduled. The business plans it again.',
      ),
      (
        'The item is damaged',
        'Report issue with a photo before leaving the pickup. If it happened on the way, tell the business straight away.',
      ),
    ],
    [
      (
        'Which documents do I need?',
        'Your driving licence (front and back) and a photo of your vehicle with the plate clear. Take them with the camera in the app.',
      ),
      (
        'Who can see my IC and licence?',
        'Nobody, not even the business. They stay sealed and open only for a police or court case, and you are told if that happens.',
      ),
      (
        'How do I change my vehicle or plate?',
        'Profile → Vehicle Details. A change of vehicle or plate has a change fee.',
      ),
    ],
    [
      (
        'How do I change my name or phone?',
        'Profile → Edit. Your email is your sign-in and changes in Security.',
      ),
      (
        'I work for more than one business',
        'Each business invites you. Switch between them on Home; each sees only its own runs.',
      ),
      (
        'How do I delete my account?',
        'Profile → Delete account. You are signed out at once; your details are erased after 30 days.',
      ),
    ],
  ],
  'ms': [
    [
      (
        'Bagaimana nak mula run?',
        'Buka Runs, pilih run hari ini dan tekan Mula. Lokasi mesti hidup semasa run aktif.',
      ),
      (
        'Bila senarai semak pickup dibuka?',
        'Bila anda dalam 200 m dari tempat pickup dan semua order dalam run sudah dibungkus.',
      ),
      (
        'Bagaimana nak sahkan penghantaran?',
        'Di stop, ambil gambar bukti penghantaran dan leret Selesai. Customer nampak di halaman tracking.',
      ),
    ],
    [
      (
        'Customer tiada di tempat',
        'Telefon atau WhatsApp customer dari stop. Jika masih tidak boleh hantar, guna Laporkan isu dan pilih sebab.',
      ),
      (
        'Customer mahu masa lain',
        'Laporkan isu → Customer tukar masa. Bisnes akan rancang semula.',
      ),
      (
        'Barang rosak',
        'Laporkan isu dengan gambar sebelum meninggalkan pickup. Jika berlaku dalam perjalanan, maklumkan bisnes segera.',
      ),
    ],
    [
      (
        'Dokumen apa yang diperlukan?',
        'Lesen memandu (depan dan belakang) dan gambar kenderaan dengan plat jelas. Ambil dengan kamera dalam app.',
      ),
      (
        'Siapa boleh lihat IC dan lesen saya?',
        'Tiada sesiapa, termasuk bisnes. Ia dimeterai dan hanya dibuka untuk kes polis atau mahkamah, dan anda akan dimaklumkan.',
      ),
      (
        'Bagaimana nak tukar kenderaan atau plat?',
        'Profil → Butiran Kenderaan. Tukar kenderaan atau plat dikenakan yuran.',
      ),
    ],
    [
      (
        'Bagaimana nak tukar nama atau telefon?',
        'Profil → Edit. Emel ialah log masuk anda dan ditukar di Keselamatan.',
      ),
      (
        'Saya bekerja dengan lebih dari satu bisnes',
        'Setiap bisnes menjemput anda. Tukar antara mereka di Home; setiap bisnes hanya nampak run sendiri.',
      ),
      (
        'Bagaimana nak padam akaun?',
        'Profil → Padam akaun. Anda terus dilog keluar; butiran dipadam selepas 30 hari.',
      ),
    ],
  ],
};

/// Shows the answers for Help topic [index] ([title] as the heading).
Future<void> showDriverFaq(
  BuildContext context, {
  required int index,
  required String title,
  required VoidCallback onContact,
}) {
  final list = (_faq[L.localeName == 'ms' ? 'ms' : 'en']!)[index];
  return showCeffloSheet<void>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.gutter, 0, Gap.gutter, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 6),
          Text(title, style: context.t.titleLarge),
          const SizedBox(height: Gap.md),
          for (final (q, a) in list)
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: Gap.md),
                expandedAlignment: Alignment.centerLeft,
                title: Text(q, style: context.t.titleSmall),
                children: [Text(a, style: context.t.bodyMedium)],
              ),
            ),
          const SizedBox(height: Gap.md),
          CeffloSecondaryButton(
            L.needMoreHelp,
            pill: false,
            onTap: () {
              Navigator.of(context).pop();
              onContact();
            },
          ),
        ],
      ),
    ),
  );
}
