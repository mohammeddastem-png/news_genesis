import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

typedef PlatformViewFactory = html.Element Function(int viewId);

void registerPlatformViewFactory(String viewType, PlatformViewFactory factory) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, factory);
}
