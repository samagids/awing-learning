import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// v1.22.0 (Session 66) — reusable image attachment control for the
/// contribution flow. Any screen that submits a contribution
/// (contribute_screen, study_set_record_screen, wrong_translation_reporter)
/// can drop this in and get:
///
///   • "Take photo" (camera) + "Choose photo" (gallery) buttons when no
///     image is attached yet
///   • Thumbnail preview + "Change" + "Remove" buttons when an image is
///     attached
///
/// The compression happens right here in the picker via image_picker's
/// built-in `maxWidth` / `imageQuality` params, so downstream code
/// (ContributionService.submit) sees a small JPEG (~50-300 KB) and can
/// base64-inline it without worrying about the 1.5 MB pre-encode cap.
///
/// Callback contract: `onChanged(String? newPath)` — null when user
/// removes the image, non-null when they pick / take one.
class ImageAttachmentPicker extends StatefulWidget {
  /// Current attached image path, or null.
  final String? imagePath;

  /// Fired whenever the attachment changes. Null = removed.
  final ValueChanged<String?> onChanged;

  /// Optional label shown above the picker. Defaults to "Add a photo".
  final String label;

  /// Optional hint shown below the label to explain what to shoot.
  final String? hint;

  /// Accent color for buttons. Defaults to the app's primary green.
  final Color accentColor;

  const ImageAttachmentPicker({
    super.key,
    required this.imagePath,
    required this.onChanged,
    this.label = 'Add a photo',
    this.hint,
    this.accentColor = const Color(0xFF006432),
  });

  @override
  State<ImageAttachmentPicker> createState() =>
      _ImageAttachmentPickerState();
}

class _ImageAttachmentPickerState extends State<ImageAttachmentPicker> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // image_picker compresses at pick time — no separate `image`
      // dependency needed. maxWidth 1024 = the SDXL asset pipeline's
      // 4x native resolution, plenty for classroom vocabulary cards.
      // imageQuality 80 = visually indistinguishable from lossless
      // for real-world photos, ~5-10x smaller than 100.
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        widget.onChanged(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text(
          'The photo will not be sent with your contribution.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.image_outlined, color: widget.accentColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasImage) ...[
                const Spacer(),
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ],
            ],
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.hint!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (hasImage)
            _buildAttachedRow(imagePath)
          else
            _buildPickButtons(),
        ],
      ),
    );
  }

  Widget _buildAttachedRow(String path) {
    final file = File(path);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 84,
              height: 84,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo attached',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: file.length(),
                builder: (_, snap) {
                  final bytes = snap.data ?? 0;
                  final kb = (bytes / 1024).round();
                  return Text(
                    kb > 0 ? '$kb KB' : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _confirmRemove,
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 18),
                    label: Text(
                      'Remove',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _pick(ImageSource.camera),
          icon: const Icon(Icons.photo_camera),
          label: const Text('Take photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose photo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.accentColor,
            side: BorderSide(color: widget.accentColor),
          ),
        ),
      ],
    );
  }
}
