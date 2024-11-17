import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nyc_public_space_map/map_screen.dart';
import 'package:nyc_public_space_map/about_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nyc_public_space_map/side_drawer.dart';
import 'package:nyc_public_space_map/public_space_properties.dart';

Future<void> initDynamicLinks(BuildContext context) async {
  print('Initializing dynamic links...');

  // Listen for dynamic link while app is in the foreground
  FirebaseDynamicLinks.instance.onLink
      .listen((PendingDynamicLinkData? dynamicLinkData) async {
    final Uri? deepLink = dynamicLinkData?.link;

    if (deepLink != null &&
        FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString())) {
      try {
        // The client SDK will parse the code from the link for you.
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailLink(
          email: "chris.m.whong@gmail.com", // Replace with the user's email
          emailLink: deepLink.toString(),
        );

        // You can access the new user via userCredential.user.
        final String? emailAddress = userCredential.user?.email;

        print('Successfully signed in with email link!');
        print('Email Address: $emailAddress');
      } catch (error) {
        print('Error signing in with email link: $error');
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
      home: HomeScreen(),
    );
  }
}

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
            icon: Icon(FontAwesomeIcons.infoCircle),
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Screen',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
