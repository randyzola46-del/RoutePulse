// lib/widgets/signature_pad.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';

class SignaturePad extends StatefulWidget {
  final void Function(Uint8List?) onSignatureChanged;

  const SignaturePad({super.key, required this.onSignatureChanged});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2.5,
    penColor: AppColors.textPrimary,
    exportBackgroundColor: AppColors.surface,
  );

  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isEmpty = _controller.isEmpty;
      if (isEmpty != _isEmpty) {
        setState(() => _isEmpty = isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    final signature = await _controller.toPngBytes();
    widget.onSignatureChanged(signature);
  }

  void _clear() {
    _controller.clear();
    widget.onSignatureChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Signature(
            controller: _controller,
            backgroundColor: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            if (!_isEmpty)
              ElevatedButton.icon(
                onPressed: _exportSignature,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Valider la signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusLivree,
                ),
              ),
          ],
        ),
      ],
    );
  }
}