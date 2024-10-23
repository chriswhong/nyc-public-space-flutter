import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TypeDescription extends StatelessWidget {
  final String iconPath;
  final String description;

  const TypeDescription({
    required this.iconPath,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          iconPath,
          width: 30,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(fontSize: 12),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class AboutDrawer extends StatelessWidget {
  final VoidCallback
      onFeedbackTap; // Function passed to handle feedback button tap

  const AboutDrawer({super.key, required this.onFeedbackTap});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      width: screenWidth, // Set full-width for the drawer
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context, 'About'),
                    const SizedBox(height: 30),
                    const Text(
                      "NYC Public Space Map exists to catalog and display a consolidated list of public spaces around the city. The most common types of public space are described below.",
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
                          'Led by the NYC Department of Education and the Trust for Public Land, the Schoolyards to Playgrounds program turns unused schoolyards into public playgrounds. Open outside school hours, these spaces feature play equipment, sports courts, and green areas, providing recreational spaces in underserved neighborhoods while fostering community and promoting physical activity.',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/misc.png',
                      description:
                          'Other public spaces include New York State Parks, sites managed by the National Park Service, private property open to the public (such as cemeteries and nonprofit-owned facilities). Let us know if there\'s a public space we may have missed.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFeedbackTap, // Trigger the passed-in function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xAA77bb3f), // Set the button background color to green
                    foregroundColor:
                        Colors.white, // Set the button text color to white
                  ),
                  child: const Text('Share your Feedback'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.times),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
