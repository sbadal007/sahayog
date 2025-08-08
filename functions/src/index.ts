import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// Archive conversations when offers are completed
export const archiveConversationOnOfferComplete = onDocumentUpdated(
  'offers/{offerId}',
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    
    // Check if offer status changed to 'completed'
    if (beforeData?.status !== 'completed' && afterData?.status === 'completed') {
      const offerId = event.params.offerId;
      
      try {
        // Find conversation for this offer
        const conversationsQuery = await db
          .collection('conversations')
          .where('offerId', '==', offerId)
          .get();
        
        if (conversationsQuery.empty) {
          console.log(`No conversation found for offer ${offerId}`);
          return;
        }
        
        const conversationDoc = conversationsQuery.docs[0];
        const conversationId = conversationDoc.id;
        const conversationData = conversationDoc.data();
        
        // Get all messages in the conversation
        const messagesQuery = await db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
        
        // Create archived conversation
        const archivedConversationData = {
          ...conversationData,
          isArchived: true,
          archivedAt: new Date(),
        };
        
        // Use batch to ensure atomicity
        const batch = db.batch();
        
        // Create archived conversation
        const archivedConversationRef = db
          .collection('archived_conversations')
          .doc(conversationId);
        batch.set(archivedConversationRef, archivedConversationData);
        
        // Copy all messages to archived conversation
        messagesQuery.docs.forEach((messageDoc) => {
          const archivedMessageRef = db
            .collection('archived_conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageDoc.id);
          batch.set(archivedMessageRef, messageDoc.data());
        });
        
        // Update original conversation to mark as archived
        const originalConversationRef = db
          .collection('conversations')
          .doc(conversationId);
        batch.update(originalConversationRef, {
          isArchived: true,
          archivedAt: new Date(),
        });
        
        // Commit all operations
        await batch.commit();
        
        console.log(`Successfully archived conversation ${conversationId} for completed offer ${offerId}`);
        
        // Optional: Clean up typing indicators
        const typingQuery = await db
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .get();
        
        const typingBatch = db.batch();
        typingQuery.docs.forEach((doc) => {
          typingBatch.delete(doc.ref);
        });
        await typingBatch.commit();
        
      } catch (error) {
        console.error(`Error archiving conversation for offer ${offerId}:`, error);
        throw error;
      }
    }
  }
);

// Clean up old typing indicators (runs every hour)
export const cleanupTypingIndicators = onDocumentUpdated(
  'conversations/{conversationId}',
  async (event) => {
    const conversationId = event.params.conversationId;
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    
    try {
      const typingQuery = await db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .where('timestamp', '<', fiveMinutesAgo)
        .get();
      
      if (!typingQuery.empty) {
        const batch = db.batch();
        typingQuery.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        
        console.log(`Cleaned up ${typingQuery.docs.length} old typing indicators for conversation ${conversationId}`);
      }
    } catch (error) {
      console.error(`Error cleaning up typing indicators for conversation ${conversationId}:`, error);
    }
  }
);
