import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:gal/gal.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List> _readPhotoBytes(String path) {
    return XFile(path).readAsBytes();
  }

  void _openPhotoViewer(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _PhotoViewerScreen(path: path, readBytes: _readPhotoBytes(path)),
      ),
    );
  }

  bool get _cameraSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _galleryWriteSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _addPhotoToApp(XFile image) async {
    await Hive.box(HiveBoxes.photos).add({
      'path': image.path,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<bool> _saveToPhoneGalleryIfNeeded(XFile image) async {
    if (!_galleryWriteSupported) return true;

    try {
      await Gal.putImage(image.path, album: 'Detailing Pro');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _capturePhoto(BuildContext context) async {
    if (!_cameraSupported) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.photosCameraUnsupported)));
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      await _addPhotoToApp(image);
      final gallerySaved = await _saveToPhoneGalleryIfNeeded(image);

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gallerySaved
                ? l10n.photosAddedAndSaved
                : l10n.photosGallerySaveFailed,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorMessage(e.toString()))));
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      await _addPhotoToApp(image);

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.photosAddedFromGallery)));
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorMessage(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photosBox = Hive.box(HiveBoxes.photos);
    final settingsBox = Hive.box(HiveBoxes.settings);
    final businessMode = BusinessMode.fromStorage(
      settingsBox.get('businessMode')?.toString(),
    );
    final appRole = AppRole.fromStorage(
      settingsBox.get('appRole')?.toString(),
      mode: businessMode,
    );
    final canDeletePhoto = appRole.canManageBusinessData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.navPhotos),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: l10n.photosAddFromGallery,
            onPressed: () => _pickFromGallery(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            tooltip: l10n.photosTakePhoto,
            onPressed: () => _capturePhoto(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: photosBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_search,
                      size: 80,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.photosEmpty,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _capturePhoto(context),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(l10n.photosAdd),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickFromGallery(context),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.photosAddFromGallery),
                    ),
                  ],
                ),
              ),
            );
          }

          final items =
              box.keys.map((key) {
                final raw = box.get(key);
                if (raw is! Map) {
                  return {'key': key, 'path': '-', 'createdAt': 0};
                }
                return {
                  'key': key,
                  'path': raw['path']?.toString() ?? '-',
                  'createdAt': (raw['createdAt'] as num?)?.toInt() ?? 0,
                };
              }).toList()..sort(
                (a, b) =>
                    (b['createdAt'] as int).compareTo(a['createdAt'] as int),
              );

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final key = item['key'];
              final path = item['path'] as String;

              return _PhotoTile(
                path: path,
                readBytes: _readPhotoBytes(path),
                onOpen: () => _openPhotoViewer(context, path),
                canDelete: canDeletePhoto,
                onDelete: () {
                  if (!canDeletePhoto) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.photosDeleteDenied)),
                    );
                    return;
                  }
                  box.delete(key);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String path;
  final Future<Uint8List> readBytes;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.path,
    required this.readBytes,
    required this.canDelete,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: readBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined, size: 42),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      path.split('\\').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: canDelete ? onDelete : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final String path;
  final Future<Uint8List> readBytes;

  const _PhotoViewerScreen({required this.path, required this.readBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          path.split('\\').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: readBytes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.memory(snapshot.data!),
              );
            }

            if (snapshot.hasError) {
              return const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 72,
              );
            }

            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
