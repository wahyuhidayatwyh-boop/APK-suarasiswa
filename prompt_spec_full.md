<USER_REQUEST>
# MASTER PROMPT FINAL

# SUARASISWA

## SaaS Mobile App untuk Siswa & Guru BK

### Flutter Android + Google Login + Cloudflare Workers + D1 + R2 + Firebase FCM

---

# 1. PERAN ANDA

Kamu adalah:

* Senior Flutter Developer
* Mobile UI/UX Designer
* Backend Engineer
* Cloudflare Developer
* Database Architect
* Security Engineer
* SaaS Architect

Bangun aplikasi Android production-ready bernama:

# SUARASISWA

Tagline:

**"Berani bersuara, bersama mencari solusi."**

SuaraSiswa adalah aplikasi SaaS mobile yang digunakan banyak sekolah.

Aplikasi memungkinkan:

### Siswa

* Bergabung ke ruang sekolah
* Login menggunakan Google
* Menyampaikan laporan bullying
* Mengirim kritik & saran
* Mengirim aspirasi
* Mengirim bukti
* Melihat status laporan
* Chat privat dengan Guru BK
* Menerima notifikasi
* Membaca materi edukasi

### Guru BK

* Login menggunakan Google
* Membuat ruang sekolah
* Mengatur profil sekolah
* Membuat kelas
* Mengelola siswa
* Membuat kode bergabung
* Mengundang Guru BK lain
* Melihat laporan
* Mengelola laporan
* Chat dengan siswa
* Mengelola konten edukasi
* Mengelola poster
* Mengelola banner
* Mengelola pengumuman
* Mengirim/mengelola notifikasi

---

# 2. KONSEP UTAMA: SELF-SERVICE SAAS

PENTING:

Developer/pemilik aplikasi TIDAK boleh harus membuat sekolah satu per satu secara manual.

Setelah aplikasi dirilis, Guru BK harus dapat melakukan onboarding sendiri.

Model:

```text
Satu APK
    ↓
Banyak Sekolah
    ↓
Setiap sekolah memiliki ruang sendiri
    ↓
Guru BK membuat dan mengelola ruang sekolah
    ↓
Siswa bergabung menggunakan kode
```

Contoh:

```text
                 SUARASISWA
                     │
        ┌────────────┼────────────┐
        │            │            │
     Sekolah A    Sekolah B    Sekolah C
      SCH001       SCH002       SCH003
        │            │            │
      Guru BK      Guru BK      Guru BK
        │            │            │
      Kelas        Kelas        Kelas
        │            │            │
      Siswa        Siswa        Siswa
```

Tidak membuat aplikasi berbeda untuk setiap sekolah.

Tidak membuat backend berbeda untuk setiap sekolah.

Tidak membuat APK berbeda untuk setiap sekolah.

---

# 3. ROLE

Hanya ada 2 role utama:

```text
STUDENT
COUNSELOR
```

JANGAN membuat:

```text
ADMIN
SUPER ADMIN
SCHOOL ADMIN
```

di dalam aplikasi mobile.

Namun sistem backend boleh memiliki mekanisme internal/deployment untuk maintenance platform. Itu bukan role yang ditampilkan kepada pengguna.

---

# 4. ARSITEKTUR SAAS

Gunakan:

```text
Flutter APK
      │
      │ HTTPS
      ▼
Cloudflare Workers
      │
 ┌────┼───────────────┐
 ▼    ▼               ▼
D1   R2              FCM
DB   Storage         Push
```

Komponen:

### Frontend

Flutter Android

### API

Cloudflare Workers

### Backend framework

Hono + TypeScript

### Database

Cloudflare D1

### File storage

Cloudflare R2

### Push notification

Firebase Cloud Messaging

---

# 5. TIDAK ADA WEBSITE

Project ini:

**100% fokus APK Android.**

JANGAN membuat:

* Website
* Landing page
* Web dashboard
* Admin dashboard
* Web portal sekolah

Guru BK melakukan semuanya melalui APK.

Cloudflare Workers hanya menjadi backend/API.

Contoh API:

```text
https://api-suarasiswa.workers.dev
```

Custom domain TIDAK wajib untuk MVP.

---

# 6. FREE-FIRST

Target awal:

**MVP dengan biaya server seminimal mungkin.**

Gunakan free tier yang tersedia dari layanan terkait.

Jangan menganggap layanan gratis tidak terbatas.

Arsitektur harus mudah di-upgrade jika:

* jumlah sekolah meningkat
* jumlah siswa meningkat
* laporan meningkat
* upload video meningkat

Jangan menggunakan:

* VPS
* server dedicated
* Kubernetes
* Redis
* Kafka
* PostgreSQL
* Firebase Firestore sebagai database utama
* Supabase sebagai database utama

Untuk MVP gunakan:

```text
Flutter
Cloudflare Workers
Cloudflare D1
Cloudflare R2
Firebase FCM
```

---

# 7. ANDROID SDK

Android SDK sudah berada di:

```text
E:\Aplikasi Android\Android\Sdk
```

Gunakan SDK tersebut.

Validasi:

```powershell
flutter config --android-sdk "E:\Aplikasi Android\Android\Sdk"
flutter doctor -v
```

JANGAN membuat Android SDK kedua.

JANGAN memindahkan kembali SDK ke C:.

---

# 8. GOOGLE LOGIN

Google Login adalah salah satu metode autentikasi utama.

User dapat:

```text
Login dengan Google
```

atau jika diperlukan:

```text
Email + Password
```

Namun Google Login harus menjadi metode utama dan UX utama.

---

# 9. GOOGLE ACCOUNT BUKAN IDENTITAS SEKOLAH

JANGAN menentukan sekolah berdasarkan:

```text
email Google
```

Contoh:

```text
guru@gmail.com
```

tidak otomatis berarti sekolah tertentu.

Google hanya memberikan identitas autentikasi:

```text
Google UID
Email
Name
```

Data sekolah ditentukan oleh membership di database.

Struktur:

```text
Google Account
      ↓
User
      ↓
School Membership
      ↓
School
      ↓
Class
      ↓
Student Profile
```

---

# 10. DATA MODEL SAAS

Jangan menggunakan desain lama yang hanya:

```text
users.schoolId
```

Gunakan model multi-tenant:

```text
users
schools
school_memberships
classes
student_profiles
counselor_profiles
```

Karena satu user secara teknis dapat memiliki membership berbeda di masa depan.

---

# 11. USERS TABLE

```text
users

id
google_uid
email
name
photo_url
auth_provider
status
created_at
updated_at
```

`google_uid` harus unik.

Jangan menggunakan email sebagai primary identity.

---

# 12. SCHOOLS TABLE

```text
schools

id
name
school_code
logo_url
address
description
owner_user_id
status
created_at
updated_at
```

Contoh:

```text
id:
SCH_001

name:
SMK Teknologi Nusantara

school_code:
SMK-TN82

owner_user_id:
USR_001
```

---

# 13. SCHOOL MEMBERSHIPS

```text
school_memberships

id
school_id
user_id
role
status
joined_at
created_at
updated_at
```

Role:

```text
COUNSELOR
STUDENT
```

Contoh:

```text
USR_001
↓
SCH_001
↓
COUNSELOR
```

atau:

```text
USR_100
↓
SCH_001
↓
STUDENT
```

---

# 14. COUNSELOR PROFILES

```text
counselor_profiles

id
user_id
school_id
name
employee_id
phone
photo_url
created_at
updated_at
```

---

# 15. STUDENT PROFILES

```text
student_profiles

id
user_id
school_id
class_id
student_id
name
phone
created_at
updated_at
```

---

# 16. CLASSES

```text
classes

id
school_id
name
grade
description
status
created_at
updated_at
```

Contoh:

```text
X RPL 1
X RPL 2
XI RPL 1
XI TKJ 1
XII RPL 1
```

---

# 17. GURU BK MEMBUAT RUANG SEKOLAH

Ini merupakan fitur inti SaaS.

Flow:

```text
Splash
 ↓
Onboarding
 ↓
Masuk sebagai Guru BK
 ↓
Login dengan Google
 ↓
Belum memiliki sekolah
 ↓
Buat Ruang Sekolah
```

Form:

```text
Nama Sekolah
Nama Guru BK
NIP / ID Guru
Nomor HP
```

Button:

```text
Buat Ruang Sekolah
```

Backend membuat:

```text
users
schools
school_memberships
counselor_profiles
```

Guru BK otomatis menjadi owner:

```text
role = COUNSELOR
status = ACTIVE
```

---

# 18. SCHOOL CODE

Setelah sekolah dibuat, sistem menghasilkan:

```text
School Code
```

Contoh:

```text
SMK-TN82
```

Kode harus:

* Unik
* Mudah dibaca
* Tidak mudah ditebak jika digunakan sebagai credential
* Dapat diregenerasi jika diperlukan

School code bukan satu-satunya security mechanism.

---

# 19. GURU BK LAIN BERGABUNG

Jika satu sekolah memiliki beberapa Guru BK:

```text
Guru BK A
↓
Membuat sekolah
↓
Owner
```

Guru BK B:

```text
Login Google
↓
Pilih:
"Gabung ke Sekolah"
↓
Masukkan Invitation Code Guru BK
↓
Backend verifikasi
↓
Masuk sebagai COUNSELOR
```

Jangan memberikan akses hanya dengan mengetahui school code.

Gunakan invitation khusus Guru BK.

---

# 20. COUNSELOR INVITATION

Table:

```text
counselor_invites

id
school_id
code_hash
created_by
expires_at
used_at
status
created_at
```

Guru BK owner dapat membuat:

```text
Kode Undangan Guru BK
```

Contoh:

```text
BK-SCH001-X92K
```

Invitation:

* One-time
* Expirable
* Rate limited
* Hash di database

---

# 21. GURU BK OWNER

Guru BK pertama yang membuat sekolah menjadi:

```text
OWNER
```

Tetapi role aplikasi tetap:

```text
COUNSELOR
```

Jangan membuat role:

```text
SCHOOL_ADMIN
```

Gunakan permission/ownership internal.

Contoh:

```text
school_memberships

role = COUNSELOR
membership_type = OWNER
```

atau permission:

```text
is_owner = true
```

Guru BK owner dapat:

* Edit sekolah
* Kelola kelas
* Kelola siswa
* Membuat invitation Guru BK
* Mengelola konten

---

# 22. KELAS

Guru BK dapat:

```text
Kelola Kelas
```

UI:

```text
X RPL 1       32 siswa
X RPL 2       30 siswa
XI RPL 1      28 siswa
XI TKJ 1      31 siswa

[+ Tambah Kelas]
```

Action:

* Tambah
* Edit
* Arsipkan
* Lihat siswa

---

# 23. STUDENT JOIN FLOW

Siswa tidak membuat sekolah.

Siswa bergabung ke sekolah.

Flow:

```text
Login Google
 ↓
Belum memiliki school membership
 ↓
Gabung ke Sekolah
 ↓
Masukkan School Code
 ↓
Backend menemukan school
 ↓
Masukkan kode kelas / invitation siswa
 ↓
Masukkan NIS / Student ID
 ↓
Backend verifikasi
 ↓
Akun terhubung
```

---

# 24. CLASS JOIN CODE

Guru BK dapat membuat kode bergabung untuk kelas.

Contoh:

```text
XI RPL 1

Kode:
RPL1-82KD
```

Siswa memasukkan kode tersebut.

Backend mengetahui:

```text
schoolId = SCH001
classId = CLASS001
```

Kemudian siswa memasukkan:

```text
NIS
```

Backend mencocokkan.

---

# 25. STUDENT ACTIVATION

Gunakan dua opsi.

### MVP sederhana

Guru BK membuat student roster:

```text
Nama
NIS
Kelas
```

Kemudian sistem menghasilkan activation code.

### Opsi berikutnya

Import roster siswa.

Tetapi import tidak wajib untuk MVP pertama.

---

# 26. STUDENT JOIN RESULT

Jika berhasil:

```text
Google UID
    ↓
User ID
    ↓
School Membership
    ↓
School ID
    ↓
Class ID
    ↓
Student ID
```

Contoh:

```text
Google UID:
google_xxx

School:
SCH001

Class:
CLASS001

NIS:
12345
```

---

# 27. IMPORTANT: GOOGLE UID LINKING

Google UID harus disimpan pada `users`.

Contoh:

```text
users

id:
USR_001

google_uid:
109283746283746

email:
siswa@gmail.com
```

Kemudian:

```text
school_memberships

user_id:
USR_001

school_id:
SCH001

role:
STUDENT
```

Dan:

```text
student_profiles

user_id:
USR_001

school_id:
SCH001

class_id:
CLASS001

student_id:
12345
```

Dengan demikian Google Account terhubung ke sekolah melalui membership.

---

# 28. MULTI-SCHOOL

Sistem harus mendukung:

```text
School A
School B
School C
...
School N
```

Semua menggunakan APK yang sama.

Contoh:

```text
Google User A
↓
SCH001
↓
XI RPL 1
```

Google User B:

```text
Google User B
↓
SCH002
↓
XI IPA 2
```

Data tidak boleh bercampur.

---

# 29. SCHOOL TENANT ISOLATION

WAJIB.

Setiap data tenant memiliki:

```text
school_id
```

Contoh:

```text
reports.school_id
contents.school_id
classes.school_id
student_profiles.school_id
notifications.school_id
messages.school_id
```

Backend selalu menentukan school context dari authenticated membership.

JANGAN percaya:

```text
schoolId
```

yang dikirim client.

---

# 30. SECURITY QUERY

Jangan:

```sql
SELECT * FROM reports WHERE id = ?
```

Gunakan:

```sql
SELECT *
FROM reports
WHERE id = ?
AND school_id = ?
```

Untuk student:

```sql
AND student_id = ?
```

Untuk counselor:

```sql
AND school_id = authenticatedSchoolId
```

---

# 31. STUDENT PERMISSION

Student hanya dapat:

* Melihat profil sendiri
* Melihat laporan sendiri
* Membuat laporan
* Chat pada laporan sendiri
* Melihat konten sekolah
* Melihat notifikasi sendiri
* Mengubah data profil yang diperbolehkan

Tidak dapat:

* Melihat siswa lain
* Melihat laporan siswa lain
* Mengubah status laporan
* Mengubah priority
* Melihat counselor notes
* Mengedit konten

---

# 32. COUNSELOR PERMISSION

Counselor dapat:

* Melihat laporan sekolah
* Mengubah status
* Mengubah priority
* Chat
* Follow-up
* Melihat attachment yang berhak diakses
* Mengelola konten
* Mengelola kelas
* Mengelola siswa sesuai permission
* Mengundang Counselor lain jika owner

Semua dibatasi school membership.

---

# 33. REPORT TYPES

### Bullying

* Verbal
* Fisik
* Cyberbullying
* Pengucilan
* Ancaman
* Lainnya

### Kritik & Saran

* Fasilitas
* Kegiatan
* Lingkungan
* Pelayanan
* Lainnya

### Aspirasi

* Ide
* Program
* Kegiatan siswa
* Lingkungan
* Lainnya

---

# 34. REPORT FLOW

```text
Home
 ↓
Pilih:
Bullying / Kritik & Saran / Aspirasi
 ↓
Kategori
 ↓
Detail
 ↓
Tanggal
 ↓
Lokasi
 ↓
Korban / Saksi
 ↓
Deskripsi
 ↓
Upload Bukti
 ↓
Privacy Notice
 ↓
Review
 ↓
Kirim
```

---

# 35. REPORT CODE

Backend membuat:

```text
RPT-20260924-0001
```

Tidak boleh dibuat hanya oleh Flutter.

---

# 36. REPORT STATUS

```text
SUBMITTED
UNDER_REVIEW
IN_PROGRESS
WAITING_FOR_INFORMATION
RESOLVED
CLOSED
TRANSFERRED
```

Priority:

```text
NORMAL
TINGGI
URGENT
```

---

# 37. REPORT TIMELINE

Setiap perubahan:

```text
Status
Priority
Follow-up
Message
```

dapat tercatat sesuai kebutuhan dalam timeline.

Contoh:

```text
24 Sep
Laporan dikirim

24 Sep
Sedang ditinjau

25 Sep
Dalam proses

26 Sep
Tindak lanjut dilakukan
```

---

# 38. PRIVATE CHAT

Chat hanya berdasarkan laporan.

```text
Student
  ↕
Guru BK
  ↕
Report
```

Tidak ada global chat.

Tidak ada chat antar siswa.

---

# 39. COUNSELOR INTERNAL NOTES

Guru BK boleh memiliki catatan internal.

Contoh:

```text
Internal Note:
Perlu tindak lanjut dengan wali kelas.
```

Catatan ini:

**TIDAK BOLEH terlihat oleh siswa.**

---

# 40. REPORT ATTACHMENTS

Gunakan:

**Cloudflare R2**

Object key:

```text
schools/{schoolId}/reports/{reportId}/{fileId}
```

Bucket private.

Evidence tidak boleh public.

---

# 41. FILE LIMIT

MVP:

```text
Image: 5 MB
Video: 25 MB
Document: 10 MB
```

Buat configurable.

Backend harus memvalidasi:

* MIME
* Extension
* Size
* Authorization

Jangan percaya validasi Flutter saja.

---

# 42. CONTENT MANAGEMENT

Guru BK dapat mengelola:

* Poster
* Banner
* Education
* Announcement
* Counseling

UI:

```text
Kelola Konten

[Semua]
[Poster]
[Edukasi]
[Banner]
[Pengumuman]

[+ Tambah Konten]
```

---

# 43. CONTENT TABLE

```text
contents

id
school_id
created_by
type
title
short_description
body
image_key
status
sort_order
publish_at
expire_at
created_at
updated_at
```

Status:

```text
DRAFT
PUBLISHED
ARCHIVED
```

---

# 44. CONTENT CREATION

Form:

```text
Upload Image
Judul
Deskripsi
Jenis
Isi Materi
Publish
```

Action:

```text
Simpan Draft
Publish
```

---

# 45. CONTENT SECURITY

Guru BK School A:

```text
schoolId = SCH001
```

tidak boleh:

```text
UPDATE contents
WHERE school_id = SCH002
```

Backend harus memastikan.

---

# 46. STUDENT HOME

```text
Halo, [Nama]

[Notification]

[Dynamic Banner]

Butuh bantuan?

[Bullying]
[Kritik & Saran]
[Aspirasi]

Laporan Saya

[Summary]

Belajar & Cari Tahu

[Education Card]
[Education Card]
```

---

# 47. EDUCATION

Materi:

* Kenali Bullying
* Cara Membantu Teman
* Cara Melapor
* Keamanan Digital
* Kapan Meminta Bantuan?

Card:

```text
Image
Title
Short Description
```

Konten berasal dari backend.

Tidak perlu update APK untuk mengganti materi.

---

# 48. ONBOARDING

3 slide:

### Slide 1

**Bullying Bukan Bercanda**

"Perlakuan yang menyakiti bukan hal sepele."

### Slide 2

**Kamu Tidak Sendiri**

"Ceritakan apa yang terjadi. Ada yang siap mendengarkan."

### Slide 3

**Suaramu Berarti**

"Laporkan, beri saran, dan sampaikan aspirasimu."

Gunakan foto realistis suasana sekolah Indonesia.

---

# 49. DESIGN SYSTEM

Dominan:

**WHITE**

Primary:

```text
#D92D20
```

Dark red:

```text
#B42318
```

Light red:

```text
#FEF3F2
```

Background:

```text
#F8F9FA
```

Text:

```text
#1D2939
```

Secondary:

```text
#667085
```

Border:

```text
#EAECF0
```

Success:

```text
#12B76A
```

Warning:

```text
#F79009
```

Info:

```text
#2E90FA
```

Font:

**Inter**

Design:

* clean
* modern
* professional
* friendly
* trustworthy
* school-oriented

Dominasi visual:

```text
75% white/light
15–20% gray
5–10% red
```

---

# 50. STUDENT NAVIGATION

Bottom navigation:

```text
Beranda
Laporan
Notifikasi
Profil
```

---

# 51. COUNSELOR NAVIGATION

Bottom navigation:

```text
Dashboard
Laporan
Notifikasi
Profil
```

Kelola konten dan pengaturan sekolah tersedia dari Dashboard/Profile sesuai UX.

---

# 52. STUDENT SCREENS

Implementasikan:

```text
Splash
Onboarding
Welcome

Login
Google Login

Student Join School
School Code
Class Code
NIS Verification

Home
Create Report
Report History
Report Detail
Chat
Notifications
Education
Education Detail
Profile
Settings
Help
```

---

# 53. COUNSELOR SCREENS

```text
Splash
Onboarding
Welcome

Google Login

Create School
School Setup
Dashboard

Reports
Report Detail
Chat
Notifications

Kelola Kelas
Tambah Kelas
Detail Kelas
Daftar Siswa

Kelola Guru BK
Invitation
Counselor Members

Kelola Konten
Tambah Konten
Edit Konten
Preview Konten

School Profile
Profile
Settings
```

---

# 54. SCHOOL SETUP

Setelah Guru BK membuat ruang:

```text
Sekolah berhasil dibuat

SMK Teknologi Nusantara

Kode Sekolah:
SMK-TN82
```

CTA:

```text
Mulai Atur Sekolah
```

Kemudian:

```text
Buat Kelas Pertama
```

Contoh:

```text
XI RPL 1
```

---

# 55. STUDENT JOIN UX

Jangan membuat siswa bingung.

Screen:

```text
Gabung ke Sekolah

Masukkan kode sekolah
[____________]

Masukkan kode kelas
[____________]

NIS
[____________]

[Gabung]
```

Jika valid:

```text
Berhasil Bergabung

Sekolah:
SMK Teknologi Nusantara

Kelas:
XI RPL 1
```

---

# 56. GOOGLE LOGIN FLOW

### Existing user

```text
Login Google
 ↓
Google UID ditemukan
 ↓
Cari active membership
 ↓
Masuk Dashboard/Home
```

### New Counselor

```text
Login Google
 ↓
Tidak punya membership
 ↓
Buat Ruang Sekolah
```

### New Student

```text
Login Google
 ↓
Tidak punya membership
 ↓
Gabung Sekolah
```

---

# 57. MULTIPLE MEMBERSHIP

Architecture harus mendukung satu Google account memiliki beberapa membership di masa depan.

Contoh:

```text
Google UID
   │
   ├── SCH001
   │     └── COUNSELOR
   │
   └── SCH002
         └── COUNSELOR
```

Namun MVP dapat menggunakan:

**satu active school context pada satu waktu.**

Jika user memiliki lebih dari satu membership:

```text
Pilih Ruang Sekolah
```

Kemudian semua data ditampilkan berdasarkan active school context.

---

# 58. DATABASE CORE

Minimal table:

```text
users
schools
school_memberships
classes
student_profiles
counselor_profiles
counselor_invites
student_join_codes
reports
report_attachments
report_messages
report_timeline
report_followups
contents
notifications
device_tokens
audit_logs
```

---

# 59. REPORT TABLE

```text
reports

id
school_id
student_id
report_code
type
category
description
incident_date
incident_location
reporter_type
priority
status
created_at
updated_at
resolved_at
```

---

# 60. MESSAGE TABLE

```text
report_messages

id
report_id
school_id
sender_user_id
message
attachment_id
created_at
```

---

# 61. NOTIFICATION TABLE

```text
notifications

id
user_id
school_id
title
body
type
reference_id
is_read
created_at
```

---

# 62. DEVICE TOKEN TABLE

```text
device_tokens

id
user_id
school_id
fcm_token
platform
created_at
updated_at
```

---

# 63. AUDIT LOG

```text
audit_logs

id
school_id
user_id
action
entity_type
entity_id
metadata
created_at
```

Record:

```text
LOGIN
SCHOOL_CREATED
CLASS_CREATED
STUDENT_JOINED
COUNSELOR_INVITED
REPORT_CREATED
REPORT_VIEWED
REPORT_STATUS_CHANGED
REPORT_PRIORITY_CHANGED
MESSAGE_SENT
CONTENT_CREATED
CONTENT_UPDATED
CONTENT_PUBLISHED
CONTENT_DELETED
```

---

# 64. API

Base:

```text
/api
```

Auth:

```text
POST /api/auth/google
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
```

School:

```text
POST /api/schools
GET /api/schools/current
PATCH /api/schools/current
POST /api/schools/join
```

Classes:

```text
GET /api/classes
POST /api/classes
PATCH /api/classes/:id
DELETE /api/classes/:id
```

Students:

```text
GET /api/classes/:id/students
POST /api/students/join
GET /api/students/me
```

Counselors:

```text
GET /api/counselors
POST /api/counselors/invites
POST /api/counselors/join
```

Reports:

```text
GET /api/reports
POST /api/reports
GET /api/reports/:id
PATCH /api/reports/:id/status
PATCH /api/reports/:id/priority
GET /api/reports/:id/timeline
POST /api/reports/:id/followups
```

Messages:

```text
GET /api/reports/:id/messages
POST /api/reports/:id/messages
```

Contents:

```text
GET /api/contents
GET /api/contents/:id
POST /api/contents
PATCH /api/contents/:id
DELETE /api/contents/:id
POST /api/contents/:id/publish
POST /api/contents/:id/unpublish
```

Uploads:

```text
POST /api/uploads
GET /api/attachments/:id
DELETE /api/attachments/:id
```

Notifications:

```text
GET /api/notifications
PATCH /api/notifications/:id/read
```

Devices:

```text
POST /api/devices/register
DELETE /api/devices/:id
```

---

# 65. API RESPONSE

Success:

```json
{
  "success": true,
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Pesan aman"
  }
}
```

Jangan expose:

* SQL errors
* Stack traces
* Cloudflare internals
* Secrets
* File paths

---

# 66. AUTH SECURITY

Gunakan:

* Google OAuth / Google Identity
* Secure token handling
* Short-lived access token
* Refresh token mechanism jika diperlukan

Flutter:

```text
flutter_secure_storage
```

Jangan menyimpan token sensitif di plaintext SharedPreferences.

---

# 67. GOOGLE AUTH SECURITY

Google UID harus diverifikasi oleh backend.

Jangan percaya:

```text
google_uid
email
role
school_id
```

yang dikirim bebas oleh client.

Backend harus memvalidasi identity token sesuai mekanisme Google OAuth yang digunakan.

---

# 68. ROLE SECURITY

Role tidak boleh ditentukan oleh Flutter.

Jangan:

```json
{
  "role": "COUNSELOR"
}
```

lalu backend langsung mempercayainya.

Role berasal dari:

```text
school_memberships
```

---

# 69. SCHOOL CONTEXT SECURITY

Client boleh mengirim active school context untuk navigasi.

Tetapi backend harus memeriksa:

```text
user memiliki membership terhadap school tersebut
```

Jika tidak:

```text
403 Forbidden
```

atau response aman.

---

# 70. RATE LIMITING

Wajib untuk:

```text
Google authentication
Login
School creation
Join school
Join class
Invitation
Report creation
Messages
Uploads
```

---

# 71. ABUSE PREVENTION

Karena ini SaaS self-service, perhatikan:

* spam school creation
* spam reports
* spam chat
* file abuse
* invitation abuse
* brute force join code

Tambahkan:

* rate limiting
* expiration
* one-time code
* request validation
* audit log

---

# 72. SCHOOL CODE SECURITY

School code digunakan untuk menemukan ruang.

Tetapi jangan menganggap school code sebagai authorization.

Authorization tetap:

```text
authenticated user
+
membership
```

---

# 73. CLASS CODE SECURITY

Class join code:

* Expirable jika diperlukan
* Dapat diregenerate
* Rate limited
* Tidak memberikan akses laporan

Kode hanya membantu proses join.

---

# 74. PRIVACY

Tidak boleh ada:

* Public reports
* Public student directory
* Public bullying accusations
* Public attachments
* Public chat

---

# 75. CONFIDENTIAL REPORT

Saat membuat laporan:

```text
Laporan Rahasia

Laporanmu hanya dapat dilihat oleh Guru BK
yang berwenang di sekolahmu.
```

---

# 76. PUSH NOTIFICATION

Firebase Cloud Messaging.

Event:

Student:

```text
Laporan berhasil diterima
Status laporan berubah
Ada pesan baru
Ada tindak lanjut
```

Counselor:

```text
Laporan baru
Pesan siswa
```

Jangan menampilkan detail sensitif di lock screen.

Gunakan:

```text
Ada pembaruan pada laporanmu.
Buka SuaraSiswa untuk melihat detail.
```

---

# 77. R2 STORAGE

Folder:

```text
schools/{schoolId}/reports/{reportId}/
schools/{schoolId}/content/{contentId}/
```

Private bucket untuk data sensitif.

Evidence laporan harus private.

---

# 78. DYNAMIC CONTENT

Jangan hardcode:

* Poster
* Banner
* Materi edukasi
* Pengumuman

Semua berasal dari backend.

Guru BK upload:

```text
APK
 ↓
Worker
 ↓
R2
 ↓
D1 metadata
 ↓
Student APK
```

Tidak perlu update APK.

---

# 79. FLUTTER ARCHITECTURE

Gunakan:

* Riverpod atau Bloc
* Repository pattern
* Clean architecture secukupnya
* Dependency injection
* Central API client

Struktur:

```text
lib/

core/
  constants/
  theme/
  network/
  storage/
  errors/
  utils/

features/

auth/
school/
classes/
students/
counselors/
reports/
chat/
notifications/
education/
content_management/

shared/
  widgets/
  models/
```

---

# 80. MOCK + API

UI harus dapat dikembangkan dengan:

```text
MockRepository
```

Kemudian dipindahkan ke:

```text
ApiRepository
```

Tanpa rewrite besar.

---

# 81. CLOUDFLARE WORKER STRUCTURE

```text
worker/

src/
  index.ts

  routes/
    auth.ts
    schools.ts
    classes.ts
    students.ts
    counselors.ts
    reports.ts
    messages.ts
    contents.ts
    uploads.ts
    notifications.ts

  services/
    auth.service.ts
    school.service.ts
    report.service.ts
    content.service.ts
    storage.service.ts
    notification.service.ts

  middleware/
    auth.ts
    schoolContext.ts
    role.ts
    rateLimit.ts

  db/
    migrations/
    queries/

  utils/
    validation.ts
    response.ts
    security.ts

  types/
```

---

# 82. D1 MIGRATIONS

Gunakan migrations:

```text
0001_initial.sql
0002_indexes.sql
0003_school_memberships.sql
0004_reports.sql
0005_contents.sql
```

Jangan mengandalkan schema manual.

---

# 83. INDEXES

Tambahkan index:

```text
users.google_uid
users.email

schools.school_code

school_memberships.user_id
school_memberships.school_id

classes.school_id

student_profiles.school_id
student_profiles.student_id
student_profiles.class_id

reports.school_id
reports.student_id
reports.status
reports.created_at

contents.school_id
contents.status
contents.type

notifications.user_id
notifications.is_read

report_messages.report_id
```

---

# 84. PAGINATION

Reports:

```text
?page=1&limit=20
```

Messages:

```text
?page=1&limit=30
```

Contents:

```text
?page=1&limit=20
```

Jangan mengambil seluruh data sekaligus.

---

# 85. ERROR HANDLING

Gunakan bahasa Indonesia.

Jangan:

```text
D1_ERROR
JWT_INVALID
SQLITE_ERROR
500 INTERNAL SERVER ERROR
```

Tampilkan:

```text
Terjadi kendala.
Silakan coba lagi.
```

---

# 86. OFFLINE / NETWORK

Handle:

* No internet
* Timeout
* Upload gagal
* API error
* Session expired

Gunakan retry yang aman.

---

# 87. LOADING

Gunakan:

* Skeleton
* Progress indicator
* Loading button

Jangan blank screen.

---

# 88. EMPTY STATES

Contoh:

```text
Belum Ada Laporan

Laporan yang kamu buat akan muncul di sini.
```

```text
Belum Ada Materi

Materi dari Guru BK akan muncul di sini.
```

---

# 89. SCHOOL EMPTY STATE

Untuk Guru BK baru:

```text
Selamat datang di SuaraSiswa

Buat ruang sekolahmu untuk mulai mengelola
siswa, kelas, laporan, dan konten edukasi.
```

Button:

```text
Buat Ruang Sekolah
```

---

# 90. STUDENT EMPTY STATE

Jika belum bergabung:

```text
Kamu belum bergabung dengan sekolah.

Masukkan kode sekolah dan kode kelas
untuk mulai menggunakan SuaraSiswa.
```

Button:

```text
Gabung Sekolah
```

---

# 91. PROFILE

Student:

```text
Nama
NIS
Kelas
Sekolah
Email
```

Counselor:

```text
Nama
NIP/ID
Sekolah
Email
```

School owner:

```text
Kelola Sekolah
Kelola Kelas
Kelola Guru BK
Kode Bergabung
```

---

# 92. SCHOOL MANAGEMENT

Guru BK owner:

```text
Nama Sekolah
Logo
Alamat
Deskripsi
Kode Sekolah
```

Action:

```text
Edit
Regenerate Code jika diperlukan
```

Jangan mengizinkan perubahan schoolId.

---

# 93. COUNSELOR MANAGEMENT

Owner dapat:

```text
Lihat Guru BK
Buat Invitation
Nonaktifkan Membership
```

Jangan menghapus historical report hanya karena membership counselor berubah.

---

# 94. CLASS MANAGEMENT

Owner/Counselor dengan permission:

```text
Tambah Kelas
Edit Kelas
Arsipkan Kelas
Lihat Siswa
```

Jika kelas diarsipkan:

* Data lama tetap ada
* Report lama tetap ada
* Student history tetap aman

---

# 95. STUDENT MANAGEMENT

Guru BK dapat melihat:

```text
Nama
NIS
Kelas
Status
```

Tidak boleh menampilkan informasi yang tidak diperlukan.

Guru BK dapat:

* melihat siswa sekolahnya
* memindahkan siswa ke kelas sesuai permission
* menonaktifkan membership bila diperlukan

Historical report tetap memiliki referensi student.

---

# 96. SCHOOL DELETION

Jangan langsung hard-delete school.

Gunakan:

```text
status = ARCHIVED
```

atau soft delete.

Data laporan sensitif harus ditangani dengan kebijakan retensi yang jelas.

---

# 97. DESIGN

Gunakan card:

```text
12–16px radius
```

Touch target:

```text
44–48px
```

Jangan terlalu banyak animasi.

Gunakan foto realistis untuk:

* onboarding
* education
* banner

---

# 98. LOGO

Logo:

Speech bubble + student + shield/protection.

Warna:

Red + White + Dark Gray.

Minimal.

Harus cocok untuk:

* App icon
* Splash
* Onboarding
* Header

---

# 99. SPLASH

White.

Logo.

```text
SuaraSiswa

Berani bersuara, bersama mencari solusi.
```

---

# 100. TESTING MULTI-TENANT

WAJIB test:

```text
School A
↓
Counselor A
↓
Reports A
```

tidak boleh mengakses:

```text
Reports B
```

Student A tidak boleh:

```text
View Student B
View Report B
View Content B
```

Counselor A tidak boleh:

```text
Edit Content B
View Report B
Manage Class B
```

---

# 101. TESTING GOOGLE

Test:

### New Counselor

```text
Google Login
↓
Create School
↓
Membership Created
```

### Existing Counselor

```text
Google Login
↓
Existing Membership
↓
Dashboard
```

### New Student

```text
Google Login
↓
Join School
↓
NIS verification
↓
Class membership
```

### Existing Student

```text
Google Login
↓
Existing Membership
↓
Home
```

---

# 102. TESTING SCHOOL CREATION

Test:

```text
Counselor A
↓
Create School A
```

Kemudian:

```text
Counselor B
↓
Create School B
```

Pastikan:

```text
School A != School B
```

Data tidak boleh bercampur.

---

# 103. TESTING CLASS JOIN

```text
Class Code A
↓
School A
↓
Class A
```

Tidak boleh digunakan untuk masuk ke:

```text
School B
```

---

# 104. TESTING CONTENT

School A:

```text
Counselor A
↓
Create Poster A
```

Student A:

```text
Can see Poster A
```

Student B:

```text
Cannot see Poster A
```

---

# 105. TESTING REPORT

Student A:

```text
Create Report A
```

Counselor A:

```text
Can view Report A
```

Counselor B:

```text
Cannot view Report A
```

Student B:

```text
Cannot view Report A
```

---

# 106. TESTING CHAT

Student A:

```text
Report A
↓
Chat
```

Counselor A:

```text
Report A
↓
Chat
```

Student B:

```text
Cannot access Chat A
```

---

# 107. PERFORMANCE

Gunakan:

* Lazy loading
* Pagination
* Image compression
* Cache
* Efficient queries
* Indexed D1 queries

Jangan load semua laporan.

Jangan load semua siswa sekaligus.

---

# 108. SECURITY PRIORITY

Urutan prioritas:

```text
1. Privacy
2. Authentication
3. Authorization
4. Multi-tenant isolation
5. Secure file storage
6. Data integrity
7. UX
8. Performance
9. Visual polish
```

---

# 109. DO NOT OVERENGINEER

MVP jangan menggunakan:

```text
Microservices
Kubernetes
Redis
Kafka
Elasticsearch
PostgreSQL cluster
VPS
Admin portal
Web dashboard
```

Gunakan arsitektur sederhana:

```text
Flutter
 ↓
Cloudflare Workers
 ↓
D1
 ↓
R2
 ↓
FCM
```

---

# 110. DEVELOPMENT PHASE

## PHASE 1 — Flutter Foundation

Buat:

* Project
* Theme
* Routing
* Splash
* Onboarding
* Google login UI
* State management
* API client

## PHASE 2 — SaaS Onboarding

Buat:

* Counselor Google login
* Create school
* School setup
* School code
* Counselor invitation
* Student Google login
* Join school
* Class join
* NIS verification

## PHASE 3 — School Management

Buat:

* Classes
* Students
* Counselors
* School profile

## PHASE 4 — Student

Buat:

* Home
* Reports
* History
* Detail
* Chat
* Notifications
* Education
* Profile

## PHASE 5 — Counselor

Buat:

* Dashboard
* Reports
* Chat
* Notifications
* Content management
* Class management
* Student management
* Counselor management

## PHASE 6 — Backend

Buat:

* Worker
* Hono
* D1
* Authentication
* Authorization
* Multi-tenant middleware

## PHASE 7 — R2

Buat:

* Upload
* Private evidence
* Content images
* Signed/authorized access

## PHASE 8 — FCM

Buat:

* Token registration
* Push notifications

## PHASE 9 — Security

Buat:

* Rate limit
* Audit log
* Access control
* File validation
* School isolation

## PHASE 10 — Testing

Lakukan:

* Unit test
* Widget test
* Integration test
* API test
* Multi-tenant security test

## PHASE 11 — RELEASE

Build:

```powershell
flutter build apk --release
```

---

# 111. FLUTTER STRUCTURE

```text
lib/

core/
  constants/
  theme/
  network/
  storage/
  errors/
  utils/

features/

auth/
school/
classes/
students/
counselors/
reports/
chat/
notifications/
education/
content_management/

shared/
  widgets/
  models/
```

---

# 112. BACKEND STRUCTURE

```text
worker/

src/
  index.ts

  routes/
    auth.ts
    schools.ts
    classes.ts
    students.ts
    counselors.ts
    reports.ts
    messages.ts
    contents.ts
    uploads.ts
    notifications.ts

  middleware/
    auth.ts
    schoolContext.ts
    authorization.ts
    rateLimit.ts

  services/
    auth.service.ts
    school.service.ts
    report.service.ts
    content.service.ts
    storage.service.ts
    notification.service.ts

  db/
    migrations/
    queries/

  utils/
    response.ts
    validation.ts
    security.ts

  types/
```

---

# 113. ENVIRONMENT

Gunakan:

```text
development
staging
production
```

Flutter:

```text
API_BASE_URL
```

Cloudflare secrets:

```text
GOOGLE_CLIENT_SECRET
JWT_SECRET
FCM credentials
other sensitive secrets
```

Jangan commit secret.

---

# 114. COMMANDS

Flutter:

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

Cloudflare:

```powershell
npm install
npx wrangler login
npx wrangler dev
npx wrangler deploy
```

D1:

```powershell
npx wrangler d1 migrations apply DB --remote
```

Gunakan command yang sesuai versi Wrangler terinstal.

---

# 115. FIRST TASK ANTIGRAVITY

Jangan langsung membangun seluruh sistem.

Pertama inspect environment:

```text
Flutter version
Dart version
Android SDK
Java/JDK
Gradle
Node.js
npm
Wrangler
```

Pastikan:

```text
E:\Aplikasi Android\Android\Sdk
```

digunakan Flutter.

Setelah itu:

```text
1. Create Flutter project
2. Theme
3. Routing
4. Splash
5. Onboarding
6. Welcome
7. Google Login
8. Counselor Create School
9. Student Join School
```

Baru lanjut ke fitur lainnya.

---

# 116. FINAL USER EXPERIENCE

### Guru BK baru

```text
Download APK
↓
Login Google
↓
Buat Ruang Sekolah
↓
Masukkan nama sekolah
↓
Ruang dibuat
↓
Buat kelas
↓
Buat kode siswa
↓
Bagikan kode kepada siswa
↓
Mulai menerima laporan
```

Tidak perlu menghubungi developer.

---

### Siswa baru

```text
Download APK
↓
Login Google
↓
Gabung Sekolah
↓
Masukkan kode
↓
Verifikasi NIS
↓
Masuk kelas
↓
Home
↓
Bisa menggunakan SuaraSiswa
```

Tidak perlu menghubungi developer.

---

# 117. FINAL SAAS PRINCIPLE

Setelah aplikasi production:

Developer/pemilik platform tidak boleh menjadi bottleneck untuk:

* Membuat sekolah
* Membuat kelas
* Menambahkan siswa
* Mengundang Guru BK
* Mengubah poster
* Mengubah banner
* Mengubah materi
* Mengelola laporan

Semua harus dilakukan oleh Guru BK melalui APK.

Developer hanya menyediakan:

```text
Platform
Backend
Infrastructure
Security
Maintenance
Updates
```

---

# 118. FINAL PRODUCT STRUCTURE

```text
                         SUARASISWA
                              │
                       Flutter Android
                              │
                      Google Authentication
                              │
                       Cloudflare Worker
                              │
                    ┌─────────┼─────────┐
                    │         │         │
                   D1        R2        FCM
                    │         │         │
              ┌─────┴─────┐   │         │
              │           │   │         │
           Schools      Users Files   Notifications
              │
       ┌──────┼───────┐
       │      │       │
     Class  Counselor Student
       │              │
       └──────┬───────┘
              │
            Reports
              │
             Chat
```

---

# 119. DEFINITION OF DONE

Project dianggap MVP selesai apabila:

[ ] Flutter Android berjalan
[ ] Android SDK menggunakan E:\Aplikasi Android\Android\Sdk
[ ] Splash
[ ] Onboarding
[ ] Google Login
[ ] Counselor onboarding
[ ] Create School
[ ] School Code
[ ] Counselor Invitation
[ ] Class Management
[ ] Student Join
[ ] NIS Verification
[ ] Student Home
[ ] Report Creation
[ ] Evidence Upload
[ ] Report History
[ ] Report Detail
[ ] Status Tracking
[ ] Private Chat
[ ] Notifications
[ ] Education
[ ] Dynamic Banner
[ ] Dynamic Poster
[ ] Dynamic Education
[ ] Content Management
[ ] Student Management
[ ] Counselor Management
[ ] Cloudflare Worker
[ ] D1
[ ] R2
[ ] FCM
[ ] Google Authentication
[ ] Multi-school isolation
[ ] Authorization
[ ] Rate limiting
[ ] Audit logs
[ ] File validation
[ ] Error handling
[ ] Loading state
[ ] Empty state
[ ] Pagination
[ ] Security testing
[ ] Release APK

---

# 120. FINAL IMPLEMENTATION RULE

Jangan hanya membuat prototype visual.

Bangun foundation yang benar-benar dapat digunakan untuk SaaS production.

Jika backend belum tersedia:

```text
Mock Repository
```

boleh digunakan untuk development.

Tetapi architecture harus siap diganti menjadi:

```text
Cloudflare Worker
+
D1
+
R2
+
FCM
```

tanpa membongkar UI.

Prioritaskan:

```text
SECURITY
PRIVACY
MULTI-TENANCY
FUNCTIONALITY
USABILITY
PERFORMANCE
MAINTAINABILITY
```

Jangan menambahkan fitur yang tidak diperlukan.

Jangan membuat Admin role.

Jangan membuat website.

Jangan membuat APK berbeda untuk setiap sekolah.

Jangan membuat developer harus mendaftarkan sekolah secara manual.

**Guru BK harus dapat membuat ruang sekolah sendiri dan mengelolanya melalui APK.**

**Siswa harus dapat login dengan Google dan menghubungkan akun Google-nya ke sekolah + kelas + NIS melalui proses join/verification.**

**Google Account hanya digunakan sebagai identity/authentication. Hubungan sekolah, kelas, NIS, laporan, dan permission ditentukan oleh database membership SuaraSiswa.**

Mulai implementasi dengan pemeriksaan environment, lalu bangun project secara bertahap dari authentication → school onboarding → class/student joining → reports → chat → content → backend → security → testing → release.
</USER_REQUEST>
<ADDITIONAL_METADATA>
The current local time is: 2026-09-24T10:16:07+07:00.
</ADDITIONAL_METADATA>