import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nyc_public_space_map/map_screen.dart';
import 'package:nyc_public_space_map/about_screen.dart';
import 'package:nyc_public_space_map/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nyc_public_space_map/side_drawer.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> initDynamicLinks(BuildContext context) async {
  print('Initializing dynamic links...');

  // Listen for dynamic link while app is in the foreground
  FirebaseDynamicLinks.instance.onLink
      .listen((PendingDynamicLinkData? dynamicLinkData) async {
    final Uri? deepLink = dynamicLinkData?.link;

    print('deepLink');
    print(deepLink);

    if (deepLink != null &&
        FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString())) {
      try {
        // Retrieve the email from shared_preferences
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('sign_in_email');
        if (email == null) {
          throw Exception("No email found in local storage");
        }
        // The client SDK will parse the code from the link for you.
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailLink(
          email: email, // Replace with the user's email
          emailLink: deepLink.toString(),
        );

              // Delete the email from shared_preferences
        await prefs.remove('sign_in_email');

        // You can access the new user via userCredential.user.
        final String? emailAddress = userCredential.user?.email;

        print('Successfully signed in with email link!');
        print('Email Address: $emailAddress');

        // Show a toast and switch to the Profile tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in!')),
        );

        // Close all navigation pages and go to HomeScreen
        Navigator.popUntil(context, (route) => route.isFirst);

        homeScreenKey.currentState?.switchToMapTab();

      } catch (error) {
        print('Error signing in with email link: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('We could not sign you in with that link. Try again.')),
        );
      }
    } else {
      print('Dynamic link received, but it is not a valid email sign-in link.');
    }
  }).onError((error) {
    print('Error processing dynamic link: $error');
  });
}

void main() {
  // ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // read the mapbox access token from environment variable
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside-down portrait
  ]).then((_) async {
    // debugPaintSizeEnabled = true; // For debugging purposes

    await Firebase.initializeApp();
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bottom Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(key: homeScreenKey),
    );
  }
}

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PublicSpaceFeature? _selectedFeature;

  int _selectedIndex = 0;

  // List of pages for the navigation
  static late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize dynamic links handling
    initDynamicLinks(context);

    // Initialize the list of pages with the feedback tap handler
    _pages = <Widget>[
      MapScreen(onReportAnIssue: _handleReportAnIssue),
      AboutScreen(onFeedbackTap: _handleFeedbackTap),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleFeedbackTap() {
    // Open the drawer using the scaffold key
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleReportAnIssue(selectedFeature) {
    // Open the drawer using the scaffold key
    _scaffoldKey.currentState?.openDrawer();
    setState(() {
      _selectedFeature = selectedFeature;
    });
  }

  void switchToMapTab() {
    print('switching to map tab');
    setState(() {
      _selectedIndex = 0; // Index of the Profile tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Attach the key to the Scaffold
      drawer: SideDrawer(
        selectedFeature: _selectedFeature,
      ),
      body: IndexedStack(
        index: _selectedIndex, // Display the selected tab
        children: _pages, // Keep all pages mounted
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.infoCircle),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
