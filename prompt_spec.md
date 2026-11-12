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
      Kelas        Kelas     
<truncated 34775 bytes>
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

