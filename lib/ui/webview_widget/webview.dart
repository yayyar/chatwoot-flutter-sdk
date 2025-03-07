import 'dart:convert';
import 'dart:io';

import 'package:chatwoot_sdk_support/chatwoot_sdk.dart';
import 'package:chatwoot_sdk_support/ui/webview_widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_flutter_android;

///Chatwoot webview widget
/// {@category FlutterClientSdk}
class Webview extends StatefulWidget {
  /// Url for Chatwoot widget in webview
  late final String widgetUrl;

  /// Chatwoot user & locale initialisation script
  late final String injectedJavaScript;

  /// See [ChatwootWidget.closeWidget]
  final void Function()? closeWidget;

  /// See [ChatwootWidget.onAttachFile]
  final Future<List<String>> Function()? onAttachFile;

  /// See [ChatwootWidget.onLoadStarted]
  final void Function()? onLoadStarted;

  /// See [ChatwootWidget.onLoadProgress]
  final void Function(int)? onLoadProgress;

  /// See [ChatwootWidget.onLoadCompleted]
  final void Function()? onLoadCompleted;

  Webview(
      {Key? key,
      required String websiteToken,
      required String baseUrl,
      ChatwootUser? user,
      String locale = "en",
      customAttributes,
      this.closeWidget,
      this.onAttachFile,
      this.onLoadStarted,
      this.onLoadProgress,
      this.onLoadCompleted})
      : super(key: key) {
    widgetUrl =
        "${baseUrl}/widget?website_token=${websiteToken}&locale=${locale}";

    injectedJavaScript = generateScripts(
        user: user, locale: locale, customAttributes: customAttributes);
  }

  @override
  _WebviewState createState() => _WebviewState();
}

class _WebviewState extends State<Webview> {
  WebViewController? _controller;
  bool hasError = false;
  String errorMessage = "Something went wrong! Please try again.";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String webviewUrl = widget.widgetUrl;
      final cwCookie = await StoreHelper.getCookie();
      if (cwCookie.isNotEmpty) {
        webviewUrl = "${webviewUrl}&cw_conversation=${cwCookie}";
      }
      setState(() {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading bar.
                widget.onLoadProgress?.call(progress);
                hasError = false;
              },
              onPageStarted: (String url) {
                widget.onLoadStarted?.call();
              },
              onPageFinished: (String url) async {
                widget.onLoadCompleted?.call();
              },
              onWebResourceError: (WebResourceError error) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  hasError = true;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                // _goToUrl(request.url);
                return NavigationDecision.navigate;
              },
            ),
          )
          ..addJavaScriptChannel("ReactNativeWebView",
              onMessageReceived: (JavaScriptMessage jsMessage) {
            print("Chatwoot message received: ${jsMessage.message}");
            final message = getMessage(jsMessage.message);
            if (isJsonString(message)) {
              final parsedMessage = jsonDecode(message);
              final eventType = parsedMessage["event"];
              final type = parsedMessage["type"];
              if (eventType == 'loaded') {
                final authToken = parsedMessage["config"]["authToken"];
                StoreHelper.storeCookie(authToken);
                _controller?.runJavaScript(widget.injectedJavaScript);
              }
              if (type == 'close-widget') {
                widget.closeWidget?.call();
              }
            }
          })
          ..loadRequest(Uri.parse(webviewUrl));

        if (Platform.isAndroid && widget.onAttachFile != null) {
          final androidController = _controller!.platform
              as webview_flutter_android.AndroidWebViewController;
          androidController
              .setOnShowFileSelector((_) => widget.onAttachFile!.call());
        }
      });
    });
  }

  void onRetry(){
    setState(() {
      hasError = false;
    });
    _controller.loadRequest(Uri.parse(webviewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return _controller != null
        ? hasError
            ? WebErrorView(onRetry: onRetry, errorMessage: errorMessage)
            : WebViewWidget(controller: _controller!)
        : SizedBox();
  }
}
