import { Router } from 'express';
import {
  getCompanyProfile,
  getCompanyFundamentals,
  getCompanyTechnical,
  getCompanyDerivatives
} from '../controllers/companyController.js';

const router = Router();

router.get('/:symbol/profile', getCompanyProfile);
router.get('/:symbol/fundamentals', getCompanyFundamentals);
router.get('/:symbol/technical', getCompanyTechnical);
router.get('/:symbol/derivatives', getCompanyDerivatives);

export default router;