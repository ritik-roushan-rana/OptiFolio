import axios from 'axios';
import fs from 'fs';
import path from 'path';
import csvParser from 'csv-parser';
import { fileURLToPath } from 'url';
import PortfolioModel from '../models/portfolioModel.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Chatbot Controller
const chatbotController = async (req, res) => {
  try {
    console.log('ChatbotController invoked');
    const { message } = req.body;
    console.log('Received message:', message);

    if (!message) {
      console.log('Error: Message is required');
      return res.status(400).json({ error: 'Message is required' });
    }

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
    const botReply = response.data.candidates?.[0]?.content?.parts?.[0]?.text || 'No reply available';

    if (!botReply) {
      console.log('Error: Failed to retrieve a reply from the Gemini API');
      return res.status(500).json({ error: 'Failed to retrieve a reply from the Gemini API.' });
    }

    console.log('Bot Reply:', botReply);
    res.status(200).json({ reply: botReply });
  } catch (error) {
    console.error('Error in chatbotController:', error);
    res.status(500).json({ error: 'Failed to process the request' });
  }
};

export default chatbotController;
