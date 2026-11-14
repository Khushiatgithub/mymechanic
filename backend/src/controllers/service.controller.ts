import { Request, Response, NextFunction } from 'express';
import { ServiceService } from '../services/service.service';
import { sendSuccess, sendPaginated } from '../utils/response.util';
import { parsePagination } from '../utils/pagination.util';

export class ServiceController {
  static async createService(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const service = await ServiceService.createService(req.body);
      sendSuccess(res, service, 201, 'Service package created successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getServices(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = parsePagination(req.query);
      const categoryId = typeof req.query.categoryId === 'string' ? req.query.categoryId : undefined;
      const activeOnly = req.query.active === 'true';
      const search = typeof req.query.search === 'string' ? req.query.search : undefined;
      const sort = typeof req.query.sort === 'string' ? req.query.sort : undefined;

      const result = await ServiceService.getServices(pagination, {
        categoryId,
        activeOnly,
        search,
        sort,
      });

      sendPaginated(res, result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  static async getServiceById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const service = await ServiceService.getServiceById(req.params.id as string);
      sendSuccess(res, service);
    } catch (error) {
      next(error);
    }
  }

  static async updateService(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updated = await ServiceService.updateService(req.params.id as string, req.body);
      sendSuccess(res, updated, 200, 'Service updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deleteService(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await ServiceService.deleteService(req.params.id as string);
      sendSuccess(res, null, 200, 'Service deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}
