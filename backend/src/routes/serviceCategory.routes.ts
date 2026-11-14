import { Router } from 'express';
import { ServiceCategoryController } from '../controllers/serviceCategory.controller';

const router = Router();

router.get('/', ServiceCategoryController.getCategories);
router.post('/', ServiceCategoryController.createCategory);
router.get('/:id', ServiceCategoryController.getCategoryById);
router.patch('/:id', ServiceCategoryController.updateCategory);
router.delete('/:id', ServiceCategoryController.deleteCategory);

export default router;
