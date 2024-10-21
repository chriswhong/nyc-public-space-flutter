import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class TypeDescription extends StatelessWidget {
  final String iconPath; // Path to the icon (image from assets)
  final String description; // The text to display

  // Constructor to accept icon and description as input
  const TypeDescription({
    required this.iconPath,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          iconPath, // Path to your asset image
          width: 30,
          fit: BoxFit.cover, // Adjust the image fitting behavior
        ),
        const SizedBox(width: 16), // Spacer between the image and text
        Expanded(
          // This will allow the text to wrap
          child: Text(
            description,
            style: const TextStyle(fontSize: 12),
            softWrap: true, // Ensures the text wraps
          ),
        ),
      ],
    );
  }
}

class SideDrawer extends StatefulWidget {
  final String drawerType;

  SideDrawer({required this.drawerType});

  @override
  _SideDrawerState createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  // Replace with your Google Form action URL and field names
  final String googleFormUrl =
      'https://docs.google.com/forms/u/0/d/e/1FAIpQLSdeRW4c1k16zHkkN3XO25PuRjoGxgOszSNAGV5zcKy6a4Afxw/formResponse';
  final String idField = 'entry.495981289';
  final String issueField =
      'entry.823964625'; // Replace YOUR_FIELD_ID with your Google Form field ID

  Future<void> _submitForm(String inputText) async {
    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
      Uri.parse(googleFormUrl),
      body: {
        idField: 'foo',
        issueField: inputText,
      },
    );

    print(response.statusCode);

    if (response.statusCode == 200 || response.statusCode == 302) {
      // Success - Update the state to show success message
      setState(() {
        _isSubmitted = true;
      });
    } else {
      // Handle failure (Optional: You can display an error message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    print('drawerType');
    print(widget.drawerType);

    if (widget.drawerType == 'report') {
      return Drawer(
        width: screenWidth,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Header with FontAwesome X icon to close the drawer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Report an Issue",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(
                                FontAwesomeIcons.times), // FontAwesome X icon
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the drawer
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isSubmitted
                            ? Center(
                                child: Text(
                                  'Thank you for your submission!',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Report an Issue',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Please describe the issue:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _controller,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter your message',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _isSubmitting
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: () {
                                            if (_controller.text.isNotEmpty) {
                                              _submitForm(_controller.text);
                                            }
                                          },
                                          child: Text('Submit'),
                                        ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

// default drawer content
    return Drawer(
      width: screenWidth,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header with FontAwesome X icon to close the drawer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "About",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(
                              FontAwesomeIcons.times), // FontAwesome X icon
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the drawer
                          },
                        ),
                      ],
                    ),
                    const Text(
                      "NYC Public Space Map was built with a simple goal in mind: to catalog and display all of the different types of public space in New York City.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Public spaces exist under a variety of regulatory frameworks, and many are unknown and not easily discoverable.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    const TypeDescription(
                      iconPath: 'assets/park.png',
                      description:
                          'NYC parks are overseen by the New York City Department of Parks and Recreation (NYC Parks). These spaces are designated for recreational use and include playgrounds, green spaces, and sports facilities. From a regulatory standpoint, parks are public land specifically allocated for leisure and recreation, protected by city laws to maintain access for all.',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/plaza.png',
                      description:
                          'Managed by the New York City Department of Transportation (NYC DOT), street plazas are car-free public spaces, typically found in underutilized roadways and intersections. These plazas are created through partnerships with local communities and businesses, and they are regulated to ensure they provide pedestrian-friendly spaces that enhance public life.',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/pops.png',
                      description:
                          'POPS are open spaces that are privately maintained but publicly accessible, created as part of zoning regulations overseen by the New York City Department of City Planning (DCP). Property developers receive zoning bonuses in exchange for providing these spaces, which must adhere to specific design and accessibility standards to ensure they serve the public.',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/wpaa.png',
                      description:
                          'Overseen by the New York City Department of City Planning (DCP), WPAAs are regulated as part of waterfront zoning rules, requiring developers to provide publicly accessible spaces along the city’s waterfront. These areas include walkways, seating, and recreational amenities, ensuring public enjoyment of the city’s waterfront as part of sustainable urban development.',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/stp.png',
                      description:
                          'The NYC Schoolyards to Playgrounds Program transforms underutilized schoolyards into vibrant community playgrounds. Managed by the NYC Department of Parks and Recreation in collaboration with the Department of Education, this initiative opens schoolyards to the public after school hours, on weekends, and during school vacations. The program aims to provide safe, accessible recreational spaces in neighborhoods that lack traditional parks, promoting outdoor play and community engagement for children and families across the city.',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Fixed buttons at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle 'Report missing or incorrect info' button tap
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0), // Add vertical padding
                      ),
                      child: const Text(
                        'Report missing or incorrect info',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle 'Share your Feedback' button tap
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0), // Add vertical padding
                      ),
                      child: const Text(
                        'Share your Feedback',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
