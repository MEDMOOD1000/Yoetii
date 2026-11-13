import 'package:flutter/material.dart';
import 'package:mornye/theme/app_motion.dart';
import 'package:mornye/theme/material_expressive.dart';

/// Wraps a child in a staggered fade-in + slide-up animation.
///
/// [index] controls the stagger delay (each item delayed by [staggerDelay]).
/// Set [animate] to false to skip the animation. Only the list's first
/// reveal animates: a lazy list builds rows again as they scroll into view,
/// and those appear at once, so no row replays it or animates while others
/// do not.
class StaggeredListItem extends StatelessWidget {
  static const int _maxAnimatedItems = 10;

  final int index;
  final Widget child;
  final Duration duration;
  final Duration staggerDelay;
  final bool animate;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.staggerDelay = const Duration(milliseconds: 40),
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final scrolled =
        position != null &&
        position.hasContentDimensions &&
        position.pixels > position.minScrollExtent;
    if (!animate ||
        scrolled ||
        index >= _maxAnimatedItems ||
        MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final cappedIndex = index.clamp(0, _maxAnimatedItems - 1);
    final delay = staggerDelay * cappedIndex;
    if (materialExpressiveEnabled(context)) {
      // Expressive: each item springs up after its own delay and may
      // overshoot slightly; opacity stays within range.
      final motion = AppMotion.spatial(
        context,
        AppMotionSpec(duration, Curves.easeOutCubic),
      );
      final total = motion.duration + delay;
      final delayFraction = total.inMicroseconds > 0
          ? delay.inMicroseconds / total.inMicroseconds
          : 0.0;
      return TweenAnimationBuilder<double>(
        key: ValueKey('stagger_$index'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: total,
        builder: (context, value, child) {
          final elapsed = value <= delayFraction
              ? 0.0
              : ((value - delayFraction) / (1.0 - delayFraction)).clamp(
                  0.0,
                  1.0,
                );
          final progress = motion.curve.transform(elapsed);
          return Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - progress)),
              child: child,
            ),
          );
        },
        child: child,
      );
    }
    final totalDuration = duration + delay;

    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: totalDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayFraction = totalDuration.inMilliseconds > 0
            ? delay.inMilliseconds / totalDuration.inMilliseconds
            : 0.0;
        final progress = value <= delayFraction
            ? 0.0
            : ((value - delayFraction) / (1.0 - delayFraction)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Creates a platform-aware material route.
///
/// This intentionally defers route transitions to Flutter's material route and
/// theme so Android predictive back and platform-default animations remain
/// intact.
Route<T> slidePageRoute<T>({required Widget page}) {
  return MaterialPageRoute<T>(builder: (context) => page);
}

/// A shimmer effect widget that can wrap skeleton placeholders.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  /// The surface the placeholders sit on; defaults to the page surface. Pass
  /// a card or group color so the placeholders keep their contrast on it.
  final Color? surface;

  const ShimmerLoading({super.key, required this.child, this.surface});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.surface == null
        ? widget.child
        : _SkeletonSurface(color: widget.surface!, child: widget.child);
    if (MediaQuery.disableAnimationsOf(context)) return content;
    final surface = widget.surface ?? Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.10), surface);
    final highlightColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.14), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.01), surface);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      // The mask moves every frame; the skeleton beneath it does not.
      child: RepaintBoundary(child: content),
    );
  }
}

/// The surface a [ShimmerLoading] declared, so still placeholders (reduced
/// motion) keep their contrast on a card or group as well.
class _SkeletonSurface extends InheritedWidget {
  const _SkeletonSurface({required this.color, required super.child});

  final Color color;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonSurface>()?.color;

  @override
  bool updateShouldNotify(_SkeletonSurface oldWidget) =>
      color != oldWidget.color;
}

/// A skeleton placeholder box used inside [ShimmerLoading].
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        _SkeletonSurface.maybeOf(context) ??
        Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), surface);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCrossfade extends StatelessWidget {
  final Widget child;

  const SkeletonCrossfade({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      // Loading and loaded screens may carry the same Hero tag (both render
      // the header cover); mute the outgoing child's heroes so a pop during
      // the fade doesn't find duplicate tags.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => HeroMode(
            enabled:
                animation.status == AnimationStatus.forward ||
                animation.status == AnimationStatus.completed,
            child: child!,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// An animated selection indicator that crossfades the checked/unchecked
/// state.
class AnimatedSelectionCheckbox extends StatelessWidget {
  final bool selected;
  final ColorScheme colorScheme;
  final double size;

  /// Background color when not selected. Defaults to `Colors.transparent`.
  final Color? unselectedColor;

  const AnimatedSelectionCheckbox({
    super.key,
    required this.selected,
    required this.colorScheme,
    this.size = 20,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final fill = AppMotion.effectsFast(
      context,
      const AppMotionSpec(Duration(milliseconds: 200), Curves.linear),
    );
    return AnimatedContainer(
      duration: fill.duration,
      curve: fill.curve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary
            : unselectedColor ?? Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: selected
            ? Icon(
                Icons.check,
                key: const ValueKey('checked'),
                size: size - 6,
                color: colorScheme.onPrimary,
              )
            : SizedBox(
                key: const ValueKey('unchecked'),
                width: size - 6,
                height: size - 6,
              ),
      ),
    );
  }
}

/// A widget that briefly flashes a success color behind its child and shows
/// an animated checkmark when [showSuccess] transitions to true.
class AnimatedBadge extends StatefulWidget {
  final int count;
  final Widget child;

  const AnimatedBadge({super.key, required this.count, required this.child});

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _previousCount && widget.count > _previousCount) {
      _controller.forward(from: 0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
