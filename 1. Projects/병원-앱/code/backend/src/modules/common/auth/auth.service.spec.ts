import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { User, UserRole } from './entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;
  let mockUserRepository: any;
  let mockJwtService: any;
  let mockConfigService: any;
  let mockBcrypt: any;

  const mockUser: User = {
    id: 'test-id-123',
    email: 'test@example.com',
    passwordHash: 'hashed-password',
    name: 'Test User',
    phone: '010-1234-5678',
    role: UserRole.PATIENT,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    mockBcrypt = require('bcrypt');
    mockBcrypt.hash = jest.fn();
    mockBcrypt.compare = jest.fn();

    mockUserRepository = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    mockJwtService = {
      sign: jest.fn(),
      verify: jest.fn(),
    };

    mockConfigService = {
      get: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: getRepositoryToken(User),
          useValue: mockUserRepository,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('should register a new user successfully with all fields', async () => {
      const registerDto: RegisterDto = {
        email: 'newuser@example.com',
        password: 'SecurePassword123!',
        name: 'New User',
        phone: '010-9876-5432',
      };

      mockUserRepository.findOne.mockResolvedValue(null);
      mockUserRepository.create.mockReturnValue({
        ...mockUser,
        email: registerDto.email,
        name: registerDto.name,
        phone: registerDto.phone,
      });
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        email: registerDto.email,
        name: registerDto.name,
        phone: registerDto.phone,
      });
      mockJwtService.sign.mockReturnValue('mock-token');
      mockConfigService.get.mockReturnValue('15m');

      const result = await service.register(registerDto);

      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email: registerDto.email },
      });
      expect(mockUserRepository.create).toHaveBeenCalled();
      expect(mockUserRepository.save).toHaveBeenCalled();
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe(registerDto.email);
    });

    it('should register a user without phone number', async () => {
      const registerDto: RegisterDto = {
        email: 'nophone@example.com',
        password: 'SecurePassword123!',
        name: 'No Phone User',
      };

      mockUserRepository.findOne.mockResolvedValue(null);
      mockUserRepository.create.mockReturnValue({
        ...mockUser,
        email: registerDto.email,
        phone: null,
      });
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        email: registerDto.email,
        phone: null,
      });
      mockJwtService.sign.mockReturnValue('mock-token');
      mockConfigService.get.mockReturnValue('15m');

      const result = await service.register(registerDto);

      expect(mockUserRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: registerDto.email,
          name: registerDto.name,
          phone: null,
        }),
      );
      expect(result.user.email).toBe(registerDto.email);
    });

    it('should throw ConflictException when email already exists', async () => {
      const registerDto: RegisterDto = {
        email: 'existing@example.com',
        password: 'SecurePassword123!',
        name: 'Existing User',
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);

      await expect(service.register(registerDto)).rejects.toThrow(
        ConflictException,
      );
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email: registerDto.email },
      });
      expect(mockUserRepository.create).not.toHaveBeenCalled();
    });

    it('should hash password before saving', async () => {
      const registerDto: RegisterDto = {
        email: 'hash@example.com',
        password: 'PlainPassword123!',
        name: 'Hash Test',
      };

      mockUserRepository.findOne.mockResolvedValue(null);
      mockBcrypt.hash.mockResolvedValue('bcrypt-hashed-value');
      mockUserRepository.create.mockReturnValue({
        ...mockUser,
        passwordHash: 'bcrypt-hashed-value',
      });
      mockUserRepository.save.mockResolvedValue({
        ...mockUser,
        passwordHash: 'bcrypt-hashed-value',
      });
      mockJwtService.sign.mockReturnValue('mock-token');
      mockConfigService.get.mockReturnValue('15m');

      await service.register(registerDto);

      expect(mockBcrypt.hash).toHaveBeenCalledWith(
        registerDto.password,
        expect.any(Number),
      );
    });
  });

  describe('login', () => {
    it('should login successfully with correct credentials', async () => {
      const loginDto: LoginDto = {
        email: 'test@example.com',
        password: 'CorrectPassword123!',
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockBcrypt.compare.mockResolvedValue(true);
      mockJwtService.sign.mockReturnValue('mock-token');
      mockConfigService.get.mockReturnValue('15m');

      const result = await service.login(loginDto);

      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email: loginDto.email },
      });
      expect(mockBcrypt.compare).toHaveBeenCalledWith(
        loginDto.password,
        mockUser.passwordHash,
      );
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe(mockUser.email);
    });

    it('should throw UnauthorizedException when password is incorrect', async () => {
      const loginDto: LoginDto = {
        email: 'test@example.com',
        password: 'WrongPassword123!',
      };

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockBcrypt.compare.mockResolvedValue(false);

      await expect(service.login(loginDto)).rejects.toThrow(
        UnauthorizedException,
      );
      expect(mockBcrypt.compare).toHaveBeenCalledWith(
        loginDto.password,
        mockUser.passwordHash,
      );
    });

    it('should throw UnauthorizedException when user does not exist', async () => {
      const loginDto: LoginDto = {
        email: 'nonexistent@example.com',
        password: 'Password123!',
      };

      mockUserRepository.findOne.mockResolvedValue(null);

      await expect(service.login(loginDto)).rejects.toThrow(
        UnauthorizedException,
      );
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email: loginDto.email },
      });
    });

    it('should throw UnauthorizedException when user is inactive', async () => {
      const loginDto: LoginDto = {
        email: 'test@example.com',
        password: 'CorrectPassword123!',
      };

      const inactiveUser = { ...mockUser, isActive: false };
      mockUserRepository.findOne.mockResolvedValue(inactiveUser);

      await expect(service.login(loginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('validateUser', () => {
    it('should return user when credentials are valid', async () => {
      const email = 'test@example.com';
      const password = 'CorrectPassword123!';

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockBcrypt.compare.mockResolvedValue(true);

      const result = await service.validateUser(email, password);

      expect(result).toEqual(mockUser);
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email },
      });
      expect(mockBcrypt.compare).toHaveBeenCalledWith(password, mockUser.passwordHash);
    });

    it('should return null when user does not exist', async () => {
      const email = 'nonexistent@example.com';
      const password = 'Password123!';

      mockUserRepository.findOne.mockResolvedValue(null);

      const result = await service.validateUser(email, password);

      expect(result).toBeNull();
      expect(mockUserRepository.findOne).toHaveBeenCalledWith({
        where: { email },
      });
    });

    it('should return null when password is incorrect', async () => {
      const email = 'test@example.com';
      const password = 'WrongPassword123!';

      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockBcrypt.compare.mockResolvedValue(false);

      const result = await service.validateUser(email, password);

      expect(result).toBeNull();
      expect(mockBcrypt.compare).toHaveBeenCalledWith(password, mockUser.passwordHash);
    });

    it('should return null when user is inactive', async () => {
      const email = 'test@example.com';
      const password = 'CorrectPassword123!';

      const inactiveUser = { ...mockUser, isActive: false };
      mockUserRepository.findOne.mockResolvedValue(inactiveUser);

      const result = await service.validateUser(email, password);

      expect(result).toBeNull();
    });

    it('should return user when credentials are valid and user is active', async () => {
      const email = 'test@example.com';
      const password = 'CorrectPassword123!';

      const activeUser = { ...mockUser, isActive: true };
      mockUserRepository.findOne.mockResolvedValue(activeUser);
      mockBcrypt.compare.mockResolvedValue(true);

      const result = await service.validateUser(email, password);

      expect(result).toEqual(activeUser);
      expect(result.isActive).toBe(true);
    });
  });
});
