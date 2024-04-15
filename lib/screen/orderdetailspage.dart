import 'dart:convert';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class OrderDetails extends StatefulWidget {
  dynamic orderJsonObj;

  OrderDetails({super.key, this.orderJsonObj});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  dynamic orderJsonObj;
  String title = 'Order Details Page';

  @override
  void initState() {
    super.initState();
    orderJsonObj = widget.orderJsonObj;
    final orderNo = orderJsonObj['orderNo'];
    title = title + '\norderNo:$orderNo';
  }

  @override
  Widget build(BuildContext context) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String prettyPrint = encoder.convert(orderJsonObj);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        color: Color.fromARGB(255, 209, 189, 242),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Text(
              prettyPrint,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
