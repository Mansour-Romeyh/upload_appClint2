// // // lib/screens/in_app_webview_screen.dart
// // // شاشة WebView داخلية — بتفتح أي URL جوه التطبيق

// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:webview_flutter/webview_flutter.dart';
// // import '../utils/theme.dart';

// // class InAppWebViewScreen extends StatefulWidget {
// //   final String url;
// //   final String title;

// //   const InAppWebViewScreen({
// //     super.key,
// //     required this.url,
// //     this.title = '',
// //   });

// //   @override
// //   State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
// // }

// // class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
// //   late final WebViewController _controller;
// //   bool _isLoading = true;
// //   bool _hasError = false;
// //   String _currentTitle = '';
// //   double _progress = 0;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _currentTitle = widget.title;

// //     _controller = WebViewController()
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..setBackgroundColor(Colors.white)
// //       ..setNavigationDelegate(NavigationDelegate(
// //         onPageStarted: (url) {
// //           if (mounted)
// //             setState(() {
// //               _isLoading = true;
// //               _hasError = false;
// //             });
// //         },
// //         onPageFinished: (url) async {
// //           if (mounted) {
// //             final title = await _controller.getTitle();
// //             setState(() {
// //               _isLoading = false;
// //               if (title != null && title.isNotEmpty) _currentTitle = title;
// //             });
// //           }
// //         },
// //         onProgress: (progress) {
// //           if (mounted) setState(() => _progress = progress / 100.0);
// //         },
// //         onWebResourceError: (_) {
// //           if (mounted)
// //             setState(() {
// //               _isLoading = false;
// //               _hasError = true;
// //             });
// //         },
// //       ))
// //       ..loadRequest(Uri.parse(widget.url));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppTheme.background,
// //       appBar: AppBar(
// //         backgroundColor: AppTheme.background,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
// //           onPressed: () async {
// //             if (await _controller.canGoBack()) {
// //               _controller.goBack();
// //             } else {
// //               if (context.mounted) Navigator.pop(context);
// //             }
// //           },
// //         ),
// //         title: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               _currentTitle.isNotEmpty ? _currentTitle : widget.url,
// //               style:
// //                   AppTheme.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
// //               maxLines: 1,
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //             Text(
// //               Uri.parse(widget.url).host,
// //               style: AppTheme.tajawal(
// //                   fontSize: 11, color: AppTheme.textSecondaryinWhite),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           // زرار Refresh
// //           IconButton(
// //             icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
// //             onPressed: () => _controller.reload(),
// //           ),
// //           // زرار Share / Open in browser
// //           IconButton(
// //             icon: const Icon(Icons.open_in_browser,
// //                 color: Colors.black, size: 20),
// //             onPressed: () async {
// //               // نسخ اللينك للـ clipboard
// //               await _launch(widget.url);
// //               if (context.mounted) {
// //                 ScaffoldMessenger.of(context).showSnackBar(
// //                   SnackBar(
// //                     content: Text('الفتح في متصفح خارجي',
// //                         style: AppTheme.tajawal(color: Colors.white)),
// //                     backgroundColor: AppTheme.primary,
// //                     behavior: SnackBarBehavior.floating,
// //                     shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(10)),
// //                     margin: const EdgeInsets.all(16),
// //                     duration: const Duration(seconds: 2),
// //                   ),
// //                 );
// //               }
// //             },
// //           ),
// //         ],
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(3),
// //           child: _isLoading
// //               ? LinearProgressIndicator(
// //                   value: _progress > 0 ? _progress : null,
// //                   backgroundColor: Colors.grey[200],
// //                   valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
// //                   minHeight: 3,
// //                 )
// //               : Container(height: 1, color: const Color(0xFFEEEEEE)),
// //         ),
// //       ),
// //       body: _hasError
// //           ? Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   const Icon(Icons.wifi_off,
// //                       size: 64, color: AppTheme.textSecondaryinWhite),
// //                   const SizedBox(height: 16),
// //                   Text('تعذّر تحميل الصفحة',
// //                       style: AppTheme.tajawal(
// //                           color: AppTheme.textSecondaryinWhite, fontSize: 16)),
// //                   const SizedBox(height: 24),
// //                   ElevatedButton(
// //                     onPressed: () => _controller.reload(),
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: AppTheme.primary,
// //                       shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(12)),
// //                     ),
// //                     child: Text('إعادة المحاولة',
// //                         style: AppTheme.tajawal(
// //                             color: Colors.white, fontWeight: FontWeight.bold)),
// //                   ),
// //                 ],
// //               ),
// //             )
// //           : WebViewWidget(controller: _controller),
// //     );
// //   }

// //   Future<void> _launch(String url) async {
// //     try {
// //       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
// //     } catch (_) {}
// //   }
// // }
// // lib/screens/in_app_webview_screen.dart
// // شاشة WebView داخلية — بتفتح أي URL جوه التطبيق

// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../utils/theme.dart';

// class InAppWebViewScreen extends StatefulWidget {
//   final String url;
//   final String title;

//   const InAppWebViewScreen({
//     super.key,
//     required this.url,
//     this.title = '',
//   });

//   @override
//   State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
// }

// class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   bool _hasError = false;
//   String _currentTitle = '';
//   double _progress = 0;

//   // ── اللينكات دي مش هتتفتح في الـ WebView — هتتفتح خارجياً ──────
//   static const _externalHosts = [
//     'ty.gl',
//     'app.adjust.com',
//     'adjust.com',
//     'onelink.me',
//     'play.google.com',
//     'apps.apple.com',
//     'itunes.apple.com',
//     'market://',
//   ];

//   /// بيرجع true لو اللينك المفروض يتفتح خارج الـ WebView
//   bool _shouldOpenExternally(String url) {
//     // أي scheme غير http/https (مثلاً intent://, market://, whatsapp://)
//     if (!url.startsWith('http://') && !url.startsWith('https://')) return true;

//     final host = Uri.tryParse(url)?.host ?? '';
//     return _externalHosts.any((h) => host.contains(h));
//   }

//   @override
//   void initState() {
//     super.initState();
//     _currentTitle = widget.title;

//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(NavigationDelegate(
//         // ── Intercept كل navigation ────────────────────────────
//         onNavigationRequest: (request) {
//           if (_shouldOpenExternally(request.url)) {
//             _launch(request.url); // افتحه خارجياً
//             return NavigationDecision.prevent; // امنعه من الـ WebView
//           }
//           return NavigationDecision.navigate;
//         },
//         onPageStarted: (url) {
//           if (mounted)
//             setState(() {
//               _isLoading = true;
//               _hasError = false;
//             });
//         },
//         onPageFinished: (url) async {
//           if (mounted) {
//             final title = await _controller.getTitle();
//             setState(() {
//               _isLoading = false;
//               if (title != null && title.isNotEmpty) _currentTitle = title;
//             });
//           }
//         },
//         onProgress: (progress) {
//           if (mounted) setState(() => _progress = progress / 100.0);
//         },
//         onWebResourceError: (_) {
//           if (mounted)
//             setState(() {
//               _isLoading = false;
//               _hasError = true;
//             });
//         },
//       ))
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       appBar: AppBar(
//         backgroundColor: AppTheme.background,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
//           onPressed: () async {
//             if (await _controller.canGoBack()) {
//               _controller.goBack();
//             } else {
//               if (context.mounted) Navigator.pop(context);
//             }
//           },
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _currentTitle.isNotEmpty ? _currentTitle : widget.url,
//               style:
//                   AppTheme.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             Text(
//               Uri.parse(widget.url).host,
//               style: AppTheme.tajawal(
//                   fontSize: 11, color: AppTheme.textSecondaryinWhite),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
//             onPressed: () => _controller.reload(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.open_in_browser,
//                 color: Colors.black, size: 20),
//             onPressed: () async {
//               await _launch(widget.url);
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('الفتح في متصفح خارجي',
//                         style: AppTheme.tajawal(color: Colors.white)),
//                     backgroundColor: AppTheme.primary,
//                     behavior: SnackBarBehavior.floating,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                     margin: const EdgeInsets.all(16),
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               }
//             },
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(3),
//           child: _isLoading
//               ? LinearProgressIndicator(
//                   value: _progress > 0 ? _progress : null,
//                   backgroundColor: Colors.grey[200],
//                   valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
//                   minHeight: 3,
//                 )
//               : Container(height: 1, color: const Color(0xFFEEEEEE)),
//         ),
//       ),
//       body: _hasError
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.wifi_off,
//                       size: 64, color: AppTheme.textSecondaryinWhite),
//                   const SizedBox(height: 16),
//                   Text('تعذّر تحميل الصفحة',
//                       style: AppTheme.tajawal(
//                           color: AppTheme.textSecondaryinWhite, fontSize: 16)),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () => _controller.reload(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.primary,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: Text('إعادة المحاولة',
//                         style: AppTheme.tajawal(
//                             color: Colors.white, fontWeight: FontWeight.bold)),
//                   ),
//                 ],
//               ),
//             )
//           : WebViewWidget(controller: _controller),
//     );
//   }

//   Future<void> _launch(String url) async {
//     try {
//       final uri = Uri.parse(url);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       }
//     } catch (_) {}
//   }
// }