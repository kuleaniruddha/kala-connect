import '../models/craft_draft.dart';
import 'cloud_intelligence_service.dart';
import 'draft_store.dart';
import 'edge_pipeline_service.dart';
import 'marketplace_gateway.dart';

/// Coordinates the resilient scan-to-market journey. The draft is saved first,
/// then each network-dependent stage can be retried by a connectivity worker.
class ListingOrchestratorService {
  ListingOrchestratorService({
    required EdgePipelineService edgePipeline,
    required DraftStore drafts,
    required CloudIntelligenceService intelligence,
    required MarketplaceGateway marketplace,
  })  : _edgePipeline = edgePipeline,
        _drafts = drafts,
        _intelligence = intelligence,
        _marketplace = marketplace;

  final EdgePipelineService _edgePipeline;
  final DraftStore _drafts;
  final CloudIntelligenceService _intelligence;
  final MarketplaceGateway _marketplace;

  /// Captures foreground and local model labels. This method is intentionally
  /// independent of connectivity; it is the only required step for saving work.
  Future<CraftDraft> createLocalDraft(String draftId) async {
    final detections = await _edgePipeline.analyseCurrentFrame();
    final imagePath = await _edgePipeline.cropForeground();
    final tags = detections
        .expand((item) => <String>[item.label, item.material])
        .toSet()
        .toList(growable: false);
    final confidence = detections.isEmpty
        ? 0.0
        : detections.map((item) => item.confidence).reduce((a, b) => a + b) /
            detections.length;
    final draft = CraftDraft(
      id: draftId,
      createdAt: DateTime.now().toUtc(),
      imagePath: imagePath,
      tags: tags,
      confidence: confidence,
      syncState: DraftSyncState.local,
    );
    await _drafts.save(draft);
    return draft;
  }

  /// Enriches through the cloud LLM and then delegates channel publication to
  /// Spring Boot. Any exception leaves the previously stored local draft intact.
  Future<void> enrichAndPublish(CraftDraft draft) async {
    final enriched = await _intelligence.enrich(draft);
    await _drafts.save(enriched);
    await _marketplace.publish(enriched);
  }
}
