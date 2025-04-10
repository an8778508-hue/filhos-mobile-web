import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) async {
        if (request.url.contains("payment/status/success")) {
          Navigator.of(context).pop(true);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageStarted: (url) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            setState(() {
              isLoading = true;
            });
          }
        });
      },
      onPageFinished: (url) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        });
      },
    ));
    controller.loadRequest(Uri.parse(
        Config.get.appInfo.privacyUrl));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: (LocalizationKeys.privacy_policy).tr(context),
        hasNotification: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: WebViewWidget(
                      controller: controller,
                    ),
                  ),
                  if (isLoading)
                    const Center(
                      child: Loading(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
