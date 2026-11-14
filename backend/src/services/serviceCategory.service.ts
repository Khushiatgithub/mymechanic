import { ServiceCategory, IServiceCategory } from '../models/serviceCategory.model';
import { Service } from '../models/service.model';
import { NotFoundError, ValidationError, ConflictError } from '../utils/errors';
import { validateObjectId } from '../utils/validation.util';
import { PaginationOptions, buildPaginationMeta } from '../utils/pagination.util';
import { PaginatedData } from '../utils/response.util';

export interface CreateServiceCategoryInput {
  name: string;
  description?: string;
  icon?: string;
  isActive?: boolean;
  sortOrder?: number;
}

export interface UpdateServiceCategoryInput {
  name?: string;
  description?: string;
  icon?: string;
  isActive?: boolean;
  sortOrder?: number;
}

export class ServiceCategoryService {
  static async createCategory(input: CreateServiceCategoryInput): Promise<IServiceCategory> {
    if (!input.name || typeof input.name !== 'string' || input.name.trim() === '') {
      throw new ValidationError('Category name is required.');
    }

    const trimmedName = input.name.trim();
    const existing = await ServiceCategory.findOne({
      name: { $regex: new RegExp(`^${trimmedName}$`, 'i') },
    });
    if (existing) {
      throw new ConflictError(
        `Category with name '${trimmedName}' already exists.`,
        'CATEGORY_ALREADY_EXISTS'
      );
    }

    const category = new ServiceCategory({
      name: trimmedName,
      ...(input.description ? { description: input.description.trim() } : {}),
      ...(input.icon ? { icon: input.icon.trim() } : {}),
      isActive: input.isActive !== undefined ? Boolean(input.isActive) : true,
      sortOrder: input.sortOrder !== undefined ? Number(input.sortOrder) : 0,
    });

    return await category.save();
  }

  static async getCategories(
    pagination: PaginationOptions,
    activeOnly?: boolean
  ): Promise<PaginatedData<IServiceCategory>> {
    const filter: Record<string, unknown> = {};
    if (activeOnly) {
      filter.isActive = true;
    }

    const total = await ServiceCategory.countDocuments(filter);
    const items = await ServiceCategory.find(filter)
      .sort({ sortOrder: 1, name: 1 })
      .skip(pagination.skip)
      .limit(pagination.limit);

    return {
      items,
      pagination: buildPaginationMeta(total, pagination.page, pagination.limit),
    };
  }

  static async getCategoryById(id: string): Promise<IServiceCategory> {
    validateObjectId(id, 'Category ID');
    const category = await ServiceCategory.findById(id);
    if (!category) {
      throw new NotFoundError(`Service category with ID '${id}' not found.`);
    }
    return category;
  }

  static async updateCategory(
    id: string,
    input: UpdateServiceCategoryInput
  ): Promise<IServiceCategory> {
    validateObjectId(id, 'Category ID');
    const category = await ServiceCategory.findById(id);
    if (!category) {
      throw new NotFoundError(`Service category with ID '${id}' not found.`);
    }

    const updatePayload: Record<string, unknown> = {};

    if (input.name !== undefined) {
      if (typeof input.name !== 'string' || input.name.trim() === '') {
        throw new ValidationError('Category name cannot be empty.');
      }
      const trimmedName = input.name.trim();
      const duplicate = await ServiceCategory.findOne({
        name: { $regex: new RegExp(`^${trimmedName}$`, 'i') },
        _id: { $ne: id },
      });
      if (duplicate) {
        throw new ConflictError(
          `Category with name '${trimmedName}' already exists.`,
          'CATEGORY_ALREADY_EXISTS'
        );
      }
      updatePayload.name = trimmedName;
    }

    if (input.description !== undefined) {
      updatePayload.description = input.description ? input.description.trim() : undefined;
    }

    if (input.icon !== undefined) {
      updatePayload.icon = input.icon ? input.icon.trim() : undefined;
    }

    if (input.isActive !== undefined) {
      updatePayload.isActive = Boolean(input.isActive);
    }

    if (input.sortOrder !== undefined) {
      updatePayload.sortOrder = Number(input.sortOrder);
    }

    const updated = await ServiceCategory.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
    });

    return updated!;
  }

  static async deleteCategory(id: string): Promise<void> {
    validateObjectId(id, 'Category ID');
    const category = await ServiceCategory.findById(id);
    if (!category) {
      throw new NotFoundError(`Service category with ID '${id}' not found.`);
    }

    // Check if services exist under this category
    const servicesCount = await Service.countDocuments({ categoryId: id });
    if (servicesCount > 0) {
      throw new ConflictError(
        'Cannot delete category with existing services',
        'CATEGORY_IN_USE'
      );
    }

    await ServiceCategory.findByIdAndDelete(id);
  }
}
