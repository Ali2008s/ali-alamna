import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:streamit_laravel/generated/assets.dart';

///-------------------------------------------------------------------------------------
/// Init engine
/// Recommended: call in main() for zero-latency first play:
/// await FocusSoundService.instance.init();

/// FocusSoundService
/// - One-line static usage: FocusSoundService.play();
///-------------------------------------------------------------------------------------

/// - Preloads an AudioSource, stores the last playing SoundHandle so it can be stopped.
class FocusSoundService {
  FocusSoundService._internal();

  static final FocusSoundService _instance = FocusSoundService._internal();

  // Optional convenience singleton getter
  static FocusSoundService get instance => _instance;

  // One-line static call used across the app
  static Future<void> play({double volume = 1.0}) => _instance._play(volume: volume);

  /// --- internal SoLoud fields ---
  final SoLoud _soLoud = SoLoud.instance;
  AudioSource? _audioSource;
  SoundHandle? _lastHandle;
  bool _initialized = false;
  File? _cachedAssetFile;
  String? _cachedAssetKey;

  // enable/disable toggle (user setting can flip this)
  bool enabled = true;

  // debounce / rate-limit (avoid overlapping spam)
  final Duration _minInterval = const Duration(milliseconds: 60);
  DateTime? _lastPlay;

  // asset path
  String assetPath = Assets.navSound;

  /// initialize the focus sound service
  Future<void> init({String? overrideAssetPath}) async {
    if (kIsWeb) {
      enabled = false;
      _initialized = true;
      return;
    }
    if (_initialized) return;
    if (overrideAssetPath != null) assetPath = overrideAssetPath;

    try {
      if (!_soLoud.isInitialized) {
        await _soLoud.init();
      }

      final assetFile = await _ensureLocalAssetFile();
      if (assetFile == null) {
        throw Exception('FocusSoundService: failed to prepare asset file.');
      }

      // load the asset as an AudioSource
      _audioSource = await _soLoud.loadFile(assetFile.path);
      _initialized = true;
    } catch (e, st) {
      // if load/init fails, disable service to avoid repeated errors
      debugPrint('FocusSoundService.init failed: $e\n$st');
      enabled = false;
      _initialized = false;
    }
  }

  /// Internal play implementation: non-blocking, debounced.
  Future<void> _play({double volume = 1.0}) async {
    if (!enabled) return;

    final now = DateTime.now();
    if (_lastPlay != null && now.difference(_lastPlay!) < _minInterval) {
      return; // rate-limited
    }
    _lastPlay = now;

    try {
      if (!_initialized) {
        // lazy init (await so first play occurs after load)
        await init().catchError((_) {});
      }

      if (_audioSource == null) {
        // nothing loaded — bail silently
        return;
      }

      // Play and store the returned handle so we can stop it later if needed
      _lastHandle = await _soLoud.play(_audioSource!, volume: volume);
      // Fire-and-forget; handle validity can be checked via getIsValidVoiceHandle
    } catch (e, st) {
      debugPrint('FocusSoundService._play error: $e\n$st');
    }
  }

  /// Ensures the bundled asset is copied to a temporary local file and returns it.
  /// Reuses a cached file when the asset path hasn't changed; returns `null` on error.
  Future<File?> _ensureLocalAssetFile() async {
    if (kIsWeb) return null;
    try {
      if (_cachedAssetFile != null && _cachedAssetKey == assetPath) {
        if (await _cachedAssetFile!.exists()) {
          return _cachedAssetFile;
        }
      }

      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final focusDir = Directory(p.join(tempDir.path, 'focus_sound_cache'));
      if (!await focusDir.exists()) {
        await focusDir.create(recursive: true);
      }

      final filePath = p.join(focusDir.path, p.basename(assetPath));
      final file = File(filePath);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      _cachedAssetFile = file;
      _cachedAssetKey = assetPath;
      return file;
    } catch (e, st) {
      debugPrint('FocusSoundService._ensureLocalAssetFile error: $e\n$st');
      return null;
    }
  }

  /// Stop the last playing instance (if any).
  /// Uses the SoundHandle returned by play() and SoLoud.stop(handle).
  Future<void> stop() async {
    try {
      final handle = _lastHandle;
      if (handle == null) return;
      // check validity before stopping
      final valid = _soLoud.getIsValidVoiceHandle(handle);
      if (valid) {
        await _soLoud.stop(handle);
      }
      _lastHandle = null;
    } catch (e, st) {
      debugPrint('FocusSoundService.stop error: $e\n$st');
    }
  }

  /// Dispose resources (unload audio, deinit engine)
  Future<void> dispose() async {
    try {
      // stop currently playing handle if there is one
      if (_lastHandle != null) {
        try {
          if (_soLoud.getIsValidVoiceHandle(_lastHandle!)) {
            await _soLoud.stop(_lastHandle!);
          }
        } catch (_) {}
        _lastHandle = null;
      }

      if (_audioSource != null) {
        await _soLoud.disposeSource(_audioSource!);
        _audioSource = null;
      }

      if (_cachedAssetFile != null) {
        try {
          if (await _cachedAssetFile!.exists()) {
            await _cachedAssetFile!.delete();
          }
        } catch (_) {}
        _cachedAssetFile = null;
        _cachedAssetKey = null;
      }

      if (_soLoud.isInitialized) {
        _soLoud.deinit();
      }
      _initialized = false;
    } catch (e, st) {
      debugPrint('FocusSoundService.dispose error: $e\n$st');
    }
  }
}
