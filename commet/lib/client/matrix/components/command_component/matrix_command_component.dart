import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon_recent/recent_emoticon_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/components/profile/matrix_profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/generated/model.dart';
import 'package:uuid/uuid.dart';

class MatrixCommandComponent extends CommandComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixCommandComponent(this.client) {
    client.getMatrixClient().addCommand("sendjson", sendJson);
    client.getMatrixClient().addCommand("status", setStatus);
    client.getMatrixClient().addCommand("clearemojistats", clearEmojiStats);
    client.getMatrixClient().addCommand("setprofile", setProfile);
    client.getMatrixClient().addCommand("addwidget", addWidget);
    client.getMatrixClient().addCommand("setstate", setState);
  }

  @override
  List<String> getCommands() {
    return client.getMatrixClient().commands.keys.toList();
  }

  @override
  Future<void> executeCommand(String string, Room room,
      {TimelineEvent? interactingEvent, EventInteractionType? type}) async {
    var mxRoom = (room as MatrixRoom).matrixRoom;
    matrix.Event? event;
    if (interactingEvent != null) {
      event = (interactingEvent as MatrixTimelineEvent).event;
    }

    await client.getMatrixClient().parseAndRunCommand(
          mxRoom,
          string,
          inReplyTo: type == EventInteractionType.reply ? event : null,
          editEventId:
              type == EventInteractionType.edit ? event?.eventId : null,
        );
  }

  @override
  bool isExecutable(String string) {
    if (string.startsWith("/")) {
      var command = string.substring(1).split(" ").first;
      return client.getMatrixClient().commands.containsKey(command);
    }

    return false;
  }

  FutureOr<String?> sendJson(matrix.CommandArgs args, StringBuffer? out) {
    var json = const JsonDecoder().convert(args.msg) as Map<String, dynamic>;

    var tx = client.getMatrixClient().generateUniqueTransactionId();
    client
        .getMatrixClient()
        .sendMessage(args.room!.id, json["type"], tx, json['content']);

    return null;
  }

  @override
  bool isPossiblyCommand(String string) {
    return string.startsWith("/");
  }

  FutureOr<String?> setStatus(
      matrix.CommandArgs args, StringBuffer? out) async {
    client.getComponent<UserProfileComponent>()?.setStatus(args.msg);

    await client.getMatrixClient().setPresence(
        client.getMatrixClient().userID!, PresenceType.online,
        statusMsg: args.msg);

    return null;
  }

  FutureOr<String?> clearEmojiStats(
      matrix.CommandArgs args, StringBuffer? out) async {
    var c = client.getComponent<RecentEmoticonComponent>();
    c?.clear();
    return null;
  }

  FutureOr<String?> setProfile(
      matrix.CommandArgs args, StringBuffer? stdout) async {
    final parts = args.msg.split(" ");
    final field = parts[0];
    final content = parts.sublist(1).join(" ");
    dynamic result = content;
    try {
      result = jsonDecode(content);
    } catch (e, s) {
      Log.onError(e, s);
    }

    var comp = client.getComponent<MatrixProfileComponent>();
    comp?.setField(field, result);

    return null;
  }

  FutureOr<String?> addWidget(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.room == null) return null;

    var url = Uri.parse(args.msg);
    var uuid = const Uuid();
    var id = uuid.v4();

    var content = {
      "type": "m.custom",
      "url": url.toString(),
      "name": "Custom",
      "id": id,
      "creatorUserId": client.self!.identifier,
      "roomId": args.room!.id,
    };

    if (url.host == "calendar-widget.commet.chat") {
      content["type"] = "chat.commet.widgets.calendar";
      content["name"] = "Calendar";
    }

    await client.matrixClient.setRoomStateWithKey(
        args.room!.id, "im.vector.modular.widgets", id, content);

    return null;
  }

  FutureOr<String?> setState(matrix.CommandArgs args, StringBuffer? out) async {
    if (args.room == null) {
      return "This command can only be used in a room.";
    }

    final trimmedArgs = args.msg.trim();
    if (trimmedArgs.isEmpty) {
      return "Usage: /setstate <event_type> <state_key|-> <json_content>";
    }

    final firstSpace = trimmedArgs.indexOf(" ");
    if (firstSpace == -1) {
      return "Missing state key and JSON content. Usage: /setstate <event_type> <state_key|-> <json_content>";
    }

    final eventType = trimmedArgs.substring(0, firstSpace);
    final keyAndContent = trimmedArgs.substring(firstSpace + 1).trim();
    final secondSpace = keyAndContent.indexOf(" ");
    if (secondSpace == -1) {
      return "Missing JSON content. Usage: /setstate <event_type> <state_key|-> <json_content>";
    }

    final rawStateKey = keyAndContent.substring(0, secondSpace).trim();
    final rawContent = keyAndContent.substring(secondSpace + 1).trim();

    if (eventType.isEmpty || rawStateKey.isEmpty || rawContent.isEmpty) {
      return "Usage: /setstate <event_type> <state_key|-> <json_content>";
    }

    Map<String, dynamic> parsedContent;
    try {
      final decoded = const JsonDecoder().convert(rawContent);
      if (decoded is! Map<String, dynamic>) {
        return "JSON content must be an object.";
      }
      parsedContent = decoded;
    } catch (e) {
      return "Invalid JSON content: ${e.toString()}";
    }

    final stateKey = rawStateKey == "-" ? "" : rawStateKey;

    try {
      await client.matrixClient
          .setRoomStateWithKey(args.room!.id, eventType, stateKey, parsedContent);
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to send state event");
      return "Failed to send state event: ${e.toString()}";
    }

    return "State event sent.";
  }
}
