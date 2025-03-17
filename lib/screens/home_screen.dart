import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String id = "home_screen";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? selectedHotel;
  bool isLoading = false;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  // Get current logged in user
  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print('Logged in as: ${loggedInUser.email}');
      }
    } catch (e) {
      print(e);
    }
  }

  // Search for hotels by name (case-insensitive)
  void searchHotel() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a hotel name to search'))
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get the search text and convert to lowercase for comparison
      String searchText = _searchController.text.trim().toLowerCase();

      // Query all hotels - we'll filter for case-insensitive search in memory
      QuerySnapshot hotelQuery = await _firestore
          .collection('hotels')
          .get();

      // Filter results to find case-insensitive matches
      var matchingHotels = hotelQuery.docs.where((doc) {
        // Get hotel name and convert to lowercase
        String hotelName = (doc.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
        // Check if the hotel name contains our search text
        return hotelName.contains(searchText);
      }).toList();

      if (matchingHotels.isNotEmpty) {
        setState(() {
          selectedHotel = matchingHotels[0].data() as Map<String, dynamic>;
          selectedHotel!['id'] = matchingHotels[0].id; // Store the document ID
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          selectedHotel = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hotel found with name: ${_searchController.text}'))
        );
      }
    } catch (e) {
      print("Error searching: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for hotels'))
      );
    }
  }

  // Show check-in dialog
  void showCheckInDialog(String hotelId, String hotelName) {
    final TextEditingController bookingIdController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    // Pre-fill name if available
    if (loggedInUser.displayName != null) {
      nameController.text = loggedInUser.displayName!;
    }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Check In to $hotelName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Please enter your booking details to check in:'),
                  SizedBox(height: 16),
                  TextField(
                    controller: bookingIdController,
                    decoration: InputDecoration(
                      labelText: 'Booking ID / Reservation Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                ),
                onPressed: () {
                  // Validate inputs
                  if (bookingIdController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your booking ID'))
                    );
                    return;
                  }
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter your name'))
                    );
                    return;
                  }

                  // Close dialog
                  Navigator.pop(context);

                  // Process check-in
                  processCheckIn(
                      hotelId,
                      hotelName,
                      bookingIdController.text.trim(),
                      nameController.text.trim()
                  );
                },
                child: Text('Check In'),
              ),
            ],
          );
        }
    );
  }

  // Process the check-in and enable chat if successful
  void processCheckIn(String hotelId, String hotelName, String bookingId, String guestName) async {
    setState(() {
      isLoading = true;
    });

    try {
      // First verify the booking exists (in a real app, you'd check against actual bookings)
      // For this demo, we'll simulate verification with a delay
      await Future.delayed(Duration(seconds: 1));

      // Create check-in record in Firestore
      String checkInId = '${loggedInUser.uid}_$hotelId';

      await _firestore.collection('check_ins').doc(checkInId).set({
        'userId': loggedInUser.uid,
        'userEmail': loggedInUser.email,
        'guestName': guestName,
        'hotelId': hotelId,
        'hotelName': hotelName,
        'bookingId': bookingId,
        'checkInTime': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Create chat channel
      await _firestore.collection('channels').doc(checkInId).set({
        'clientId': loggedInUser.uid,
        'clientName': guestName,
        'clientEmail': loggedInUser.email,
        'hotelId': hotelId,
        'hotelName': hotelName,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      setState(() {
        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in successful!'),
            backgroundColor: Colors.green,
          )
      );

      // Navigate to chat
      Navigator.pushNamed(
          context,
          ChatScreen.id,
          arguments: {
            'channelId': checkInId,
            'hotelName': hotelName,
            'guestName': guestName,
          }
      );

    } catch (e) {
      print("Error during check-in: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during check-in. Please try again.'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  // Show hotel details
  void showHotelDetails(Map<String, dynamic> hotel) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(hotel['name'] ?? 'Hotel Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel image placeholder
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.hotel, size: 80, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.lightBlueAccent),
                    SizedBox(width: 8),
                    Expanded(child: Text(hotel['location'] ?? 'Location not available')),
                  ],
                ),
                SizedBox(height: 8),
                // Phone
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.lightBlueAccent),
                    SizedBox(width: 8),
                    Text(hotel['phone'] ?? 'Phone not available'),
                  ],
                ),
                SizedBox(height: 8),
                // Description if available
                if (hotel['description'] != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'About',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(hotel['description']),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  showCheckInDialog(hotel['id'], hotel['name']);
                },
                child: Text('Check In'),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }
          ),
        ],
        title: Text('🏨 Hotel Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a hotel by name',
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.lightBlueAccent),
                    onPressed: searchHotel,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: searchHotel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: Text(
                  'Search',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ),
            SizedBox(height: 24.0),

            // Display search result
            selectedHotel != null
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  onTap: () {
                    // Show hotel details instead of directly starting chat
                    showHotelDetails(selectedHotel!);
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.lightBlueAccent,
                    child: Icon(Icons.hotel, color: Colors.white),
                  ),
                  title: Text(
                    selectedHotel!['name'] ?? 'Unknown Hotel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  subtitle: Text(selectedHotel!['location'] ?? ''),
                  trailing: ElevatedButton(
                    onPressed: () {
                      showCheckInDialog(
                          selectedHotel!['id'] ?? '',
                          selectedHotel!['name'] ?? 'Unknown Hotel'
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                    child: Text('Check In'),
                  ),
                ),
              ),
            )
                : Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('hotels').limit(10).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No hotels found",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16.0,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Available Hotels",
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            var hotelData = doc.data() as Map<String, dynamic>;

                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: ListTile(
                                onTap: () {
                                },
                                leading: CircleAvatar(
                                  backgroundColor: Colors.lightBlueAccent,
                                  child: Icon(Icons.hotel, color: Colors.white),
                                ),
                                title: Text(
                                  hotelData['name'] ?? 'Unknown Hotel',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(hotelData['location'] ?? ''),
                                trailing: Icon(Icons.chat, color: Colors.lightBlueAccent),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}