import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:commet/ui/pages/matrix/room_address_settings/matrix_room_address_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../room/general/room_general_settings_view.dart';

class SpaceGeneralSettingsPage extends StatefulWidget {
  const SpaceGeneralSettingsPage({super.key, required this.space});
  final Space space;

  @override
  State<SpaceGeneralSettingsPage> createState() =>
      _SpaceGeneralSettingsPageState();
}

class _SpaceGeneralSettingsPageState extends State<SpaceGeneralSettingsPage> {
  late PushRule pushRule;

  String get labelSpaceSettingsNotifications => Intl.message(
      "Space notifications",
      desc: "Label for the notifications section in space settings",
      name: "labelSpaceSettingsNotifications");

  String get labelSpacePushRuleNotifyAll => Intl.message(
      "All messages in this space",
      desc:
          "Label for the push rule which notifies for all messages in a space",
      name: "labelSpacePushRuleNotifyAll");

  String get labelSpacePushRuleMentionsAndKeywords => Intl.message(
      "Mentions & keywords in this space",
      desc:
          "Label for the push rule which notifies only for mentions and keywords in a space",
      name: "labelSpacePushRuleMentionsAndKeywords");

  String get labelSpacePushRuleNone => Intl.message("Mute this space",
      desc: "Label for muting notifications for a space",
      name: "labelSpacePushRuleNone");

  @override
  void initState() {
    pushRule = widget.space.pushRule;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoomGeneralSettingsView(
          pushRule: pushRule,
          onPushRuleChanged: setPushRule,
          labelRoomSettingsNotificationsOverride: labelSpaceSettingsNotifications,
          labelPushRuleNotifyAllOverride: labelSpacePushRuleNotifyAll,
          labelPushRuleMentionsAndKeywordsOverride:
              labelSpacePushRuleMentionsAndKeywords,
          labelPushRuleNoneOverride: labelSpacePushRuleNone,
        ),
        const SizedBox(
          height: 10,
        ),
        if (widget.space is MatrixSpace)
          MatrixRoomAddressSettings((widget.space as MatrixSpace).matrixRoom)
      ],
    );
  }

  void setPushRule(PushRule? rule) {
    if (rule == null) return;

    setState(() {
      pushRule = rule;
    });

    widget.space.setPushRule(rule);
  }
}
