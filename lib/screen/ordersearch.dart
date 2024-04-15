import 'dart:convert';
import 'package:flutter/material.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:shimmer/shimmer.dart';

class OrderSearch extends StatefulWidget {
  const OrderSearch({super.key});

  @override
  State<OrderSearch> createState() => _OrderSearchState();
}

class _OrderSearchState extends State<OrderSearch> {
  String title = 'Order Search Page';
  List<dynamic> orders = [];
  bool shimmer = false;
  bool ordersNotFound = false;
  Map<String, dynamic> responseHeaderAttributes = {};
  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingMessageWidget = const Padding(
      padding: EdgeInsets.all(100),
      child: Text(
        'Fetching Order Details',
        style: TextStyle(fontSize: 20),
      ),
    );

    Widget emptyOrderDetailsWidget = const Center(
      child: Text(
        "Order doesn't exist!",
        style: TextStyle(
          fontSize: 20.0,
        ),
      ),
    );

    Widget userInputTextWidget = Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: textEditingController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter order number',
        ),
      ),
    );

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
          centerTitle: true,
        ),
        body: ordersNotFound
            ? emptyOrderDetailsWidget
            : shimmer
                ? Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: Colors.transparent,
                    child: loadingMessageWidget,
                  )
                : userInputTextWidget,
        floatingActionButton: shimmer
            ? Container()
            : Center(
                child: FloatingActionButton(
                  heroTag: 'fetchOrderInfoBtn',
                  onPressed: () {
                    fetchOrderInfo(textEditingController.text);
                  },
                  tooltip: 'Fetch Order Details!',
                  child: const Icon(Icons.search),
                ),
              ));
  }

  fetchOrderInfo(String orderNo) {
    invokeOSApi(orderNo);
  }

  void invokeOSApi(String orderNo) async {
    setState(() {
      shimmer = true;
    });

    final localHostForVirtualDevice = Platform.isIOS
        ? LOCAL_HOST_FOR_IOS_SIMULATOR
        : LOCAL_HOST_FOR_ANDROID_EMULATOR;

    final localBaseUrl = '$localHostForVirtualDevice:8080';

    final baseUrl = connectToLocalWcpOsAdapter ? localBaseUrl : devBaseUrl;

    final apiPath = '/wcp-adapter/v1/orders';

    Map<String, String> queryParams = {
      'orderNo': orderNo,
    };

    final requestHeaders = prepareRequestHeaders('S&G OS', '0:0');

    var uri = Uri.http(baseUrl, apiPath,
        queryParams.map((key, value) => MapEntry(key, value.toString())));

    print(
        'Calling invokeOSApi for OrderSearch where orderNo=$orderNo and uri=$uri and requestHeaders=$requestHeaders');
    final response = await http.get(uri, headers: requestHeaders);
    int statusCode = response.statusCode;
    final body = response.body;
    final json = jsonDecode(body);
    if (statusCode != 200) {
      setState(() {
        ordersNotFound = true;
      });
      throw Exception("There are no orders.");
    }
    if (json['status'] == 'FAIL' || json['status'] == 'NOT_FOUND') {
      setState(() {
        ordersNotFound = true;
      });
      throw Exception("There are no orders.");
    }
    setState(() {
      responseHeaderAttributes = json['header']['headerAttributes'];
      orders = json['payload'];
      shimmer = false;
    });
    print(
        'Completed invokeOSApi for OrderSearch where orderNo=$orderNo and uri=$uri and requestHeaders=$requestHeaders and responseHeaderAttributes=$responseHeaderAttributes');

    navigateToOrderDetailsPage(context, orderJsonObj: orders[0]);
  }
}
