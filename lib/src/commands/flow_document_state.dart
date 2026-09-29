import '../model/flow_document.dart';
import '../model/flow_id.dart';
import '../model/flow_page.dart';

/// Mutable holder for the current [FlowDocument].
///
/// Commands are the only things allowed to write to [document]. The stack
/// owns a single instance; the controller reads it back.
class FlowDocumentState {
  FlowDocumentState(this.document);

  FlowDocument document;

  FlowPage? page(FlowId pageId) => document.pageById(pageId);
}