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

async function run() {
  console.log('1. Logging in as Counselor...');
  const loginRes = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/auth/google', {
    method: 'POST'
  }, {
    google_uid: 'counselor_google_test_888',
    email: 'counselor888@sekolah.sch.id',
    name: 'Ibu Ratna Sari, S.Pd',
  });
  console.log('Login result:', loginRes.status, loginRes.data?.success);
  const token = loginRes.data?.data?.token;
  if (!token) {
    console.error('No token received');
    return;
  }

  // 2. Check if user has school
  let school = loginRes.data?.data?.school;
  if (!school) {
    console.log('2. Creating School...');
    const schoolRes = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/schools', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }, {
      school_name: 'SMA Negeri 1 Prestasi',
      counselor_name: 'Ibu Ratna Sari, S.Pd',
      nip: '198501012010012001',
      phone: '081234567899'
    });
    console.log('School create result:', schoolRes.status, schoolRes.data?.success);
    school = schoolRes.data?.data?.school;
  }
  console.log('Active school:', school?.name, 'ID:', school?.id);

  // 3. Try adding class WITH and WITHOUT X-School-Id header
  console.log('\n3. Testing Add Class WITHOUT X-School-Id (relying on DB fallback)...');
  const classRes1 = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/classes', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  }, {
    name: 'X MIPA 1',
    grade: 'X',
    description: 'Kelas Unggulan Sains'
  });
  console.log('Add class without header:', classRes1.status, JSON.stringify(classRes1.data));

  console.log('\n4. Testing Add Class WITH X-School-Id header...');
  const classRes2 = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/classes', {
    method: 'POST',
    headers: { 
      'Authorization': `Bearer ${token}`,
      'X-School-Id': school?.id
    }
  }, {
    name: 'XI IPS 2',
    grade: 'XI',
    description: 'Kelas Peminatan Sosial'
  });
  console.log('Add class with header:', classRes2.status, JSON.stringify(classRes2.data));

  // 5. List classes
  console.log('\n5. Listing classes...');
  const listRes = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/classes', {
    method: 'GET',
    headers: { 
      'Authorization': `Bearer ${token}`,
      'X-School-Id': school?.id
    }
  });
  console.log('List classes:', listRes.status, 'Total found:', listRes.data?.data?.length);

  // 6. Test Student Flow: Join school using school_code and class_code!
  if (listRes.data?.data?.length > 0) {
    const targetClass = listRes.data.data[0];
    console.log('\n6. Testing Student Join with code:', school.school_code, targetClass.join_code);
    
    // Login student
    const studentLogin = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/auth/google', {
      method: 'POST'
    }, {
      google_uid: 'student_google_test_999',
      email: 'student999@sekolah.sch.id',
      name: 'Aditya Pratama',
    });
    const sToken = studentLogin.data?.data?.token;

    const joinRes = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/students/join', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${sToken}` }
    }, {
      school_code: school.school_code,
      class_code: targetClass.join_code,
      student_id: 'NIS10023',
      student_name: 'Aditya Pratama',
      phone: '085700011122'
    });
    console.log('Student join result:', joinRes.status, JSON.stringify(joinRes.data));

    // 7. Test Student creating a report
    console.log('\n7. Student submitting report...');
    const reportRes = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/reports', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sToken}`,
        'X-School-Id': school.id
      }
    }, {
      type: 'bullying',
      category: 'Perundungan Fisik / Verbal',
      incident_date: '2026-09-24',
      incident_location: 'Kantin Belakang',
      description: 'Ada pemalakan uang saku saat jam istirahat pertama.',
      reporter_type: 'victim',
      priority: 'high',
      is_anonymous: false
    });
    console.log('Report creation result:', reportRes.status, JSON.stringify(reportRes.data));

    // 8. Counselor reading the report
    console.log('\n8. Counselor fetching reports list...');
    const reportsList = await request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/reports', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-School-Id': school.id
      }
    });
    console.log('Counselor reports count:', reportsList.data?.data?.length);
  }
}

run().catch(console.error);
