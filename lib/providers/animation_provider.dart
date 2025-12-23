import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/animation_sequence.dart';

/// State for managing animation sequences
class AnimationState {
  /// All animation sequences in the project
  final List<AnimationSequence> sequences;

  /// Currently selected animation ID
  final String? selectedAnimationId;

  /// Currently selected frame index within the selected animation
  final int? selectedFrameIndex;

  /// Whether animation is currently playing
  final bool isPlaying;

  /// Current frame index during playback
  final int currentPlaybackFrame;

  /// Counter for generating unique animation IDs
  final int nextId;

  /// Direction for ping-pong playback (1 = forward, -1 = backward)
  final int pingPongDirection;

  const AnimationState({
    this.sequences = const [],
    this.selectedAnimationId,
    this.selectedFrameIndex,
    this.isPlaying = false,
    this.currentPlaybackFrame = 0,
    this.nextId = 0,
    this.pingPongDirection = 1,
  });

  AnimationState copyWith({
    List<AnimationSequence>? sequences,
    String? selectedAnimationId,
    int? selectedFrameIndex,
    bool? isPlaying,
    int? currentPlaybackFrame,
    int? nextId,
    int? pingPongDirection,
    bool clearSelectedAnimation = false,
    bool clearSelectedFrame = false,
  }) {
    return AnimationState(
      sequences: sequences ?? this.sequences,
      selectedAnimationId: clearSelectedAnimation
          ? null
          : (selectedAnimationId ?? this.selectedAnimationId),
      selectedFrameIndex: clearSelectedFrame
          ? null
          : (selectedFrameIndex ?? this.selectedFrameIndex),
      isPlaying: isPlaying ?? this.isPlaying,
      currentPlaybackFrame: currentPlaybackFrame ?? this.currentPlaybackFrame,
      nextId: nextId ?? this.nextId,
      pingPongDirection: pingPongDirection ?? this.pingPongDirection,
    );
  }

  /// Get currently selected animation
  AnimationSequence? get selectedAnimation {
    if (selectedAnimationId == null) return null;
    try {
      return sequences.firstWhere((a) => a.id == selectedAnimationId);
    } catch (_) {
      return null;
    }
  }

  /// Get currently selected frame
  AnimationFrame? get selectedFrame {
    final anim = selectedAnimation;
    if (anim == null || selectedFrameIndex == null) return null;
    return anim.getFrameAt(selectedFrameIndex!);
  }

  /// Total animation count
  int get count => sequences.length;

  /// Check if any animation is selected
  bool get hasSelection => selectedAnimationId != null;
}

/// Notifier for animation state management
class AnimationNotifier extends StateNotifier<AnimationState> {
  AnimationNotifier() : super(const AnimationState());

  /// Generate unique animation ID
  String _generateId() {
    final id = 'anim_${state.nextId}';
    state = state.copyWith(nextId: state.nextId + 1);
    return id;
  }

  // ============================================
  // Animation Sequence Operations
  // ============================================

  /// Create a new animation sequence
  AnimationSequence createAnimation({String? name}) {
    final id = _generateId();
    final animation = AnimationSequence(
      id: id,
      name: name ?? 'Animation ${state.sequences.length + 1}',
    );

    state = state.copyWith(
      sequences: [...state.sequences, animation],
      selectedAnimationId: id,
    );

    return animation;
  }

  /// Delete animation by ID
  void deleteAnimation(String animationId) {
    final isSelected = state.selectedAnimationId == animationId;

    state = state.copyWith(
      sequences: state.sequences.where((a) => a.id != animationId).toList(),
      clearSelectedAnimation: isSelected,
      clearSelectedFrame: isSelected,
      isPlaying: isSelected ? false : state.isPlaying,
    );
  }

  /// Select animation by ID
  void selectAnimation(String animationId) {
    if (!state.sequences.any((a) => a.id == animationId)) return;

    state = state.copyWith(
      selectedAnimationId: animationId,
      clearSelectedFrame: true,
      isPlaying: false,
      currentPlaybackFrame: 0,
      pingPongDirection: 1, // Reset ping-pong direction when selecting new animation
    );
  }

  /// Clear animation selection
  void clearSelection() {
    state = state.copyWith(
      clearSelectedAnimation: true,
      clearSelectedFrame: true,
      isPlaying: false,
    );
  }

  /// Update animation properties
  void updateAnimation(String animationId, AnimationSequence updated) {
    state = state.copyWith(
      sequences: state.sequences.map((a) {
        return a.id == animationId ? updated : a;
      }).toList(),
    );
  }

  /// Rename animation
  void renameAnimation(String animationId, String newName) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.copyWith(name: newName));
  }

  /// Set loop mode for animation
  void setLoopMode(String animationId, AnimationLoopMode mode) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.copyWith(loopMode: mode));
  }

  /// Set playback speed for animation
  void setSpeed(String animationId, double speed) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.copyWith(speed: speed.clamp(0.1, 10.0)));
  }

  /// Set FPS for animation
  void setFps(String animationId, int fps) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.copyWith(fps: fps.clamp(1, 60)));
  }

  // ============================================
  // Frame Operations
  // ============================================

  /// Add frame to animation
  void addFrame(String animationId, String spriteId, {double duration = 0.1}) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    final frame = AnimationFrame(spriteId: spriteId, duration: duration);
    updateAnimation(animationId, animation.addFrame(frame));
  }

  /// Add multiple frames from sprite IDs
  void addFramesFromSprites(
    String animationId,
    List<String> spriteIds, {
    double duration = 0.1,
  }) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    var updated = animation;
    for (final spriteId in spriteIds) {
      final frame = AnimationFrame(spriteId: spriteId, duration: duration);
      updated = updated.addFrame(frame);
    }
    updateAnimation(animationId, updated);
  }

  /// Remove frame at index
  void removeFrameAt(String animationId, int index) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.removeFrameAt(index));

    // Clear frame selection if removed frame was selected
    if (state.selectedAnimationId == animationId &&
        state.selectedFrameIndex == index) {
      state = state.copyWith(clearSelectedFrame: true);
    }
  }

  /// Select frame at index
  void selectFrame(int index) {
    final animation = state.selectedAnimation;
    if (animation == null) return;
    if (index < 0 || index >= animation.frameCount) return;

    state = state.copyWith(selectedFrameIndex: index);
  }

  /// Clear frame selection
  void clearFrameSelection() {
    state = state.copyWith(clearSelectedFrame: true);
  }

  /// Reorder frame
  void reorderFrame(String animationId, int oldIndex, int newIndex) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.reorderFrame(oldIndex, newIndex));

    // Update selected frame index if needed
    if (state.selectedAnimationId == animationId &&
        state.selectedFrameIndex != null) {
      final selectedIdx = state.selectedFrameIndex!;
      int newSelectedIdx = selectedIdx;

      if (selectedIdx == oldIndex) {
        // The selected frame was moved
        newSelectedIdx = newIndex > oldIndex ? newIndex - 1 : newIndex;
      } else if (oldIndex < selectedIdx && newIndex >= selectedIdx) {
        // Frame moved from before to after selected
        newSelectedIdx = selectedIdx - 1;
      } else if (oldIndex > selectedIdx && newIndex <= selectedIdx) {
        // Frame moved from after to before selected
        newSelectedIdx = selectedIdx + 1;
      }

      if (newSelectedIdx != selectedIdx) {
        state = state.copyWith(selectedFrameIndex: newSelectedIdx);
      }
    }
  }

  /// Update frame at index
  void updateFrameAt(String animationId, int index, AnimationFrame frame) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.updateFrameAt(index, frame));
  }

  /// Update frame duration
  void setFrameDuration(String animationId, int index, double duration) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    final frame = animation.getFrameAt(index);
    if (frame == null) return;

    updateFrameAt(animationId, index, frame.copyWith(duration: duration));
  }

  /// Toggle frame flipX
  void toggleFrameFlipX(String animationId, int index) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    final frame = animation.getFrameAt(index);
    if (frame == null) return;

    updateFrameAt(animationId, index, frame.copyWith(flipX: !frame.flipX));
  }

  /// Toggle frame flipY
  void toggleFrameFlipY(String animationId, int index) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    final frame = animation.getFrameAt(index);
    if (frame == null) return;

    updateFrameAt(animationId, index, frame.copyWith(flipY: !frame.flipY));
  }

  /// Set uniform duration for all frames
  void setUniformDuration(String animationId, double duration) {
    final animation = _getAnimation(animationId);
    if (animation == null) return;

    updateAnimation(animationId, animation.setUniformDuration(duration));
  }

  // ============================================
  // Playback Control
  // ============================================

  /// Start playback
  void play() {
    if (state.selectedAnimation == null) return;
    if (state.selectedAnimation!.isEmpty) return;

    state = state.copyWith(isPlaying: true);
  }

  /// Pause playback
  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  /// Stop playback and reset to first frame
  void stop() {
    state = state.copyWith(
      isPlaying: false,
      currentPlaybackFrame: 0,
    );
  }

  /// Toggle play/pause
  void togglePlayback() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Set current playback frame (for animation tick)
  void setPlaybackFrame(int frame) {
    final animation = state.selectedAnimation;
    if (animation == null || animation.isEmpty) return;

    state = state.copyWith(
      currentPlaybackFrame: frame.clamp(0, animation.frameCount - 1),
    );
  }

  /// Advance to next frame (for animation tick)
  /// Returns true if animation should continue
  bool advanceFrame() {
    final animation = state.selectedAnimation;
    if (animation == null || animation.isEmpty) {
      stop();
      return false;
    }

    final currentFrame = state.currentPlaybackFrame;
    final direction = state.pingPongDirection;

    switch (animation.loopMode) {
      case AnimationLoopMode.once:
        final nextFrame = currentFrame + 1;
        if (nextFrame >= animation.frameCount) {
          stop();
          return false;
        }
        state = state.copyWith(currentPlaybackFrame: nextFrame);
        return true;

      case AnimationLoopMode.loop:
        final nextFrame = (currentFrame + 1) % animation.frameCount;
        state = state.copyWith(currentPlaybackFrame: nextFrame);
        return true;

      case AnimationLoopMode.pingPong:
        // Ping-pong: 0,1,2,3,2,1,0,1,2,3...
        int nextFrame = currentFrame + direction;
        int newDirection = direction;

        if (nextFrame >= animation.frameCount) {
          // Reached end, reverse direction
          nextFrame = animation.frameCount - 2;
          newDirection = -1;
          if (nextFrame < 0) nextFrame = 0;
        } else if (nextFrame < 0) {
          // Reached start, reverse direction
          nextFrame = 1;
          newDirection = 1;
          if (nextFrame >= animation.frameCount) nextFrame = 0;
        }

        state = state.copyWith(
          currentPlaybackFrame: nextFrame.clamp(0, animation.frameCount - 1),
          pingPongDirection: newDirection,
        );
        return true;
    }
  }

  /// Get current frame's duration in milliseconds
  int getCurrentFrameDurationMs() {
    final animation = state.selectedAnimation;
    if (animation == null || animation.isEmpty) return 100;

    final frame = animation.getFrameAt(state.currentPlaybackFrame);
    if (frame == null) return 100;

    return frame.durationMs;
  }

  /// Go to first frame
  void goToFirstFrame() {
    state = state.copyWith(currentPlaybackFrame: 0);
  }

  /// Go to last frame
  void goToLastFrame() {
    final animation = state.selectedAnimation;
    if (animation == null || animation.isEmpty) return;

    state = state.copyWith(currentPlaybackFrame: animation.frameCount - 1);
  }

  /// Go to previous frame
  void previousFrame() {
    if (state.currentPlaybackFrame > 0) {
      state = state.copyWith(currentPlaybackFrame: state.currentPlaybackFrame - 1);
    }
  }

  /// Go to next frame
  void nextFrame() {
    final animation = state.selectedAnimation;
    if (animation == null || animation.isEmpty) return;

    if (state.currentPlaybackFrame < animation.frameCount - 1) {
      state = state.copyWith(currentPlaybackFrame: state.currentPlaybackFrame + 1);
    }
  }

  // ============================================
  // Utility
  // ============================================

  AnimationSequence? _getAnimation(String id) {
    try {
      return state.sequences.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear all animations
  void clearAll() {
    state = const AnimationState();
  }

  /// Load animations from project data
  void loadFromProject(List<AnimationSequence> animations) {
    if (animations.isEmpty) {
      clearAll();
      return;
    }

    // Find max ID number for nextId
    int maxIdNum = 0;
    for (final anim in animations) {
      final match = RegExp(r'anim_(\d+)').firstMatch(anim.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxIdNum) maxIdNum = num;
      }
    }

    state = AnimationState(
      sequences: animations,
      nextId: maxIdNum + 1,
    );
  }

  /// Get animation by ID
  AnimationSequence? getAnimationById(String id) => _getAnimation(id);

  /// Check if a sprite is used in any animation
  bool isSpriteUsed(String spriteId) {
    return state.sequences.any((a) => a.usesSpriteId(spriteId));
  }

  /// Get all animations using a sprite
  List<AnimationSequence> getAnimationsUsingSpriteId(String spriteId) {
    return state.sequences.where((a) => a.usesSpriteId(spriteId)).toList();
  }
}

/// Provider for animation state
final animationProvider =
    StateNotifierProvider<AnimationNotifier, AnimationState>((ref) {
  return AnimationNotifier();
});

/// Provider for selected animation
final selectedAnimationProvider = Provider<AnimationSequence?>((ref) {
  return ref.watch(animationProvider).selectedAnimation;
});

/// Provider for selected frame
final selectedFrameProvider = Provider<AnimationFrame?>((ref) {
  return ref.watch(animationProvider).selectedFrame;
});

/// Provider for playback state
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(animationProvider).isPlaying;
});

/// Provider for current playback frame index
final currentPlaybackFrameProvider = Provider<int>((ref) {
  return ref.watch(animationProvider).currentPlaybackFrame;
});

/// Provider for animation count
final animationCountProvider = Provider<int>((ref) {
  return ref.watch(animationProvider).count;
});
