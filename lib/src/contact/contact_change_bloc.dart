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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:delta_chat_core/delta_chat_core.dart';
import 'package:ox_coi/src/contact/contact_change.dart';
import 'package:ox_coi/src/contact/contact_change_event_state.dart';
import 'package:ox_coi/src/data/repository.dart';
import 'package:ox_coi/src/data/repository_manager.dart';
import 'package:ox_coi/src/invite/invite_mixin.dart';
import 'package:ox_coi/src/utils/error.dart';

enum ContactChangeType {
  add,
  edit,
  delete,
  block,
  unblock,
}

class ContactChangeBloc extends Bloc<ContactChangeEvent, ContactChangeState> with InviteMixin {
  final Repository<Chat> _chatRepository = RepositoryManager.get(RepositoryType.chat);
  final Repository<Contact> contactRepository = RepositoryManager.get(RepositoryType.contact);

  @override
  ContactChangeState get initialState => ContactChangeStateInitial();

  @override
  Stream<ContactChangeState> mapEventToState(ContactChangeEvent event) async* {
    if (event is ChangeContact) {
      yield ContactChangeStateLoading();
      try {
        _changeContact(event.name, event.email, event.contactAction);
      } catch (error) {
        yield ContactChangeStateFailure(error: error.toString());
      }
    } else if (event is ContactAdded) {
      yield ContactChangeStateSuccess(type: ContactChangeType.add, id: event.id);
    } else if (event is ContactEdited) {
      yield ContactChangeStateSuccess(type: ContactChangeType.edit);
    } else if (event is DeleteContact) {
      _deleteContact(event.id);
    } else if (event is ContactDeleted) {
      yield ContactChangeStateSuccess(type: ContactChangeType.delete);
    } else if (event is ContactDeleteFailed) {
      yield ContactChangeStateFailure(error: event.error);
    } else if (event is BlockContact) {
      _blockContact(event.contactId, event.chatId, event.messageId);
    } else if (event is ContactBlocked) {
      yield ContactChangeStateSuccess(type: ContactChangeType.block);
    } else if (event is UnblockContact) {
      _unblockContact(event.id);
    } else if (event is ContactUnblocked) {
      yield ContactChangeStateSuccess(type: ContactChangeType.unblock);
    }
  }

  void _changeContact(String name, String address, ContactAction contactAction) async {
    Context context = Context();
    int id = await context.createContact(name, address);
    if (contactAction == ContactAction.add) {
      dispatch(ContactAdded(id: id));
    } else {
      Contact contact = contactRepository.get(id);
      contact.set(Contact.methodContactGetName, name);
      int chatId = await context.getChatByContactId(id);
      if (chatId != 0) {
        renameChat(chatId, name);
      }
      dispatch(ContactEdited());
    }
  }

  void renameChat(int chatId, String name) {
    Chat chat = _chatRepository.get(chatId);
    chat.set(Chat.methodChatGetName, name);
  }

  void _deleteContact(int id) async {
    Context context = Context();
    bool deleted = await context.deleteContact(id);
    if (deleted) {
      contactRepository.remove(id: id);
      dispatch(ContactDeleted());
    } else {
      int chatId = await context.getChatByContactId(id);
      String error = chatId != 0 ? contactDeleteChatExists : contactDeleteGeneric;
      dispatch(ContactDeleteFailed(error: error));
    }
  }

  void _blockContact(int contactId, int chatId, int messageId) async {
    if (contactId == null && messageId != null) {
      contactId = await getContactIdFromMessage(messageId);
    }
    Context context = Context();
    if (chatId == null) {
      chatId = await context.getChatByContactId(contactId);
    }
    await context.blockContact(contactId);
    if (isInviteChat(chatId)) {
      Repository<ChatMsg> messageListRepository = RepositoryManager.get(RepositoryType.chatMessage, Chat.typeInvite);
      messageListRepository.clear();
    }
    adjustChatListOnBlockUnblock(chatId, block: true);
    dispatch(ContactBlocked());
  }

  void adjustChatListOnBlockUnblock(int chatId, {bool block}) {
    if (block) {
      if (chatId != null && chatId != Chat.typeInvite) {
        _chatRepository.remove(id: chatId);
      }
    } else {
      if (chatId != 0) {
        _chatRepository.putIfAbsent(id: chatId);
      }
    }
  }

  void _unblockContact(int id) async {
    Context context = Context();
    await context.unblockContact(id);
    var chatId = await context.getChatByContactId(id);
    adjustChatListOnBlockUnblock(chatId, block: false);
    dispatch(ContactUnblocked());
  }
}
