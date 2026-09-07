import 'dart:convert';

/// A recoverable listing-in-progress. It is JSON serializable so native mobile
/// storage and Firebase/PostgreSQL sync layers share the exact same contract.
class CraftDraft {
  const CraftDraft({
    required this.id,
    required this.createdAt,
    required this.imagePath,
    required this.tags,
    required this.confidence,
    this.description,
    this.suggestedPrice,
    this.syncState = DraftSyncState.local,
  });

  final String id;
  final DateTime createdAt;
  final String imagePath;
  final List<String> tags;
  final double confidence;
  final String? description;
  final double? suggestedPrice;
  final DraftSyncState syncState;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'imagePath': imagePath,
        'tags': tags,
        'confidence': confidence,
        'description': description,
        'suggestedPrice': suggestedPrice,
        'syncState': syncState.name,
      };

  String encode() => jsonEncode(toJson());

  factory CraftDraft.decode(String source) {
    final value = jsonDecode(source) as Map<String, dynamic>;
    return CraftDraft(
      id: value['id'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String),
      imagePath: value['imagePath'] as String,
      tags: List<String>.from(value['tags'] as List<dynamic>),
      confidence: (value['confidence'] as num).toDouble(),
      description: value['description'] as String?,
      suggestedPrice: (value['suggestedPrice'] as num?)?.toDouble(),
      syncState: DraftSyncState.values.byName(
        value['syncState'] as String? ?? DraftSyncState.local.name,
      ),
    );
  }
}

enum DraftSyncState { local, queued, synced, failed }
