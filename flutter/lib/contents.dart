import 'dart:io';

class Resources {
  Resources(this.path);

  String path;

  static Resources platformDefault() {
    if (Platform.isMacOS) {
      return Resources("/Users/chasekanipe/Github/resources");
    }

    print("Couldn't find contents folder");
    exit(1);
  }
}
