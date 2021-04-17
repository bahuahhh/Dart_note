/*

面向对象编程(OOP)的三个基本特征是：//todo  封装、继承、多态      

      封装：封装是对象和类概念的主要特性。封装，把客观事物封装成抽象的类，并且把自己的部分属性和方法提供给其他对象调用, 而一部分属性和方法则隐藏。
                
      继承：面向对象编程 (OOP) 语言的一个主要功能就是“继承”。继承是指这样一种能力：它可以使用现有类的功能，并在无需重新编写原来的类的情况下对这些功能进行扩展。
            
      多态：允许将子类类型的指针赋值给父类类型的指针, 同一个函数调用会有不同的执行效果 。


Dart所有的东西都是对象，所有的对象都继承自Object类。

Dart是一门使用类和单继承的面向对象语言，所有的对象都是类的实例，并且所有的类都是Object的子类

///todo    一个类通常由属性和方法组成。

*/

void main() {
  // ignore: deprecated_member_use
  List list = <String>[];
  list.isEmpty;
  list.add('香蕉');
  list.add('香蕉1');

  Map m = new Map();
  m["username"] = "张三";
  m.addAll({"age": 20});
  m.isEmpty;

  Object a = 123;
  Object v = true;
  print(a);
  print(v);
  // ignore: deprecated_member_use
  print(list);
}
