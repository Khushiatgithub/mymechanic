import { Workshop, IWorkshop } from '../models/workshop.model';
import { NotFoundError } from '../utils/errors';

export class WorkshopService {
  /**
   * Retrieves all active workshops, optionally filtered by city or area.
   */
  async getWorkshops(filter: { city?: string; area?: string } = {}): Promise<IWorkshop[]> {
    const query: Record<string, unknown> = {
      isActive: true,
      city: { $ne: 'Bengaluru' },
      isDemoSeedData: { $ne: true },
    };

    if (filter.city) {
      query.city = { $regex: new RegExp(`^${filter.city.trim()}$`, 'i') };
    }
    if (filter.area) {
      query.area = { $regex: new RegExp(`^${filter.area.trim()}$`, 'i') };
    }

    return Workshop.find(query).sort({ rating: -1, name: 1 });
  }

  /**
   * Retrieves a workshop by ID.
   */
  async getWorkshopById(id: string): Promise<IWorkshop> {
    const workshop = await Workshop.findOne({
      _id: id,
      isActive: true,
      city: { $ne: 'Bengaluru' },
      isDemoSeedData: { $ne: true },
    });
    if (!workshop) {
      throw new NotFoundError('Workshop not found or is currently inactive.');
    }
    return workshop;
  }
}

export const workshopService = new WorkshopService();
