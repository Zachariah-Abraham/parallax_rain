# Changelog

## [1.4.0](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.3.0...v1.4.0) (2026-11-14)


### Features

* add alignment to position the child inside the rain area ([#19](https://github.com/Zachariah-Abraham/parallax_rain/issues/19)) ([c61d12d](https://github.com/Zachariah-Abraham/parallax_rain/commit/c61d12db3fd3f99a3023d8cbc223e2f462ea1441))

## [1.3.0](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.2.0...v1.3.0) (2026-11-14)


### Features

* add an angle to tilt the fall direction of the rain ([#16](https://github.com/Zachariah-Abraham/parallax_rain/issues/16)) ([8667430](https://github.com/Zachariah-Abraham/parallax_rain/commit/866743071287e6485f93b7c89dae044df9df0b15))
* make the ParallaxRain constructor const ([#15](https://github.com/Zachariah-Abraham/parallax_rain/issues/15)) ([34eb229](https://github.com/Zachariah-Abraham/parallax_rain/commit/34eb22934f08577aabed3cc4190323e6b57a0f8d))

## [1.2.0](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.1.3...v1.2.0) (2026-11-13)


### Features

* stop the rain when the system asks for reduced motion ([#12](https://github.com/Zachariah-Abraham/parallax_rain/issues/12)) ([aacb781](https://github.com/Zachariah-Abraham/parallax_rain/commit/aacb7810f5851c46de29e11de285ef64cfa5df8c))

## [1.1.3](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.1.2...v1.1.3) (2026-11-13)


### Bug Fixes

* apply new ParallaxRain settings after the first build ([#7](https://github.com/Zachariah-Abraham/parallax_rain/issues/7)) ([11b224b](https://github.com/Zachariah-Abraham/parallax_rain/commit/11b224b83d02efcba29d69bc967508a025a7dfbf))
* keep the rain spread over the area when its size changes ([#8](https://github.com/Zachariah-Abraham/parallax_rain/issues/8)) ([63a8c52](https://github.com/Zachariah-Abraham/parallax_rain/commit/63a8c5293fb3314e3ede63ad1d1582196e914207))
* stop importing the deprecated Material library ([#10](https://github.com/Zachariah-Abraham/parallax_rain/issues/10)) ([3ff1265](https://github.com/Zachariah-Abraham/parallax_rain/commit/3ff1265a3c8f2ce98236556ac2b15d3cb06886eb))

## [1.1.2](https://github.com/Zachariah-Abraham/parallax_rain/compare/v1.1.1...v1.1.2) (2026-11-10)


### Bug Fixes

* stop the animation on dispose and use frame-rate independent speed ([0880de9](https://github.com/Zachariah-Abraham/parallax_rain/commit/0880de981226e0c46f11c3ac8d28b2f36ce2cc21))

## 1.1.1

* Relaxed SDK constraints.

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
