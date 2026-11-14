import { Router } from 'express';
import { VehicleController } from '../controllers/vehicle.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all vehicle routes with authentication
router.use(authenticate);

router.get('/', VehicleController.getVehicles);
router.post('/', VehicleController.createVehicle);
router.get('/:id', VehicleController.getVehicleById);
router.patch('/:id/active', VehicleController.setActiveVehicle);
router.patch('/:id', VehicleController.updateVehicle);
router.delete('/:id', VehicleController.deleteVehicle);

export default router;
