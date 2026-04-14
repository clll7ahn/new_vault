import { createConnection, getConnection } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../../src/modules/common/auth/entities/user.entity';
import { Hospital } from '../../src/modules/common/hospital-info/entities/hospital.entity';
import { Department } from '../../src/modules/common/hospital-info/entities/department.entity';
import { Doctor } from '../../src/modules/common/hospital-info/entities/doctor.entity';
import { Appointment } from '../../src/modules/common/appointment/entities/appointment.entity';
import { ScheduleSlot } from '../../src/modules/common/appointment/entities/schedule-slot.entity';

const saltRounds = 10;

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, saltRounds);
}

async function seedDatabase() {
  let connection;

  try {
    // Create connection
    connection = await createConnection({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      username: process.env.DB_USERNAME || 'hospital',
      password: process.env.DB_PASSWORD || 'password',
      database: process.env.DB_DATABASE || 'hospital_app',
      entities: [__dirname + '/../../src/**/*.entity{.ts,.js}'],
      synchronize: true,
      logging: true,
    });

    console.log('✓ Database connection established');

    // Clear existing data
    console.log('Clearing existing data...');
    await connection.dropDatabase();
    await connection.synchronize();
    console.log('✓ Database synchronized');

    const userRepository = connection.getRepository(User);
    const hospitalRepository = connection.getRepository(Hospital);
    const departmentRepository = connection.getRepository(Department);
    const doctorRepository = connection.getRepository(Doctor);
    const appointmentRepository = connection.getRepository(Appointment);
    const scheduleSlotRepository = connection.getRepository(ScheduleSlot);

    // 1. Create Hospital
    console.log('\n[1/7] Creating hospital...');
    const hospital = hospitalRepository.create({
      name: '예시내과의원',
      address: '서울시 강남구 테헤란로 123',
      phone: '02-1234-5678',
      registrationNumber: 'REG20250414001',
      operatingHours: {
        monday: { open: '09:00', close: '18:00' },
        tuesday: { open: '09:00', close: '18:00' },
        wednesday: { open: '09:00', close: '18:00' },
        thursday: { open: '09:00', close: '18:00' },
        friday: { open: '09:00', close: '18:00' },
        saturday: { open: '09:00', close: '13:00' },
        sunday: { open: '', close: '' },
      },
      latitude: 37.4979,
      longitude: 127.0276,
    });
    const savedHospital = await hospitalRepository.save(hospital);
    console.log('✓ Hospital created:', savedHospital.name);

    // 2. Create Departments
    console.log('\n[2/7] Creating departments...');
    const departments = departmentRepository.create([
      {
        hospitalId: savedHospital.id,
        name: '내과',
        description: '일반 내과 진료',
        isActive: true,
        displayOrder: 1,
      },
      {
        hospitalId: savedHospital.id,
        name: '피부과',
        description: '피부 질환 진료',
        isActive: true,
        displayOrder: 2,
      },
      {
        hospitalId: savedHospital.id,
        name: '정형외과',
        description: '뼈 및 관절 질환 진료',
        isActive: true,
        displayOrder: 3,
      },
    ]);
    const savedDepartments = await departmentRepository.save(departments);
    console.log('✓ Departments created:', savedDepartments.map((d) => d.name).join(', '));

    // 3. Create Admin User
    console.log('\n[3/7] Creating admin user...');
    const adminPasswordHash = await hashPassword('admin123');
    const admin = userRepository.create({
      email: 'admin@hospital.com',
      passwordHash: adminPasswordHash,
      name: '관리자',
      role: UserRole.ADMIN,
      phone: '010-0000-0000',
      isActive: true,
    });
    const savedAdmin = await userRepository.save(admin);
    console.log('✓ Admin user created:', savedAdmin.email);

    // 4. Create Doctors
    console.log('\n[4/7] Creating doctors...');
    const doctorPasswordHash = await hashPassword('doctor123');
    const doctors = userRepository.create([
      {
        email: 'doctor1@hospital.com',
        passwordHash: doctorPasswordHash,
        name: '김내과',
        role: UserRole.DOCTOR,
        phone: '010-1111-1111',
        isActive: true,
      },
      {
        email: 'doctor2@hospital.com',
        passwordHash: doctorPasswordHash,
        name: '이피부',
        role: UserRole.DOCTOR,
        phone: '010-2222-2222',
        isActive: true,
      },
      {
        email: 'doctor3@hospital.com',
        passwordHash: doctorPasswordHash,
        name: '박정형',
        role: UserRole.DOCTOR,
        phone: '010-3333-3333',
        isActive: true,
      },
    ]);
    const savedDoctors = await userRepository.save(doctors);
    console.log('✓ Doctors created:', savedDoctors.map((d) => d.name).join(', '));

    // Create Doctor records linking to departments
    const doctorRecords = doctorRepository.create([
      {
        userId: savedDoctors[0].id,
        name: savedDoctors[0].name,
        departmentId: savedDepartments[0].id,
        licenseNumber: 'LIC20250001',
        licenseIssuedDate: new Date('2020-01-01'),
        yearsOfExperience: 5,
        specialty: '내과',
        bio: '내과 전문의',
        isAvailable: true,
      },
      {
        userId: savedDoctors[1].id,
        name: savedDoctors[1].name,
        departmentId: savedDepartments[1].id,
        licenseNumber: 'LIC20250002',
        licenseIssuedDate: new Date('2018-06-15'),
        yearsOfExperience: 7,
        specialty: '피부과',
        bio: '피부과 전문의',
        isAvailable: true,
      },
      {
        userId: savedDoctors[2].id,
        name: savedDoctors[2].name,
        departmentId: savedDepartments[2].id,
        licenseNumber: 'LIC20250003',
        licenseIssuedDate: new Date('2019-03-20'),
        yearsOfExperience: 6,
        specialty: '정형외과',
        bio: '정형외과 전문의',
        isAvailable: true,
      },
    ]);
    const savedDoctorRecords = await doctorRepository.save(doctorRecords);
    console.log('✓ Doctor records created');

    // 5. Create Patient Users
    console.log('\n[5/7] Creating patient users...');
    const patientPasswordHash = await hashPassword('patient123');
    const patients = userRepository.create([
      {
        email: 'patient1@test.com',
        passwordHash: patientPasswordHash,
        name: '환자1',
        role: UserRole.PATIENT,
        phone: '010-4444-4444',
        isActive: true,
      },
      {
        email: 'patient2@test.com',
        passwordHash: patientPasswordHash,
        name: '환자2',
        role: UserRole.PATIENT,
        phone: '010-5555-5555',
        isActive: true,
      },
    ]);
    const savedPatients = await userRepository.save(patients);
    console.log('✓ Patient users created:', savedPatients.map((p) => p.name).join(', '));

    // 6. Create Schedule Slots
    console.log('\n[6/7] Creating schedule slots...');
    const scheduleSlots = [];
    const startHour = 9;
    const endHour = 17;
    const slotDurationMin = 30; // minutes

    // Create schedule slots for each doctor (Monday to Friday = 1 to 5)
    for (const doctor of savedDoctorRecords) {
      for (let dayOfWeek = 1; dayOfWeek <= 5; dayOfWeek++) {
        // 1 = Monday, 5 = Friday
        for (let hour = startHour; hour < endHour; hour++) {
          for (let minute = 0; minute < 60; minute += slotDurationMin) {
            const startTimeStr = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}:00`;
            const endHour = minute + slotDurationMin >= 60 ? hour + 1 : hour;
            const endMinute = (minute + slotDurationMin) % 60;
            const endTimeStr = `${String(endHour).padStart(2, '0')}:${String(endMinute).padStart(2, '0')}:00`;

            scheduleSlots.push({
              doctorId: doctor.id,
              dayOfWeek: dayOfWeek,
              startTime: startTimeStr,
              endTime: endTimeStr,
              slotDurationMin: slotDurationMin,
              maxPatients: 1,
              isActive: true,
            });
          }
        }
      }
    }

    const savedSlots = await scheduleSlotRepository.save(scheduleSlots);
    console.log('✓ Schedule slots created:', savedSlots.length, 'slots');

    // 7. Create Sample Appointments
    console.log('\n[7/7] Creating sample appointments...');
    const appointmentStatusValues = ['pending', 'confirmed', 'cancelled', 'completed', 'no_show'];
    const appointments = appointmentRepository.create([
      {
        patientId: savedPatients[0].id,
        doctorId: savedDoctorRecords[0].id,
        departmentId: savedDepartments[0].id,
        appointmentDate: new Date(Date.now() + 86400000).toISOString().split('T')[0], // Tomorrow (YYYY-MM-DD)
        appointmentTime: '10:00:00', // HH:MM:SS
        status: 'confirmed',
        chiefComplaint: '감기 증상',
        notes: '최근 기침이 심함',
      },
      {
        patientId: savedPatients[0].id,
        doctorId: savedDoctorRecords[1].id,
        departmentId: savedDepartments[1].id,
        appointmentDate: new Date(Date.now() + 172800000).toISOString().split('T')[0], // In 2 days
        appointmentTime: '14:00:00',
        status: 'confirmed',
        chiefComplaint: '피부 발진',
        notes: '팔에 발진이 있음',
      },
      {
        patientId: savedPatients[1].id,
        doctorId: savedDoctorRecords[2].id,
        departmentId: savedDepartments[2].id,
        appointmentDate: new Date(Date.now() + 259200000).toISOString().split('T')[0], // In 3 days
        appointmentTime: '11:00:00',
        status: 'confirmed',
        chiefComplaint: '허리 통증',
        notes: '장시간 앉아서 일을 함',
      },
      {
        patientId: savedPatients[1].id,
        doctorId: savedDoctorRecords[0].id,
        departmentId: savedDepartments[0].id,
        appointmentDate: new Date(Date.now() + 345600000).toISOString().split('T')[0], // In 4 days
        appointmentTime: '15:30:00',
        status: 'pending',
        chiefComplaint: '건강검진',
        notes: '정기 건강검진',
      },
      {
        patientId: savedPatients[0].id,
        doctorId: savedDoctorRecords[2].id,
        departmentId: savedDepartments[2].id,
        appointmentDate: new Date(Date.now() + 432000000).toISOString().split('T')[0], // In 5 days
        appointmentTime: '09:00:00',
        status: 'pending',
        chiefComplaint: '무릎 통증',
        notes: '운동 중 발생한 통증',
      },
    ]);
    const savedAppointments = await appointmentRepository.save(appointments);
    console.log('✓ Sample appointments created:', savedAppointments.length, 'appointments');

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('✓ SEED DATA COMPLETED SUCCESSFULLY');
    console.log('='.repeat(50));
    console.log('\nTest Credentials:');
    console.log('━'.repeat(50));
    console.log('Admin Account:');
    console.log('  Email: admin@hospital.com');
    console.log('  Password: admin123');
    console.log('\nDoctor Accounts:');
    console.log('  Email: doctor1@hospital.com / doctor2@hospital.com / doctor3@hospital.com');
    console.log('  Password: doctor123');
    console.log('\nPatient Accounts:');
    console.log('  Email: patient1@test.com / patient2@test.com');
    console.log('  Password: patient123');
    console.log('━'.repeat(50));

    await connection.close();
    process.exit(0);
  } catch (error) {
    console.error('\n✗ SEED DATA ERROR:', error);
    if (connection && connection.isInitialized) {
      await connection.close();
    }
    process.exit(1);
  }
}

// Run the seed
seedDatabase();
