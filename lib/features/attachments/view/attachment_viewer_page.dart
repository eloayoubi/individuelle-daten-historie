import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/core.dart';
import '../cubit/attachments_cubit.dart';
import '../data/attachments_repository.dart';

/// Beleg ansehen: Foto mit Zoom, PDF über das Teilen-Sheet (Vorschau, In Dateien sichern).
class AttachmentViewerPage extends StatelessWidget {
  const AttachmentViewerPage({super.key, required this.attachment, required this.canDelete});

  final Attachment attachment;
  final bool canDelete;

  /// Mit dem Cubit der Liste, damit Löschen dort ankommt.
  static Future<void> open(BuildContext context, Attachment attachment, {required bool canDelete}) {
    final cubit = context.read<AttachmentsCubit>();
    return Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => BlocProvider.value(value: cubit, child: AttachmentViewerPage(attachment: attachment, canDelete: canDelete)),
      ),
    );
  }

  Future<void> _share(BuildContext context, Uint8List bytes) {
    final name = attachment.path.split('/').last;
    return AppShare.files(context, [XFile.fromData(bytes, mimeType: attachment.mimeType, name: name)]);
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AttachmentsCubit>();
    final ok = await AppDialog.confirm(context, title: l10n.attachmentsDeleteTitle, message: l10n.attachmentsDeleteBody, confirmLabel: l10n.actionDelete, destructive: true);
    if (!ok || !context.mounted) return;
    await cubit.delete(attachment);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: lookup<AttachmentsRepository>().bytes(attachment),
          builder: (context, snap) {
            final bytes = snap.data;
            return Column(
              children: [
                AppHeader(
                  title: attachment.isPdf ? l10n.attachmentsPdfTitle : l10n.attachmentsPhotoTitle,
                  overline: context.shortDate(attachment.createdAt),
                  onBack: () => Navigator.of(context).pop(),
                  actions: [
                    if (bytes != null)
                      Builder(
                        builder: (context) => AppIconButton(icon: CupertinoIcons.share, semanticLabel: l10n.attachmentsShare, onPressed: () => _share(context, bytes)),
                      ),
                    if (canDelete) AppIconButton(icon: CupertinoIcons.trash, semanticLabel: l10n.actionDelete, foreground: c.danger, onPressed: () => _delete(context)),
                  ],
                ),
                Expanded(
                  child: switch (bytes) {
                    _ when snap.hasError => Center(child: AppText(l10n.attachmentsOffline, style: (t) => t.subheadline, color: c.textSecondary)),
                    null => const Center(child: CupertinoActivityIndicator()),
                    final data when attachment.isPdf => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: Spacing.m,
                        children: [
                          Icon(CupertinoIcons.doc_text_fill, color: c.danger, size: 72),
                          AppText(context.fileSize(attachment.sizeBytes), style: (t) => t.subheadline, color: c.textSecondary),
                          Builder(
                            builder: (context) => AppButton(label: l10n.attachmentsOpenPdf, icon: CupertinoIcons.share, expand: false, onPressed: () => _share(context, data)),
                          ),
                        ],
                      ),
                    ),
                    final data => InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(data, fit: BoxFit.contain))),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
