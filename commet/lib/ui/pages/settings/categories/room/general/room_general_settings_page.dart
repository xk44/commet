import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/pages/matrix/room_address_settings/matrix_room_address_settings.dart';
import 'package:commet/ui/pages/settings/categories/room/general/room_general_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomGeneralSettingsPage extends StatefulWidget {
  const RoomGeneralSettingsPage({super.key, required this.room});
  final Room room;
  @override
  State<RoomGeneralSettingsPage> createState() =>
      _RoomGeneralSettingsPageState();
}

class _RoomGeneralSettingsPageState extends State<RoomGeneralSettingsPage> {
  late PushRule pushRule;
  bool loadingJoinRule = false;
  matrix.JoinRules? joinRule;
  bool canEditJoinRule = false;

  @override
  void initState() {
    pushRule = widget.room.pushRule;

    if (widget.room is MatrixRoom) {
      final matrixRoom = (widget.room as MatrixRoom).matrixRoom;
      joinRule = matrixRoom.joinRules;
      canEditJoinRule = matrixRoom.canChangeStateEvent(matrix.EventTypes.RoomJoinRules);
    }

    super.initState();
  }

  String get labelJoinRuleSettingsHeader => Intl.message(
        "Room Access",
        name: "labelJoinRuleSettingsHeader",
        desc: "Header for room access settings in room general settings",
      );

  String get labelJoinRulePublic => Intl.message(
        "Public",
        name: "labelJoinRulePublic",
        desc: "Label for rooms that are public and joinable by anyone",
      );

  String get labelJoinRuleInvite => Intl.message(
        "Invite only",
        name: "labelJoinRuleInvite",
        desc: "Label for rooms that can only be joined by invitation",
      );

  String get labelJoinRuleKnock => Intl.message(
        "Knock",
        name: "labelJoinRuleKnock",
        desc: "Label for rooms where users can request to join",
      );

  String get labelJoinRuleRestricted => Intl.message(
        "Restricted",
        name: "labelJoinRuleRestricted",
        desc: "Label for rooms restricted to users in specific spaces",
      );

  String get labelJoinRuleNoPermissionHint => Intl.message(
        "You do not have permission to change room access settings.",
        name: "labelJoinRuleNoPermissionHint",
        desc: "Hint shown when the user cannot edit room join rules",
      );

  String get errorFailedToUpdateJoinRule => Intl.message(
        "Failed to update room access settings.",
        name: "errorFailedToUpdateJoinRule",
        desc: "Error shown when updating join rules fails",
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoomGeneralSettingsView(
          pushRule: pushRule,
          onPushRuleChanged: setPushRule,
        ),
        const SizedBox(
          height: 10,
        ),
        if (widget.room is MatrixRoom)
          ...[
            const SizedBox(height: 10),
            buildJoinRulePanel((widget.room as MatrixRoom).matrixRoom),
            const SizedBox(height: 10),
            MatrixRoomAddressSettings((widget.room as MatrixRoom).matrixRoom),
          ],
      ],
    );
  }

  Widget buildJoinRulePanel(matrix.Room matrixRoom) {
    final roomJoinRule = joinRule;
    final allowRestrictedOption =
        roomJoinRule == matrix.JoinRules.restricted || hasRestrictedAllowList(matrixRoom);

    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      header: labelJoinRuleSettingsHeader,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            tiamat.RadioButton<matrix.JoinRules>(
              groupValue: roomJoinRule,
              value: matrix.JoinRules.public,
              icon: Icons.public,
              text: labelJoinRulePublic,
              onChanged: canEditJoinRule && !loadingJoinRule ? setJoinRule : null,
            ),
            tiamat.RadioButton<matrix.JoinRules>(
              groupValue: roomJoinRule,
              value: matrix.JoinRules.invite,
              icon: Icons.lock,
              text: labelJoinRuleInvite,
              onChanged: canEditJoinRule && !loadingJoinRule ? setJoinRule : null,
            ),
            tiamat.RadioButton<matrix.JoinRules>(
              groupValue: roomJoinRule,
              value: matrix.JoinRules.knock,
              icon: Icons.pan_tool_alt,
              text: labelJoinRuleKnock,
              onChanged: canEditJoinRule && !loadingJoinRule ? setJoinRule : null,
            ),
            if (allowRestrictedOption)
              tiamat.RadioButton<matrix.JoinRules>(
                groupValue: roomJoinRule,
                value: matrix.JoinRules.restricted,
                icon: Icons.lock_outline,
                text: labelJoinRuleRestricted,
                onChanged:
                    canEditJoinRule && !loadingJoinRule ? setJoinRule : null,
              ),
            if (!canEditJoinRule)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    labelJoinRuleNoPermissionHint,
                  ),
                ),
              ),
            if (loadingJoinRule)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool hasRestrictedAllowList(matrix.Room room) {
    final joinRuleState = room.getState(matrix.EventTypes.RoomJoinRules);
    final allow = joinRuleState?.content['allow'];
    return allow is List && allow.isNotEmpty;
  }

  Future<void> setJoinRule(matrix.JoinRules? selectedJoinRule) async {
    if (selectedJoinRule == null || widget.room is! MatrixRoom) {
      return;
    }

    final matrixRoom = (widget.room as MatrixRoom).matrixRoom;
    final joinRuleState = matrixRoom.getState(matrix.EventTypes.RoomJoinRules);
    final originalJoinRule = joinRule;

    final content = <String, Object?>{
      'join_rule': selectedJoinRule.name,
    };

    if (selectedJoinRule == matrix.JoinRules.restricted) {
      final allow = joinRuleState?.content['allow'];
      if (allow is List && allow.isNotEmpty) {
        content['allow'] = allow;
      } else {
        return;
      }
    }

    setState(() {
      loadingJoinRule = true;
      joinRule = selectedJoinRule;
    });

    try {
      await matrixRoom.client.setRoomStateWithKey(
        matrixRoom.id,
        matrix.EventTypes.RoomJoinRules,
        '',
        content,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        joinRule = originalJoinRule;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorFailedToUpdateJoinRule)),
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingJoinRule = false;
        });
      }
    }
  }

  void setPushRule(PushRule? rule) {
    if (rule == null) return;

    setState(() {
      pushRule = rule;
    });

    widget.room.setPushRule(rule);
  }
}
