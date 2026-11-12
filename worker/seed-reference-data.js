const https = require('https');

async function request(url, options = {}, body = null) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request({
      hostname: u.hostname,
      port: 443,
      path: u.pathname + u.search,
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {})
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function seed() {
  const BASE_URL = 'https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev';

  console.log('1. Log in or create Counselor: Ibu Siti Aminah, S.Pd...');
  const counselorRes = await request(`${BASE_URL}/api/auth/google`, { method: 'POST' }, {
    google_uid: 'google_counselor_siti_aminah',
    email: 'siti.aminah@smkn1gombong.sch.id',
    name: 'Ibu Siti Aminah, S.Pd',
  });
  const cToken = counselorRes.data?.data?.token;
  console.log('Counselor token obtained.');

  let school = counselorRes.data?.data?.school;
  if (!school) {
    console.log('Creating SMK Negeri 1 Gombong...');
    const schoolRes = await request(`${BASE_URL}/api/schools`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${cToken}` }
    }, {
      school_name: 'SMK Negeri 1 Gombong',
      counselor_name: 'Ibu Siti Aminah, S.Pd',
      nip: '197903152005012003',
      phone: '081234567890'
    });
    school = schoolRes.data?.data?.school;
    console.log('School created:', school?.name, 'Code:', school?.school_code);
  } else {
    console.log('School exists:', school?.name, 'Code:', school?.school_code);
  }

  // Create Class XI RPL 1 if not exists
  const classesRes = await request(`${BASE_URL}/api/classes`, {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${cToken}`, 'X-School-Id': school.id }
  });
  let classList = classesRes.data?.data || [];
  let targetClass = classList.find(c => c.name.includes('XI RPL 1'));
  if (!targetClass) {
    console.log('Creating class: XI RPL 1...');
    const createClassRes = await request(`${BASE_URL}/api/classes`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${cToken}`, 'X-School-Id': school.id }
    }, {
      name: 'Kelas XI RPL 1',
      grade: 'XI',
      description: 'Rekayasa Perangkat Lunak 1'
    });
    targetClass = createClassRes.data?.data;
    console.log('Class created:', targetClass?.name, 'Join code:', targetClass?.join_code);
  } else {
    console.log('Class XI RPL 1 exists, join code:', targetClass.join_code);
  }

  // Student: Ahmad Rizky Pratama
  console.log('\n2. Log in or create Student: Ahmad Rizky Pratama...');
  const studentRes = await request(`${BASE_URL}/api/auth/google`, { method: 'POST' }, {
    google_uid: 'google_student_ahmad_rizky',
    email: 'ahmad.rizky@smkn1gombong.sch.id',
    name: 'Ahmad Rizky Pratama',
  });
  const sToken = studentRes.data?.data?.token;
  let sMembership = studentRes.data?.data?.membership;

  if (!sMembership) {
    console.log('Enrolling Ahmad Rizky Pratama to SMK Negeri 1 Gombong...');
    const joinRes = await request(`${BASE_URL}/api/students/join`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${sToken}` }
    }, {
      school_code: school.school_code,
      class_code: targetClass.join_code,
      student_id: '0068192041',
      student_name: 'Ahmad Rizky Pratama',
      phone: '081399887766'
    });
    console.log('Student enrolled:', joinRes.status, joinRes.data?.success);
  } else {
    console.log('Student already enrolled.');
  }

  // Submit sample reports if needed
  const reportsRes = await request(`${BASE_URL}/api/reports`, {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${sToken}`, 'X-School-Id': school.id }
  });
  const reports = reportsRes.data?.data || [];
  if (reports.length === 0) {
    console.log('\n3. Creating sample reports matching reference...');
    await request(`${BASE_URL}/api/reports`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${sToken}`, 'X-School-Id': school.id }
    }, {
      type: 'bullying',
      category: 'Laporan Bullying',
      incident_date: '2026-09-20',
      incident_location: 'Koridor Sayap Barat',
      description: 'Pencegahan Perundungan Verbal di Koridor',
      reporter_type: 'victim',
      priority: 'high',
      is_anonymous: false
    });

    await request(`${BASE_URL}/api/reports`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${sToken}`, 'X-School-Id': school.id }
    }, {
      type: 'kritik_saran',
      category: 'Aspirasi & Fasilitas Siswa',
      incident_date: '2026-09-12',
      incident_location: 'Gedung Lab RPL',
      description: 'Penyediaan Loker & Tempat Sampah Daur Ulang',
      reporter_type: 'witness',
      priority: 'medium',
      is_anonymous: false
    });
    console.log('Sample reports created successfully.');
  } else {
    console.log('Existing reports found count:', reports.length);
  }

  console.log('\nSeed finished successfully!');
}

seed().catch(console.error);
