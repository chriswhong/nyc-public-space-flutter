import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SearchInput extends StatefulWidget {
  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when text changes
    _controller.addListener(() {
      print('listener');
      setState(() {}); // This triggers UI updates when text changes
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_controller.text);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Magnifying glass icon on the left
          FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            color: Colors.grey,
            size: 18,
          ),
          SizedBox(width: 10),
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search...',
              ),
              onChanged: (value) {
                setState(() {}); // Ensure state updates on text change
              },
            ),
          ),
          // Clear (X) button on the right
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.xmark,
                color: Colors.grey,
                size: 18,
              ),
              onPressed: () {
                _controller.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
