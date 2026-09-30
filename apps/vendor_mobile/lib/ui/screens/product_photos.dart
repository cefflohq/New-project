import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/vendor_repository.dart';
import '../widgets.dart';

import 'package:cefflo_vendor_mobile/l10n/l10n.dart';

/// Up to 5 product photos (Founder, 2026-10-01; 20260930090556). Changes are
/// kept on the form and committed with the product's Save, so a new
/// product can take photos before it exists. JPG / PNG / WebP, 5 MB each,
/// checked here and again by the server.
class ProductPhoto {
  ProductPhoto.existing(this.mediaId, this.status, this.url)
    : bytes = null,
      contentType = null;
  ProductPhoto.local(this.bytes, this.contentType)
    : mediaId = null,
      status = null,
      url = null;
  final String? mediaId, status, url;
  final Uint8List? bytes;
  final String? contentType;
  bool get isNew => mediaId == null;
}

class ProductPhotosController extends ChangeNotifier {
  static const maxPhotos = 5;
  static const maxBytes = 5 * 1024 * 1024;

  final List<ProductPhoto> photos = [];
  final List<String> _removed = [];
  List<String> _loadedOrder = const [];

  Future<void> load(VendorRepository repo, String productId) async {
    final rows = await repo.productMedia(productId);
    photos
      ..clear()
      ..addAll([
        for (final r in rows)
          ProductPhoto.existing(
            r['id'] as String,
            r['status'] as String?,
            await repo.productOriginalUrl(r['original_storage_path'] as String),
          ),
      ]);
    _loadedOrder = [for (final p in photos) p.mediaId!];
    notifyListeners();
  }

  void add(ProductPhoto p) {
    photos.add(p);
    notifyListeners();
  }

  void remove(int i) {
    final p = photos.removeAt(i);
    if (!p.isNew) _removed.add(p.mediaId!);
    notifyListeners();
  }

  void move(int from, int to) {
    if (to < 0 || to >= photos.length) return;
    photos.insert(to, photos.removeAt(from));
    notifyListeners();
  }

  /// Removes, uploads, then applies the on-screen order. Existing photos
  /// keep their media ids; new ones take free positions, then the final
  /// reorder writes positions 1..n exactly as shown.
  Future<void> commit(
    VendorRepository repo, {
    required String businessId,
    required String productId,
  }) async {
    for (final id in _removed) {
      await repo.removeProductPhoto(id);
    }
    _removed.clear();
    final hadNew = photos.any((p) => p.isNew);
    for (final p in photos.where((p) => p.isNew).toList()) {
      await repo.addProductPhoto(
        businessId: businessId,
        productId: productId,
        bytes: p.bytes!,
        contentType: p.contentType!,
      );
    }
    final existingOrder = [
      for (final p in photos.where((p) => !p.isNew)) p.mediaId!,
    ];
    if (!hadNew && _listEq(existingOrder, _loadedOrder)) return;
    // Server ids of the new uploads, in on-screen order: reload and match
    // the remaining (new) rows by their position after the existing ones.
    final rows = await repo.productMedia(productId);
    final serverIds = [for (final r in rows) r['id'] as String];
    final newIds = serverIds
        .where((id) => !existingOrder.contains(id))
        .toList();
    var n = 0;
    final order = [for (final p in photos) p.isNew ? newIds[n++] : p.mediaId!];
    if (!_listEq(order, serverIds)) {
      await repo.reorderProductPhotos(productId, order);
    }
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ProductPhotosField extends StatelessWidget {
  const ProductPhotosField({
    super.key,
    required this.controller,
    this.enabled = true,
  });
  final ProductPhotosController controller;
  final bool enabled;

  static String? _type(XFile f) {
    final n = f.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return f.mimeType;
  }

  Future<void> _add(BuildContext context) async {
    final room = ProductPhotosController.maxPhotos - controller.photos.length;
    if (room <= 0) {
      showCefToast(context, L.photosMax5, error: true);
      return;
    }
    // Resized and compressed on the device before any size check, so a
    // large camera original is not rejected before it is shrunk.
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
      limit: room,
    );
    if (files.isEmpty || !context.mounted) return;
    if (files.length > room) {
      showCefToast(context, L.photosMax5, error: true);
    }
    for (final f in files.take(room)) {
      final type = _type(f);
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(type)) {
        if (context.mounted) showCefToast(context, L.photoFormat, error: true);
        continue;
      }
      final bytes = await f.readAsBytes();
      if (!context.mounted) return;
      if (bytes.length > ProductPhotosController.maxBytes) {
        showCefToast(context, L.photoOver5mb, error: true);
        continue;
      }
      controller.add(ProductPhoto.local(bytes, type));
    }
  }

  void _options(BuildContext context, int i) {
    showListSheet(
      context,
      title: L.photoN(i + 1),
      children: [
        if (i > 0)
          CefListRow(
            title: L.moveEarlier,
            icon: LucideIcons.arrowLeft,
            showChevron: false,
            onTap: () {
              controller.move(i, i - 1);
              Navigator.of(context).pop();
            },
          ),
        if (i < controller.photos.length - 1)
          CefListRow(
            title: L.moveLater,
            icon: LucideIcons.arrowRight,
            showChevron: false,
            onTap: () {
              controller.move(i, i + 1);
              Navigator.of(context).pop();
            },
          ),
        CefListRow(
          title: L.removePhoto,
          icon: LucideIcons.trash2,
          titleColor: context.c.attention,
          showChevron: false,
          onTap: () {
            controller.remove(i);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = context.c;
      final text = Theme.of(context).textTheme;
      final photos = controller.photos;
      Widget tile(Widget child, {VoidCallback? onTap}) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Sizes.cardRadius),
        child: Container(
          width: 76,
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.grouped,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: child,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final (i, p) in photos.indexed)
                tile(
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      if (p.bytes != null)
                        Image.memory(p.bytes!, fit: BoxFit.cover)
                      else if (p.url != null)
                        Image.network(
                          p.url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(LucideIcons.image, color: c.iconColor),
                        )
                      else
                        Icon(LucideIcons.image, color: c.iconColor),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(
                              Sizes.buttonRadius,
                            ),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: text.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _options(context, i),
                ),
              if (photos.length < ProductPhotosController.maxPhotos)
                tile(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imagePlus, size: 24, color: c.iconColor),
                      const SizedBox(height: 2),
                      Text(
                        '${photos.length}/${ProductPhotosController.maxPhotos}',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                  onTap: () => _add(context),
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(L.photosRules, style: text.bodySmall),
        ],
      );
    },
  );
}
