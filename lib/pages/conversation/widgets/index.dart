import 'package:juai/pages/conversation/widgets/firends_dialog.dart';
import 'package:juai/common/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PageViewMessage extends StatefulWidget {
  const PageViewMessage({Key? key}) : super(key: key);

  @override
  State<PageViewMessage> createState() => _PageViewMessageState();
}

class _PageViewMessageState extends State<PageViewMessage> {
  @override
  void initState() {
    super.initState();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: const Text('聊天'),
              actions: [
                PopupMenuButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add,
                    size: WcaoTheme.fsBase * 1.75,
                  ),
                  onSelected: (item) async {
                    if (item == 1) {
                    } else if (item == 2) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) => const FirendsDialog(),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.crop_free),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: const Text('扫一扫'),
                          ),
                        ],
                      ),
                      value: 1,
                    ),
                    PopupMenuItem(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.how_to_reg),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: const Text('添加好友'),
                          ),
                        ],
                      ),
                      value: 2,
                    ),
                  ],
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // search(),
                    ...[1, 2, 3]
                        .map(
                          (e) => InkWell(
                            child: listCard(),
                            onTap: () => Get.toNamed('/message/chat'),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container listCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage("erorr"),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              margin: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: .5,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(.5),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "已删除",
                        style: TextStyle(
                          fontSize: WcaoTheme.fsXl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'T',
                        style: TextStyle(fontSize: WcaoTheme.fsSm, color: Theme.of(context).colorScheme.secondary),
                      )
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(right: 24),
                            child: Text(
                              "item.text",
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: WcaoTheme.fsBase,
                              ),
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 10,
                          child: Text(
                            'item.fav',
                            style: TextStyle(fontSize: WcaoTheme.fsSm),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Container search() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).focusColor,
        ),
        child: TextField(
          enableSuggestions: false,
          autocorrect: false,
          style: TextStyle(fontSize: WcaoTheme.fsBase),
          decoration: const InputDecoration(
            hintText: "请输入搜索关键词",
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
