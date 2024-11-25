import 'package:flutter/material.dart';
import 'package:nyc_public_space_map/colors.dart';

import './feedback_screen.dart';

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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'About NYC Public Space',
                textAlign: TextAlign.center, // Center the text horizontally

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark, // Header text color
                ),
              ),
            ),
            // Scrollable Content
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "New York City is home to an incredible variety of public spaces, from sprawling parks and waterfronts to small plazas and playgrounds. However, these spaces fall under the jurisdiction of a wide array of agencies and organizations, each responsible for different types of public spaces and governed by distinct regulations. This fragmentation makes it difficult for New Yorkers to access a complete picture of the spaces available for recreation and relaxation.",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "The NYC Public Space app was created to solve this problem. By consolidating data from multiple sources—including city, state, and federal agencies, as well as private organizations—the app provides a unified and user-friendly platform to explore public spaces throughout the city. Whether you're searching for a quiet park to unwind, a plaza for a community gathering, or a waterfront area for exercise, the NYC Public Space app helps you discover the options available to you.",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Types of Public Space",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    SizedBox(height: 10),
                    TypeDescription(
                      iconPath: 'assets/park.png',
                      description:
                          'NYC parks are overseen by the New York City Department of Parks and Recreation (NYC Parks). These spaces are designated for recreational use and include playgrounds, green spaces, and sports facilities. From a regulatory standpoint, parks are public land specifically allocated for leisure and recreation, protected by city laws to maintain access for all.',
                    ),
                    SizedBox(height: 30),
                    TypeDescription(
                      iconPath: 'assets/plaza.png',
                      description:
                          'Managed by the New York City Department of Transportation (NYC DOT), street plazas are car-free public spaces, typically found in underutilized roadways and intersections. These plazas are created through partnerships with local communities and businesses, and they are regulated to ensure they provide pedestrian-friendly spaces that enhance public life.',
                    ),
                    SizedBox(height: 30),
                    TypeDescription(
                      iconPath: 'assets/pops.png',
                      description:
                          'POPS are open spaces that are privately maintained but publicly accessible, created as part of zoning regulations overseen by the New York City Department of City Planning (DCP). Property developers receive zoning bonuses in exchange for providing these spaces, which must adhere to specific design and accessibility standards to ensure they serve the public.',
                    ),
                    SizedBox(height: 30),
                    TypeDescription(
                      iconPath: 'assets/wpaa.png',
                      description:
                          'Overseen by the New York City Department of City Planning (DCP), WPAAs are regulated as part of waterfront zoning rules, requiring developers to provide publicly accessible spaces along the city’s waterfront. These areas include walkways, seating, and recreational amenities, ensuring public enjoyment of the city’s waterfront as part of sustainable urban development.',
                    ),
                    SizedBox(height: 30),
                    TypeDescription(
                      iconPath: 'assets/stp.png',
                      description:
                          'Led by the NYC Department of Education and the Trust for Public Land, the Schoolyards to Playgrounds program turns unused schoolyards into public playgrounds. Open outside school hours, these spaces feature play equipment, sports courts, and green areas, providing recreational spaces in underserved neighborhoods while fostering community and promoting physical activity.',
                    ),
                    SizedBox(height: 30),
                    TypeDescription(
                      iconPath: 'assets/misc.png',
                      description:
                          'Other public spaces include New York State Parks, sites managed by the National Park Service, private property open to the public (such as cemeteries and nonprofit-owned facilities). Let us know if there\'s a public space we may have missed.',
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Data Sources",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Most of the data used came from NYC Open Data and has been augmented by manual and AI-assisted research and updates.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Feedback Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(),
                    ),
                  );
                },
                  style: AppStyles.buttonStyle,
                  child: const Text('Share your Feedback'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
