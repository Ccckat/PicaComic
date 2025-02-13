import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../base.dart';

///Flutter内置的SelectableText弹出菜单为英文, 这个对其作出修改
class SelectableTextCN extends StatelessWidget {
  const SelectableTextCN({required this.text, this.style, this.items, this.withAddToBlockKeywordButton=false, super.key});
  final String text;
  final TextStyle? style;
  final List<ContextMenuButtonItem>? items;
  final bool withAddToBlockKeywordButton;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      contextMenuBuilder: (context, state) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: text.substring(state.currentTextEditingValue.selection.start,
                          state.currentTextEditingValue.selection.end)));
                  state.hideToolbar();
                },
                label: "复制".tr),
            ContextMenuButtonItem(
                onPressed: () {
                  state.selectAll(SelectionChangedCause.toolbar);
                },
                label: "全选".tr),
            if(withAddToBlockKeywordButton)
            ContextMenuButtonItem(
                onPressed: () {
                  final select = text.substring(state.currentTextEditingValue.selection.start,
                      state.currentTextEditingValue.selection.end);

                  if(select == "" || appdata.blockingKeyword.contains(select)){
                    state.hideToolbar();
                    return;
                  }
                  appdata.blockingKeyword.add(select);
                  appdata.writeData();
                  state.hideToolbar();
                },
                label: "添加至屏蔽词".tr),
          ],
        );
      },
    );
  }
}
