import { Router } from 'express';
import { WorkshopController } from '../controllers/workshop.controller';

const router = Router();

// Publicly readable workshops endpoint (guest or authenticated)
router.get('/', WorkshopController.getWorkshops);
router.get('/:id', WorkshopController.getWorkshopById);

export default router;
