import 'dart:math';
import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveSizer {
  ResponsiveSizer._();

  static final ResponsiveSizer instance = ResponsiveSizer._();

  static const double _tabletShortestSide = 600;
  static const double _desktopShortestSide = 900;
  static const double _tabletDampenFactor = 0.55;
  static const double _desktopDampenFactor = 0.4;
  static const double _minScaleRatio = 0.7;
  static const double _maxScaleRatio = 1.9;
  static const double _maxRadiusRatio = 1.6;
  static const double _minFontRatio = 0.8;
  static const double _maxFontRatioMobile = 1.3;
  static const double _maxFontRatioLarge = 1.15;
  static const double _defaultDesignWidth = 375;
  static const double _defaultDesignHeight = 812;

  Size _screenSize = const Size(_defaultDesignWidth, _defaultDesignHeight);
  double _designWidth = _defaultDesignWidth;
  double _designHeight = _defaultDesignHeight;
  double _devicePixelRatio = 1;
  Orientation _orientation = Orientation.portrait;
  DeviceType _deviceType = DeviceType.mobile;
  double _maxDesktopContentWidth = 480;
  double _maxTabletContentWidth = 420;
  bool _initialized = false;

  void init(
    Size size,
    double devicePixelRatio,
    Orientation orientation, {
    double designWidth = _defaultDesignWidth,
    double designHeight = _defaultDesignHeight,
    double maxTabletContentWidth = 420,
    double maxDesktopContentWidth = 480,
  }) {
    _screenSize = size;
    _designWidth = designWidth <= 0 ? _defaultDesignWidth : designWidth;
    _designHeight = designHeight <= 0 ? _defaultDesignHeight : designHeight;
    _devicePixelRatio = devicePixelRatio;
    _orientation = orientation;
    _deviceType = _resolveDeviceType(size);
    _maxTabletContentWidth = maxTabletContentWidth;
    _maxDesktopContentWidth = maxDesktopContentWidth;
    _initialized = true;
  }

  @visibleForTesting
  void reset() {
    _screenSize = const Size(_defaultDesignWidth, _defaultDesignHeight);
    _designWidth = _defaultDesignWidth;
    _designHeight = _defaultDesignHeight;
    _devicePixelRatio = 1;
    _orientation = Orientation.portrait;
    _deviceType = DeviceType.mobile;
    _initialized = false;
  }

  DeviceType _resolveDeviceType(Size size) {
    final shortest = size.shortestSide;
    if (shortest >= _desktopShortestSide) return DeviceType.desktop;
    if (shortest >= _tabletShortestSide) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  void _ensureInitialized() {
    assert(
      _initialized,
      'ResponsiveSizer is not initialized. '
      'Wrap your app with ResponsiveInit above MaterialApp '
      'or inside MaterialApp.builder.',
    );
  }

  double get screenWidth {
    _ensureInitialized();
    return _screenSize.width;
  }

  double get screenHeight {
    _ensureInitialized();
    return _screenSize.height;
  }

  double get devicePixelRatio {
    _ensureInitialized();
    return _devicePixelRatio;
  }

  Orientation get orientation {
    _ensureInitialized();
    return _orientation;
  }

  DeviceType get deviceType {
    _ensureInitialized();
    return _deviceType;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  double get _rawWidthRatio {
    _ensureInitialized();
    return _screenSize.shortestSide / _designWidth;
  }

  double get _rawHeightRatio {
    _ensureInitialized();
    return _screenSize.longestSide / _designHeight;
  }

  double _dampen(double rawRatio) {
    if (isMobile) return rawRatio;
    final factor = isTablet ? _tabletDampenFactor : _desktopDampenFactor;
    return 1 + (rawRatio - 1) * factor;
  }

  double scaleWidth(double value) {
    final ratio = _dampen(_rawWidthRatio).clamp(_minScaleRatio, _maxScaleRatio);
    return value * ratio;
  }

  double scaleHeight(double value) {
    final ratio = _dampen(
      _rawHeightRatio,
    ).clamp(_minScaleRatio, _maxScaleRatio);
    return value * ratio;
  }

  double scaleRadius(double value) {
    final ratio = _dampen(
      min(_rawWidthRatio, _rawHeightRatio),
    ).clamp(_minScaleRatio, _maxRadiusRatio);
    return value * ratio;
  }

  double scaleFont(double value) {
    final ratio = _dampen(
      min(_rawWidthRatio, _rawHeightRatio),
    ).clamp(_minFontRatio, isMobile ? _maxFontRatioMobile : _maxFontRatioLarge);
    return value * ratio;
  }

  double percentWidth(double percent) => screenWidth * (percent / 100);

  double percentHeight(double percent) => screenHeight * (percent / 100);

  double adaptiveMaxContentWidth() {
    if (isDesktop) return _maxDesktopContentWidth;
    if (isTablet) return _maxTabletContentWidth;
    return screenWidth;
  }
}

class ResponsiveInit extends StatelessWidget {
  final Widget child;
  final double designWidth;
  final double designHeight;
  final double minTextScale;
  final double maxTextScale;
  final double maxTabletContentWidth;
  final double maxDesktopContentWidth;

  const ResponsiveInit({
    super.key,
    required this.child,
    this.designWidth = 375,
    this.designHeight = 812,
    this.minTextScale = 0.85,
    this.maxTextScale = 1.25,
    this.maxTabletContentWidth = 420,
    this.maxDesktopContentWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final textScaler = MediaQuery.textScalerOf(context);

    ResponsiveSizer.instance.init(
      size,
      devicePixelRatio,
      orientation,
      designWidth: designWidth,
      designHeight: designHeight,
      maxTabletContentWidth: maxTabletContentWidth,
      maxDesktopContentWidth: maxDesktopContentWidth,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: textScaler.clamp(
          minScaleFactor: minTextScale,
          maxScaleFactor: maxTextScale,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('${size.width}x${size.height}-$orientation'),
        child: child,
      ),
    );
  }
}

extension ResponsiveNumExtension on num {
  double get w => ResponsiveSizer.instance.scaleWidth(toDouble());
  double get h => ResponsiveSizer.instance.scaleHeight(toDouble());
  double get sp => ResponsiveSizer.instance.scaleFont(toDouble());
  double get r => ResponsiveSizer.instance.scaleRadius(toDouble());
  double get sw => ResponsiveSizer.instance.percentWidth(toDouble());
  double get sh => ResponsiveSizer.instance.percentHeight(toDouble());
}

extension ResponsiveContextExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomSafeHeight => MediaQuery.paddingOf(this).bottom;
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;
  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
  DeviceType get deviceType => ResponsiveSizer.instance.deviceType;
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  double get adaptiveMaxContentWidth =>
      ResponsiveSizer.instance.adaptiveMaxContentWidth();
}

class AdaptiveContentWrapper extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final double? maxWidth;

  const AdaptiveContentWrapper({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return child;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.adaptiveMaxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
