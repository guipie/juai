import 'dart:async';
import 'dart:convert';

import 'package:JuAI/common/apis/chat_api.dart';
import 'package:JuAI/entities/api_response.dart';
import 'package:JuAI/common/apis/notice_api.dart';
import 'package:JuAI/common/assets.dart';
import 'package:JuAI/common/config.dart';
import 'package:JuAI/common/routers/routes.dart';
import 'package:JuAI/common/store/user.dart';
import 'package:JuAI/common/utils/loading.dart';
import 'package:JuAI/entities/message/chat_prompt.dart';
import 'package:flutter/material.dart';
import 'package:JuAI/entities/message/conversation.dart';
import 'package:JuAI/common/utils/db_sqlite.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';

enum SendType { canNotSend, canSend, sending }

class ChatStore extends GetxController {
  static ChatStore get to => Get.find();
  var sendType = SendType.canNotSend.obs;
  var scrollContrller = ScrollController();
  var chatPrompts = <ChatPromptEntity>[].obs;
  ChatPromptEntity? currentChatPrompt;
  var lastChats = List<ConversationLast>.empty(growable: true).obs;
  var chats = <Conversation>[].obs; //当前会话列表
  ConversationLast? lastChat; //当前会话详情
  var connected = false;
  //流临时存储的会话数据
  final ValueNotifier<String> currentChat = ValueNotifier("");
// If you want only to log out the message for the higer level hub protocol:
  // final hubProtLogger = Logger("SignalR - hub");
// If youn want to also to log out transport messages:
  var hubConnection = HubConnectionBuilder()
      .withUrl(
    SERVER_SIGNALR_URL,
    options: HttpConnectionOptions(
      accessTokenFactory: () => Future.value(UserStore.to.tokenInfo!.token),
      logMessageContent: true,
    ),
  )
      .withAutomaticReconnect(
    retryDelays: [0, 1000, 2000, 5000, 10000],
  ).build();
  @override
  Future<void> onInit() async {
    super.onInit();
    lastChats.value = await DbSqlite.instance.queryWhereOrderBy("chat_last", "userId=?", [UserStore.to.userId], 1000, "lastSendTime desc").then((value) => value.map((e) => ConversationLast.fromJson(e)).toList());
    _signalRInit();
    _loadChatRole();
    debugPrint("初始化会话列表：${lastChats.length}条");
  }

  void _loadChatRole() {
    ChatApis.getChatPrompts().then((value) {
      chatPrompts.value = value;
      debugPrint("加载成功${value.length}");
    }).catchError((err) {
      debugPrint("加载失败$err");
    });
  }

  void _signalRInit() {
    // Configer the logging
    // final defaultHeaders = MessageHeaders();
    // var token = HttpUtil().getAuthorizationHeader();
    // defaultHeaders.setHeaderValue("Authorization", token?["Authorization"]);
//     Logger.root.level = Level.ALL;
// // Writes the log messages to the console
//     Logger.root.onRecord.listen((LogRecord rec) {
//       debugPrint('${rec.level.name}: ${rec.time}: ${rec.message}');
//     });
//     final transportProtLogger = Logger("SignalR - transport");
    try {
      hubConnection.onclose(({error}) {
        debugPrint("连接关闭：$error");
        connected = false;
        _signalRTimeOut();
      });
      hubConnection.on("ReceiveChatGPT", (arguments) {
        if (arguments == null || arguments.first == null) return;
        debugPrint("接受chatgpt回答[ReceiveChatGPT]数据：$arguments");
        var chatResult = ApiChatResponse.fromRawJson(arguments.first.toString());
        if (currentChat.value == "思考中..") currentChat.value = "";
        currentChat.value = currentChat.value + (chatResult.data ?? "");
        if (chatResult.isStop) {
          var conversation = Conversation.fromJsonFromChatGPT(currentChat.value, null, lastChat!);
          toAddChatStore(conversation);
          toAddChatLastStore(conversation);
          currentChat.value = "";
          toBottom();
          UserStore.to.userInfo.value!.tokenNum -= (chatResult.reqUsegeCnt + chatResult.resUsegeCnt);
        }
      });
      hubConnection.on("ReceiveChat", (arguments) {
        debugPrint("接受到[ReceiveChat]数据：$arguments");
        getAllChat();
      });
      hubConnection.onreconnecting(({error}) {
        debugPrint("重新连接：$error");
      });
      hubConnection.onreconnected(({connectionId}) {
        debugPrint("重新连接结束：$connectionId");
      });
      // hubConnection.serverTimeoutInMilliseconds = 1000 * 10;
      // hubConnection.keepAliveIntervalInMilliseconds = 1000 * 10;
      hubConnection.start()!.onError((error, stackTrace) {
        connected = false;
        debugPrint("连接出错了$error，stackTrace：$stackTrace");
        _signalRTimeOut();
      });
    } catch (e) {
      connected = false;
      debugPrint("连接出错了$e");
    }
    // state.hubConnection.start();
  }

  void _signalRTimeOut() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (connected) timer.cancel();
      connected = true;
      hubConnection.start()!.onError((error, stackTrace) {
        connected = false;
        debugPrint("重试连接出错了$error，stackTrace：$stackTrace");
      });
    });
  }

  Future<void> getAllChat() async {
    NoticeApis.getAllChat().then((value) {
      debugPrint(value.toString());
      List.generate(value.length, (index) {
        var cChat = value[index];
        var existIndex = lastChats.indexWhere((m) => m.conversationId == cChat.sendId);
        ConversationLast _lastChat;
        if (existIndex > -1) {
          lastChats[existIndex].content = cChat.content;
          lastChats[existIndex].lastSenderAvatar = cChat.sendAvatar ?? "";
          lastChats[existIndex].lastSendTime = cChat.sendTime.toString();
          lastChats[existIndex].unread++;
          _lastChat = lastChats[existIndex];
        } else {
          _lastChat = ConversationLast(
            conversationId: cChat.sendId,
            lastSender: cChat.sendNick,
            lastSenderAvatar: cChat.sendAvatar ?? "",
            lastSendTime: cChat.sendTime.toString(),
            content: cChat.content,
            type: 'user',
            userId: UserStore.to.userId,
          );
          _lastChat.unread++;
          lastChats.add(_lastChat);
        }
        lastChats.refresh();
        Conversation _chat = Conversation(conversationId: _lastChat.conversationId, sendId: cChat.sendId, recevieId: UserStore.to.userId, sendTime: cChat.sendTime.toString(), receiveTime: DateTime.now().toString(), content: cChat.content);
        toAddChatStore(_chat);
        toAddChatLastStore(_chat);
      });
    });
    // var receiveChat = Conversation.fromJsonFromChatGPT(msg, chatOpenAiId, state.chatRoleEntity);
    // if (conversationId > 0 && receiveId == state.chatRoleEntity.id) {
    //   _toAddChatStore(receiveChat);
    //   _toBottom();
    // }
    // _toAddChatLastStore(receiveChat);
  }

  void toChat({ConversationLast? conversation, ChatPromptEntity? chatPrompt, int? userId}) {
    debugPrint("conversation：${conversation?.toJson()},chatPrompt${chatPrompt?.toJson()},userId:$userId");
    currentChatPrompt = null;
    if (conversation != null) {
      lastChat = conversation;
    } else if (userId != null && userId > 0) {
      UserAPI.getUserInfo(userId).then((value) {
        lastChat = ConversationLast(
          conversationId: DateTime.now().millisecondsSinceEpoch,
          lastSenderId: value.id,
          lastSender: value.nickName,
          lastSenderAvatar: value.avatar ?? "",
          lastSendTime: DateTime.now().toString(),
          content: "",
          type: "user",
          userId: UserStore.to.userId,
        );
      }).catchError((err) {
        Loading.error("该用户获取失败");
      });
    } else if (chatPrompt != null) {
      currentChatPrompt = chatPrompt;
      lastChat = ConversationLast(
        conversationId: DateTime.now().millisecondsSinceEpoch,
        promptId: chatPrompt.id,
        lastSender: chatPrompt.title,
        lastSenderAvatar: chatPrompt.avatar,
        lastSendTime: DateTime.now().toString(),
        content: "",
        type: ChatPromptRoleEnum.user.name,
        userId: UserStore.to.userId,
      );
    } else {
      lastChat = ConversationLast(
        conversationId: DateTime.now().millisecondsSinceEpoch,
        lastSender: "AI机器人",
        lastSenderAvatar: Assets.robotAvatar,
        lastSendTime: DateTime.now().toString(),
        content: "",
        type: ChatPromptRoleEnum.user.name,
        userId: UserStore.to.userId,
      );
    }
    Get.toNamed(Routes.currentChat, arguments: DateTime.now());
  }

  void toBottom() {
    // 滚动到最底部
    scrollContrller.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeIn,
    );
  }

  void toAddChatStore(Conversation conversation) {
    ChatStore.to.chats.insert(0, conversation);
    DbSqlite.instance.insert("chat", conversation.toJson());
    Future.delayed(const Duration(milliseconds: 200), () => toBottom());
  }

  void toAddChatLastStore(Conversation conversation) {
    lastChat!.content = conversation.content;
    lastChat!.lastSendTime = DateTime.now().toString();
    ChatStore.to.lastChats.removeWhere((element) => element.conversationId == conversation.conversationId);
    ChatStore.to.lastChats.insert(0, lastChat!);
    DbSqlite.instance.insertExist("chat_last", lastChat!.toJson(), "conversationId=?", [conversation.conversationId]);
    Future.delayed(const Duration(milliseconds: 200), () => toBottom());
  }
}
