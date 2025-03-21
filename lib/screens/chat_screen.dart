  import 'package:firebase_core/firebase_core.dart';
  import 'package:flutter/material.dart';
  import 'package:flash_chat/constants.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  
  class ChatScreen extends StatefulWidget {
    static const String id = "chat_screen";
    @override
    _ChatScreenState createState() => _ChatScreenState();
  }
  
  class _ChatScreenState extends State<ChatScreen> {
    final messageTextController = TextEditingController();
    final _auth = FirebaseAuth.instance;
  
    late String messageText;
  
    @override
    void initState() {
      super.initState();
      getCurrentUser();
    }
  
    void getCurrentUser() async {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          loggedInUser = user;
          print(loggedInUser.email);
        }
      } catch (e) {
        print(e);
      }
    }
  
    void messagesStream() async {
      await for (var snapshot in _firestore.collection('messages').snapshots()) {
        for (var message in snapshot.docs) {
          print(message.data());
        }
      }
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  _auth.signOut();
                  Navigator.pop(context);
                }),
          ],
          title: Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessagesStream(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        messageTextController.clear();
                        _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser.email,
                          'senderName': loggedInUser.displayName ?? 'Anonymous',
                          'timestamp': FieldValue.serverTimestamp(), // Add timestamp
                        });
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
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
  
  class MessagesStream extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('messages')
              .orderBy('timestamp', descending: true) // Order by timestamp
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data!.docs;
            List<MessageBubble> messageBubbles = [];
  
            for (var message in messages) {
              final messageText = message.data()?['text'] ?? 'No text';
              final messageSender = message.data()?['sender'] ?? 'Unknown sender';
              final messageSenderName = message.data()?['senderName'] ?? 'Anonymous';

              final currentUser = loggedInUser.email;
  
              final messageBubble = MessageBubble(
                sender: messageSenderName,
                text: messageText,
                isMe: currentUser == messageSender,
              );
              messageBubbles.add(messageBubble);
            }
  
            return Expanded(
              child: ListView(
                reverse: true, // Fixed the semicolon
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                children: messageBubbles,
              ),
            );
          });
    }
  }
  
  class MessageBubble extends StatelessWidget {
    MessageBubble({required this.sender, required this.text, required this.isMe});
  
    final String sender;
    final String text;
    final bool isMe;
  
    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              sender,
              style: TextStyle(fontSize: 12.0, color: Colors.black54),
            ),
            Material(
              borderRadius: isMe
                  ? BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0))
                  : BorderRadius.only(
                  topRight: Radius.circular(30.0),
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0)),
              elevation: 5.0,
              color: isMe ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }