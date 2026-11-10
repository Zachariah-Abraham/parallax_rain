## 1.1.1

* Relaxed SDK constraints.

## [1.1.2](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.1.1...v1.1.2) (2026-11-10)


### Bug Fixes

* stop the animation on dispose and use frame-rate independent speed ([8ec7ec2](https://github.com/Zachariah-Abraham/parallax_rain/commit/8ec7ec255931d07e6059b8eab3ef9ba70dc4531d))
* stop the animation on dispose and use frame-rate independent speed ([0880de9](https://github.com/Zachariah-Abraham/parallax_rain/commit/0880de981226e0c46f11c3ac8d28b2f36ce2cc21))

## 1.1.0

* The ParallaxRain widget's painter will now ignore state changes so the rain doesn't reset every time setState is called. (unless you instantiate a new ParallaxRain widget on purpose).

## 1.0.4

* Fixed a bug that stopped the rain when used with a widget that provides infinite height or width (like a Row or a Column).

## 1.0.3

* Documentation fixes.

## 1.0.2

* The ParallaxRain widget now sizes itself to its child rather than its parent.

## 1.0.1

* Added documentation.

## 1.0.0

* Initial release. Supporting multiple colors, adjustable speeds, background and foreground rain and droplet trails.
