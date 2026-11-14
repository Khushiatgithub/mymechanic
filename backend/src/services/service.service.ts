import { Service, IService } from '../models/service.model';
import { ServiceCategory } from '../models/serviceCategory.model';
import { Booking } from '../models/booking.model';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors';
import { validateObjectId } from '../utils/validation.util';
import { PaginationOptions, buildPaginationMeta } from '../utils/pagination.util';
import { PaginatedData } from '../utils/response.util';

export interface CreateServiceInput {
  categoryId: string;
  title: string;
  description: string;
  price: number;
  originalPrice?: number;
  durationText?: string;
  rating?: number;
  reviewCount?: number;
  isActive?: boolean;
  warrantyPeriod?: string;
  includedItems?: string[];
  excludedItems?: string[];
}

export interface UpdateServiceInput {
  categoryId?: string;
  title?: string;
  description?: string;
  price?: number;
  originalPrice?: number;
  durationText?: string;
  rating?: number;
  reviewCount?: number;
  isActive?: boolean;
  warrantyPeriod?: string;
  includedItems?: string[];
  excludedItems?: string[];
}

export interface ServiceFilterOptions {
  categoryId?: string;
  activeOnly?: boolean;
  search?: string;
  sort?: string;
}

export class ServiceService {
  static async createService(input: CreateServiceInput): Promise<IService> {
    const categoryId = validateObjectId(input.categoryId, 'Category ID');

    // 1. Validate category exists
    const categoryExists = await ServiceCategory.exists({ _id: categoryId });
    if (!categoryExists) {
      throw new NotFoundError(`Service category with ID '${input.categoryId}' not found.`);
    }

    // 2. Validate fields
    if (!input.title || typeof input.title !== 'string' || input.title.trim() === '') {
      throw new ValidationError('Service title is required.');
    }

    if (!input.description || typeof input.description !== 'string' || input.description.trim() === '') {
      throw new ValidationError('Service description is required.');
    }

    const price = Number(input.price);
    if (isNaN(price) || price < 0) {
      throw new ValidationError('Price must be a non-negative number.');
    }

    let originalPrice: number | undefined;
    if (input.originalPrice !== undefined) {
      originalPrice = Number(input.originalPrice);
      if (isNaN(originalPrice) || originalPrice < 0) {
        throw new ValidationError('Original price must be a non-negative number.');
      }
    }

    let rating = 4.8;
    if (input.rating !== undefined) {
      rating = Number(input.rating);
      if (isNaN(rating) || rating < 0 || rating > 5) {
        throw new ValidationError('Rating must be between 0 and 5.');
      }
    }

    let reviewCount = 0;
    if (input.reviewCount !== undefined) {
      reviewCount = Number(input.reviewCount);
      if (isNaN(reviewCount) || reviewCount < 0) {
        throw new ValidationError('Review count must be a non-negative number.');
      }
    }

    const service = new Service({
      categoryId,
      title: input.title.trim(),
      description: input.description.trim(),
      price,
      originalPrice,
      durationText: input.durationText ? input.durationText.trim() : '3-4 Hours',
      rating,
      reviewCount,
      isActive: input.isActive !== undefined ? Boolean(input.isActive) : true,
      ...(input.warrantyPeriod ? { warrantyPeriod: input.warrantyPeriod.trim() } : {}),
      includedItems: Array.isArray(input.includedItems) ? input.includedItems : [],
      excludedItems: Array.isArray(input.excludedItems) ? input.excludedItems : [],
    });

    const saved = await service.save();
    return (await saved.populate('categoryId', 'name icon')) as IService;
  }

  static async getServices(
    pagination: PaginationOptions,
    filters: ServiceFilterOptions
  ): Promise<PaginatedData<IService>> {
    const query: Record<string, unknown> = {};

    if (filters.categoryId) {
      validateObjectId(filters.categoryId, 'Category ID');
      query.categoryId = filters.categoryId;
    }

    if (filters.activeOnly) {
      query.isActive = true;
    }

    if (filters.search && filters.search.trim() !== '') {
      const searchRegex = new RegExp(filters.search.trim(), 'i');
      query.$or = [{ title: searchRegex }, { description: searchRegex }];
    }

    // Determine sorting
    let sortOption: Record<string, 1 | -1> = { createdAt: -1 };
    if (filters.sort === 'price_asc') {
      sortOption = { price: 1 };
    } else if (filters.sort === 'price_desc') {
      sortOption = { price: -1 };
    } else if (filters.sort === 'rating_desc') {
      sortOption = { rating: -1, reviewCount: -1 };
    }

    const total = await Service.countDocuments(query);
    const items = await Service.find(query)
      .populate('categoryId', 'name icon')
      .sort(sortOption)
      .skip(pagination.skip)
      .limit(pagination.limit);

    return {
      items,
      pagination: buildPaginationMeta(total, pagination.page, pagination.limit),
    };
  }

  static async getServiceById(id: string): Promise<IService> {
    validateObjectId(id, 'Service ID');
    const service = await Service.findById(id).populate('categoryId', 'name icon description');
    if (!service) {
      throw new NotFoundError(`Service with ID '${id}' not found.`);
    }
    return service;
  }

  static async updateService(id: string, input: UpdateServiceInput): Promise<IService> {
    validateObjectId(id, 'Service ID');
    const existingService = await Service.findById(id);
    if (!existingService) {
      throw new NotFoundError(`Service with ID '${id}' not found.`);
    }

    const updatePayload: Record<string, unknown> = {};

    if (input.categoryId !== undefined) {
      validateObjectId(input.categoryId, 'Category ID');
      const catExists = await ServiceCategory.exists({ _id: input.categoryId });
      if (!catExists) {
        throw new NotFoundError(`Service category with ID '${input.categoryId}' not found.`);
      }
      updatePayload.categoryId = input.categoryId;
    }

    if (input.title !== undefined) {
      if (typeof input.title !== 'string' || input.title.trim() === '') {
        throw new ValidationError('Service title cannot be empty.');
      }
      updatePayload.title = input.title.trim();
    }

    if (input.description !== undefined) {
      if (typeof input.description !== 'string' || input.description.trim() === '') {
        throw new ValidationError('Service description cannot be empty.');
      }
      updatePayload.description = input.description.trim();
    }

    if (input.price !== undefined) {
      const price = Number(input.price);
      if (isNaN(price) || price < 0) {
        throw new ValidationError('Price must be a non-negative number.');
      }
      updatePayload.price = price;
    }

    if (input.originalPrice !== undefined) {
      const orig = Number(input.originalPrice);
      if (isNaN(orig) || orig < 0) {
        throw new ValidationError('Original price must be a non-negative number.');
      }
      updatePayload.originalPrice = orig;
    }

    if (input.durationText !== undefined) {
      updatePayload.durationText = input.durationText.trim();
    }

    if (input.rating !== undefined) {
      const rating = Number(input.rating);
      if (isNaN(rating) || rating < 0 || rating > 5) {
        throw new ValidationError('Rating must be between 0 and 5.');
      }
      updatePayload.rating = rating;
    }

    if (input.reviewCount !== undefined) {
      const rc = Number(input.reviewCount);
      if (isNaN(rc) || rc < 0) {
        throw new ValidationError('Review count must be a non-negative number.');
      }
      updatePayload.reviewCount = rc;
    }

    if (input.isActive !== undefined) {
      updatePayload.isActive = Boolean(input.isActive);
    }

    if (input.warrantyPeriod !== undefined) {
      updatePayload.warrantyPeriod = input.warrantyPeriod ? input.warrantyPeriod.trim() : undefined;
    }

    if (input.includedItems !== undefined) {
      updatePayload.includedItems = Array.isArray(input.includedItems) ? input.includedItems : [];
    }

    if (input.excludedItems !== undefined) {
      updatePayload.excludedItems = Array.isArray(input.excludedItems) ? input.excludedItems : [];
    }

    const updated = await Service.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    }).populate('categoryId', 'name icon');

    return updated!;
  }

  static async deleteService(id: string): Promise<void> {
    validateObjectId(id, 'Service ID');
    const service = await Service.findById(id);
    if (!service) {
      throw new NotFoundError(`Service with ID '${id}' not found.`);
    }

    const activeBooking = await Booking.findOne({
      serviceId: id,
      status: { $nin: ['completed', 'cancelled'] },
    });

    if (activeBooking) {
      throw new ConflictError(
        'Cannot delete service while active bookings are in progress.',
        'SERVICE_HAS_ACTIVE_BOOKINGS'
      );
    }

    await Service.findByIdAndDelete(id);
  }
}
