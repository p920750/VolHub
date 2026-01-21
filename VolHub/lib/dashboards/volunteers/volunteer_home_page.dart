// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'volunteer_colors.dart';
// // import 'volunteer_menu_page.dart';
// // import 'volunteer_chat_page.dart';
// // import 'volunteer_board_page.dart';
// import 'volunteer_profile_page.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class VolunteerHomePage extends StatefulWidget {
//   const VolunteerHomePage({Key? key}) : super(key: key);

//   @override
//   State<VolunteerHomePage> createState() => _VolunteerHomePageState();
// }

// class _VolunteerHomePageState extends State<VolunteerHomePage> {
//   int _currentIndex = 0;
//   String _selectedSortLabel = 'Sort by';
//   String? userProfileImage;

//   final GlobalKey _sortKey = GlobalKey();
//   OverlayEntry? _overlayEntry;

//   bool _isSortOpen = false;
//   String? _expandedCategory;

//   @override
//   void initState() {
//     super.initState();
//     final user = Supabase.instance.client.auth.currentUser;

//     // Use avatar_url or picture
//     userProfileImage = (user?.userMetadata?['avatar_url'] as String?) ??
//                        (user?.userMetadata?['picture'] as String?);
//   }

//   final Map<String, List<String>> sortOptions = {
//     'Day': [
//       '5 days ago',
//       '10 days ago',
//       '15 days ago',
//       '20 days ago',
//       '25 days ago',
//       '30 days ago',
//     ],
//     'Week': [
//       '1 week ago',
//       '2 weeks ago',
//       '3 weeks ago',
//       '4 weeks ago',
//       '7 weeks ago',
//       '14 weeks ago',
//       '28 weeks ago',
//     ],
//     'Month': [
//       '1 month ago',
//       '2 months ago',
//       '3 months ago',
//       '4 months ago',
//       '5 months ago',
//       '6 months ago',
//       '10 months ago',
//       '12 months ago',
//       '15 months ago',
//       '22 months ago',
//       '25 months ago',
//       '30 months ago',
//     ],
//     'Year': [
//       '1 year ago',
//       '2 years ago',
//       '3 years ago',
//       '4 years ago',
//       '5 years ago',
//       '6 years ago',
//       '10 years ago',
//       '12 years ago',
//       '15 years ago',
//       '17 years ago',
//       '20 years ago',
//       '22 years ago',
//       '25 years ago',
//       '30 years ago',
//     ],
//   };

//   // Mock data for events
//   final List<Map<String, dynamic>> _events = [
//     {
//       'name': 'Beach Clean-up 2026',
//       'org': 'Green Earth Foundation',
//       'location': 'Santa Monica Beach',
//       'desc':
//           'Join us for a day of environmental action and community building.',
//       'isApplied': false,
//     },
//     {
//       'name': 'Food Drive',
//       'org': 'City Food Bank',
//       'location': 'Downtown Community Center',
//       'desc': 'Help us sort and distribute food packages to families in need.',
//       'isApplied': false,
//     },
//     {
//       'name': 'Tech Mentorship',
//       'org': 'Future Coders',
//       'location': 'Public Library Hall B',
//       'desc': 'Guide young students through their first Python projects.',
//       'isApplied': false,
//     },
//   ];

//   void _toggleSortDropdown() {
//     if (_overlayEntry != null) {
//       _removeOverlay();
//       return;
//     }

//     setState(() {
//       _isSortOpen = true;
//     });

//     final renderBox = _sortKey.currentContext!.findRenderObject() as RenderBox;
//     final offset = renderBox.localToGlobal(Offset.zero);
//     final screenSize = MediaQuery.of(context).size;

//     const double dropdownWidth = 320;

//     double left = offset.dx;
//     if (left + dropdownWidth > screenSize.width - 8) {
//       left = screenSize.width - dropdownWidth - 8;
//     }

//     _overlayEntry = OverlayEntry(
//       builder: (_) => Positioned(
//         left: left,
//         top: offset.dy + renderBox.size.height + 6,
//         width: dropdownWidth,
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
//             decoration: BoxDecoration(
//               color: VolunteerColors.card,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: const [
//                 BoxShadow(blurRadius: 10, color: Colors.black26),
//               ],
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: sortOptions.entries.map((entry) {
//                   final bool isExpanded = _expandedCategory == entry.key;

//                   return Column(
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           setState(() {
//                             _expandedCategory = isExpanded ? null : entry.key;
//                           });
//                           _overlayEntry?.markNeedsBuild();
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 14,
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   entry.key,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                               AnimatedRotation(
//                                 turns: isExpanded ? 0.5 : 0.0,
//                                 duration: const Duration(milliseconds: 200),
//                                 child: const Icon(Icons.keyboard_arrow_down),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       if (isExpanded)
//                         Column(
//                           children: entry.value.map((option) {
//                             return InkWell(
//                               onTap: () {
//                                 setState(() {
//                                   _selectedSortLabel = option;
//                                 });
//                                 _removeOverlay();
//                               },
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 24,
//                                   vertical: 10,
//                                 ),
//                                 child: Align(
//                                   alignment: Alignment.centerLeft,
//                                   child: Text(option),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//   }

//   void _removeOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//     _expandedCategory = null;

//     setState(() {
//       _isSortOpen = false;
//     });
//   }

//   @override
//   void dispose() {
//     _removeOverlay();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: VolunteerColors.background,

//       // 🔹 APP BAR
//       appBar: AppBar(
//         backgroundColor: VolunteerColors.card,
//         elevation: 0,
//         leadingWidth: 56,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 20),
//           child: Center(
//             child: Image.asset(
//               'assets/icons/icon_1.png',
//               width: 32,
//               height: 32,
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: GestureDetector(
//               onTap: () {
//                 _removeOverlay();
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const VolunteerProfilePage(),
//                   ),
//                 );
//               },
//               child: CircleAvatar(
//                 radius: 20,
//                 backgroundColor: VolunteerColors.accentSoftBlue,
//                 backgroundImage: userProfileImage != null
//                     ? NetworkImage(userProfileImage!)
//                     : null,
//               ),
//             ),
//           ),
//         ],
//       ),

//       // 🔹 BODY
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 const Text(
//                   'Events',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//                 ),
//                 const Spacer(),
//                 TextButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(FontAwesomeIcons.filter, size: 14),
//                   label: const Text('Filter'),
//                 ),
//                 const SizedBox(width: 16),
//                 GestureDetector(
//                   key: _sortKey,
//                   onTap: _toggleSortDropdown,
//                   child: Row(
//                     children: [
//                       Text(
//                         _selectedSortLabel,
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(width: 2),
//                       AnimatedRotation(
//                         turns: _isSortOpen ? 0.5 : 0.0,
//                         duration: const Duration(milliseconds: 200),
//                         child: const Icon(Icons.keyboard_arrow_down, size: 20),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),
//           Expanded(
//             child: _events.isEmpty
//                 ? const Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           FontAwesomeIcons.boxOpen,
//                           size: 48,
//                           color: Colors.grey,
//                         ),
//                         SizedBox(height: 12),
//                         Text(
//                           'No events yet',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: _events.length,
//                     itemBuilder: (context, index) {
//                       final event = _events[index];
//                       return Card(
//                         color: VolunteerColors.card,
//                         margin: const EdgeInsets.only(bottom: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 event['name'],
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 event['org'],
//                                 style: TextStyle(
//                                   color: VolunteerColors.accentSoftBlue,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.location_on,
//                                     size: 16,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     event['location'],
//                                     style: const TextStyle(color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 event['desc'],
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   height: 1.4,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: event['isApplied']
//                                         ? Colors.green
//                                         : Colors.blue,
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       event['isApplied'] = !event['isApplied'];
//                                     });
//                                   },
//                                   child: Text(
//                                     event['isApplied'] ? 'Applied' : 'Register',
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),

//       // 🔹 BOTTOM NAV
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         type: BottomNavigationBarType.fixed,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });

//           if (index == 0) return;

//           if (index == 1) {
//             // Navigator.push(
//             //   context,
//             //   MaterialPageRoute(builder: (_) => const VolunteerMenuPage()),
//             // );
//           } else if (index == 2) {
//             // Navigator.push(
//             //   context,
//             //   MaterialPageRoute(builder: (_) => const VolunteerChatPage()),
//             // );
//           } else if (index == 3) {
//             // Navigator.push(
//             //   context,
//             //   MaterialPageRoute(builder: (_) => const VolunteerBoardPage()),
//             // );
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(FontAwesomeIcons.house),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(FontAwesomeIcons.bars),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(FontAwesomeIcons.comments),
//             label: 'Chats',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(FontAwesomeIcons.chartSimple),
//             label: 'Board',
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'volunteer_colors.dart';
// import 'volunteer_menu_page.dart';
// import 'volunteer_chat_page.dart';
// import 'volunteer_board_page.dart';
import 'volunteer_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({Key? key}) : super(key: key);

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  int _currentIndex = 0;
  String _selectedSortLabel = 'Sort by';
  String? userProfileImage;

  final GlobalKey _sortKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  bool _isSortOpen = false;
  String? _expandedCategory;

  bool isApplied = false;
  bool isCancelled = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;

    // Use avatar_url or picture
    userProfileImage =
        (user?.userMetadata?['avatar_url'] as String?) ??
        (user?.userMetadata?['picture'] as String?);
  }

  final Map<String, List<String>> sortOptions = {
    'Day': [
      '1 day ago',
      '2 days ago',
      '3 days ago',
      '4 days ago',
      '5 days ago',
      '6 days ago',
    ],
    'Week': [
      '1 week ago',
      '2 weeks ago',
      '3 weeks ago',
      '4 weeks ago',
      '5 weeks ago',
      '6 weeks ago',
    ],
    'Month': [
      '1 month ago',
      '2 months ago',
      '3 months ago',
      '4 months ago',
      '5 months ago',
      '6 months ago',
    ],
    'Year': [
      '1 year ago',
      '2 years ago',
      '3 years ago',
      '4 years ago',
      '5 years ago',
      '6 years ago',
    ],
  };

  // Mock data for events
  final List<Map<String, dynamic>> _events = [
    {
      'name': 'Beach Clean-up 2026',
      'org': 'Green Earth Foundation',
      'location': 'Santa Monica Beach',
      'desc':
          'Join us for a day of environmental action and community building.',
      'isApplied': false,
      'isCancelled': false,
    },
    {
      'name': 'Food Drive',
      'org': 'City Food Bank',
      'location': 'Downtown Community Center',
      'desc': 'Help us sort and distribute food packages to families in need.',
      'isApplied': false,
      'isCancelled': false,
    },
    {
      'name': 'Tech Mentorship',
      'org': 'Future Coders',
      'location': 'Public Library Hall B',
      'desc': 'Guide young students through their first Python projects.',
      'isApplied': false,
      'isCancelled': false,
    },
  ];

  void _toggleSortDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    setState(() {
      _isSortOpen = true;
    });

    final renderBox = _sortKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    const double dropdownWidth = 320;

    double left = offset.dx;
    if (left + dropdownWidth > screenSize.width - 8) {
      left = screenSize.width - dropdownWidth - 8;
    }

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: offset.dy + renderBox.size.height + 6,
        width: dropdownWidth,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
            decoration: BoxDecoration(
              color: VolunteerColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black26),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: sortOptions.entries.map((entry) {
                  final bool isExpanded = _expandedCategory == entry.key;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedCategory = isExpanded ? null : entry.key;
                          });
                          _overlayEntry?.markNeedsBuild();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Column(
                          children: entry.value.map((option) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSortLabel = option;
                                });
                                _removeOverlay();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(option),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  String _truncateDescription(String text, {int maxWords = 45}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return words.take(maxWords).join(' ') + ' ...';
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _expandedCategory = null;

    setState(() {
      _isSortOpen = false;
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        useMaterial3: false, // ✅ disables scroll tint
      ),
      child: Scaffold(
        backgroundColor: VolunteerColors.background,

        // 🔹 APP BAR
        appBar: AppBar(
          backgroundColor: VolunteerColors.card,
          elevation: 0,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Center(
              child: Image.asset(
                'assets/icons/icon_1.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  _removeOverlay();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VolunteerProfilePage(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: VolunteerColors.accentSoftBlue,
                  backgroundImage: userProfileImage != null
                      ? NetworkImage(userProfileImage!)
                      : null,
                ),
              ),
            ),
          ],
        ),

        // 🔹 BODY
        body: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(FontAwesomeIcons.filter, size: 14),
                    label: const Text('Filter'),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    key: _sortKey,
                    onTap: _toggleSortDropdown,
                    child: Row(
                      children: [
                        Text(
                          _selectedSortLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: _isSortOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _events.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FontAwesomeIcons.boxOpen,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No events yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return InkWell(
                          // onTap: () {
                          //   Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (_) => EventCardViewPage(event: event),
                          //     ),
                          //   );
                          // },
                          child: Card(
                            color: VolunteerColors.card,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name of event: ' + event['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hosted by: ' + event['org'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Color.fromARGB(255, 243, 54, 40),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Location: ' + event['location'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Description: ' +
                                        _truncateDescription(event['desc']),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            event['isApplied'] == true
                                            ? Colors.green
                                            : Colors.blue,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.green,
                                        disabledForegroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: event['isApplied'] == true
                                          ? null // disables the button when already applied
                                          : () {
                                              setState(() {
                                                event['isApplied'] = true;
                                              });
                                            },
                                      child: Text(
                                        event['isApplied']
                                            ? 'Applied'
                                            : 'Register',
                                      ),
                                    ),
                                  ),
                                  if (event['isApplied'] == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  alignment: Alignment.center,
                                                  content: const Text(
                                                    'Are you sure you want to cancel the registered event?',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  actionsAlignment:
                                                      MainAxisAlignment.center,
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          event['isApplied'] =
                                                              false;
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        'Yes',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        'No',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // 🔹 BOTTOM NAV
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });

            if (index == 0) return;

            if (index == 1) {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const VolunteerMenuPage()),
              // );
            } else if (index == 2) {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const VolunteerChatPage()),
              // );
            } else if (index == 3) {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const VolunteerBoardPage()),
              // );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.house),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.bars),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.comments),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.chartSimple),
              label: 'Board',
            ),
          ],
        ),
      ),
    );
  }
}
