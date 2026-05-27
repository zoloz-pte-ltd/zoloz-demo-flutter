import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zolozkit_for_flutter/zolozkit_for_flutter.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String hostErrorText = "";
  TextEditingController hostController =
  TextEditingController.fromValue(TextEditingValue(
    text: "http://lan_ip:lan_port",
    //need  bizserver ,refer to this link :https://docs.zoloz.com/zoloz/saas/integration/neug2p#YzBBl
  ));
  TextEditingController apiController =
      TextEditingController.fromValue(TextEditingValue(
    text: "/api/realid/initialize",
  ));

  TextEditingController docTypeController =
      TextEditingController.fromValue(TextEditingValue(
    text: "00000001003",
  ));
  TextEditingController serviceLevelController =
      TextEditingController.fromValue(TextEditingValue(
    text: "REALID0001",
  ));

  @override
  void initState() {
    super.initState();
  }

  Future<String> copyUIConfigFile() async {
    var file = await rootBundle.load("files/UIConfig.zip");
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String configFilePath = "${appDocDir.path}/UIConfig.zip";
    final buffer = file.buffer;
    await File(configFilePath).writeAsBytes(
        buffer.asUint8List(file.offsetInBytes, file.lengthInBytes));
    return configFilePath;
  }

  void checkResult(String transationId) async {
    var uri =
     Uri.http('lan_ip:lan_port', '/api/realid/checkresult');
    var body = jsonEncode({
      "transactionId": transationId
    });
    var httpClient = new HttpClient();
    var request = await httpClient.postUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(body));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var result = json.decode(responseBody);
    print(result.toString());
  }


  Future<String> loadJsonFromAssets(String assetsPath) async {
    return await rootBundle.loadString(assetsPath);
  }

  void startZoloz() async {
    var httpPath = hostController.text;
    var api = apiController.text;
    var docType = docTypeController.text;
    var serviceLevel = serviceLevelController.text;
    var httpClient = new HttpClient();
    var metaInfo = await ZolozkitForFlutter.metaInfo;
    var local = await ZolozkitForFlutter.zolozLocale;
    var configPath = await ZolozkitForFlutter.zolozChameleonConfigPath;
    var uri;
    if (httpPath.startsWith("https")) {
      uri = Uri.https(httpPath.replaceAll("https://", ""), api);
    } else if (httpPath.startsWith("http")) {
      uri = Uri.http(httpPath.replaceAll("http://", ""), api);
    } else {
      return;
    }
    print(uri);
    var body = jsonEncode({
      "metaInfo": metaInfo,
      "serviceLevel": serviceLevel,
      "docType": docType
    });
    var request = await httpClient.postUrl(uri);
    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(body));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var result = json.decode(responseBody);
    print(result.toString());
    String configFilePath = await copyUIConfigFile();

    await ZolozkitForFlutter.start(result['clientCfg'], {
      configPath: configFilePath,
      local: "en"
    },
    (String retCode, Map<Object?, Object?>? extInfo) {
        print("onInterrupted:$retCode, $extInfo");
    },
    (String retCode, Map<Object?, Object?>? extInfo) {
        print("onComplete:$retCode, $extInfo");
        //checkResult(result["transactionId"]);
    },
);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ZOLOZ Flutter SaaS Example'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              new Container(
                padding: const EdgeInsets.all(8.0),
                child: new TextField(
                  maxLines: 1,
                  controller: hostController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5.0),
                    icon: Icon(Icons.http),
                    errorText: hostErrorText,
                    labelText: 'Host Address',
                    helperText: 'Host Address Example: http://lan_ip:lan_port',
                  ),
                ),
              ),
              new Container(
                padding: const EdgeInsets.all(8.0),
                child: new TextField(
                  maxLines: 1,
                  controller: apiController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5.0),
                    icon: Icon(Icons.api),
                    labelText: 'API Path',
                    helperText: 'API Path Example: /api/realid/initialize',
                  ),
                ),
              ),
              new Container(
                padding: const EdgeInsets.all(8.0),
                child: new TextField(
                  maxLines: 1,
                  controller: docTypeController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5.0),
                    icon: Icon(Icons.file_copy),
                    labelText: 'Doc Type',
                    helperText: 'Doc Type Example: 00000001003',
                  ),
                ),
              ),
              new Container(
                padding: const EdgeInsets.all(8.0),
                child: new TextField(
                  maxLines: 1,
                  controller: serviceLevelController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5.0),
                    icon: Icon(Icons.approval),
                    labelText: 'Service Level',
                    helperText: 'Service Level Example: REALID0002',
                  ),
                ),
              ),
              new Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text("Initialize"),
                    onPressed: startZoloz,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
