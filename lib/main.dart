import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  List<ProductDetails> _subcriptionProducts = <ProductDetails>[];
  List<ProductDetails> _nonConsumableProducts = <ProductDetails>[];

  List<String> _kConsumableProductIds = <String>[
    'com.portal.kangekixr.stg.p30000',
    'com.portal.kangekixr.stg.p800',
    'com.portal.kangekixr.stg.p3000',
    'com.portal.kangekixr.stg.p500'
  ];

  List<String> _kSubscriptionProductIds = <String>[
    'movie.monthly',
    'movie.yearly',
    'com.portal.kangekixr.stg.mi1',
  ];
  List<String> _kNonConsumableProductIds = <String>[
    'com.portal.kangekixr.stg.mi1',
  ];

  @override
  void initState() {
    _subscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('onError ${error.toString()} ')),
      );
    });
    initStoreInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consumable Products'),
              ...List.generate(
                _products.length,
                (index) {
                  return GestureDetector(
                    onTap: () {
                      onConsumablePurchase(_products[index]);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Center(
                          child: Text(
                            'Tittle: ${_products[index].title}\n'
                            'Price: ${_products[index].price}\n'
                            'Description: ${_products[index].description}'
                            '\nCurrencyCode: ${_products[index].currencyCode}',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Subscription Products'),
              ...List.generate(
                _subcriptionProducts.length,
                (index) {
                  final item = _subcriptionProducts[index];
                  return GestureDetector(
                    onTap: () {
                      buySubscription(item);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Center(
                          child: Text(
                            'Tittle: ${item.title}\n'
                            'Price: ${item.price}\n'
                            'Description: ${item.description}'
                            '\nCurrencyCode: ${item.currencyCode}',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Non-Consumable Products'),
              ...List.generate(
                _nonConsumableProducts.length,
                (index) {
                  final item = _nonConsumableProducts[index];
                  return GestureDetector(
                    onTap: () {
                      buySubscription(item);
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Center(
                          child: Text(
                            'Tittle: ${item.title}\n'
                            'Price: ${item.price}\n'
                            'Description: ${item.description}'
                            '\nCurrencyCode: ${item.currencyCode}',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
      });
      return;
    }

    // if (Platform.isIOS) {
    //   final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
    //       _inAppPurchase
    //           .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    //   await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    // }
    _products = await getProducts(_kConsumableProductIds.toSet());
    _subcriptionProducts = await getProducts(_kSubscriptionProductIds.toSet());
    _nonConsumableProducts =
        await getProducts(_kNonConsumableProductIds.toSet());
    setState(() {});
    try {
      await _inAppPurchase.restorePurchases();
    } catch (ex) {
      print('===== ex $ex');
    }
  }

  Future<List<ProductDetails>> getProducts(Set<String> query) async {
    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(query);

    if (productDetailResponse.error != null) {
      return productDetailResponse.productDetails;
    }
    if (productDetailResponse.productDetails.isEmpty) {
      return productDetailResponse.productDetails;
    }

    return productDetailResponse.productDetails;
  }

  void onConsumablePurchase(ProductDetails item) {
    InAppPurchase.instance
        .buyConsumable(purchaseParam: PurchaseParam(productDetails: item))
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    });
  }

  void buySubscription(ProductDetails item) {
    InAppPurchase.instance
        .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: item))
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PurchaseStatus.pending')),
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(purchaseDetails.error!.message)),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${purchaseDetails.status}')),
          );
        }
        // if (Platform.isAndroid) {
        //   if (!_kAutoConsume && purchaseDetails.productID == _kConsumableId) {
        //     final InAppPurchaseAndroidPlatformAddition androidAddition =
        //         _inAppPurchase.getPlatformAddition<
        //             InAppPurchaseAndroidPlatformAddition>();
        //     await androidAddition.consumePurchase(purchaseDetails);
        //   }
        // }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }
}
