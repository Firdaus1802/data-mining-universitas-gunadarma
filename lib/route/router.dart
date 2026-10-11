import 'package:flutter/cupertino.dart';
import 'package:shop/entry_point.dart';

import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OnBordingScreen(),
      );
    case logInScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const EntryPoint(),
      );
    case signUpScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case otpScreenRoute:
    case signUpVerificationScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return EmailVerificationScreen(
            email: args['email'] as String? ?? 'user@gunadarma.ac.id',
            expectedOtp: args['expectedOtp'] as String? ?? '',
            userName: args['userName'] as String?,
          );
        },
      );
    case productDetailsScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) {
          bool isProductAvailable = settings.arguments as bool? ?? true;
          return ProductDetailsScreen(isProductAvailable: isProductAvailable);
        },
      );
    case productReviewsScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const ProductReviewsScreen(),
      );
    case homeScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const HomeScreen(),
      );
    case discoverScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const DiscoverScreen(),
      );
    case onSaleScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OnSaleScreen(),
      );
    case kidsScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const KidsScreen(),
      );
    case searchScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const SearchScreen(),
      );
    case bookmarkScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const BookmarkScreen(),
      );
    case entryPointScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const ProfileScreen(),
      );
    case userInfoScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const UserInfoScreen(),
      );
    case notificationsScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const NotificationOptionsScreen(),
      );
    case addressesScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const AddressesScreen(),
      );
    case ordersScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OrdersScreen(),
      );
    case preferencesScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const PreferencesScreen(),
      );
    case emptyWalletScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const EmptyWalletScreen(),
      );
    case walletScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const WalletScreen(),
      );
    case cartScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const CartScreen(),
      );
    case aprioriDashboardScreenRoute:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const AprioriDashboardScreen(),
      );
    default:
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => const OnBordingScreen(),
      );
  }
}
