/* main() {
  Future.delayed(new Duration(seconds: 10), () {
    return "hi world!";
  }).then((data) {
    print(data);
  });
}
 */
main() {
/*   Future.delayed(Duration(seconds: 10), () {
    return "hello world";
  }).then((data) {
    print(data);
  }); */

// Future.catchError
/*   Future.delayed(new Duration(seconds: 2), () {
    //return "hi world!";
    throw AssertionError("Error");
  }).then((data) {
    //执行成功会走到这里
    print("success");
  }).catchError((e) {
    //执行失败会走到这里
    print(e);
  }); */

/*   Future.delayed(new Duration(seconds: 2), () {
    //return "hi world!";
    throw AssertionError("Error");
  }).then((data) {
    print("success");
  }, onError: (e) {
    print(e);
  }); */

  Future.wait([
    Future.delayed(new Duration(seconds: 2), () {
      return 'hello';
    }),
    Future.delayed(Duration(seconds: 4), () {
      return 'world';
    })
  ]).then((results) {
    print(results[0] + results[1]);
  }).catchError((e) {
    print(e);
  });
}
