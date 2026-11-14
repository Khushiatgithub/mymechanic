import { User, IUser } from '../models/user.model';
import { RefreshSession } from '../models/refreshSession.model';
import {
  hashPassword,
  comparePassword,
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  verifyRefreshToken,
} from '../utils/auth.util';
import { ApiError, ValidationError, ConflictError, NotFoundError } from '../utils/errors';
import { isValidEmail, isValidPhone, validateObjectId } from '../utils/validation.util';

export interface RegisterInput {
  name: string;
  email: string;
  password: string;
  phone?: string;
  profileImage?: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse {
  user: IUser;
  tokens: AuthTokens;
}

export class AuthService {
  /**
   * Register a new user with secure password hashing and initial session generation.
   */
  static async register(input: RegisterInput): Promise<AuthResponse> {
    if (!input.name || typeof input.name !== 'string' || input.name.trim() === '') {
      throw new ValidationError('Name is required.');
    }

    if (!input.email || typeof input.email !== 'string' || !isValidEmail(input.email)) {
      throw new ValidationError('A valid email address is required.');
    }

    if (!input.password || typeof input.password !== 'string' || input.password.length < 8) {
      throw new ValidationError('Password must be at least 8 characters long.');
    }

    if (input.phone && !isValidPhone(input.phone)) {
      throw new ValidationError('Please provide a valid phone number.');
    }

    const normalizedEmail = input.email.trim().toLowerCase();

    // Check duplicate email
    const existingEmail = await User.findOne({ email: normalizedEmail });
    if (existingEmail) {
      throw new ConflictError(
        'An account with this email address already exists.',
        'EMAIL_ALREADY_EXISTS'
      );
    }

    // Check duplicate phone if provided
    if (input.phone) {
      const existingPhone = await User.findOne({ phone: input.phone.trim() });
      if (existingPhone) {
        throw new ConflictError(
          'An account with this phone number already exists.',
          'PHONE_ALREADY_EXISTS'
        );
      }
    }

    const hashedPassword = await hashPassword(input.password);

    const user = new User({
      name: input.name.trim(),
      email: normalizedEmail,
      passwordHash: hashedPassword,
      isActive: true,
      ...(input.phone ? { phone: input.phone.trim() } : {}),
      ...(input.profileImage ? { profileImage: input.profileImage.trim() } : {}),
    });

    const savedUser = await user.save();

    // Generate tokens
    const accessToken = generateAccessToken(savedUser._id.toString());
    const { token: refreshToken, tokenHash, expiresAt } = generateRefreshToken(
      savedUser._id.toString()
    );

    await RefreshSession.create({
      userId: savedUser._id,
      tokenHash,
      expiresAt,
    });

    return {
      user: savedUser.toJSON() as IUser,
      tokens: {
        accessToken,
        refreshToken,
      },
    };
  }

  /**
   * Authenticate user with email and password.
   */
  static async login(input: LoginInput): Promise<AuthResponse> {
    if (!input.email || !input.password) {
      throw new ApiError('Email and password are required.', 400, 'BAD_REQUEST');
    }

    const normalizedEmail = input.email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail }).select(
      '+passwordHash +isActive'
    );

    // Generic error message for security — never leak whether email or password was wrong
    if (!user || !user.passwordHash) {
      throw new ApiError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }

    const isPasswordValid = await comparePassword(input.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new ApiError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }

    if (!user.isActive) {
      throw new ApiError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }

    // Update last login timestamp
    user.lastLoginAt = new Date();
    await user.save();

    // Issue tokens
    const accessToken = generateAccessToken(user._id.toString());
    const { token: refreshToken, tokenHash, expiresAt } = generateRefreshToken(
      user._id.toString()
    );

    await RefreshSession.create({
      userId: user._id,
      tokenHash,
      expiresAt,
    });

    return {
      user: user.toJSON() as IUser,
      tokens: {
        accessToken,
        refreshToken,
      },
    };
  }

  /**
   * Refresh session with token rotation and reuse detection.
   */
  static async refreshTokens(presentedToken: string): Promise<AuthTokens> {
    if (!presentedToken || typeof presentedToken !== 'string') {
      throw new ApiError('Refresh token is required.', 400, 'MISSING_REFRESH_TOKEN');
    }

    const payload = verifyRefreshToken(presentedToken);
    const tokenStorageHash = hashToken(presentedToken);

    const session = await RefreshSession.findOne({ tokenHash: tokenStorageHash });
    if (!session) {
      throw new ApiError(
        'Invalid refresh session. Please log in again.',
        401,
        'INVALID_REFRESH_TOKEN'
      );
    }

    // Security: Token Reuse Detection
    if (session.revokedAt) {
      // Invalidate all sessions for this user immediately
      await RefreshSession.updateMany(
        { userId: session.userId, revokedAt: null },
        { revokedAt: new Date() }
      );
      throw new ApiError(
        'Revoked refresh token reuse detected. All active sessions invalidated for security.',
        401,
        'TOKEN_REUSE_DETECTED'
      );
    }

    // Check expiration
    if (session.expiresAt.getTime() < Date.now()) {
      session.revokedAt = new Date();
      await session.save();
      throw new ApiError(
        'Refresh token has expired. Please log in again.',
        401,
        'REFRESH_TOKEN_EXPIRED'
      );
    }

    const user = await User.findById(payload.sub).select('+isActive');
    if (!user || !user.isActive) {
      session.revokedAt = new Date();
      await session.save();
      throw new ApiError('Account is disabled or no longer exists.', 401, 'UNAUTHORIZED');
    }

    // Rotate: Revoke current session
    session.revokedAt = new Date();
    await session.save();

    // Generate new tokens
    const newAccessToken = generateAccessToken(user._id.toString());
    const { token: newRefreshToken, tokenHash: newHash, expiresAt } = generateRefreshToken(
      user._id.toString()
    );

    await RefreshSession.create({
      userId: user._id,
      tokenHash: newHash,
      expiresAt,
    });

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    };
  }

  /**
   * Logout user by revoking refresh sessions.
   */
  static async logout(userId: string, presentedToken?: string): Promise<void> {
    validateObjectId(userId, 'User ID');

    if (presentedToken) {
      const tokenStorageHash = hashToken(presentedToken);
      await RefreshSession.findOneAndUpdate(
        { tokenHash: tokenStorageHash },
        { revokedAt: new Date() }
      );
    } else {
      // Revoke all active sessions for this user
      await RefreshSession.updateMany(
        { userId, revokedAt: null },
        { revokedAt: new Date() }
      );
    }
  }

  /**
   * Retrieve current authenticated user profile.
   */
  static async getMe(userId: string): Promise<IUser> {
    validateObjectId(userId, 'User ID');
    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError(`User with ID '${userId}' not found.`);
    }
    return user;
  }

  /**
   * Change user password and revoke existing refresh sessions.
   */
  static async changePassword(
    userId: string,
    currentPass: string,
    newPass: string
  ): Promise<void> {
    validateObjectId(userId, 'User ID');

    if (!currentPass || typeof currentPass !== 'string') {
      throw new ValidationError('Current password is required.');
    }

    if (!newPass || typeof newPass !== 'string' || newPass.length < 8) {
      throw new ValidationError('New password must be at least 8 characters long.');
    }

    const user = await User.findById(userId).select('+passwordHash');
    if (!user || !user.passwordHash) {
      throw new NotFoundError('User not found.');
    }

    const isMatch = await comparePassword(currentPass, user.passwordHash);
    if (!isMatch) {
      throw new ApiError('Current password is incorrect.', 400, 'INCORRECT_PASSWORD');
    }

    user.passwordHash = await hashPassword(newPass);
    await user.save();

    // Revoke all existing sessions so old tokens cannot be used
    await RefreshSession.updateMany(
      { userId, revokedAt: null },
      { revokedAt: new Date() }
    );
  }
}
