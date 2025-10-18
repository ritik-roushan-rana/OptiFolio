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
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!req.user || !req.user.id) {
      return res.status(401).json({ error: 'User authentication is required' });
    }

    const userId = req.user.id;
    const portfolio = await PortfolioModel.findOne({ userId });

    if (!portfolio) {
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    console.log('Portfolio Data:', portfolio);

    // Call Gemini API with portfolio data
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      {
        contents: [
          {
            parts: [
              {
                text: `User Message: ${message}\nPortfolio Context: ${JSON.stringify(portfolio)}`,
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
      return res.status(500).json({ error: 'Failed to retrieve a reply from the Gemini API.' });
    }

    res.status(200).json({ reply: botReply });
  } catch (error) {
    console.error('Error in chatbotController:', error);
    res.status(500).json({ error: 'Failed to process the request' });
  }
};

export default chatbotController;
