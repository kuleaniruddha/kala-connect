import 'package:flutter/services.dart';

/// The normalized output expected from the native YOLO + TensorFlow Lite
/// pipeline. Keeping it Dart-only makes model upgrades independent of the UI.
class EdgeDetection {
  const EdgeDetection({
    required this.label,
    required this.material,
    required this.confidence,
    required this.bounds,
  });

  final String label;
  final String material;
  final double confidence;
  final DetectionBounds bounds;

  factory EdgeDetection.fromMap(Map<Object?, Object?> map) {
    final box = Map<Object?, Object?>.from(map['bounds']! as Map);
    return EdgeDetection(
      label: map['label']! as String,
      material: map['material']! as String,
      confidence: (map['confidence']! as num).toDouble(),
      bounds: DetectionBounds.fromMap(box),
    );
  }
}

class DetectionBounds {
  const DetectionBounds(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  factory DetectionBounds.fromMap(Map<Object?, Object?> map) => DetectionBounds(
        (map['left']! as num).toDouble(),
        (map['top']! as num).toDouble(),
        (map['width']! as num).toDouble(),
        (map['height']! as num).toDouble(),
      );
}

/// Bridge to Android/iOS camera code. Native handlers own camera frames,
/// background removal, YOLO inference, and TensorFlow Lite material inference.
class EdgePipelineService {
  EdgePipelineService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('in.kalaconnect/edge_ai');

  final MethodChannel _channel;

  Future<void> startCamera() => _channel.invokeMethod<void>('startCamera');

  Future<void> stopCamera() => _channel.invokeMethod<void>('stopCamera');

  Future<List<EdgeDetection>> analyseCurrentFrame() async {
    final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
          'analyseCurrentFrame',
        ) ??
        const <Map<dynamic, dynamic>>[];
    return result
        .map((item) => EdgeDetection.fromMap(Map<Object?, Object?>.from(item)))
        .toList(growable: false);
  }

  Future<String> cropForeground() async {
    return await _channel.invokeMethod<String>('cropForeground') ?? '';
  }

  /// Native camera code sends the final YOLO/TFLite JSON contract here after
  /// cropping, tagging, and cloud description enrichment complete.
  Future<Map<String, dynamic>> captureStructuredListing({
    String? heroImagePath,
    List<String> additionalImages = const <String>[],
  }) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'captureStructuredListing',
        <String, Object?>{
          'heroImagePath': heroImagePath,
          'additionalImages': additionalImages,
        },
      );
      if (raw == null) throw StateError('The edge pipeline returned no listing payload.');
      return Map<String, dynamic>.from(raw);
    } on MissingPluginException {
      return <String, dynamic>{
        'id': 'preview-kantha-001',
        'heroImagePath': heroImagePath ?? 'https://images.unsplash.com/photo-1603204077779-bed963ea7d0d?auto=format&fit=crop&w=900&q=80',
        'description': 'Hand-stitched textile art, made with patient traditional craftsmanship. Each thread carries a small story from its maker.',
        'suggestedPrice': 750,
        'currency': 'INR',
        'tags': <String>['handmade', 'textile', 'red'],
        'moreInfo': 'AI detected cotton textile and hand embroidery. Add material, dimensions, and making time through voice before publishing.',
        'additionalImages': additionalImages.isEmpty
            ? <String>['https://images.unsplash.com/photo-1606722590583-3caa991d0bdf?auto=format&fit=crop&w=500&q=80']
            : additionalImages,
        'comments': <Map<String, String>>[
          <String, String>{'author': 'Asha', 'message': 'I love the red colour and the fine stitching.', 'languageCode': 'en'},
          <String, String>{'author': 'Riya', 'message': 'बहुत सुंदर है, पर कीमत थोड़ी महंगी लगती है।', 'languageCode': 'hi'},
        ],
      };
    }
  }
}
