import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  group('FlowDocument', () {
    test('empty creates one page', () {
      final doc = FlowDocument.empty();
      expect(doc.pages, hasLength(1));
      expect(doc.schemaVersion, FlowDocument.currentSchemaVersion);
    });

    test('pageById', () {
      final doc = FlowDocument.empty();
      final firstId = doc.pages.first.id;
      expect(doc.pageById(firstId), isNotNull);
      expect(doc.pageById(const FlowId('missing')), isNull);
    });

    test('equality', () {
      final a = FlowDocument.empty(id: const FlowId('d'));
      final b = FlowDocument.empty(id: const FlowId('d'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}