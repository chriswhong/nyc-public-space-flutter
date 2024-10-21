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
  const AboutDrawer({super.key});

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
                      "NYC Public Space Map was built with a simple goal in mind: to catalog and display all of the different types of public space in New York City.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/park.png',
                      description:
                          'NYC parks are overseen by the New York City Department of Parks and Recreation (NYC Parks)...',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/plaza.png',
                      description:
                          'Managed by the New York City Department of Transportation (NYC DOT), street plazas...',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/pops.png',
                      description:
                          'POPS are open spaces that are privately maintained but publicly accessible...',
                    ),
                    const SizedBox(height: 30),
                    const TypeDescription(
                      iconPath: 'assets/wpaa.png',
                      description:
                          'Overseen by the New York City Department of City Planning (DCP)...',
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