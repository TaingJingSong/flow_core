import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const _deepEq = DeepCollectionEquality();

/// Free-form document-level information. Safe to extend.
@immutable
class FlowMetadata {
  const FlowMetadata({
    this.title,
    this.description,
    this.author,
    this.createdAt,
    this.updatedAt,
    this.tags = const <String>{},
    this.custom = const <String, Object?>{},
  });

  final String? title;
  final String? description;
  final String? author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Set<String> tags;
  final Map<String, Object?> custom;

  FlowMetadata copyWith({
    Object? title = _unset,
    Object? description = _unset,
    Object? author = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
    Set<String>? tags,
    Map<String, Object?>? custom,
  }) =>
      FlowMetadata(
        title: title == _unset ? this.title : title as String?,
        description:
            description == _unset ? this.description : description as String?,
        author: author == _unset ? this.author : author as String?,
        createdAt:
            createdAt == _unset ? this.createdAt : createdAt as DateTime?,
        updatedAt:
            updatedAt == _unset ? this.updatedAt : updatedAt as DateTime?,
        tags: tags ?? this.tags,
        custom: custom ?? this.custom,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowMetadata &&
          other.title == title &&
          other.description == description &&
          other.author == author &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          const SetEquality<String>().equals(other.tags, tags) &&
          _deepEq.equals(other.custom, custom);

  @override
  int get hashCode => Object.hash(
        title,
        description,
        author,
        createdAt,
        updatedAt,
        const SetEquality<String>().hash(tags),
        _deepEq.hash(custom),
      );

  @override
  String toString() => 'FlowMetadata(${title ?? 'untitled'})';
}

const Object _unset = Object();