import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
  }) {
    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Replace with actual key
      'amount': (amount * 100).toInt(),
      'name': 'Haritham',
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Razorpay Error: $e");
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
