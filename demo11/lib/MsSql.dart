import '../../demo12/01Dart中implements实现多个接口.dart';
import 'Db.dart';

class MsSql implements Db {
  @override
  String uri;
  @override
  add(String data) {
    print('这是mssql的add方法' + data);
  }

  @override
  delete() {
    // TODO: implement delete
    return null;
  }

  @override
  save() {
    // TODO: implement save
    return null;
  }
}
