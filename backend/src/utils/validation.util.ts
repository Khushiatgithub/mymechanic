import { Types } from 'mongoose';
import { ValidationError } from './errors';

/**
 * Checks whether a value is a valid 24-character hexadecimal MongoDB ObjectId string.
 */
export function isValidObjectId(id: unknown): boolean {
  if (typeof id !== 'string') return false;
  return Types.ObjectId.isValid(id) && new Types.ObjectId(id).toString() === id;
}

/**
 * Asserts that a value is a valid MongoDB ObjectId.
 * Throws a ValidationError with code 'INVALID_ID' if malformed.
 */
export function validateObjectId(id: unknown, fieldName = 'ID'): string {
  if (!id || typeof id !== 'string' || !isValidObjectId(id)) {
    throw new ValidationError(
      `Invalid ${fieldName} format. Must be a 24-character hex string.`,
      'INVALID_ID'
    );
  }
  return id;
}

/**
 * Normalizes an Indian automotive registration number.
 * Example: 'dl 01 ab 1234' -> 'DL-01-AB-1234' or 'DL01AB1234' (uppercased, trimmed).
 */
export function normalizeRegistrationNumber(reg: string): string {
  return reg.trim().toUpperCase().replace(/\s+/g, '-');
}

/**
 * Validates standard email address format.
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim());
}

/**
 * Validates phone number (10-15 digits, optional + prefix).
 */
export function isValidPhone(phone: string): boolean {
  const phoneRegex = /^\+?[0-9]{10,15}$/;
  return phoneRegex.test(phone.trim().replace(/[-\s]/g, ''));
}

/**
 * Generates a unique booking reference matching the MyMechanic convention:
 * Format: MM-YYYY-XXXX (e.g. MM-2026-7A8B)
 */
export function generateBookingNumber(year?: number): string {
  const currentYear = year || new Date().getFullYear();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let randomPart = '';
  for (let i = 0; i < 4; i++) {
    randomPart += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `MM-${currentYear}-${randomPart}`;
}
