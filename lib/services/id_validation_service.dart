/// Validation result for sprite ID
class IdValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> conflictingSpriteIds;

  const IdValidationResult({
    required this.isValid,
    this.errorMessage,
    this.conflictingSpriteIds = const [],
  });

  const IdValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        conflictingSpriteIds = const [];

  const IdValidationResult.invalid(String message)
      : isValid = false,
        errorMessage = message,
        conflictingSpriteIds = const [];

  const IdValidationResult.duplicate(List<String> conflicts)
      : isValid = false,
        errorMessage = 'Duplicate ID',
        conflictingSpriteIds = conflicts;
}

/// Service for validating sprite IDs
class IdValidationService {
  const IdValidationService();

  /// Allowed characters pattern: alphanumeric and underscore
  static final RegExp _allowedPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

  /// Validate ID format
  IdValidationResult validateFormat(String id) {
    if (id.isEmpty) {
      return const IdValidationResult.invalid('ID cannot be empty');
    }

    if (id.length > 64) {
      return const IdValidationResult.invalid('ID too long (max 64 chars)');
    }

    if (!_allowedPattern.hasMatch(id)) {
      return const IdValidationResult.invalid(
        'ID must start with a letter and contain only letters, numbers, and underscores',
      );
    }

    return const IdValidationResult.valid();
  }

  /// Check for duplicate IDs in sprite list
  IdValidationResult checkDuplicate(
    String newId,
    String currentId,
    List<String> allIds,
  ) {
    // If ID hasn't changed, it's valid
    if (newId == currentId) {
      return const IdValidationResult.valid();
    }

    // Check for duplicates
    final duplicates = allIds.where((id) => id == newId && id != currentId).toList();

    if (duplicates.isNotEmpty) {
      return IdValidationResult.duplicate(duplicates);
    }

    return const IdValidationResult.valid();
  }

  /// Full validation: format + duplicate check
  IdValidationResult validate(
    String newId,
    String currentId,
    List<String> allIds,
  ) {
    // First check format
    final formatResult = validateFormat(newId);
    if (!formatResult.isValid) {
      return formatResult;
    }

    // Then check for duplicates
    return checkDuplicate(newId, currentId, allIds);
  }

  /// Find all duplicate IDs in the sprite list
  Map<String, List<int>> findDuplicates(List<String> ids) {
    final duplicates = <String, List<int>>{};

    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      if (duplicates.containsKey(id)) {
        duplicates[id]!.add(i);
      } else {
        // Check if this ID appears later in the list
        for (int j = i + 1; j < ids.length; j++) {
          if (ids[j] == id) {
            duplicates[id] = [i, j];
            break;
          }
        }
      }
    }

    return duplicates;
  }

  /// Check if any duplicate IDs exist
  bool hasDuplicates(List<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (seen.contains(id)) {
        return true;
      }
      seen.add(id);
    }
    return false;
  }
}
