import mongoose from 'mongoose';

const chatbotSchema = new mongoose.Schema({
  userMessage: { type: String, required: true },
  botReply: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

chatbotSchema.index({ createdAt: 1 }, { expireAfterSeconds: 86400 }); // Automatically delete after 24 hours

const ChatbotMessage = mongoose.model('ChatbotMessage', chatbotSchema);

export default ChatbotMessage;
