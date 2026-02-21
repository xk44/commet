import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:flutter/material.dart';

class MatrixTimelineEventPoll extends MatrixTimelineEvent
    implements TimelineEventGeneric {
  MatrixTimelineEventPoll(super.event, {required super.client});

  static const _pollStartTypes = {
    'm.poll.start',
    'org.matrix.msc3381.poll.start',
  };

  static const _pollResponseTypes = {
    'm.poll.response',
    'org.matrix.msc3381.poll.response',
  };

  static const _pollEndTypes = {
    'm.poll.end',
    'org.matrix.msc3381.poll.end',
  };

  @override
  IconData get icon {
    if (_pollEndTypes.contains(event.type)) {
      return Icons.how_to_vote_outlined;
    }

    if (_pollResponseTypes.contains(event.type)) {
      return Icons.how_to_vote;
    }

    return Icons.poll_outlined;
  }

  @override
  String get plainTextBody => getBody();

  @override
  bool get showSenderAvatar => false;

  String? _pollQuestion() {
    final poll = event.content['m.poll.start'] ??
        event.content['org.matrix.msc3381.poll.start'];

    if (poll is! Map) {
      return null;
    }

    final question = poll['question'];
    if (question is! Map) {
      return null;
    }

    final text = question['m.text'] ?? question['org.matrix.msc1767.text'];
    return text is String ? text : null;
  }

  @override
  String getBody({Timeline? timeline}) {
    final senderName =
        event.senderFromMemoryOrFallback.displayName ?? event.senderId;
    final question = _pollQuestion();

    if (_pollResponseTypes.contains(event.type)) {
      return '$senderName voted in a poll';
    }

    if (_pollEndTypes.contains(event.type)) {
      if (question != null && question.isNotEmpty) {
        return '$senderName ended the poll: $question';
      }
      return '$senderName ended a poll';
    }

    if (question != null && question.isNotEmpty) {
      return '$senderName started a poll: $question';
    }

    return '$senderName started a poll';
  }
}
