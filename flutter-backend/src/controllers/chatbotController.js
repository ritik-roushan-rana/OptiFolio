import axios from 'axios';
import path from 'path';
import csvParser from 'csv-parser';
import { fileURLToPath } from 'url';
import PortfolioModel from '../models/portfolioModel.js';
import ChatbotMessage from '../models/chatbotModel.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Chatbot Controller
const chatbotController = async (req, res) => {
  try {
    console.log('ChatbotController invoked');
    const { message, userId } = req.body;
    console.log('Received message:', message);

    if (!message || !userId) {
      console.log('Error: Message and userId are required');
      return res.status(400).json({ error: 'Message and userId are required' });
    }

    // Send an intermediate response to indicate processing
    res.status(200).json({ reply: 'Analyzing data...' });

    let botReply;

    if (message.toLowerCase().includes('my name is')) {
      const name = message.split('my name is')[1].trim();
      botReply = `Okay, ${name}. Nice to meet you! Is there anything I can help you with today?`;
    } else if (message.toLowerCase().includes('what is my name')) {
      botReply = `I don't know your name. You would need to tell me your name.`;
    } else {
      // Call Gemini API with user message only
      const response = await axios.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        {
          contents: [
            {
              parts: [
                {
                  text: `User Message: ${message}`,
                },
              ],
            },
          ],
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': process.env.GEMINI_API_KEY,
          },
        }
      );

      console.log('Gemini API Response:', response.data);

      // Extract the bot's reply from the Gemini API response
      botReply = response.data.candidates?.[0]?.content?.parts?.[0]?.text || 'Sorry, I could not understand that.';

      if (!botReply) {
        console.log('Error: Failed to retrieve a reply from the Gemini API');
        return res.status(500).json({ error: 'Failed to retrieve a reply from the Gemini API.' });
      }
    }

    // Ensure the response is well-formatted and does not contain unwanted symbols
    const formattedReply = botReply.replace(/\*\*/g, '').replace(/\*/g, '').trim();

    console.log('Bot Reply:', formattedReply);

    res.status(200).json({ reply: formattedReply });
  } catch (error) {
    console.error('Error in chatbotController:', error.response?.data || error.message || error);
    res.status(500).json({ error: 'Failed to process the request' });
  }
};

export default chatbotController;
