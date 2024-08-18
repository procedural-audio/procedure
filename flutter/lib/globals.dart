import 'plugins.dart';
import 'core.dart';
import 'patch/patch.dart';

Globals globals = Globals();

class Globals {
  Core core = Core.create();
  Assets assets = Assets.platformDefault();
}
