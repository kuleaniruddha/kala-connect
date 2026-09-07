import 'dart:convert';
import 'dart:io';

import '../models/craft_draft.dart';

/// Calls a server-side AI proxy, never an LLM provider directly from a phone.
/// The proxy can safely attach credentials and retrieve market-rate signals.
class CloudIntelligenceService {
  CloudIntelligenceService({required this.baseUri, HttpClient? client})
      : _client = client ?? HttpClient();

  final Uri baseUri;
  final HttpClient _client;

  Future<CraftDraft> enrich(CraftDraft draft) async {
    final request = await _client.postUrl(baseUri.resolve('/v1/listings/enrich'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(draft.toJson()));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('AI enrichment failed: ${response.statusCode}');
    }
    return CraftDraft.decode(body);
  }
}
