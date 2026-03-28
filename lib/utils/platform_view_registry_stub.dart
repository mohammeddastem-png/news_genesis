typedef PlatformViewFactory = dynamic Function(int viewId);

void registerPlatformViewFactory(String viewType, PlatformViewFactory factory) {
  // No-op for non-web platforms.
}
