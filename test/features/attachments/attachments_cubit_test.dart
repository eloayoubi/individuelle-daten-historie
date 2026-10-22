import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/attachments/cubit/attachments_cubit.dart';
import 'package:kostenkurve/features/attachments/data/attachments_repository.dart';
import 'package:kostenkurve/features/attachments/data/mock_attachments_repository.dart';

void main() {
  const args = AttachmentsArgs(categoryId: 'c-strom', entryId: 'e-1');
  late MockAttachmentsRepository repo;
  setUp(() => repo = MockAttachmentsRepository());

  test('Typ aus der Dateiendung', () {
    expect(AttachmentsRepository.mimeOf('Rechnung.PDF'), AttachmentsRepository.pdf);
    expect(AttachmentsRepository.mimeOf('IMG_1.jpeg'), 'image/jpeg');
    expect(AttachmentsRepository.mimeOf('zaehler.heic'), 'image/heic');
    expect(AttachmentsRepository.mimeOf('notiz.txt'), isNull);
  });

  test('Prüfung: Typ, Größe, Speicher', () {
    expect(() => AttachmentsRepository.check(size: 10, mimeType: 'text/plain', used: 0), throwsA(isA<AttachmentRejected>().having((e) => e.problem, 'problem', AttachmentProblem.type)));
    expect(
      () => AttachmentsRepository.check(size: AttachmentsRepository.maxBytes + 1, mimeType: 'image/png', used: 0),
      throwsA(isA<AttachmentRejected>().having((e) => e.problem, 'problem', AttachmentProblem.tooLarge)),
    );
    expect(
      () => AttachmentsRepository.check(size: 100, mimeType: 'image/png', used: AttachmentsRepository.quotaBytes - 50),
      throwsA(isA<AttachmentRejected>().having((e) => e.problem, 'problem', AttachmentProblem.quota)),
    );
    AttachmentsRepository.check(size: 100, mimeType: AttachmentsRepository.pdf, used: 0);
  });

  test('hinzufügen, Pfad nach Kategorie/Eintrag, löschen', () async {
    final cubit = AttachmentsCubit(repo, args);
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.items, isEmpty);

    await cubit.add(Uint8List.fromList([1, 2, 3]), 'image/jpeg');
    expect(cubit.state.event?.kind, AttachmentsEventKind.added);
    final a = cubit.state.items.single;
    expect(a.path, matches(RegExp(r'^c-strom/e-1/[0-9a-f-]{36}\.jpg$')));
    expect(a.sizeBytes, 3);
    expect(await repo.bytes(a), [1, 2, 3]);
    expect(await repo.usage(), 3);

    await cubit.delete(a);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.event?.kind, AttachmentsEventKind.deleted);
    expect(await repo.usage(), 0);
    await cubit.close();
  });

  test('falscher Typ wird abgelehnt und gemeldet', () async {
    final cubit = AttachmentsCubit(repo, args);
    await cubit.add(Uint8List(4), 'text/plain');
    expect(cubit.state.event?.kind, AttachmentsEventKind.rejected);
    expect(cubit.state.event?.problem, AttachmentProblem.type);
    expect(cubit.state.uploading, isFalse);
    await cubit.close();
  });
}
