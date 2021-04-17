// void main() {
//   var n = "hello";

//   print(n);
// }

/*    set最大功能就是去重
set是没有顺序不能重复的集合，也不能通过索引值去获取值
// */
// main() {
//   var s = Set();
//   s.add('heehh');
//   s.add('heehh');
//   s.add('heehh');
//   print(s);
// }

/* main() {
  // List myList = ['1', '2', '3'];
  // myList.forEach((element) {
  //   print(element);
  // });

  var s = Set();
  s.addAll([1.2, 3]);
  s.forEach((element) {
    print(element);
  });
}
 */

//方法定义（函数）
// print() 内置函数

//  返回类型 函数名（参数）{
//    方法体
//    return  fanhuzihi1
//  }

// main(List<String> args) {
//   getNum();
//   print(getNum());
// }

// printInfo() {}
// int getNum() {
//   var myNum = 13;
//   return myNum;
// }

// 调用方法传参
// main() {
//   int sunNumber(int n) {
//     var sum = 0;
//     for (var i = 0; i < n; i++) {
//       sum += i;
//     }
//     return sum;
//   }

//   var n1 = sunNumber(5);
//   print(n1);
//   var n2 = sunNumber(100);
//   print(n2);
// }

/* main(List<String> args) {
  var sum = 0;
  fn(int n) {
    sum += n;

    if (n == 0) {
      return;
    }
    fn(n - 1);
  }

  print(fn(100));
  print(sum);
} */

// 匿名方法
// 就是
/* main(List<String> args) {
  Fm();
}
// ignore: top_level_function_literal_block
var Fm = () {
  // 把这个方法给Fm
  print(123);
};
 */

//? 自执行方法
/* main(List<String> args) {
  (() {
    print('hello');
  })();
}
 */

//? 方法递归就是调用自己

//? 闭包
//  就是方法里嵌套方法 既不会污染全局 还可以常驻内存
/*   fn() {
    var n = 132;
    return () {
      n++;
      print(n);
    };
  }

  var x = fn();
  x();
  x();
  x(); */

/* gz
 todo 类和对象 
  todo 类一般是由属性和方法组成
复习函数
    返回类型 函数名字（参数）{

        函数体
        return 返回值
    }
 */
//  todo自定义类需要class关键词放在方法外面
//todo 类的首字母一定要大写
//! 类语法
/* 
class HaiZi {
  String name = '张三';
  int age = 12; //属性
  HaiZi({
    required this.name,
    required this.age,
  });

  void getInfo() {
    print('${this.name}');
    print('${this.age}'); //方法
  }

  @override
  String toString() => 'HaiZi(name: $name, age: $age)';
}

main() {
  //实例化
  var h1 = HaiZi();
  print(h1.age);
  print(h1.name);
}
  */

//todo 构造函数
/* class HaiZi /*关键词  类名*/ {
  String name = '张三';
  int age = 12; //属性
  //默认构造函数
  HaiZi() {
    print('构造函数里面的内容你 在实例化的时候触发');
  }

  void getInfo() {
    print('${this.name}');
    print('${this.age}'); //方法
  }
}

//程序运行自动运行方法 就称之为构造函数
main(List<String> args) {
  HaiZi p1 = HaiZi();
}
 */

//todo 构造函数可以动态给HaiZi类指定属性
class HaiZi /*关键词  类名*/ {
/*   not_initialized_non_nullable_instance_field
必须初始化不可用实例字段"{0}"。
您还可以将字段标记为删除诊断的字段，但如果字段在访问之前未分配值，
则会导致在运行时间抛出异常值。只有在您确信该字段始终在引用之前始终被分配时，
才应使用此方法。late

class C {
  late int x;
} */

/*   late String name;
  late int age; //属性
  //默认构造函数
  HaiZi(String name, int age) {
    this.name = name;
    this.age = age;
  }

  void getInfo() {
    print('${this.name}${this.age}'); //方法
  }
}

//程序运行自动运行方法 就称之为构造函数
main() {
  //可以实例化多次
  HaiZi p1 = HaiZi('张随便拿', 12);
  HaiZi p2 = HaiZi('里斯', 16);
  p1.getInfo();
  p2.getInfo(); */

//? 简写
/*   String name;
  int age; //属性
  //默认构造函数
  HaiZi(this.name, this.age) {
    // this.name = name;
    // this.age = age;
  }

  void getInfo() {
    print('${this.name}${this.age}'); //方法
  }
}

//程序运行自动运行方法 就称之为构造函数
main() {
  //可以实例化多次
  HaiZi p1 = HaiZi('张随便拿', 12);
  HaiZi p2 = HaiZi('里斯', 16);
  p1.getInfo();
  p2.getInfo(); */

  // todo 命名构造函数
/*   late String name;
  late int age;
  HaiZi(this.name, this.age);
  HaiZi.now() {
    print('hello');
  }
  void getInfo() {
    print('${this.name}${this.age}'); //方法
  }
}
 */
/* main(List<String> args) {
  // HaiZi p1 = HaiZi('张随便拿', 12);
  HaiZi p2 = HaiZi.now(); //调用命名构造函数
} */
//默认构造函数只能写一个
//命名构造函数可以写多个
//_私有类 必须要单独抽出到一个文件他才有效果
//setter修饰可以计算
}

//demo
/* class MaTe {
  late String name;
  late int age;
  MaTe(this.name, this.age);
  MaTe.h1() {
    print('hello ');
  }
  MaTe.info(name, age) {
    this.age = age;
    this.name = name;
  }

  void printInfo() {
    print('${this.name}${this.age}');
  }
}

void main() {
  MaTe p1 = MaTe.info('bai bai', 29);
  p1.printInfo();
  MaTe p2 = MaTe.h1();
  p2.printInfo();
}
 */

// class Mate {
//   late String name;
//   late String sex;
//   late int age;
//   Mate(this.age, this.name, this.sex);
//   Mate.no() {
//     print('object');
//   }
//   Mate.setInfo(String name, String sex, int age) {
//     this.name = name;
//     this.sex = sex;
//     this.age = age;
//   }

//   void printInfo() {
//     print('%${this.name}/n${this.sex}/n${this.age}');
//   }
// }

// void main() {
//   Mate p1 = Mate.setInfo('白井黑子', '男', 12);
//   p1.printInfo();
//   Mate p2 = Mate.no();
//   p2.printInfo();
// }

// 常量构造函数

class ImmutablePoint {
  static final ImmutablePoint origin = const ImmutablePoint(0, 0);
  final num x, y;
  const ImmutablePoint(this.x, this.y);
}

main() {}
