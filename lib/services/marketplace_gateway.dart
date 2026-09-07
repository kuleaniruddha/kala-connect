import 'dart:convert';
import 'dart:io';

import '../models/craft_draft.dart';

/// Contract for Spring Boot. The backend fans the payload out to Amazon/ONDC
/// and synchronizes PostgreSQL and Firebase transactionally.
class MarketplaceGateway {
  MarketplaceGateway({required this.baseUri, HttpClient? client})
      : _client = client ?? HttpClient();

  final Uri baseUri;
  final HttpClient _client;

  Future<void> publish(CraftDraft draft) async {
    final request = await _client.postUrl(baseUri.resolve('/v1/marketplaces/publish'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{
      'listing': draft.toJson(),
      'channels': const <String>['amazon', 'ondc'],
    }));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Marketplace publish failed: ${response.statusCode}');
    }
    await response.drain<void>();
  }
}
