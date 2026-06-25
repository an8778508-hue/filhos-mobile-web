import 'dart:io';

import 'package:dartz/dartz.dart' hide State;
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/gallery/model/gallery_image_model.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Teacher-facing screen to upload a photo into a child's album.
///
/// [children] is the roster the teacher can pick from. [repo] is injected so it
/// can be mocked in widget tests. [picker] is overridable for the same reason.
class TeacherGalleryUploadScreen extends StatefulWidget {
  final GalleryRepo repo;
  final List<ChildModel> children;
  final ImagePicker? picker;

  const TeacherGalleryUploadScreen({
    super.key,
    required this.repo,
    required this.children,
    this.picker,
  });

  @override
  State<TeacherGalleryUploadScreen> createState() => _TeacherGalleryUploadScreenState();
}

class _TeacherGalleryUploadScreenState extends State<TeacherGalleryUploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  late ImagePicker _picker;

  ChildModel? _selectedChild;
  String? _pickedImagePath;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.picker ?? ImagePicker();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImagePath = picked.path);
    }
  }

  Future<void> _upload() async {
    final child = _selectedChild;
    final path = _pickedImagePath;
    if (child == null || path == null || _uploading) return;

    setState(() => _uploading = true);

    final Either<Failure, GalleryImageModel> result = await widget.repo.uploadPhoto(
      childId: child.id,
      imagePath: path,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded')),
        );
        setState(() {
          _pickedImagePath = null;
          _captionController.clear();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ChildModel>(
              value: _selectedChild,
              decoration: const InputDecoration(labelText: 'Child'),
              items: widget.children
                  .map((c) => DropdownMenuItem<ChildModel>(
                        value: c,
                        child: Text(c.name ?? 'Child #${c.id}'),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _selectedChild = c),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black26),
                ),
                child: _pickedImagePath == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40),
                            SizedBox(height: 8),
                            Text('Pick a photo'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_pickedImagePath!), fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_pickedImagePath != null && _selectedChild != null && !_uploading) ? _upload : null,
              child: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
