import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/core.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../cubit/attachments_cubit.dart';
import '../data/attachments_repository.dart';
import 'attachment_viewer_page.dart';

/// Belege im Eintrag: Vorschau-Kacheln, hinzufügen per Kamera, Fotos oder PDF (mit Plus).
/// Neue Einträge zeigen nur den Hinweis – Belege hängen an einem gespeicherten Eintrag.
class EntryAttachments extends StatelessWidget {
  const EntryAttachments({super.key, required this.categoryId, required this.entryId, required this.isNew, required this.canEdit});

  final String categoryId;
  final String entryId;
  final bool isNew;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    if (isNew) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.l10n.attachmentsTitle),
          _Hint(text: context.l10n.attachmentsAfterSave),
        ],
      );
    }
    return BlocProvider(
      create: (_) => lookup<AttachmentsCubit>(param1: AttachmentsArgs(categoryId: categoryId, entryId: entryId))..load(),
      child: _AttachmentsView(canEdit: canEdit),
    );
  }
}

enum _Source { camera, photos, pdf }

class _AttachmentsView extends StatelessWidget {
  const _AttachmentsView({required this.canEdit});

  final bool canEdit;

  static const _tile = 88.0;

  void _onEvent(BuildContext context, AttachmentsState state) {
    final l10n = context.l10n;
    final event = state.event!;
    const warn = CupertinoIcons.exclamationmark_circle_fill;
    switch (event.kind) {
      case AttachmentsEventKind.added:
        AppToast.show(context, l10n.attachmentsAdded, icon: CupertinoIcons.paperclip);
      case AttachmentsEventKind.deleted:
        AppToast.show(context, l10n.attachmentsDeleted, icon: CupertinoIcons.trash_fill);
      case AttachmentsEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: warn);
      case AttachmentsEventKind.rejected:
        AppToast.show(
          context,
          switch (event.problem!) {
            AttachmentProblem.needsPlus => l10n.attachmentsNeedsPlus,
            AttachmentProblem.tooLarge => l10n.attachmentsTooLarge,
            AttachmentProblem.quota => l10n.attachmentsQuota,
            AttachmentProblem.type => l10n.attachmentsType,
            AttachmentProblem.notSynced => l10n.attachmentsNotSynced,
          },
          icon: warn,
        );
    }
  }

  Future<void> _add(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AttachmentsCubit>();
    final plus = context.read<PlusCubit>();
    if (!plus.state.active) {
      await PaywallPage.open(context);
      if (!context.mounted || !plus.state.active) return;
    }
    final source = await AppSheet.show<_Source>(context, title: l10n.attachmentsAdd, child: const _SourcePicker());
    if (source == null) return;
    try {
      final (bytes, mimeType) = switch (source) {
        _Source.pdf => await _pickPdf(),
        _Source.camera => await _pickImage(ImageSource.camera),
        _Source.photos => await _pickImage(ImageSource.gallery),
      };
      if (bytes != null) await cubit.add(bytes, mimeType);
    } catch (_) {
      // Kein Zugriff auf Kamera oder Fotos: das System hat schon gefragt.
      if (context.mounted) AppToast.show(context, l10n.attachmentsNoAccess, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  /// Fotos verkleinert (2048 px, JPEG 80 %) – Belege bleiben lesbar und klein.
  static Future<(Uint8List?, String)> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 80);
    if (file == null) return (null, '');
    return (await file.readAsBytes(), file.mimeType ?? AttachmentsRepository.mimeOf(file.name) ?? 'image/jpeg');
  }

  static Future<(Uint8List?, String)> _pickPdf() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
    if (file == null) return (null, '');
    return (await file.readAsBytes(), AttachmentsRepository.pdf);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return BlocConsumer<AttachmentsCubit, AttachmentsState>(
      listenWhen: (previous, current) => current.event != null && current.event != previous.event,
      listener: _onEvent,
      builder: (context, s) {
        final active = context.select((PlusCubit p) => p.state.active);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.attachmentsTitle, action: canEdit && !s.uploading ? l10n.attachmentsAdd : null, onAction: () => _add(context)),
            if (!s.loaded)
              const Padding(padding: EdgeInsets.all(Spacing.l), child: CupertinoActivityIndicator())
            else if (s.items.isEmpty && !s.uploading)
              _Hint(text: s.failed ? l10n.attachmentsOffline : (active ? l10n.attachmentsEmpty : l10n.attachmentsEmptyPlus), plus: !active && canEdit)
            else
              SizedBox(
                height: _tile,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: Spacing.screen,
                  children: [
                    for (final a in s.items)
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.s),
                        child: AppPressable(
                          onTap: () => AttachmentViewerPage.open(context, a, canDelete: canEdit),
                          child: _Thumb(attachment: a, size: _tile),
                        ),
                      ),
                    if (s.uploading)
                      Container(
                        width: _tile,
                        decoration: ShapeDecoration(color: c.fill, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Radii.m))),
                        child: const CupertinoActivityIndicator(),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.plus = false});

  final String text;
  final bool plus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        onTap: plus ? () => PaywallPage.open(context) : null,
        child: Row(
          spacing: Spacing.m,
          children: [
            AppIconTile(icon: CupertinoIcons.paperclip, color: plus ? c.accent : c.textTertiary),
            Expanded(child: AppText(text, style: (t) => t.footnote, color: c.textSecondary)),
            if (plus) AppChip(label: context.l10n.plusBadge, background: c.accentSoft, foreground: c.accent),
          ],
        ),
      ),
    );
  }
}

/// Vorschau: Foto verkleinert, PDF als Symbol.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment, required this.size});

  final Attachment attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(Radii.m),
      child: Container(
        width: size,
        height: size,
        color: c.fill,
        child: attachment.isPdf
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: Spacing.xxs,
                children: [
                  Icon(CupertinoIcons.doc_text_fill, color: c.danger, size: 30),
                  AppText(context.fileSize(attachment.sizeBytes), style: (t) => t.caption2, color: c.textSecondary),
                ],
              )
            : FutureBuilder(
                future: lookup<AttachmentsRepository>().bytes(attachment),
                builder: (context, snap) => switch (snap.data) {
                  final Uint8List bytes when bytes.isNotEmpty => Image.memory(bytes, fit: BoxFit.cover, cacheWidth: (size * 3).round(), gaplessPlayback: true),
                  _ when snap.hasError => Icon(CupertinoIcons.photo, color: c.textTertiary),
                  _ when snap.connectionState == ConnectionState.done => Icon(CupertinoIcons.photo, color: c.textTertiary),
                  _ => const CupertinoActivityIndicator(),
                },
              ),
      ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: AppListGroup(
        color: c.surfaceRaised,
        children: [
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.camera_fill, color: c.accent),
            title: l10n.attachmentsCamera,
            onTap: () => Navigator.of(context).pop(_Source.camera),
          ),
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.photo_fill, color: c.success),
            title: l10n.attachmentsPhotos,
            onTap: () => Navigator.of(context).pop(_Source.photos),
          ),
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.doc_text_fill, color: c.danger),
            title: l10n.attachmentsPdf,
            onTap: () => Navigator.of(context).pop(_Source.pdf),
          ),
        ],
      ),
    );
  }
}
