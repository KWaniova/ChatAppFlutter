import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return const Center(
              child: Text('No messages yet'),
            );
          }
          final messages = chatSnapshots.data!.docs;
          return ListView.builder(
              padding: const EdgeInsets.only(bottom: 40, left: 13, right: 13),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                final chatMessage = messages[index].data();
                final nextChatMessage = index + 1 < messages.length
                    ? messages[index + 1].data()
                    : null;
                final currentMessageUserId = chatMessage['userId'];
                final nextMessageUserId =
                    nextChatMessage != null ? nextChatMessage['userId'] : null;

                final nextUserIsSame =
                    currentMessageUserId == nextMessageUserId;
                final isMe = currentUserId == chatMessage['userId'];

                if (nextUserIsSame) {
                  return MessageBubble.next(
                      message: chatMessage['text'], isMe: isMe);
                }

                return MessageBubble.first(
                  message: chatMessage['text'],
                  isMe: isMe,
                  key: ValueKey(messages[index].id),
                  username: chatMessage['username'],
                  userImage: chatMessage['userImage'],
                );
              }
              // => ListTile(
              //       leading: CircleAvatar(
              //           backgroundImage:
              //               NetworkImage(chatDocs[index]['userImage'])),
              //       title: Text(chatDocs[index]['username']),
              //       subtitle: Text(chatDocs[index]['text']),
              //     )
              );
        });
  }
}
