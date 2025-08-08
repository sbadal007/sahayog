import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'error_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get conversation for an offer
  static Future<String> createOrGetConversation({
    required String offerId,
    required String requesterId,
    required String helperId,
    String? requestId, // Add requestId for better conversation lookup
  }) async {
    // Validate required parameters
    if (offerId.isEmpty || requesterId.isEmpty || helperId.isEmpty) {
      throw ArgumentError('offerId, requesterId, and helperId cannot be empty');
    }
    
    if (requesterId == helperId) {
      throw ArgumentError('requesterId and helperId cannot be the same');
    }
    
    try {
      // First, check if conversation already exists between these participants
      // This prevents duplicate chats for the same request between same users
      final existingConversation = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: requesterId)
          .limit(20) // Limit to improve performance
          .get();

      // Look for existing conversation with both participants
      String? fallbackConversationId;
      
      for (var doc in existingConversation.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        // Check if this conversation involves both users
        if (participants.contains(helperId) && participants.contains(requesterId)) {
          // If requestId is provided, prefer conversations for the same request
          if (requestId != null && requestId.isNotEmpty) {
            final existingRequestId = data['requestId'] as String?;
            if (existingRequestId == requestId) {
              debugPrint('ChatService: Found existing conversation for same request: ${doc.id}');
              return doc.id;
            }
            // Store as fallback if no exact match found
            fallbackConversationId ??= doc.id;
          } else {
            // If no requestId specified, return the first matching conversation
            debugPrint('ChatService: Found existing conversation: ${doc.id}');
            return doc.id;
          }
        }
      }

      // If requestId was provided but no exact match found, reuse existing conversation
      if (requestId != null && requestId.isNotEmpty && fallbackConversationId != null) {
        debugPrint('ChatService: Reusing existing conversation for new request: $fallbackConversationId');
        
        // Add a system message about the new request
        await sendMessage(
          conversationId: fallbackConversationId,
          text: 'New offer discussion started for a different request.',
          isSystemMessage: true,
        );
        
        return fallbackConversationId;
      }

      // Create new conversation if none exists
      final conversationData = Conversation(
        id: '',
        offerId: offerId,
        requestId: requestId,
        participants: [requesterId, helperId],
        lastMessageAt: DateTime.now(),
        lastMessageText: 'Conversation started',
        unreadCount: {requesterId: 0, helperId: 0},
        isArchived: false,
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData.toMap());

      // Create system message
      await sendMessage(
        conversationId: docRef.id,
        text: 'Chat started for this offer. You can now communicate directly!',
        isSystemMessage: true,
      );

      debugPrint('ChatService: Created new conversation: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      ErrorService.logFirebaseError(
        message: 'Failed to create or get conversation',
        location: 'ChatService.createOrGetConversation',
        error: e,
        stackTrace: stackTrace,
        collection: 'conversations',
        operation: 'create_conversation',
      );
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String conversationId,
    required String text,
    bool isSystemMessage = false,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null && !isSystemMessage) {
        throw Exception('User must be authenticated to send messages');
      }

      // Get conversation to validate participants
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final conversation = Conversation.fromMap(conversationDoc.data()!, conversationId);

      // Check if conversation is archived
      if (conversation.isArchived) {
        throw Exception('Cannot send messages to archived conversations');
      }

      // Validate user is participant (unless system message)
      if (!isSystemMessage && !conversation.participants.contains(currentUser!.uid)) {
        throw Exception('User is not a participant in this conversation');
      }

      // Create message
      final message = Message(
        id: '',
        conversationId: conversationId,
        senderId: isSystemMessage ? 'system' : currentUser!.uid,
        senderName: isSystemMessage ? 'System' : (currentUser!.displayName ?? 'User'),
        text: text,
        createdAt: DateTime.now(),
        readBy: isSystemMessage ? conversation.participants : [currentUser!.uid],
        type: isSystemMessage ? 'system' : 'text',
      );

      // Add message to subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());

      // Update conversation last message and unread counts
      final updatedUnreadCount = Map<String, int>.from(conversation.unreadCount);
      if (!isSystemMessage) {
        for (String participantId in conversation.participants) {
          if (participantId != currentUser!.uid) {
            updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1;
          }
        }
      }

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessageText': text,
        'unreadCount': updatedUnreadCount,
      });

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Reset unread count for this user
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'unreadCount.$userId': 0,
      });

      // Update messages readBy array
      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('readBy', whereNotIn: [userId])
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get conversation stream
  static Stream<Conversation?> getConversationStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Conversation.fromMap(doc.data()!, doc.id);
    });
  }

  // Get messages stream for a conversation
  static Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get user conversations stream
  static Stream<List<Conversation>> getUserConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get archived conversations stream
  static Stream<List<Conversation>> getArchivedConversationsStream(String userId) {
    return _firestore
        .collection('archived_conversations')
        .where('participants', arrayContains: userId)
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get total unread count for user
  static Stream<int> getTotalUnreadCountStream(String userId) {
    return getUserConversationsStream(userId).map((conversations) {
      return conversations.fold<int>(0, (total, conversation) {
        return total + conversation.getUnreadCountForUser(userId);
      });
    });
  }

  // Get conversation by offer ID
  static Future<String?> getConversationByOfferId(String offerId) async {
    try {
      final query = await _firestore
          .collection('conversations')
          .where('offerId', isEqualTo: offerId)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting conversation by offer ID: $e');
      return null;
    }
  }

  // Update typing indicator
  static Future<void> updateTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': isTyping,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating typing indicator: $e');
    }
  }

  // Get typing indicators stream
  static Stream<List<String>> getTypingIndicatorsStream(String conversationId, String currentUserId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final typingUsers = <String>[];
      final fiveMinutesAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5)));

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isTyping = data['isTyping'] as bool? ?? false;
        final timestamp = data['timestamp'] as Timestamp?;
        
        // Only consider recent typing indicators and exclude current user
        if (isTyping && 
            doc.id != currentUserId && 
            timestamp != null && 
            timestamp.compareTo(fiveMinutesAgo) > 0) {
          typingUsers.add(doc.id);
        }
      }

      return typingUsers;
    });
  }
}
