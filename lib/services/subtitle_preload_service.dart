import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:subtitle/subtitle.dart';

/// Service to preload and cache subtitles in the background
/// This service downloads and parses subtitles when Content Details API is called,
/// so they are ready immediately when user selects a subtitle
class SubtitlePreloadService {
  // Singleton instance
  static final SubtitlePreloadService _instance = SubtitlePreloadService._internal();
  factory SubtitlePreloadService() => _instance;
  SubtitlePreloadService._internal();

  // Shared cache storage (same as VideoPlayersController cache)
  final Map<String, List<Subtitle>> _subtitleCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(hours: 1);

  /// Check if cache is valid for a subtitle URL
  bool _isCacheValid(String url) {
    final timestamp = _cacheTimestamps[url];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  /// Get cached subtitles if available
  List<Subtitle>? getCachedSubtitles(String url) {
    if (_isCacheValid(url)) {
      log("[SUBTITLE] Cache hit for URL: $url");
      return _subtitleCache[url];
    }
    log("[SUBTITLE] Cache miss for URL: $url");
    return null;
  }

  /// Cache subtitles (public method for VideoPlayersController to use)
  void cacheSubtitles(String url, List<Subtitle> subtitles) {
    log("[SUBTITLE] Caching subtitles: URL=$url, entries=${subtitles.length}");
    _cacheSubtitles(url, subtitles);
  }

  /// Cache subtitles
  void _cacheSubtitles(String url, List<Subtitle> subtitles) {
    _subtitleCache[url] = subtitles;
    _cacheTimestamps[url] = DateTime.now();
    log("[SUBTITLE] Subtitles cached successfully: URL=$url, entries=${subtitles.length}, timestamp=${DateTime.now()}");
  }

  /// Clear all cached subtitles
  void clearCache() {
    final count = _subtitleCache.length;
    _subtitleCache.clear();
    _cacheTimestamps.clear();
    log("[SUBTITLE] Cache cleared: removed $count entries");
  }

  /// Check if subtitle format is valid
  bool isValidSubtitleFormat(String url) {
    return url.endsWith('.srt') || url.endsWith('.vtt');
  }

  /// Get subtitle format type from URL
  SubtitleType getSubtitleFormat(String url) {
    if (url.endsWith('.srt')) return SubtitleType.srt;
    if (url.endsWith('.vtt')) return SubtitleType.vtt;
    return SubtitleType.custom;
  }

  /// Check if URL is valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Preload a single subtitle file in background
  /// This runs in an isolate to avoid blocking the main thread
  Future<void> preloadSubtitle(SubtitleModel subtitle) async {
    try {
      final rawUrl = subtitle.subtitleFile;
      
      log("[SUBTITLE] Starting preload for subtitle: id=${subtitle.id}, language=${subtitle.language}, url=$rawUrl");
      
      // Skip if already cached
      if (_isCacheValid(rawUrl)) {
        log("[SUBTITLE] Subtitle already cached, skipping preload: language=${subtitle.language}, url=$rawUrl");
        return;
      }

      // Skip if invalid URL or format
      if (!_isValidUrl(rawUrl) || !isValidSubtitleFormat(rawUrl)) {
        log("[SUBTITLE] Invalid subtitle URL or format, skipping: language=${subtitle.language}, url=$rawUrl");
        return;
      }

      log("[SUBTITLE] Downloading subtitle file in background: language=${subtitle.language}, url=$rawUrl");

      // Download subtitle file
      final encodedUrl = Uri.encodeFull(rawUrl);
      final downloadStartTime = DateTime.now();
      final response = await http.get(Uri.parse(encodedUrl));
      final downloadDuration = DateTime.now().difference(downloadStartTime);

      if (response.statusCode != 200) {
        log("[SUBTITLE] Failed to download subtitle: language=${subtitle.language}, HTTP ${response.statusCode}, url=$rawUrl");
        return;
      }

      log("[SUBTITLE] Subtitle downloaded successfully: language=${subtitle.language}, size=${response.bodyBytes.length} bytes, duration=${downloadDuration.inMilliseconds}ms");

      // Decode content
      String content;
      try {
        content = utf8.decode(response.bodyBytes);
      } catch (e) {
        final filtered = response.bodyBytes.where((b) => b != 0x00).toList();
        try {
          content = utf8.decode(filtered);
        } catch (e2) {
          content = latin1.decode(filtered);
        }
      }

      log("[SUBTITLE] Starting subtitle parsing in isolate: language=${subtitle.language}, format=${getSubtitleFormat(rawUrl)}");
      final parseStartTime = DateTime.now();

      // Parse subtitle in background isolate to avoid blocking main thread
      final subtitles = await compute(
        (Map<String, dynamic> params) async {
          final provider = StringSubtitle(
            data: params['content'] as String,
            type: params['type'] as SubtitleType,
          );
          final controller = SubtitleController(provider: provider);
          await controller.initial();
          return controller.subtitles;
        },
        {
          'content': content,
          'type': getSubtitleFormat(rawUrl),
        },
      );

      final parseDuration = DateTime.now().difference(parseStartTime);
      log("[SUBTITLE] Subtitle parsed successfully: language=${subtitle.language}, entries=${subtitles.length}, parse_duration=${parseDuration.inMilliseconds}ms");

      // Cache the parsed subtitles
      _cacheSubtitles(rawUrl, subtitles);
      log("[SUBTITLE] Subtitle preloaded and cached successfully: language=${subtitle.language}, entries=${subtitles.length}, url=$rawUrl");

    } catch (e) {
      log("[SUBTITLE] Error preloading subtitle: language=${subtitle.language}, error=$e, stackTrace=${StackTrace.current}");
      // Fail silently - don't throw error as this is background operation
    }
  }

  /// Preload all subtitles from a ContentModel in background
  /// This method processes subtitles one by one to avoid overwhelming the network
  Future<void> preloadSubtitles(ContentModel contentModel) async {
    if (contentModel.subtitleList.isEmpty) {
      log("[SUBTITLE] No subtitles to preload for content: id=${contentModel.id}");
      return;
    }

    final validSubtitles = contentModel.subtitleList.where((s) => s.id != -1).toList();
    final cachedCount = validSubtitles.where((s) => _isCacheValid(s.subtitleFile)).length;
    final toPreloadCount = validSubtitles.length - cachedCount;

    log("[SUBTITLE] Starting background subtitle preload: content_id=${contentModel.id}, total_subtitles=${contentModel.subtitleList.length}, valid=${validSubtitles.length}, already_cached=$cachedCount, to_preload=$toPreloadCount");

    if (toPreloadCount == 0) {
      log("[SUBTITLE] All subtitles already cached, skipping preload");
      return;
    }

    // Preload all subtitles concurrently but limit concurrency to avoid overwhelming
    // final futures = <Future<void>>[];
    final preloadStartTime = DateTime.now();
    
    for (final subtitle in contentModel.subtitleList) {
      // Skip "Off" option (id: -1)
      if (subtitle.id == -1) continue;
      
      // Skip if already cached
      if (_isCacheValid(subtitle.subtitleFile)) {
        log("[SUBTITLE] Skipping already cached subtitle: language=${subtitle.language}");
        continue;
      }

      // Add to queue
      await preloadSubtitle(subtitle);
    }

    // Wait for all preloads to complete (or fail silently)
    // await Future.wait(futures, eagerError: false);
    
    final preloadDuration = DateTime.now().difference(preloadStartTime);
    log("[SUBTITLE] Background subtitle preload completed: content_id=${contentModel.id}, duration=${preloadDuration.inMilliseconds}ms, attempted=$toPreloadCount");
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_count': _subtitleCache.length,
      'cache_keys': _subtitleCache.keys.toList(),
      'timestamps': _cacheTimestamps.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }
}

