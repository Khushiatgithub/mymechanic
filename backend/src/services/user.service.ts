import { User, IUser } from '../models/user.model';
import { Vehicle } from '../models/vehicle.model';
import { Booking } from '../models/booking.model';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors';
import { validateObjectId, isValidEmail, isValidPhone } from '../utils/validation.util';
import { PaginationOptions, buildPaginationMeta } from '../utils/pagination.util';
import { PaginatedData } from '../utils/response.util';

export interface CreateUserInput {
  name: string;
  email?: string;
  phone: string;
  profileImage?: string;
}

export interface UpdateUserInput {
  name?: string;
  email?: string;
  phone?: string;
  profileImage?: string;
}

export class UserService {
  static async createUser(input: CreateUserInput): Promise<IUser> {
    if (!input.name || typeof input.name !== 'string' || input.name.trim() === '') {
      throw new ValidationError('User name is required and cannot be empty.');
    }

    if (!input.phone || typeof input.phone !== 'string' || !isValidPhone(input.phone)) {
      throw new ValidationError('A valid phone number is required.');
    }

    if (input.email !== undefined && input.email !== null && input.email !== '') {
      if (!isValidEmail(input.email)) {
        throw new ValidationError('Please provide a valid email address.');
      }
    }

    // Check existing phone
    const existingPhone = await User.findOne({ phone: input.phone.trim() });
    if (existingPhone) {
      throw new ConflictError(
        'A user with this phone number already exists.',
        'PHONE_ALREADY_EXISTS'
      );
    }

    if (input.email) {
      const existingEmail = await User.findOne({ email: input.email.trim().toLowerCase() });
      if (existingEmail) {
        throw new ConflictError(
          'A user with this email already exists.',
          'EMAIL_ALREADY_EXISTS'
        );
      }
    }

    const user = new User({
      name: input.name.trim(),
      phone: input.phone.trim(),
      ...(input.email ? { email: input.email.trim().toLowerCase() } : {}),
      ...(input.profileImage ? { profileImage: input.profileImage.trim() } : {}),
    });

    return await user.save();
  }

  static async getUsers(pagination: PaginationOptions): Promise<PaginatedData<IUser>> {
    const total = await User.countDocuments();
    const items = await User.find()
      .sort({ createdAt: -1 })
      .skip(pagination.skip)
      .limit(pagination.limit);

    return {
      items,
      pagination: buildPaginationMeta(total, pagination.page, pagination.limit),
    };
  }

  static async getUserById(id: string): Promise<IUser> {
    validateObjectId(id, 'User ID');
    const user = await User.findById(id);
    if (!user) {
      throw new NotFoundError(`User with ID '${id}' not found.`);
    }
    return user;
  }

  static async updateUser(id: string, input: UpdateUserInput): Promise<IUser> {
    validateObjectId(id, 'User ID');

    if (input.name !== undefined) {
      if (typeof input.name !== 'string' || input.name.trim() === '') {
        throw new ValidationError('User name cannot be empty.');
      }
    }

    if (input.email !== undefined && input.email !== '') {
      if (!isValidEmail(input.email)) {
        throw new ValidationError('Please provide a valid email address.');
      }
      const existingEmail = await User.findOne({
        email: input.email.trim().toLowerCase(),
        _id: { $ne: id },
      });
      if (existingEmail) {
        throw new ConflictError('Email is already taken by another account.', 'EMAIL_ALREADY_EXISTS');
      }
    }

    if (input.phone !== undefined) {
      if (!isValidPhone(input.phone)) {
        throw new ValidationError('Please provide a valid phone number.');
      }
      const existingPhone = await User.findOne({
        phone: input.phone.trim(),
        _id: { $ne: id },
      });
      if (existingPhone) {
        throw new ConflictError('Phone number is already taken by another account.', 'PHONE_ALREADY_EXISTS');
      }
    }

    const updatePayload: Record<string, unknown> = {};
    if (input.name !== undefined) updatePayload.name = input.name.trim();
    if (input.phone !== undefined) updatePayload.phone = input.phone.trim();
    if (input.email !== undefined) updatePayload.email = input.email ? input.email.trim().toLowerCase() : undefined;
    if (input.profileImage !== undefined) updatePayload.profileImage = input.profileImage.trim();

    const updatedUser = await User.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    });

    if (!updatedUser) {
      throw new NotFoundError(`User with ID '${id}' not found.`);
    }

    return updatedUser;
  }

  static async deleteUser(id: string): Promise<void> {
    validateObjectId(id, 'User ID');
    const user = await User.findById(id);
    if (!user) {
      throw new NotFoundError(`User with ID '${id}' not found.`);
    }

    // Safety check: Prevent deleting user if active bookings exist
    const activeBooking = await Booking.findOne({
      userId: id,
      status: { $nin: ['completed', 'cancelled'] },
    });

    if (activeBooking) {
      throw new ConflictError(
        'Cannot delete user while active service bookings are in progress.',
        'USER_HAS_ACTIVE_BOOKINGS'
      );
    }

    // Safely remove associated vehicles and completed/cancelled bookings
    await Booking.deleteMany({ userId: id });
    await Vehicle.deleteMany({ userId: id });
    await User.findByIdAndDelete(id);
  }
}
