/// Image group model for merged source images (Photoshop-style layer groups)
class ImageGroup {
  final String id;
  final String name;
  final List<String> sourceIds; // 그룹 내 소스 ID들
  final bool isExpanded; // 펼침/접힘 상태
  final DateTime createdAt;

  const ImageGroup({
    required this.id,
    required this.name,
    required this.sourceIds,
    this.isExpanded = true,
    required this.createdAt,
  });

  ImageGroup copyWith({
    String? id,
    String? name,
    List<String>? sourceIds,
    bool? isExpanded,
    DateTime? createdAt,
  }) {
    return ImageGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceIds: sourceIds ?? this.sourceIds,
      isExpanded: isExpanded ?? this.isExpanded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get sprite count display text
  int get sourceCount => sourceIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImageGroup) return false;
    return id == other.id &&
        name == other.name &&
        isExpanded == other.isExpanded &&
        _listEquals(sourceIds, other.sourceIds);
  }

  @override
  int get hashCode => Object.hash(id, name, isExpanded, Object.hashAll(sourceIds));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
