//todo 自定义类 类=属性+函数
/* class Person {      //放外面
//!类
  //属性    practice
  String name ='张三';
  int age = 23;            

  //方法
  void getInfo(){  //没有返回值 viod
      //  print('$name\n$age');
           print('${this.name}\n{$this.age}'); //推荐写法

    }
    void setInfo(int age){
      this.age=age;
    }
}
void main(){          //使用类
                        //需要实例化
/*   var p1 = new Person();

  print(p1.name);
  p1.getInfo();
 */

  Person p1=new Person();
  // print(p1.name);

  p1.setInfo(28);
  p1.getInfo();
 } 
 */

/* class Person {
  String name = '张三';
  int age = 23;
  void getInfo() {
    print('${this.name}\n{$this.age}');
  }
  void setInfo(int age) {
    this.age = age;
  }
}

void main() {
  Person p1 = new Person();
  p1.setInfo(28);
  p1.getInfo();
} */

/* class Person { 
  String name="张三";
  int age=23;
  void getInfo() {
      print("${this.name}----${this.age}");
  }
  void setInfo(int age){
    this.age=age;
  }
}
void main(){
  Person p1=new Person();
  p1.setInfo(28);
  p1.getInfo();
} */

/* class Person {
  String name ='张三';
  int age =23;
  void getInfo(){
    print('${this.name}\n{this.age}');

  }
  void setInfo(int age){
    this.age=age;
  }
  
}
void main(){
  Person p1 = new Person();
  p1.setInfo(28);
  p1.getInfo();
} */
//? 2020-3-6
// main(){

/*   String ar = "hello";
  String rr = "3-6";
  print('$rr\n$ar');
  print(ar+rr); */
// (1)
/*   var l1 =['1','2','3'];
  print(l1);
  print(l1.length);
  print(l1.toList());

//(2)
    var l2 = new List();
    l2.add('bai jin heizi');
    l2.add('yu ban mei qian');
    l2.add('guan yu');

    print(l2);

    var l3 = new List<String>();
    l3.add('2');

print(l3);

    var l4 = new List<int>();
    l4.add(3754);
    print(l4); */

/*     var e5={
      'name':'bai jing hei zi',
      'age':  20,
      'work':'ai pao jie',
    };
    print(e5);
    print(e5.toString()); */

/* 
    var e6 =new Map();
    e6['name']='bai jing';
    e6['age']=23;
    e6['work']='xie shou';
    e6['hobby']='kan man hua';

      print(e6); */

// String str ='123';
// var myNum = int.parse(str);
//   print(str);
//   print(myNum is int);

// String str = '123.3';
// var myNum = double.parse(str);
// print(str);
// print(myNum is double);

// var myNum =12;
// var str =myNum.toString();
// print(str is String);

//try  ... catch  //
/*      String price='';
      try{
        var myNum=double.parse(price);

        print(myNum);

      }catch(p){
           print(0);
/*       }  */

    for (var i = 0; i <= 100; i++) {
          if (i%2==0) {
            print(i);
          }
    }
 */

/* List list =[
  {
    'cate':'国内',
    'news':[
      {'title':'国内新闻1'},
      {'title':'国内新闻2'},k
    ]
  },
    {
      'cate':'国际',
        'news':[
        {'title':'国w新闻1'},
      {'title':'国w新闻2'},
      {'title':'国w新闻3'}
    ]
  }     
];
  for (var i = 0; i < list.length; i++) {
    print(list[i]['cate']);
    print('...............');
    for (var j= 0; j< list[i]['news'].length; j++) {
      print(list[i]['news'][j]['title']);
    }
  }*/

/*       List list=['baijin','baijin','meiqin'];
      var s = new  Set();
      for (var i = 0; i < list.length; i++) {
        print(list);
      }
      s.addAll(list);
      print(s);
      print(s.toString());
      */

/*       List list = ['hahah','zainali'];
      // for (var i = 0; i < list.length; i++) {
      //   print(list);
      // }

      // for(var item in list){
      //   print(item);
      // }

  /*     list.forEach((element) {
        print('$element');
      }); */


      List myList=[1,3,4];      
      var newList=myList.map((value){
          return value*2;
      });
       print(newList.toList()); */

// }

/* class Person{
  String name = '张三';
  int age  =23;
  void getInfo(){
    print('${this.name}---${this.age}');
  }
  void setInfo(int age){
    this.age=age;
  }
}
void main(){
  Person p1 = new Person();
  p1.setInfo(23);
  p1.getInfo();
  } */
/* 
 
  返回类型 方法名称（参数1，，参数2.。。）{   //todo  void 代表没有返回值
    方法体
    return 返回值;
  } */

/* void mei(){
  print('我任性');
}
void main(){


  mei();
} */
/*   
  void il(){
    print('我乐意');
  }

  void main(){
      il();
  }

  返回类型 方法名称（）{
      方法体

    返回值
    return 
  } */

/* 
  void op(){
    print('wohu');
  }
        int bp(){
         var bum = 123;
          return bum;
        }

        List list(){
          return[1,23,44];
        }
  void main(){
        // op();



/*         int b p(){
         var bum = 123;
          return bum;
        }
    var n= bp();
    print(n);
     */

    String skr(){
      return 'skt';
    }


    print(skr());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
    print(list());
  }

 */

/* main(){
  var sum =0;
    for (var i = 0; i <=100; i++) {
      sum+=i;
    }
    print(sum);
} */

void main() {
/* sumNum(int n){
    var sum = 0;
   for (var i = 0; i <=n; i++) {
     sum+=i;
   }
   return sum;
}
var n = sumNum(110);
print(sumNum(n)); */

  /*   resume(String name,[int age]){ //todo 可选加[]
        if (age==null) {
          return'姓名 :$name \n年龄:未知';
        }else
          return  '姓名 :$name \n年龄:$age';
      }
      print(resume('张三',99)); */

//命名参数
/*         resume(String name,{int age}){ //todo 可选加[]
        if (age==null) {
          return'姓名 :$name \n年龄:未知';
        }else
          return  '姓名 :$name \n年龄:$age';
      }
      print(resume('张三',age: 5));
 */
//返回类型 方法名称{
//   方法体
//   return 返回值
// }

//?  方法当参数

/* fn1(){
  print('niaho');
}
fn2(fn){
    fn();
}
fn2(fn1); */

/*  List list=['1','2','3'];
    list.forEach((element) {
      print(element);
  
    });


      list.forEach((element)=>print(element)); */

  // List list1=[1,4,3,2,9];
  /*      var ne=list1.map((element) {
        if (element>2) {
          return element*2;
        }
          return element;
       });
       print(ne.toList()); */

  // var ne2 = list1.map((e)=>e>2? e*2:e);
  // print(ne2.toList());

  /*     bool even(int n){
          if (n%2==0) {
            return true;
          }
          return false;
        }  
        // ignore: unused_element
        printNum(int n ){
          for (var i = 1; i <=n; i++) {
            if (even(i)) {
              print(i);
            }
          }
          printNum(10);
        } */
  /*         ((n){
            print('自执行方法');
            print(n);
            })(12);
     
 */
//?   2020 03 08 uuppupu
/*         Map person={
          'name':'张三n',        
          'age':23,
          'sex':'nan'
      
};
print(person); */
  // static //实现类级别的变量和函数
  // 静态方法不能访问非静态成员

//? 2020 03 039 upupupup
/* 
  var l3 = new List();
  l3.add('张三');
  print(l3); */
///////////////////////////////////////////////////////////
  ///  1 Haaa();
  ///  2 Haaa(1,2);
  //   3 print(Haaa(1, 2));
  //   4  int sum = Haaa(1, 2);
  //      print(sum);
//  5 Haaa(1, 2);
//  6 print(Haaa(1, 2));
// print('北京','nv',3)
}

// todo 函数
// 1 定义函数
// 2 函数传参
// 3 函数返回值
// 4 函数默认返回值
// 5 箭头函数（无返回值）
// 6 箭头函数（有返回值）
// 7 函数参数（可选参数）
// 8 函数参数 命名
// 9 函数参数 赋默认值

//? 1 定义函数
/* void Haaa() {
  int a = 1;
  int b = 1;
  int sum = a + b;
  print(sum);
} */

//? 2 函数传参
/* void Haaa(int a, int b) {
  int sum = a + b;
  print(sum);
} */

//? 3 函数返回值
/* int Haaa(int a, int b) {
  int sum = a + b;
  return sum; //return什么类型 函数前面就是什么类型
} */

//? 4 函数默认返回值
// int Haaa(int a, int b) {
//   int sum = a + b;
// }
//
//? 5 箭头函数（无返回值）
// void Haaa(int a, int b) => print("和:${a + b}");

//? 6 箭头函数（有返回值）
// int Haaa(int a, int b) => a + b;

//? 7 函数参数（可选参数）

//? 8 函数参数 命名
//? 9 函数参数 赋默认值
