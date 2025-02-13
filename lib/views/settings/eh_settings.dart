import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import '../../base.dart';
import '../widgets/select.dart';

class EhSettings extends StatefulWidget {
  const EhSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<EhSettings> createState() => _EhSettingsState();
}

class _EhSettingsState extends State<EhSettings> {
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        child: Column(
          children: [
            const ListTile(
              title: Text("E-Hentai"),
            ),
            ListTile(
              leading: Icon(Icons.domain, color: Theme.of(context).colorScheme.secondary),
              title: Text("画廊站点".tr),
              trailing: Select(
                initialValue: int.parse(appdata.settings[20]),
                width: 150,
                values: const [
                  "e-hentai.org",
                  "exhentai.org",
                ],
                whenChange: (i){
                  appdata.settings[20] = i.toString();
                  appdata.updateSettings();
                  EhNetwork().updateUrl();
                },
                inPopUpWidget: widget.popUp,
              ),
              //onTap: () => setEhDomain(context),
            ),
          ],
        ));
  }
}
