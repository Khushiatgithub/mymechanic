import { Vehicle, IVehicle } from '../models/vehicle.model';
import { User } from '../models/user.model';
import { Booking } from '../models/booking.model';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors';
import { validateObjectId, normalizeRegistrationNumber } from '../utils/validation.util';
import { PaginationOptions, buildPaginationMeta } from '../utils/pagination.util';
import { PaginatedData } from '../utils/response.util';

export const ALLOWED_FUEL_TYPES = ['Petrol', 'Diesel', 'Electric', 'CNG', 'Hybrid'] as const;
export type FuelType = typeof ALLOWED_FUEL_TYPES[number];

export interface CreateVehicleInput {
  userId: string;
  make: string;
  model: string;
  variant?: string;
  registrationNumber: string;
  fuelType: string;
  year: number;
  isActive?: boolean;
}

export interface UpdateVehicleInput {
  make?: string;
  model?: string;
  variant?: string;
  registrationNumber?: string;
  fuelType?: string;
  year?: number;
  isActive?: boolean;
}

export class VehicleService {
  static async createVehicle(input: CreateVehicleInput): Promise<IVehicle> {
    const userId = validateObjectId(input.userId, 'User ID');

    // 1. Verify user exists
    const userExists = await User.exists({ _id: userId });
    if (!userExists) {
      throw new NotFoundError(`User with ID '${input.userId}' not found.`);
    }

    // 2. Validate fields
    if (!input.make || typeof input.make !== 'string' || input.make.trim() === '') {
      throw new ValidationError('Vehicle make is required.');
    }
    if (!input.model || typeof input.model !== 'string' || input.model.trim() === '') {
      throw new ValidationError('Vehicle model is required.');
    }
    if (
      !input.registrationNumber ||
      typeof input.registrationNumber !== 'string' ||
      input.registrationNumber.trim() === ''
    ) {
      throw new ValidationError('Registration number is required.');
    }

    const regNumber = normalizeRegistrationNumber(input.registrationNumber);

    // Check duplicate registration number for this user
    const existingVehicle = await Vehicle.findOne({
      userId,
      registrationNumber: regNumber,
    });
    if (existingVehicle) {
      throw new ConflictError(
        `Vehicle with registration number '${regNumber}' already exists in this garage.`,
        'VEHICLE_ALREADY_EXISTS'
      );
    }

    if (!input.fuelType || !ALLOWED_FUEL_TYPES.includes(input.fuelType as FuelType)) {
      throw new ValidationError(
        `Invalid fuel type. Allowed values are: ${ALLOWED_FUEL_TYPES.join(', ')}.`
      );
    }

    const currentYear = new Date().getFullYear();
    const parsedYear = Number(input.year);
    if (!Number.isInteger(parsedYear) || parsedYear < 1990 || parsedYear > currentYear + 1) {
      throw new ValidationError(
        `Year must be a valid integer between 1990 and ${currentYear + 1}.`
      );
    }

    // Check if user has other vehicles. If first vehicle or isActive is true, set as active
    const userVehicleCount = await Vehicle.countDocuments({ userId });
    const shouldBeActive =
      input.isActive !== undefined ? Boolean(input.isActive) : userVehicleCount === 0;

    if (shouldBeActive) {
      // Deactivate other vehicles for this user
      await Vehicle.updateMany({ userId }, { isActive: false });
    }

    const vehicle = new Vehicle({
      userId,
      make: input.make.trim(),
      model: input.model.trim(),
      ...(input.variant ? { variant: input.variant.trim() } : {}),
      registrationNumber: regNumber,
      fuelType: input.fuelType,
      year: parsedYear,
      isActive: shouldBeActive,
    });

    return await vehicle.save();
  }

  static async getVehicles(
    pagination: PaginationOptions,
    ownerUserId?: string
  ): Promise<PaginatedData<IVehicle>> {
    const filter: Record<string, unknown> = {};

    if (ownerUserId) {
      validateObjectId(ownerUserId, 'User ID');
      filter.userId = ownerUserId;
    }

    const total = await Vehicle.countDocuments(filter);
    const items = await Vehicle.find(filter)
      .sort({ isActive: -1, createdAt: -1 })
      .skip(pagination.skip)
      .limit(pagination.limit);

    return {
      items,
      pagination: buildPaginationMeta(total, pagination.page, pagination.limit),
    };
  }

  static async getVehicleById(id: string, ownerUserId?: string): Promise<IVehicle> {
    validateObjectId(id, 'Vehicle ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const vehicle = await Vehicle.findOne(filter);
    if (!vehicle) {
      throw new NotFoundError(`Vehicle with ID '${id}' not found.`);
    }
    return vehicle;
  }

  static async updateVehicle(
    id: string,
    input: UpdateVehicleInput,
    ownerUserId?: string
  ): Promise<IVehicle> {
    validateObjectId(id, 'Vehicle ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const existingVehicle = await Vehicle.findOne(filter);
    if (!existingVehicle) {
      throw new NotFoundError(`Vehicle with ID '${id}' not found.`);
    }

    const updatePayload: Record<string, unknown> = {};

    if (input.make !== undefined) {
      if (typeof input.make !== 'string' || input.make.trim() === '') {
        throw new ValidationError('Vehicle make cannot be empty.');
      }
      updatePayload.make = input.make.trim();
    }

    if (input.model !== undefined) {
      if (typeof input.model !== 'string' || input.model.trim() === '') {
        throw new ValidationError('Vehicle model cannot be empty.');
      }
      updatePayload.model = input.model.trim();
    }

    if (input.variant !== undefined) {
      updatePayload.variant = input.variant ? input.variant.trim() : undefined;
    }

    if (input.registrationNumber !== undefined) {
      if (
        typeof input.registrationNumber !== 'string' ||
        input.registrationNumber.trim() === ''
      ) {
        throw new ValidationError('Registration number cannot be empty.');
      }
      const regNumber = normalizeRegistrationNumber(input.registrationNumber);
      const duplicate = await Vehicle.findOne({
        userId: existingVehicle.userId,
        registrationNumber: regNumber,
        _id: { $ne: id },
      });
      if (duplicate) {
        throw new ConflictError(
          `Vehicle with registration number '${regNumber}' already exists for this user.`,
          'VEHICLE_ALREADY_EXISTS'
        );
      }
      updatePayload.registrationNumber = regNumber;
    }

    if (input.fuelType !== undefined) {
      if (!ALLOWED_FUEL_TYPES.includes(input.fuelType as FuelType)) {
        throw new ValidationError(
          `Invalid fuel type. Allowed values are: ${ALLOWED_FUEL_TYPES.join(', ')}.`
        );
      }
      updatePayload.fuelType = input.fuelType;
    }

    if (input.year !== undefined) {
      const currentYear = new Date().getFullYear();
      const parsedYear = Number(input.year);
      if (!Number.isInteger(parsedYear) || parsedYear < 1990 || parsedYear > currentYear + 1) {
        throw new ValidationError(
          `Year must be an integer between 1990 and ${currentYear + 1}.`
        );
      }
      updatePayload.year = parsedYear;
    }

    if (input.isActive !== undefined) {
      if (input.isActive) {
        // Deactivate all others for this user first
        await Vehicle.updateMany({ userId: existingVehicle.userId }, { isActive: false });
      }
      updatePayload.isActive = Boolean(input.isActive);
    }

    const updated = await Vehicle.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    });

    return updated!;
  }

  static async setActiveVehicle(id: string, ownerUserId?: string): Promise<IVehicle> {
    validateObjectId(id, 'Vehicle ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const vehicle = await Vehicle.findOne(filter);
    if (!vehicle) {
      throw new NotFoundError(`Vehicle with ID '${id}' not found.`);
    }

    // Deactivate all other vehicles for this user
    await Vehicle.updateMany(
      { userId: vehicle.userId, _id: { $ne: vehicle._id } },
      { isActive: false }
    );

    vehicle.isActive = true;
    return await vehicle.save();
  }

  static async deleteVehicle(id: string, ownerUserId?: string): Promise<void> {
    validateObjectId(id, 'Vehicle ID');
    const filter: Record<string, unknown> = { _id: id };
    if (ownerUserId) {
      validateObjectId(ownerUserId, 'Owner User ID');
      filter.userId = ownerUserId;
    }

    const vehicle = await Vehicle.findOne(filter);
    if (!vehicle) {
      throw new NotFoundError(`Vehicle with ID '${id}' not found.`);
    }

    // Safety check: Prevent deleting vehicle with active bookings
    const activeBooking = await Booking.findOne({
      vehicleId: id,
      status: { $nin: ['completed', 'cancelled'] },
    });

    if (activeBooking) {
      throw new ConflictError(
        'Cannot delete vehicle while active service bookings are in progress.',
        'VEHICLE_HAS_ACTIVE_BOOKINGS'
      );
    }

    await Booking.deleteMany({ vehicleId: id });
    await Vehicle.findByIdAndDelete(id);

    // If the deleted vehicle was active, set the most recent vehicle of this user as active
    if (vehicle.isActive) {
      const remainingVehicle = await Vehicle.findOne({ userId: vehicle.userId }).sort({
        createdAt: -1,
      });
      if (remainingVehicle) {
        remainingVehicle.isActive = true;
        await remainingVehicle.save();
      }
    }
  }
}
