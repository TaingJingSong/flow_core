import 'package:flow_core/flow_core.dart';
import 'package:test/test.dart';

void main() {
  test('FlowId equality', () {
    expect(const FlowId('a'), const FlowId('a'));
    expect(const FlowId('a'), isNot(const FlowId('b')));
  });
}