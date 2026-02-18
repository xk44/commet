import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/invitation/invitation.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/molecules/alert_view.dart';
import 'package:commet/ui/molecules/invitation_display.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class HomeScreenView extends StatefulWidget {
  final ClientManager clientManager;
  final List<Room>? rooms;
  final List<Room>? recentActivity;
  final List<Invitation>? invitations;
  final Function(Room room)? onRoomClicked;
  final Future<void> Function(Invitation invite)? acceptInvite;
  final Future<void> Function(Invitation invite)? rejectInvite;
  final Future<void> Function(Client client, String address)? joinRoom;
  final Future<void> Function(Client client, CreateRoomArgs args)? createRoom;

  const HomeScreenView(
      {super.key,
      required this.clientManager,
      this.rooms,
      this.recentActivity,
      this.onRoomClicked,
      this.acceptInvite,
      this.rejectInvite,
      this.joinRoom,
      this.createRoom,
      this.invitations});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  String roomSearchQuery = "";

  String get labelHomeRecentActivity => Intl.message("Recent Activity",
      name: "labelHomeRecentActivity",
      desc: "Short label for header of recent room activity");

  String get labelHomeAlerts => Intl.message("Alerts",
      name: "labelHomeAlerts", desc: "Short label for header of alerts");

  String get labelHomeRoomsList => Intl.message("Rooms",
      name: "labelHomeRoomsList", desc: "Short label for header of rooms list");

  String get labelHomeInvitations => Intl.message("Invitations",
      name: "labelHomeInvitations",
      desc: "Short label for header of invitations list");

  String get promptSearchRooms => Intl.message("Search rooms",
      name: "promptSearchRooms",
      desc: "Prompt in the home screen room search input");

  List<Room> _filterRooms(List<Room>? source) {
    if (source == null) return List.empty();

    final query = roomSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return source;

    return source.where((room) {
      final displayName = room.displayName.toLowerCase();
      final identifier = room.identifier.toLowerCase();
      return displayName.contains(query) || identifier.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecentActivity = _filterRooms(widget.recentActivity);
    final filteredRooms = _filterRooms(widget.rooms);

    return Column(
      children: [
        if (widget.clientManager.alertManager.alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: alerts(),
          ),
        if (widget.invitations?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: invitationsList(),
          ),
        if (filteredRecentActivity.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: recentRooms(filteredRecentActivity),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: roomsList(context, filteredRooms),
        )
      ],
    );
  }

  Widget alerts() {
    return Panel(
        mode: TileType.surfaceContainerLow,
        header: labelHomeAlerts,
        child: ImplicitlyAnimatedList(
          padding: EdgeInsetsGeometry.zero,
          shrinkWrap: true,
          itemData: widget.clientManager.alertManager.alerts,
          initialAnimation: false,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, alert) {
            return AlertView(alert);
          },
        ));
  }

  Widget recentRooms(List<Room> recentRooms) {
    return Panel(
        mode: TileType.surface,
        header: labelHomeRecentActivity,
        child: ImplicitlyAnimatedList(
          shrinkWrap: true,
          padding: EdgeInsetsGeometry.zero,
          itemData: recentRooms,
          initialAnimation: false,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, room) {
            return RoomPanel(
              displayName: room.displayName,
              avatar: room.avatar,
              color: room.defaultColor,
              body: room.lastEvent?.plainTextBody,
              recentEventSender: room.lastEvent != null
                  ? room
                      .getMemberOrFallback(room.lastEvent!.senderId)
                      .displayName
                  : null,
              recentEventSenderColor: room.lastEvent != null
                  ? room.getColorOfUser(room.lastEvent!.senderId)
                  : null,
              onTap: () => widget.onRoomClicked?.call(room),
              showUserAvatar: widget.clientManager.rooms
                      .where((element) => element.identifier == room.identifier)
                      .length >
                  1,
              userAvatar: room.client.self!.avatar,
              userDisplayName: room.client.self!.displayName,
              userColor: room.client.self!.defaultColor,
            );
          },
        ));
  }

  Widget roomsList(BuildContext context, List<Room> rooms) {
    return Panel(
        mode: TileType.surface,
        header: labelHomeRoomsList,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextFormField(
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: promptSearchRooms,
                ),
                onChanged: (value) {
                  setState(() {
                    roomSearchQuery = value;
                  });
                },
              ),
            ),
            ImplicitlyAnimatedList(
              padding: EdgeInsetsGeometry.zero,
              physics: const NeverScrollableScrollPhysics(),
              initialAnimation: false,
              shrinkWrap: true,
              itemData: rooms,
              itemBuilder: (context, room) {
                return RoomPanel(
                  displayName: room.displayName,
                  avatar: room.avatar,
                  color: room.defaultColor,
                  body: room.lastEvent?.plainTextBody,
                  recentEventSender: room.lastEvent != null
                      ? room
                          .getMemberOrFallback(room.lastEvent!.senderId)
                          .displayName
                      : null,
                  recentEventSenderColor: room.lastEvent != null
                      ? room.getColorOfUser(room.lastEvent!.senderId)
                      : null,
                  onTap: () => widget.onRoomClicked?.call(room),
                  showUserAvatar: widget.clientManager.rooms
                          .where((element) =>
                              element.identifier == room.identifier)
                          .length >
                      1,
                  userAvatar: room.client.self!.avatar,
                  userDisplayName: room.client.self!.displayName,
                  userColor: room.client.self!.defaultColor,
                );
              },
            ),
            tiamat.CircleButton(
              radius: BuildConfig.MOBILE ? 24 : 16,
              icon: Icons.add,
              onPressed: () => addRoomDialog(context),
            ),
          ],
        ));
  }

  Widget invitationsList() {
    return Panel(
        mode: TileType.surfaceContainer,
        header: labelHomeInvitations,
        child: ImplicitlyAnimatedList(
          padding: EdgeInsetsGeometry.zero,
          physics: const NeverScrollableScrollPhysics(),
          initialAnimation: false,
          shrinkWrap: true,
          itemData: widget.invitations!,
          itemBuilder: (context, invitation) {
            return InvitationDisplay(
              invitation,
              acceptInvitation: widget.acceptInvite,
              rejectInvitation: widget.rejectInvite,
            );
          },
        ));
  }

  void addRoomDialog(BuildContext context) {
    GetOrCreateRoom.show(null, context,
        pickExisting: false, showAllRoomTypes: true);
  }
}
