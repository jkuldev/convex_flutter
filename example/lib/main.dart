import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/material.dart';

late ConvexClient convexClient;
Future<void> main() async {
  convexClient = await ConvexClient.init(
    deploymentUrl: "https://merry-grasshopper-563.convex.cloud",
    clientId: "flutter-app-1.0",
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController messageController = TextEditingController();
  SubscriptionHandle? subscriptionHandle;
  String currentUserId = "Flutter App"; // Replace with actual user ID
  List<Map<String, dynamic>> updates = [];

  @override
  void initState() {
    super.initState();
    subChat();
  }

  subChat() async {
    if (subscriptionHandle == null) {
      subscriptionHandle = await convexClient.subscribe(
        name: "messages:list",
        args: {},
        onUpdate: (value) {
          final List<dynamic> jsonList = jsonDecode(value);
          final List<Map<String, dynamic>> parsedValues = jsonList
              .map((e) => e as Map<String, dynamic>)
              .toList();
          setState(() {
            updates = parsedValues;
          });
        },
        onError: (message, value) {
          print("Error: $message, Value: $value");
        },
      );
    } else {
      subscriptionHandle?.dispose();
      subscriptionHandle = null;
    }
  }

  sendMessage(String message) async {
    print("Sending message: $message");
    await ConvexClient.instance.mutation(
      name: "messages:send",
      args: {"body": message, "author": "Singh"},
    );
    print("Message sent: $message");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Convex Flutter Demo')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    final message = updates[index];
                    final bool isMyMessage = message['userId'] == currentUserId;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? Colors.blue[100]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12).copyWith(
                            bottomRight: isMyMessage
                                ? Radius.zero
                                : const Radius.circular(12),
                            bottomLeft: isMyMessage
                                ? const Radius.circular(12)
                                : Radius.zero,
                          ),
                        ),
                        child: Text(
                          message['body'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        sendMessage(messageController.text);
                        messageController.clear();
                      },
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
