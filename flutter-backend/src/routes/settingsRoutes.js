import { Router } from 'express';
import { authGuard } from '../middleware/auth.js';
import { getSettings, upsertSettings, patchSetting } from '../controllers/settingsController.js';

const router = Router();
router.use(authGuard);

router.get('/', getSettings);
router.put('/', upsertSettings);
router.patch('/:key', patchSetting);

export default router;