import { Router } from 'express';
import { ServiceController } from '../controllers/service.controller';

const router = Router();

router.get('/', ServiceController.getServices);
router.post('/', ServiceController.createService);
router.get('/:id', ServiceController.getServiceById);
router.patch('/:id', ServiceController.updateService);
router.delete('/:id', ServiceController.deleteService);

export default router;
