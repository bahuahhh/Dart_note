enum GroupedButtonsOrientation{
  HORIZONTAL,
  VERTICAL,
}



//Widget _body(){
//  return ListView(
//      children: <Widget>[
//
//        //--------------------
//        //SIMPLE USAGE EXAMPLE
//        //--------------------
//
//        //BASIC CHECKBOXGROUP
//        Container(
//          padding: const EdgeInsets.only(left: 14.0, top: 14.0),
//          child: Text("Basic CheckboxGroup",
//            style: TextStyle(
//                fontWeight: FontWeight.bold,
//                fontSize: 20.0
//            ),
//          ),
//        ),
//
//        CheckboxGroup(
//          labels: <String>[
//            "Sunday",
//            "Monday",
//            "Tuesday",
//            "Wednesday",
//            "Thursday",
//            "Friday",
//            "Saturday",
//          ],
//          disabled: [
//            "Wednesday",
//            "Friday"
//          ],
//          onChange: (bool isChecked, String label, int index) => print("isChecked: $isChecked   label: $label  index: $index"),
//          onSelected: (List<String> checked) => print("checked: ${checked.toString()}"),
//        ),
//
//
//
//        //BASIC RADIOBUTTONGROUP
//        Container(
//          padding: const EdgeInsets.only(left: 14.0, top: 14.0),
//          child: Text("Basic RadioButtonGroup",
//            style: TextStyle(
//                fontWeight: FontWeight.bold,
//                fontSize: 20.0
//            ),
//          ),
//        ),
//
//        RadioButtonGroup(
//          labels: [
//            "Option 1",
//            "Option 2",
//          ],
//          disabled: [
//            "Option 1"
//          ],
//          onChange: (String label, int index) => print("label: $label index: $index"),
//          onSelected: (String label) => print(label),
//        ),
//
//
//
//
//        //--------------------
//        //CUSTOM USAGE EXAMPLE
//        //--------------------
//
//        ///CUSTOM CHECKBOX GROUP
//        Container(
//          padding: const EdgeInsets.only(left: 14.0, top: 14.0, bottom: 14.0),
//          child: Text("Custom CheckboxGroup",
//            style: TextStyle(
//                fontWeight: FontWeight.bold,
//                fontSize: 20.0
//            ),
//          ),
//        ),
//
//        CheckboxGroup(
//          orientation: GroupedButtonsOrientation.HORIZONTAL,
//          margin: const EdgeInsets.only(left: 12.0),
//          onSelected: (List selected) => setState((){
//            _checked = selected;
//          }),
//          labels: <String>[
//            "A",
//            "B",
//          ],
//          checked: _checked,
//          itemBuilder: (Checkbox cb, Text txt, int i){
//            return Column(
//              children: <Widget>[
//                Icon(Icons.polymer),
//                cb,
//                txt,
//              ],
//            );
//          },
//        ),
//
//
//
//        ///CUSTOM RADIOBUTTON GROUP
//        Container(
//          padding: const EdgeInsets.only(left: 14.0, top: 14.0, bottom: 14.0),
//          child: Text("Custom RadioButtonGroup",
//            style: TextStyle(
//                fontWeight: FontWeight.bold,
//                fontSize: 20.0
//            ),
//          ),
//        ),
//
//        RadioButtonGroup(
//          orientation: GroupedButtonsOrientation.HORIZONTAL,
//          margin: const EdgeInsets.only(left: 12.0),
//          onSelected: (String selected) => setState((){
//            _picked = selected;
//          }),
//          labels: <String>[
//            "One",
//            "Two",
//          ],
//          picked: _picked,
//          itemBuilder: (Radio rb, Text txt, int i){
//            return Column(
//              children: <Widget>[
//                Icon(Icons.public),
//                rb,
//                txt,
//              ],
//            );
//          },
//        ),
//
//      ]
//  );
//}
//
//}