import { Request, Response, NextFunction } from 'express';
import { VehicleService } from '../services/vehicle.service';
import { sendSuccess, sendPaginated } from '../utils/response.util';
import { parsePagination } from '../utils/pagination.util';
import { ApiError } from '../utils/errors';

export class VehicleController {
  static async createVehicle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      // Security: Prevent User ID Spoofing
      if (req.body.userId && req.body.userId !== req.user.id) {
        throw new ApiError('Cannot create a vehicle for another user.', 403, 'FORBIDDEN');
      }

      const { make, model, variant, registrationNumber, fuelType, year, isActive } =
        req.body;
      const vehicle = await VehicleService.createVehicle({
        userId: req.user.id,
        make,
        model,
        variant,
        registrationNumber,
        fuelType,
        year,
        isActive,
      });
      sendSuccess(res, vehicle, 201, 'Vehicle added to garage successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getVehicles(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const pagination = parsePagination(req.query);

      // Security: Always scope list query to authenticated user's ID
      const result = await VehicleService.getVehicles(pagination, req.user.id);
      sendPaginated(res, result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  static async getVehicleById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const vehicle = await VehicleService.getVehicleById(
        req.params.id as string,
        req.user.id
      );
      sendSuccess(res, vehicle);
    } catch (error) {
      next(error);
    }
  }

  static async updateVehicle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const updatedVehicle = await VehicleService.updateVehicle(
        req.params.id as string,
        req.body,
        req.user.id
      );
      sendSuccess(res, updatedVehicle, 200, 'Vehicle updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async setActiveVehicle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      const vehicle = await VehicleService.setActiveVehicle(
        req.params.id as string,
        req.user.id
      );
      sendSuccess(res, vehicle, 200, 'Active vehicle updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deleteVehicle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new ApiError('Authentication required', 401, 'UNAUTHORIZED');
      }

      await VehicleService.deleteVehicle(req.params.id as string, req.user.id);
      sendSuccess(res, null, 200, 'Vehicle removed from garage');
    } catch (error) {
      next(error);
    }
  }
}
