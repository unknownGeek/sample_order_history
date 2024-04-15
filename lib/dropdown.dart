import 'package:flutter/material.dart';

const List<String> clientTypes = <String>['WCP OS', 'INTL OS', 'S&G OS'];
String dropdownValue = clientTypes.first;

String getDropdownValue() {
  return dropdownValue;
}

class ClientTypeDropdown extends StatefulWidget {
  const ClientTypeDropdown({super.key});

  @override
  State<ClientTypeDropdown> createState() => _ClientTypeDropdownState();
}

class _ClientTypeDropdownState extends State<ClientTypeDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      dropdownColor: Color.fromARGB(255, 200, 192, 192),
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
      },
      items: clientTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
