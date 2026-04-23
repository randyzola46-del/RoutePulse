// lib/widgets/verification_livraison_sheet.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/livraison.dart';
import '../models/preuve_livraison.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'signature_pad.dart';
import 'photo_picker_sheet.dart';

class VerificationLivraisonSheet extends StatefulWidget {
  final Livraison livraison;
  final VoidCallback? onValidated;

  const VerificationLivraisonSheet({
    super.key,
    required this.livraison,
    this.onValidated,
  });

  @override
  State<VerificationLivraisonSheet> createState() => _VerificationLivraisonSheetState();
}

class _VerificationLivraisonSheetState extends State<VerificationLivraisonSheet> {
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  int _nbColisVerifies = 0;
  File? _photo;
  Uint8List? _signature;
  String? _commentaire;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nbColisVerifies = widget.livraison.nbColis;
  }

  Future<String> _getPreuvesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final preuvesDir = Directory('${appDir.path}/preuves');
    if (!await preuvesDir.exists()) {
      await preuvesDir.create(recursive: true);
    }
    return preuvesDir.path;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_photo == null && _signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez fournir une photo ou une signature'),
          backgroundColor: AppColors.statusAnnulee,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoPath;
      if (_photo != null) {
        final preuvesDir = await _getPreuvesDirectory();
        final fileName = 'preuve_${widget.livraison.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoPath = '$preuvesDir/$fileName';

        // Copier la photo vers le dossier de l'application
        await _photo!.copy(photoPath);
      }

      final preuve = PreuveLivraison(
        id: _uuid.v4(),
        livraisonId: widget.livraison.id,
        timestamp: DateTime.now(),
        photoPath: photoPath,
        signatureBytes: _signature,
        nbColisVerifies: _nbColisVerifies,
        commentaire: _commentaire,
      );

      await DatabaseService().insertPreuve(preuve);

      if (mounted) {
        widget.onValidated?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison validée avec succès !'),
            backgroundColor: AppColors.statusLivree,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.statusAnnulee,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoPickerSheet(
        onPhotoSelected: (photo) {
          setState(() => _photo = photo);
        },
      ),
    );
  }

  void _removePhoto() {
    setState(() => _photo = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusLivree.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.statusLivree,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validation livraison',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      Text(
                        widget.livraison.nomClient,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre de colis vérifiés
            const Text(
              'NOMBRE DE COLIS',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _nbColisVerifies > 0
                        ? () => setState(() => _nbColisVerifies--)
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    color: AppColors.coral,
                  ),
                  Expanded(
                    child: Text(
                      '$_nbColisVerifies / ${widget.livraison.nbColis}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nbColisVerifies < widget.livraison.nbColis
                        ? () => setState(() => _nbColisVerifies++)
                        : null,
                    icon: const Icon(Icons.add, size: 20),
                    color: AppColors.coral,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Photo
            const Text(
              'PREUVE PHOTO',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (_photo == null)
              GestureDetector(
                onTap: _showPhotoPicker,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _photo!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: _showPhotoPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Reprendre', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Signature
            const Text(
              'SIGNATURE CLIENT',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SignaturePad(
              onSignatureChanged: (sig) => setState(() => _signature = sig),
            ),

            const SizedBox(height: 20),

            // Commentaire
            TextFormField(
              maxLines: 2,
              onChanged: (value) => _commentaire = value,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Informations supplémentaires...',
                prefixIcon: Icon(Icons.comment_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de validation
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusLivree,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text('Valider la livraison'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}