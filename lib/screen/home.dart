// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sample_order_history/screen/orderdetailspage.dart';
import 'package:sample_order_history/screen/ordersearch.dart';
import 'package:shimmer/shimmer.dart';

import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

import 'package:sample_order_history/dropdown.dart';
import 'package:intl/intl.dart'; // for date format
// import 'package:intl/date_symbol_data_local.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

bool connectToLocalWcpOsAdapter = false;
// Emulator used 10.0.2.2 as LOCAL-HOST
// ignore: duplicate_ignore
// ignore: constant_identifier_names
const LOCAL_HOST_FOR_ANDROID_EMULATOR = '10.0.2.2';
// final LOCAL_HOST_FOR_IOS_SIMULATOR = '192.168.1.4';
const LOCAL_HOST_FOR_IOS_SIMULATOR = 'localhost';
final devBaseUrl = 'wcp-os-adapter-wcnp.dev.walmart.com';

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> orders = [];
  List<int> offsets = [0];
  int limit = 7;
  int currPage = 0;
  String offsetMark = '0:0';
  int maxSupportedPages = 100;
  late int totalPages = 20;
  late int totalCount = 200;
  bool shimmer = false;
  bool ordersNotFound = false;
  bool orderHistoryButtonPressed = false;
  String title = 'Scatter & Gather Demo';
  Map<String, dynamic> responseHeaderAttributes = {};

  _HomeScreenState() {
    int pageOffset = 0;
    for (int i = 1; i <= maxSupportedPages; ++i) {
      offsets.add(pageOffset);
      pageOffset += limit;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget emptyOrderHistoryWidget = const Center(
      child: Text(
        'There are no past orders',
        style: TextStyle(
          fontSize: 20.0,
        ),
      ),
    );

    Widget walmartLogoWidget = currPage != 0
        ? Container()
        : Padding(
            padding: const EdgeInsets.all(5.0),
            child: Image.asset(
              'assets/walmartlogo.png',
            ),
          );
    double leadingWidthVal = currPage != 0 ? 0 : 120;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        leadingWidth: leadingWidthVal,
        leading: walmartLogoWidget,
        centerTitle: true,
      ),
      body: ordersNotFound
          ? emptyOrderHistoryWidget
          : ListView.builder(
              shrinkWrap: true,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderNo = order['orderNo'];
                final orderDate = order['orderDate'];
                DateTime orderDateWithTimeZone = DateTime.parse(orderDate);

                var orderDateInStringFormat =
                    DateFormat().format(orderDateWithTimeZone);
                // print(
                //     'orderDate : $orderDate and dateTimeWithTimeZone : $orderDateWithTimeZone and orderDateInStringFormat: $orderDateInStringFormat');

                final orderDateStr = 'Placed on ${orderDateInStringFormat}';

                Widget listTileWidget = ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(orderNo),
                  subtitle: Text(orderDateStr),
                  onTap: () {
                    navigateToOrderDetailsPage(context, orderJsonObj: order);
                  },
                );
                Widget emptyListWidget = listTileWidget;
                return shimmer
                    ? Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: Colors.transparent,
                        child: emptyListWidget,
                      )
                    : listTileWidget;
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment:
            currPage == 0 ? MainAxisAlignment.center : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              currPage != 0 || shimmer
                  ? shimmer && orderHistoryButtonPressed
                      ? Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: Colors.transparent,
                          child: const Center(
                            child: Text(
                              'Fetching Order History',
                              style: TextStyle(
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        )
                      : Container()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          const SizedBox(
                            width: 20.0,
                            height: 100.0,
                          ),
                          const Text(
                            'Select Client Type\nfrom below Dropdown Menu',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            width: 20.0,
                            height: 1.0,
                          ),
                          const ClientTypeDropdown(),
                          const SizedBox(
                            width: 20.0,
                            height: 100.0,
                          ),
                          FloatingActionButton(
                            tooltip: 'Go to Order History Page!',
                            heroTag: "orderHistoryPageBtn",
                            onPressed: loadOrderHistoryPage,
                            child: const Icon(
                              Icons.home,
                            ),
                          ),
                          const SizedBox(
                            width: 20.0,
                            height: 25.0,
                          ),
                          const Text(
                            'Click above to view\nOrder History Page',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            width: 20.0,
                            height: 100.0,
                          ),
                          FloatingActionButton(
                            tooltip: 'Go to Order Search Page!',
                            heroTag: "orderSearchBtn",
                            onPressed: () {
                              _navigateToOrderSearchPage(context);
                            },
                            child: const Icon(
                              Icons.search_sharp,
                            ),
                          ),
                          const SizedBox(
                            width: 20.0,
                            height: 25.0,
                          ),
                          const Text(
                            'Click above for\nOrder Search Page',
                            textAlign: TextAlign.center,
                          ),
                        ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  currPage < 2 || shimmer
                      ? Container()
                      : FloatingActionButton(
                          tooltip: 'Previous Page!',
                          heroTag: "previousPageBtn",
                          onPressed: fetchPreviousPage,
                          child: const Icon(Icons.arrow_back),
                        ),
                ],
              ),
              currPage > 1 && currPage < totalPages
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                    )
                  : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  currPage >= totalPages
                      ? Container()
                      : currPage > 0 && !shimmer
                          ? FloatingActionButton(
                              tooltip: 'Next Page!',
                              heroTag: "nextPageBtn",
                              onPressed: fetchNextPage,
                              child: const Icon(Icons.arrow_forward),
                            )
                          : Container(),
                ],
              ),
            ],
          ),
          const SizedBox(
            width: 20.0,
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              currPage > 0 && !shimmer
                  ? FloatingActionButton(
                      tooltip: 'Restart App!',
                      heroTag: "restartAppBtn",
                      onPressed: restartApp,
                      child: const Icon(Icons.restart_alt),
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }

  void fetchPreviousPage() {
    invokeOSApi(false, false);
  }

  void fetchNextPage() {
    invokeOSApi(true, false);
  }

  void restartApp() {
    if (Platform.isIOS) {
      Phoenix.rebirth(context);
    } else {
      Restart.restartApp();
    }
  }

  void loadOrderHistoryPage() {
    invokeOSApi(true, true);
  }

  dynamic invokeOSApi(bool isNextPage, bool isFirstTimeLoadingPage) async {
    setState(() {
      shimmer = true;
      orderHistoryButtonPressed = isFirstTimeLoadingPage;
    });
    // final url = 'https://randomuser.me/api/?results=$limit&page=$page';
    // print('Called invokeOSApi with page=$page where url=$url');
    // final uri = Uri.parse(url);
    int page = isNextPage ? currPage + 1 : currPage - 1;

    final localHostForVirtualDevice = Platform.isIOS
        ? LOCAL_HOST_FOR_IOS_SIMULATOR
        : LOCAL_HOST_FOR_ANDROID_EMULATOR;

    final localBaseUrl = '$localHostForVirtualDevice:8080';

    final baseUrl = connectToLocalWcpOsAdapter ? localBaseUrl : devBaseUrl;

    final apiPath = '/wcp-adapter/v1/orders';

    Map<String, String> queryParams = {
      // 'customerId:WCP':
      //     '4d460249-27f5-48d3-91bf-997cb65dcf1f', // with 67 orders in US Prod
      // 'customerId:INTL':
      //     '020da7d9-3cf9-49a8-acac-bf1b6fffd5f5', // with 91 orders in MX Private Prod

      // 'customerId:WCP':
      //     'dfea3d16-651d-4f68-8115-dd12f0c0e0f4', // with 12 orders in US Prod
      // 'customerId:INTL':
      //     '96380d6c-5ad9-4bd3-9d19-9ae3a6aecab3', // with 16 orders in MX Private Prod

      // 'customerId:WCP':
      //     'dece6fa0-a21a-4ee2-a1f8-7d769b13447e', // with 43 orders in US Prod
      // 'customerId:INTL':
      //     '96380d6c-5ad9-4bd3-9d19-9ae3a6aecab3', // with 16 orders in MX Private Prod

      // 'customerId:WCP':
      //     '4d460249-27f5-48d3-91bf-997cb65dcf1f', // with 67 orders in US Prod
      // 'customerId:INTL':
      //     '020da7d9-3cf9-49a8-acac-bf1b6fffd5f5', // with 87 orders in MX Private Prod

      'customerId:WCP':
          'f6f6274b-9bad-4010-8339-23b1a3bf1981', // with 23 orders in US teflon
      'customerId:INTL':
          '9b30590d-db43-4dc8-8bf1-8054ff128a20', // with 119 orders in MX QA

      'limit': limit.toString(),
      'offset': offsets[page].toString()
    };

    String clientTypeDropdownValue = getDropdownValue();

    final requestHeaders =
        prepareRequestHeaders(clientTypeDropdownValue, offsetMark);

    var uri = Uri.http(baseUrl, apiPath,
        queryParams.map((key, value) => MapEntry(key, value.toString())));

    print(
        'Calling invokeOSApi with page=$page where uri=$uri and requestHeaders=$requestHeaders');
    final response = await http.get(uri, headers: requestHeaders);
    int statusCode = response.statusCode;
    final body = response.body;
    final json = jsonDecode(body);
    if (statusCode != 200) {
      setState(() {
        ordersNotFound = true;
        orderHistoryButtonPressed = false;
      });
      throw Exception("There are no orders.");
    }
    if (json['status'] == 'FAIL' || json['status'] == 'NOT_FOUND') {
      setState(() {
        ordersNotFound = true;
        orderHistoryButtonPressed = false;
      });
      throw Exception("There are no orders.");
    }
    setState(() {
      responseHeaderAttributes = json['header']['headerAttributes'];
      offsetMark = responseHeaderAttributes['offsetMark'];
      if (isFirstTimeLoadingPage) {
        totalCount = responseHeaderAttributes['totalCount'];
        totalPages = (totalCount / limit).ceil();
        orderHistoryButtonPressed = false;
      }
      orders = json['payload'];
      currPage = page;
      shimmer = false;
      if (page != 0) {
        title =
            '$clientTypeDropdownValue : Page $page of $totalPages with $totalCount orders';
      }
    });
    print(
        'Completed invokeOSApi with page=$page where uri=$uri and requestHeaders=$requestHeaders and responseHeaderAttributes=$responseHeaderAttributes with totalPages=$totalPages');
    return json;
  }
}

Map<String, String> prepareRequestHeaders(
    String clientTypeDropdownValue, String offsetMark) {
  final requestHeaders = {
    "tenant-id": "hvgqan",
    "WM_CONSUMER.ID": "postman-local",
    "offsetMark": "0:0",
    "Content-Type": "application/json",
    "Accept": "application/json",
    // ignore: equal_keys_in_map
    "offsetMark": offsetMark
  };

  String isWcpLookupEnabled = 'true';
  String isIntlLookupEnabled = 'true';

  if (clientTypeDropdownValue == 'WCP OS') {
    isWcpLookupEnabled = 'true';
    isIntlLookupEnabled = 'false';
  } else if (clientTypeDropdownValue == 'INTL OS') {
    isWcpLookupEnabled = 'false';
    isIntlLookupEnabled = 'true';
  }
  requestHeaders.putIfAbsent('isWcpLookupEnabled', () => isWcpLookupEnabled);
  requestHeaders.putIfAbsent('isIntlLookupEnabled', () => isIntlLookupEnabled);
  return requestHeaders;
}

void navigateToOrderDetailsPage(BuildContext context, {dynamic orderJsonObj}) {
  Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OrderDetails(orderJsonObj: orderJsonObj)));
}

void _navigateToOrderSearchPage(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const OrderSearch()));
}
