import 'package:freezed_annotation/freezed_annotation.dart';

part 'animation_sequence.freezed.dart';
part 'animation_sequence.g.dart';

/// Animation loop mode
enum AnimationLoopMode {
  /// Play once and stop at the last frame
  once,

  /// Loop continuously
  loop,

  /// Play forward then backward (ping-pong)
  pingPong,
}

/// Single frame in an animation sequence
@freezed
class AnimationFrame with _$AnimationFrame {
  const AnimationFrame._();

  const factory AnimationFrame({
    /// Reference to sprite ID
    required String spriteId,

    /// Duration in seconds (must be > 0)
    @Default(0.1) double duration,

    /// Horizontal flip
    @Default(false) bool flipX,

    /// Vertical flip
    @Default(false) bool flipY,
  }) = _AnimationFrame;

  factory AnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$AnimationFrameFromJson(json);

  /// Duration in milliseconds
  int get durationMs => (duration * 1000).round();

  /// Validate frame
  bool get isValid => duration > 0 && spriteId.isNotEmpty;
}

/// Animation sequence containing multiple frames
@freezed
class AnimationSequence with _$AnimationSequence {
  const AnimationSequence._();

  const factory AnimationSequence({
    /// Unique animation ID
    required String id,

    /// Display name
    @Default('Animation') String name,

    /// List of frames in order
    @Default([]) List<AnimationFrame> frames,

    /// Loop mode
    @Default(AnimationLoopMode.loop) AnimationLoopMode loopMode,

    /// Playback speed multiplier (1.0 = normal)
    @Default(1.0) double speed,

    /// Frames per second (1-60)
    @Default(12) int fps,
  }) = _AnimationSequence;

  factory AnimationSequence.fromJson(Map<String, dynamic> json) =>
      _$AnimationSequenceFromJson(json);

  /// Total duration in seconds
  double get totalDuration =>
      frames.fold(0.0, (sum, frame) => sum + frame.duration);

  /// Total duration in milliseconds
  int get totalDurationMs => (totalDuration * 1000).round();

  /// Frame count
  int get frameCount => frames.length;

  /// Check if animation has valid frames
  bool get isValid => frames.isNotEmpty && frames.every((f) => f.isValid);

  /// Check if animation is empty
  bool get isEmpty => frames.isEmpty;

  /// Get frame at index (safe)
  AnimationFrame? getFrameAt(int index) {
    if (index < 0 || index >= frames.length) return null;
    return frames[index];
  }

  /// Get all sprite IDs used in this animation
  Set<String> get usedSpriteIds => frames.map((f) => f.spriteId).toSet();

  /// Check if a sprite ID is used in this animation
  bool usesSpriteId(String spriteId) =>
      frames.any((f) => f.spriteId == spriteId);

  /// Create a copy with a frame added at the end
  AnimationSequence addFrame(AnimationFrame frame) {
    return copyWith(frames: [...frames, frame]);
  }

  /// Create a copy with a frame removed
  AnimationSequence removeFrameAt(int index) {
    if (index < 0 || index >= frames.length) return this;
    final newFrames = List<AnimationFrame>.from(frames)..removeAt(index);
    return copyWith(frames: newFrames);
  }

  /// Create a copy with frames reordered
  AnimationSequence reorderFrame(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= frames.length) return this;
    if (newIndex < 0 || newIndex > frames.length) return this;

    final newFrames = List<AnimationFrame>.from(frames);
    final frame = newFrames.removeAt(oldIndex);
    newFrames.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, frame);
    return copyWith(frames: newFrames);
  }

  /// Create a copy with a frame updated at index
  AnimationSequence updateFrameAt(int index, AnimationFrame frame) {
    if (index < 0 || index >= frames.length) return this;
    final newFrames = List<AnimationFrame>.from(frames);
    newFrames[index] = frame;
    return copyWith(frames: newFrames);
  }

  /// Set uniform duration for all frames
  AnimationSequence setUniformDuration(double duration) {
    return copyWith(
      frames: frames.map((f) => f.copyWith(duration: duration)).toList(),
    );
  }
}
