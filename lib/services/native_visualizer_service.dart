import 'dart:async';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

class NativeVisualizerService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.music_flow_mobile/visualizer_method');
  static const EventChannel _eventChannel = EventChannel('com.example.music_flow_mobile/visualizer_event');
  
  static final Stream<dynamic> _visualizerBroadcastStream = _eventChannel.receiveBroadcastStream();
  
  static Stream<dynamic> get visualizerStream => _visualizerBroadcastStream;

  static Future<void> startVisualizer(int? sessionId) async {
    if (sessionId != null && sessionId != 0) {
      try {
        await _methodChannel.invokeMethod('startVisualizer', {'sessionId': sessionId});
      } catch (e) {
        AppLogger.error('Error starting native visualizer', e, null, 'AUDIO');
      }
    }
  }

  static Future<void> setVisualizerCore(String core) async {
    try {
      await _methodChannel.invokeMethod('setVisualizerCore', {'core': core});
    } catch (e) {
      AppLogger.error('Error setting visualizer core', e, null, 'AUDIO');
    }
  }

  static Future<void> stopVisualizer() async {
    try {
      await _methodChannel.invokeMethod('stopVisualizer');
    } catch (e) {
      AppLogger.error('Error stopping native visualizer', e, null, 'AUDIO');
    }
  }
}
