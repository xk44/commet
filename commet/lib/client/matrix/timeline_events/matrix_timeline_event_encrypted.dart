import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/matrix/utils/decryption_retry.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_encrypted.dart';

class MatrixTimelineEventEncrypted extends MatrixTimelineEvent
    implements TimelineEventEncrypted {
  MatrixTimelineEventEncrypted(super.event, {required super.client});

  @override
  Future<TimelineEvent<Client>?> attemptDecrypt(Room room) async {
    await requestKeyWithRetry(event,
        context: 'MatrixTimelineEventEncrypted.attemptDecrypt');
    return room.getEvent(event.eventId);
  }
}
