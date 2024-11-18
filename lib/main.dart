import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'colors.dart';
import 'map_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'side_drawer.dart';
import 'public_space_properties.dart';
import 'user_provider.dart'; 
import 'username_input_screen.dart';


Future<void> initDynamicLinks(BuildContext context) async {
  print('Initializing dynamic links...');

  // Listen for dynamic link while app is in the foreground
  FirebaseDynamicLinks.instance.onLink
      .listen((PendingDynamicLinkData? dynamicLinkData) async {
    final Uri? deepLink = dynamicLinkData?.link;

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
    firestore.FirebaseFirestore.instance.settings =
        const firestore.Settings(persistenceEnabled: false);
    runApp(
      ChangeNotifierProvider(
        create: (context) {
          final userProvider = UserProvider();
          userProvider.initializeAuth(context); // Initialize auth
          return userProvider;
        },
        child: MyApp(),
      ),
    );
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {

  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Bottom Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(key: homeScreenKey),
      routes: {
        '/username_input': (context) => UsernameInputScreen(
              onUsernameCreated: (newUsername) {
                userProvider.setUsernameLocally(newUsername);
              },
            ),
      },
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
        bottomNavigationBar: SizedBox(
          height: 90,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.map),
                ),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.infoCircle),
                ),
                label: 'About',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                      top: 8.0, bottom: 4.0), // Add padding above the icon
                  child: Icon(FontAwesomeIcons.user),
                ),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.dark,
            selectedLabelStyle: TextStyle(fontSize: 10), // Adjust font size
            unselectedItemColor: AppColors.gray,
            unselectedLabelStyle: TextStyle(fontSize: 10),
            iconSize: 20, // Set the desired size for the icons
            onTap: _onItemTapped,
          ),
        ));
  }
}
