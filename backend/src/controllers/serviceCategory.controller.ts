import { Request, Response, NextFunction } from 'express';
import { ServiceCategoryService } from '../services/serviceCategory.service';
import { sendSuccess, sendPaginated } from '../utils/response.util';
import { parsePagination } from '../utils/pagination.util';

export class ServiceCategoryController {
  static async createCategory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await ServiceCategoryService.createCategory(req.body);
      sendSuccess(res, category, 201, 'Service category created successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getCategories(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = parsePagination(req.query);
      const activeOnly = req.query.active === 'true';
      const result = await ServiceCategoryService.getCategories(pagination, activeOnly);
      sendPaginated(res, result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  static async getCategoryById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await ServiceCategoryService.getCategoryById(req.params.id as string);
      sendSuccess(res, category);
    } catch (error) {
      next(error);
    }
  }

  static async updateCategory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updated = await ServiceCategoryService.updateCategory(req.params.id as string, req.body);
      sendSuccess(res, updated, 200, 'Service category updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deleteCategory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await ServiceCategoryService.deleteCategory(req.params.id as string);
      sendSuccess(res, null, 200, 'Service category deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}
