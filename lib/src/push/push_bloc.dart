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

import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:http/io_client.dart';
import 'package:ox_coi/src/platform/app_information.dart';
import 'package:ox_coi/src/push/push_event_state.dart';

class PushBloc extends Bloc<PushEvent, PushState> {
  String _pushUrl = 'https://10.50.0.26:443/push/resource/';
  String _transportMethod = 'firebase';
  String _publicKey = 'BGC4JKIBjQPrNrJ4pPG8q0OXjdG-YAcARwIVSg7oDj_f9qe-GbYTr7ATTwQil85lVydfoPdZ4vFOeevxtE9SIZ8';
  String _pushToken =
      'e-jeDxC2bOw:APA91bGqqATQ49l9qFRp6hW0zWHIl40BSROooOV95R6ZKEvbepOYSrl5JdgHiuHfT-9WQSoh0RPsWPR9u4Lqt8FthCcGto_tb5BHcn_85bt6CtzcTUfvxyP7hTfnSpD0A5LHfJqCjt40';
  //TODO: Add correct push token
  Map<String, String> _headers = {"Content-type": "application/json"};

  @override
  PushState get initialState => PushStateInitial();

  @override
  Stream<PushState> mapEventToState(PushEvent event) async* {
    if (event is RegisterPush) {
      yield PushStateLoading();
      try {
        registerPush();
      } catch (error) {
        yield PushStateFailure(error: error.toString());
      }
    } else if (event is GetPush) {
      yield PushStateLoading();
      try {
        getPush();
      } catch (error) {
        yield PushStateFailure(error: error.toString());
      }
    } else if (event is PatchPush) {
      yield PushStateLoading();
      try {
        patchPush();
      } catch (error) {
        yield PushStateFailure(error: error.toString());
      }
    } else if (event is DeletePush) {
      yield PushStateLoading();
      try {
        deletePush();
      } catch (error) {
        yield PushStateFailure(error: error.toString());
      }
    }
  }

  void registerPush() async {
    String packageName = await getPackageName();
    String encodedBody = json.encode({'appId': packageName, 'pushToken': _pushToken, 'transport': _transportMethod, 'publicKey': _publicKey});

    IOClient ioClient = createIOClient();
    var response = await ioClient
        .put(_pushUrl, headers: _headers, body: encodedBody)
        .catchError((error) => print("[PushBloc.registerPush] error - ${error.toString()}"));

    print("[PushBloc.registerPush] response.body - ${response.body}");
    //TODO: parse response to object
  }

  void getPush() async{
    IOClient ioClient = createIOClient();
    String id = ""; //TODO: add id from registerPush() response

    var response = await ioClient
        .get(_pushUrl + id.toString(), headers: _headers)
        .catchError((error) => print("[PushBloc.getPush] error - ${error.toString()}"));

    print("[PushBloc.getPush] response.body - ${response.body}");
    //TODO: handle response
  }

  void patchPush() async{
    IOClient ioClient = createIOClient();
    String id = ""; //TODO: add id from registerPush() response
    String encodedBody = json.encode({'pushToken': _pushToken});

    var response = await ioClient
        .patch(_pushUrl + id.toString(), headers: _headers, body: encodedBody)
        .catchError((error) => print("[PushBloc.patchPush] error - ${error.toString()}"));

    print("[PushBloc.patchPush] response.body - ${response.body}");
    //TODO: handle response
  }

  void deletePush() async{
    IOClient ioClient = createIOClient();
    String id = ""; //TODO: add id from registerPush() response

    var response = await ioClient
        .delete(_pushUrl + id.toString(), headers: _headers)
        .catchError((error) => print("[PushBloc.deletePush] error - ${error.toString()}"));

    print("[PushBloc.deletePush] response.body - ${response.body}");
    //TODO: handle response
  }

  IOClient createIOClient(){
    HttpClient httpClient = HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    return IOClient(httpClient);
  }
}
