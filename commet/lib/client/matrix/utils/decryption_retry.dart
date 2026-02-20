import 'dart:async';

import 'package:commet/utils/logger.dart';
import 'package:matrix/matrix.dart' as matrix;

const List<Duration> _retryDelays = [
  Duration(milliseconds: 150),
  Duration(milliseconds: 350),
  Duration(milliseconds: 700),
];

Future<matrix.Event> requestKeyWithRetry(matrix.Event event,
    {required String context}) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
    try {
      await event.requestKey();
      return event;
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;

      if (attempt == _retryDelays.length) {
        break;
      }

      await Future.delayed(_retryDelays[attempt]);
    }
  }

  final senderKey = event.content.tryGet<String>('sender_key');
  final sessionId = event.content.tryGet<String>('session_id');
  final algorithm = event.content.tryGet<String>('algorithm');

  Log.e(
      'Failed to decrypt encrypted event in $context after ${_retryDelays.length + 1} attempts. '
      'eventId=${event.eventId} roomId=${event.room.id} sender=${event.senderId} '
      'algorithm=$algorithm senderKey=$senderKey sessionId=$sessionId');

  if (lastError != null && lastStackTrace != null) {
    Log.onError(lastError, lastStackTrace);
  }

  throw lastError ?? Exception('Unable to decrypt event');
}
