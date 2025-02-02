/*
 * OPEN-XCHANGE legal information
 *
 * All intellectual property rights in the Software are protected by
 * international copyright laws.
 *
 *
 * In some countries OX, OX Open-Xchange and open xchange
 * as well as the corresponding Logos OX Open-Xchange and OX are registered
 * trademarks of the OX Software GmbH group of companies.
 * The use of the Logos is not covered by the Mozilla Public License 2.0 (MPL 2.0).
 * Instead, you are allowed to use these Logos according to the terms and
 * conditions of the Creative Commons License, Version 2.5, Attribution,
 * Non-commercial, ShareAlike, and the interpretation of the term
 * Non-commercial applicable to the aforementioned license is published
 * on the web site https://www.open-xchange.com/terms-and-conditions/.
 *
 * Please make sure that third-party modules and libraries are used
 * according to their respective licenses.
 *
 * Any modifications to this package must retain all copyright notices
 * of the original copyright holder(s) for the original code used.
 *
 * After any such modifications, the original and derivative code shall remain
 * under the copyright of the copyright holder(s) and/or original author(s) as stated here:
 * https://www.open-xchange.com/legal/. The contributing author shall be
 * given Attribution for the derivative code and a license granting use.
 *
 * Copyright (C) 2016-2020 OX Software GmbH
 * Mail: info@open-xchange.com
 *
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the Mozilla Public License 2.0
 * for more details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ox_coi/src/chat/chat_change_bloc.dart';
import 'package:ox_coi/src/chat/chat_change_event_state.dart';
import 'package:ox_coi/src/chat/chat_profile_group_contact_item.dart';
import 'package:ox_coi/src/contact/contact_list_bloc.dart';
import 'package:ox_coi/src/contact/contact_list_event_state.dart';
import 'package:ox_coi/src/l10n/l.dart';
import 'package:ox_coi/src/l10n/l10n.dart';
import 'package:ox_coi/src/navigation/navigatable.dart';
import 'package:ox_coi/src/navigation/navigation.dart';
import 'package:ox_coi/src/ui/color.dart';
import 'package:ox_coi/src/ui/dimensions.dart';
import 'package:ox_coi/src/widgets/profile_body.dart';
import 'package:ox_coi/src/widgets/profile_header.dart';
import 'package:ox_coi/src/utils/keyMapping.dart';

import 'chat_add_group_participants.dart';
import 'chat_bloc.dart';
import 'chat_event_state.dart';
import 'edit_name.dart';

class ChatProfileGroup extends StatefulWidget {
  final int chatId;
  final Color chatColor;
  final bool isVerified;

  ChatProfileGroup({@required this.chatId, this.chatColor, this.isVerified});

  @override
  _ChatProfileGroupState createState() => _ChatProfileGroupState();
}

class _ChatProfileGroupState extends State<ChatProfileGroup> {
  ContactListBloc _contactListBloc = ContactListBloc();
  ChatChangeBloc _chatChangeBloc = ChatChangeBloc();
  ChatBloc chatBloc;
  Navigation _navigation = Navigation();
  String chatName;

  @override
  void initState() {
    super.initState();
    _navigation.current = Navigatable(Type.chatGroupProfile);
    _contactListBloc.dispatch(RequestContacts(typeOrChatId: widget.chatId));
  }

  @override
  void dispose() {
    _contactListBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chatBloc = BlocProvider.of<ChatBloc>(context);
    return BlocBuilder(
      bloc: _contactListBloc,
      builder: (context, state) {
        if (state is ContactListStateSuccess) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BlocBuilder(
                bloc: chatBloc,
                builder: (context, state) {
                  if (state is ChatStateSuccess) {
                    chatName = state.name;
                    return ProfileData(
                        color: widget.chatColor,
                        text: state.name,
                        textStyle: Theme.of(context).textTheme.title,
                        iconData: state.isVerified ? Icons.verified_user : null,
                        imageActionCallback: _editPhotoCallback,
                        child: Column(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.center,
                              child: ProfileAvatar(
                                imagePath: state.avatarPath,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  ProfileHeaderText(),
                                  IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        key: Key(keyChatProfileGroupEditIcon),
                                        color: accent,
                                      ),
                                      onPressed: _goToEditName)
                                ],
                              ),
                            ),
                          ],
                        ));
                  } else {
                    return Container();
                  }
                },
              ),
              Padding(
                  padding: EdgeInsets.only(left: 20.0),
                  child: ProfileData(
                    text: L10n.getFormatted(L.participantXP, [state.contactIds.length], count: state.contactIds.length),
                    child: ProfileMemberHeaderText(),
                  )),
              Divider(),
              InkWell(
                onTap: () => _navigation.push(
                    context, MaterialPageRoute(builder: (context) => ChatAddGroupParticipants(chatId: widget.chatId, contactIds: state.contactIds))),
                child: Container(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: listAvatarRadius,
                        backgroundColor: accent,
                        foregroundColor: onAccent,
                        child: Icon(Icons.group_add),
                        key: Key(keyChatProfileGroupAddParticipant),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text(
                          L10n.get(L.participantAdd),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.subhead.apply(color: accent),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                child: _buildGroupMemberList(state),
              ),
              Divider(
                height: dividerHeight,
              ),
              ProfileAction(
                iconData: Icons.delete,
                key: Key(keyChatProfileGroupDelete),
                text: L10n.get(L.groupLeave),
                onTap: () => showActionDialog(context, ProfileActionType.leave, _leaveGroup),
                color: Colors.red,
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  _editPhotoCallback(String avatarPath) {
    _chatChangeBloc.dispatch(SetImagePath(chatId: widget.chatId, newPath: avatarPath));
  }

  ListView _buildGroupMemberList(ContactListStateSuccess state) {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
          height: dividerHeight,
          color: onBackground.withOpacity(barely),
        ),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: state.contactIds.length,
        itemBuilder: (BuildContext context, int index) {
          var contactId = state.contactIds[index];
          var key = "$contactId-${state.contactLastUpdateValues[index]}";
          return ChatProfileGroupContactItem(chatId: widget.chatId, contactId: contactId, showMoreButton: true, key: key);
        });
  }

  _leaveGroup() async {
    _chatChangeBloc.dispatch(LeaveGroupChat(chatId: widget.chatId));
    _chatChangeBloc.dispatch(DeleteChat(chatId: widget.chatId));
    _navigation.popUntil(context, ModalRoute.withName(Navigation.root));
  }

  void _goToEditName() {
    _navigation.push(
      context,
      MaterialPageRoute<EditName>(
        builder: (context) {
          return BlocProvider.value(
            value: chatBloc,
            child: EditName(
              chatId: widget.chatId,
              actualName: chatName,
              title: L10n.get(L.groupRename),
            ),
          );
        },
      ),
    );
  }
}
