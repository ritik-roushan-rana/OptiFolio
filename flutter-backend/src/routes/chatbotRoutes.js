import express from 'express';
import chatbotController from '../controllers/chatbotController.js';
import { authGuard } from '../middleware/auth.js';

const router = express.Router();

router.post('/chatbot', authGuard, chatbotController);

export default router;
