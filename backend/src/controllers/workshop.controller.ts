import { Request, Response, NextFunction } from 'express';
import { workshopService } from '../services/workshop.service';
import { sendSuccess } from '../utils/response.util';

export class WorkshopController {
  static async getWorkshops(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const city = typeof req.query.city === 'string' ? req.query.city : undefined;
      const area = typeof req.query.area === 'string' ? req.query.area : undefined;

      const workshops = await workshopService.getWorkshops({ city, area });
      sendSuccess(res, workshops, 200, 'Workshops retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getWorkshopById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const workshop = await workshopService.getWorkshopById(req.params.id as string);
      sendSuccess(res, workshop, 200, 'Workshop retrieved successfully');
    } catch (error) {
      next(error);
    }
  }
}
