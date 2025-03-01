import 'dart:convert';

import 'package:http/http.dart' as http;

class PluginInfo {
  String username;
  String repository;
  String tag;
  List<String> tags;

  PluginInfo({
    required this.username,
    required this.repository,
    required this.tag,
    required this.tags
  });

  static Future<PluginInfo> create(String username, String repository) async {
    var tags = await getTags(username, repository);
    return PluginInfo(
      username: username,
      repository: repository,
      tag: tags[0],
      tags: tags
    );
  }

  static Future<List<String>> getTags(String username, String repository) async {
    var uri = Uri.parse('https://api.github.com/repos/$username/$repository/tags');
    var response = await http.get(uri);
    var json = jsonDecode(response.body);

    List<String> tags = [];
    for (var tag in json) {
      tags.add(tag["name"]);
    }

    return tags;
  }

  void refreshTags() async {
    tags = await getTags(username, repository);
    print("Refreshed tags: $tags");
  }

  Map<String, dynamic> toJson() {
    return {
      "usearname": username,
      "repository": repository,
      "tag": tag,
      "tags": tags
    };
  }

  PluginInfo fromJson(Map<String, dynamic> json) {
    return PluginInfo(
      username: json["username"],
      repository: json["repository"],
      tag: json["tag"],
      tags: json["tags"]
    );
  }
}
