const https = require('https');

async function testUpload() {
  const loginData = JSON.stringify({
    google_uid: 'counselor_google_test_888',
    email: 'counselor888@sekolah.sch.id',
    name: 'Ibu Ratna Sari, S.Pd',
  });
  
  const token = await new Promise((res, rej) => {
    const req = https.request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => res(JSON.parse(d).data.token));
    });
    req.write(loginData);
    req.end();
  });

  console.log('Got auth token');

  const pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  const pngBuffer = Buffer.from(pngBase64, 'base64');
  
  const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
  let header = '--' + boundary + '\r\n';
  header += 'Content-Disposition: form-data; name="file"; filename="test_pixel.png"\r\n';
  header += 'Content-Type: image/png\r\n\r\n';
  
  const payload = Buffer.concat([
    Buffer.from(header, 'utf-8'),
    pngBuffer,
    Buffer.from('\r\n--' + boundary + '--\r\n', 'utf-8')
  ]);

  const uploadRes = await new Promise((res, rej) => {
    const req = https.request('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev/api/uploads', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'multipart/form-data; boundary=' + boundary,
        'Content-Length': payload.length
      }
    }, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => {
        try { res(JSON.parse(d)); } catch(e) { res({ raw: d }); }
      });
    });
    req.write(payload);
    req.end();
  });

  console.log('Upload result:', JSON.stringify(uploadRes));
  if (!uploadRes.success) return;

  const url = uploadRes.data.url;
  console.log('Testing GET stream from URL:', url);

  const streamRes = await new Promise((res) => {
    https.get('https://suara-siswa-backend.wahyuhidayat-wyh.workers.dev' + url, r => {
      let len = 0;
      r.on('data', chunk => len += chunk.length);
      r.on('end', () => res({ status: r.statusCode, headers: r.headers, bytesReceived: len }));
    });
  });

  console.log('Stream result status:', streamRes.status, 'Content-Type:', streamRes.headers['content-type'], 'Bytes:', streamRes.bytesReceived);
}

testUpload();
