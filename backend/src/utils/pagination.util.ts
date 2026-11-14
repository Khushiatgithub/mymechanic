import { ValidationError } from './errors';
import { PaginationMeta } from './response.util';

export interface PaginationOptions {
  page: number;
  limit: number;
  skip: number;
}

export function parsePagination(query: {
  page?: unknown;
  limit?: unknown;
}): PaginationOptions {
  let page = 1;
  let limit = 20;

  if (query.page !== undefined && query.page !== '') {
    const parsedPage = Number(query.page);
    if (!Number.isInteger(parsedPage) || parsedPage < 1) {
      throw new ValidationError(
        'Invalid page query parameter. Must be an integer greater than or equal to 1.',
        'INVALID_PAGINATION'
      );
    }
    page = parsedPage;
  }

  if (query.limit !== undefined && query.limit !== '') {
    const parsedLimit = Number(query.limit);
    if (!Number.isInteger(parsedLimit) || parsedLimit < 1 || parsedLimit > 100) {
      throw new ValidationError(
        'Invalid limit query parameter. Must be an integer between 1 and 100.',
        'INVALID_PAGINATION'
      );
    }
    limit = parsedLimit;
  }

  return {
    page,
    limit,
    skip: (page - 1) * limit,
  };
}

export function buildPaginationMeta(
  total: number,
  page: number,
  limit: number
): PaginationMeta {
  const totalPages = Math.ceil(total / limit) || (total === 0 ? 0 : 1);
  return {
    page,
    limit,
    total,
    totalPages,
  };
}
