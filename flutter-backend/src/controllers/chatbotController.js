import axios from 'axios';
import fs from 'fs';
import path from 'path';
import csvParser from 'csv-parser';
import { fileURLToPath } from 'url';
import PortfolioModel from '../models/portfolioModel.js';
import ChatbotMessage from '../models/chatbotModel.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LOCAL_STORAGE_PATH = path.join(__dirname, '../../localStorage/userData.json');

const saveUserDataLocally = (userId, key, value) => {
  const timestamp = new Date().toISOString();
  const data = fs.existsSync(LOCAL_STORAGE_PATH)
    ? JSON.parse(fs.readFileSync(LOCAL_STORAGE_PATH, 'utf-8'))
    : {};

  if (!data[userId]) {
    data[userId] = {};
  }

  data[userId][key] = { value, timestamp };

  // Clean up data older than 24 hours
  Object.keys(data).forEach((id) => {
    Object.keys(data[id]).forEach((key) => {
      const entryTime = new Date(data[id][key].timestamp);
      if ((new Date() - entryTime) > 24 * 60 * 60 * 1000) {
        delete data[id][key];
      }
    });

    if (Object.keys(data[id]).length === 0) {
      delete data[id];
    }
  });

  fs.writeFileSync(LOCAL_STORAGE_PATH, JSON.stringify(data, null, 2));
};

const getUserDataLocally = (userId, key) => {
  if (!fs.existsSync(LOCAL_STORAGE_PATH)) return null;

  const data = JSON.parse(fs.readFileSync(LOCAL_STORAGE_PATH, 'utf-8'));
  return data[userId]?.[key]?.value || null;
};

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
      saveUserDataLocally(userId, 'name', name);
      botReply = `Okay, ${name}. Nice to meet you! Is there anything I can help you with today?`;
    } else if (message.toLowerCase().includes('what is my name')) {
      const name = getUserDataLocally(userId, 'name');
      botReply = name ? `Your name is ${name}.` : `I don't know your name. You would need to tell me your name.`;
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
