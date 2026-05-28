# zoloz_demo_flutter

A demo project demonstrating how to integrate ZOLOZ identity verification services using the Flutter plugin (client/server mode).

## Supported Products

- RealID
- Face Capture
- ID Recognition
- Connect

## Supported Platforms

- Android 4.4+
- iOS 9+

> Note: x86 architecture is not supported. Only armeabi, arm64-v8a, and armeabi-v7a are supported.

## Requirements

- Flutter >= 2.0.0
- Dart SDK >= 2.12.0 (null safety)

## Integration Architecture

The ZOLOZ Flutter plugin integration consists of two parts:

1. **Client-side integration**: Integrate the ZOLOZ Flutter plugin into your Flutter app. The plugin invokes native iOS/Android SDKs to capture user data (e.g., face images, ID card images).
2. **Server-side integration**: Expose endpoints on your server so the Flutter app can communicate with it, then call ZOLOZ APIs to initialize transactions and perform double-check on verification results.

## Quick Start

### 1. Install Dependencies

Add the following to your `pubspec.yaml`:

```yaml
environment:
  sdk: '>=2.18.5 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  zolozkit_for_flutter: ^1.1.4
  path_provider: ^2.0.15
```

> It is recommended to use the latest plugin version. See [pub.dev](https://pub.dev/packages/zolozkit_for_flutter) for release notes.

### 2. Get Meta Info

```dart
var metaInfo = await ZolozkitForFlutter.metaInfo;
```

### 3. Initialize Transaction

The Flutter app sends a request containing the meta info to the merchant server, which calls the `initialize` API to obtain the client configuration and returns it to the app.

### 4. Start Transaction

```dart
await ZolozkitForFlutter.start(
  result['clientCfg'],
  {},
  (String retCode, Map<Object?, Object?>? extInfo) {
    print("onInterrupted:$retCode, $extInfo");
  },
  (String retCode, Map<Object?, Object?>? extInfo) {
    print("onComplete:$retCode, $extInfo");
  },
);
```

- `onComplete`: The user has completed the interaction flow. Sync the transaction status with your server and call the `checkResult` API for double-checking.
- `onInterrupted`: The user did not complete the interaction flow. Handle it according to your business requirements.

## Custom UI Configuration (Optional)

### 1. Configure and Export UI File

Refer to the [ZOLOZ UI configuration documentation](https://docs.zoloz.com/zoloz/saas/cn/rhs0mlqb) to configure and export the UI configuration file.

### 2. Import Configuration File

Save the configuration file to your project (e.g., `files/UIConfig.zip`) and declare it in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - files/UIConfig.zip
```

### 3. Start SDK with Configuration File

```dart
import 'package:path_provider/path_provider.dart';

Future<String> copyUIConfigFile() async {
  var file = await rootBundle.load("files/UIConfig.zip");
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String configFilePath = "${appDocDir.path}/UIConfig.zip";
  final buffer = file.buffer;
  await File(configFilePath).writeAsBytes(
    buffer.asUint8List(file.offsetInBytes, file.lengthInBytes),
  );
  return configFilePath;
}

void startZoloz() async {
  var configPath = await ZolozkitForFlutter.zolozChameleonConfigPath;
  String configFilePath = await copyUIConfigFile();
  await ZolozkitForFlutter.start(
    result['clientCfg'],
    {configPath: configFilePath},
    (String retCode, Map<Object?, Object?>? extInfo) {
      print("onInterrupted:$retCode, $extInfo");
    },
    (String retCode, Map<Object?, Object?>? extInfo) {
      print("onComplete:$retCode, $extInfo");
    },
  );
}
```

### 4. Configure Locale (Optional)

```dart
var configPath = await ZolozkitForFlutter.zolozChameleonConfigPath;
var local = await ZolozkitForFlutter.zolozLocale;
await ZolozkitForFlutter.start(
  result['clientCfg'],
  {configPath: configFilePath, local: "zh-CN"},
  (String retCode, Map<Object?, Object?>? extInfo) {
    print("onInterrupted:$retCode, $extInfo");
  },
  (String retCode, Map<Object?, Object?>? extInfo) {
    print("onComplete:$retCode, $extInfo");
  },
);
```

> The `zolozLocale` parameter must be in `language-Country` format, e.g., `zh-CN`.

## ProGuard Configuration (Android Only)

If ProGuard is enabled, add the following configuration:

### 1. Modify `android/app/build.gradle`

```gradle
android {
  buildTypes {
    release {
      proguardFiles getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro"
    }
  }
}
```

### 2. Add ProGuard Rules

Create or edit `android/app/proguard-rules.pro` and add:

```proguard
-dontwarn com.zoloz.**
-keep class okio.** { *; }
-keep class com.alibaba.fastjson.** { *; }
-keep class com.alibaba.fastjson2.** { *; }
-keep class com.zoloz.zhub.** { *; }
-keep class com.alipay.zoloz.** { *; }
-keep class com.zoloz.zcore.facade.common.** { *; }
-keep class com.alipay.android.phone.zoloz.** { *; }
-keep class com.alipay.biometrics.** { *; }
-keep class com.alipay.bis.** { *; }
-keep class com.alipay.mobile.security.** { *; }
-keep class com.ap.zoloz.** { *; }
-keep class com.ap.zhubid.endpoint.** { *; }
-keep class com.zoloz.android.phone.zdoc.** { *; }
-keep class zoloz.ap.com.toolkit.** { *; }
-keep class com.zoloz.builder.** { *; }
-keep class com.ant.phone.xmedia.** { *; }
-keep class com.alipay.alipaysecuritysdk.** { *; }
-keep class com.alipay.blueshield.** { *; }
-keep class com.alipay.deviceid.** { *; }
-keep class com.alipay.edge.** { *; }
-keep class com.alipay.softtee.** { *; }
-keep class com.alipay.apmobilesecuritysdk.** { *; }
-keep class face.security.device.api.** { *; }
-keep class com.zoloz.zeta.** { *; }
-dontwarn face.security.device.api.**
```

## Interaction Flow

1. The user initiates a business flow (e.g., identity verification) from the Flutter app.
2. The Flutter app calls `ZolozkitForFlutter.metaInfo` to obtain meta info.
3. The Flutter app sends the meta info to the merchant server.
4. The merchant server calls the `initialize` API to get the client configuration.
5. The Flutter app uses the client configuration to start the ZOLOZ plugin.
6. The plugin invokes the native SDK to capture data and upload it for verification.
7. After the transaction completes, the Flutter app syncs with the server, which calls the `checkResult` API for double-checking.
8. The server returns the desensitized result to the Flutter app.

> Sensitive data (e.g., face images) is only returned to the merchant server, never to the client app.

## References

- [ZOLOZ Flutter Plugin Integration Guide](https://docs.zoloz.com/zoloz/saas/cn/rhs0mlqb)
- [zolozkit_for_flutter (pub.dev)](https://pub.dev/packages/zolozkit_for_flutter)
