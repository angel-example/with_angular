import 'package:angel_framework/common.dart';

class User extends Model {
  @override
  String id;
  @override
  DateTime createdAt, updatedAt;
  String username, password;

  User({this.id, this.username, this.password, this.createdAt, this.updatedAt});

  static User parse(Map map) => new User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String()
    };
  }
}

class Note extends Model {
  @override
  String id;
  @override
  DateTime createdAt, updatedAt;
  String userId, title, text;

  Note(
      {this.id,
      this.userId,
      this.title,
      this.text,
      this.createdAt,
      this.updatedAt});

  static Note parse(Map map) => new Note(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      text: map['text'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'text': text,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String()
    };
  }
}
