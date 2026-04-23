// lib/widgets/photo_picker_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import 'camera_widget.dart';

class PhotoPickerSheet extends StatelessWidget {
  final void Function(File?) onPhotoSelected;

  const PhotoPickerSheet({super.key, required this.onPhotoSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Icon(Icons.camera_alt, size: 48, color: AppColors.coral),
                SizedBox(height: 12),
                Text(
                  'Prendre une photo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Cadrez les colis et prenez une photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: CameraWidget(
              onPhotoCaptured: (photo) {
                if (photo != null) {
                  onPhotoSelected(photo);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.textMuted),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}