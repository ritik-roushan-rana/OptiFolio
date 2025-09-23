import { Router } from 'express';
import { authGuard } from '../middleware/auth.js';
import { listAlerts, createAlert } from '../controllers/alertController.js';

const router = Router();

router.use(authGuard);

router.get('/', listAlerts);
router.post('/', createAlert);

export default router;