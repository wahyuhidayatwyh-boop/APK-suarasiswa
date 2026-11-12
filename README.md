# SuaraSiswa — Platform Pengaduan & Bimbingan Konseling Sekolah

> *"Berani bersuara, bersama mencari solusi."*

SuaraSiswa adalah platform **SaaS Mobile Application** berbasis **Flutter** dan **Cloudflare Serverless Stack** yang dirancang untuk menjembatani komunikasi aman dan rahasia antara **Siswa** dan **Guru BK (Bimbingan & Konseling)** di lingkungan sekolah. Aplikasi ini mendukung penanganan kasus perundungan (*bullying*), penyampaian aspirasi, kritik & saran, chat privat, pelacakan status penanganan laporan secara transparan, serta edukasi siswa.

---

## Daftar Isi Dokumentasi Sistem

Sesuai standar rekayasa perangkat lunak, dokumentasi teknis sistem dirangkum dalam tabel berikut:

| No. | Dokumentasi | Fungsi |
|---|---|---|
| 1 | [Flowchart Sistem](#1-flowchart-sistem) | Menggambarkan alur kerja aplikasi secara menyeluruh |
| 2 | [Use Case Diagram](#2-use-case-diagram) | Menggambarkan interaksi aktor (Siswa & Guru BK) dengan sistem |
| 3 | [Activity Diagram](#3-activity-diagram) | Menggambarkan aktivitas mendalam pada alur fitur utama |
| 4 | [Sequence Diagram](#4-sequence-diagram) | Menggambarkan komunikasi antar komponen teknis aplikasi |
| 5 | [Class Diagram](#5-class-diagram) | Menggambarkan struktur kelas dan relasi data aplikasi |
| 6 | [ERD (Entity Relationship Diagram)](#6-erd-entity-relationship-diagram) | Menggambarkan struktur dan relasi database relasional D1 |
| 7 | [Arsitektur Sistem](#7-arsitektur-sistem) | Menjelaskan hubungan Frontend, Backend Edge, dan Database |

---

## 1. Flowchart Sistem
Menggambarkan alur kerja pengguna mulai dari autentikasi Google, pemilihan peran, pendaftaran sekolah/kelas, hingga siklus pelaporan dan konseling.

```mermaid
flowchart TD
    Start([Mulai]) --> Login[Login Akun Google]
    Login --> CheckUser{Sudah terdaftar?}
    
    CheckUser -->|Belum| RoleSelect[Pilih Peran: Siswa / Guru BK]
    CheckUser -->|Sudah| CheckRole{Peran Pengguna?}
    
    %% Alur Siswa
    RoleSelect -->|Siswa| JoinSchool[Input Kode Sekolah dan Kelas]
    JoinSchool --> StudentHome[Dashboard Siswa]
    CheckRole -->|Siswa| StudentHome
    
    StudentHome --> ActionStudent{Pilih Aksi Siswa}
    ActionStudent --> CreateReport[Buat Laporan atau Aspirasi]
    CreateReport --> UploadProof[Unggah Bukti Foto Opsional]
    UploadProof --> SubmitReport[Kirim Laporan - Anonim atau Identitas]
    SubmitReport --> TrackReport[Pantau Status dan Timeline Laporan]
    TrackReport --> ChatCounselor[Chat Konseling Privat dengan Guru BK]
    
    ActionStudent --> ReadEdu[Baca Materi Edukasi dan Artikel]
    ActionStudent --> CheckNotif[Cek Notifikasi dan Update Laporan]
    
    %% Alur Guru BK
    RoleSelect -->|Guru BK| SchoolSetup[Buat Sekolah Baru atau Gabung via Undangan]
    SchoolSetup --> CounselorHome[Dashboard Guru BK]
    CheckRole -->|Guru BK| CounselorHome
    
    CounselorHome --> ActionCounselor{Pilih Aksi Guru BK}
    ActionCounselor --> ManageClass[Kelola Data Kelas dan Siswa]
    ActionCounselor --> ManageReports[Review Laporan Masuk]
    ManageReports --> UpdateStatus[Ubah Status: Investigasi / Tindakan / Selesai]
    UpdateStatus --> ChatStudent[Beri Solusi dan Chat dengan Siswa]
    ActionCounselor --> PublishContent[Publikasikan Artikel dan Poster Edukasi]
    ActionCounselor --> InviteCounselor[Undang Rekan Guru BK via Kode]
    
    ChatCounselor --> End([Selesai])
    ChatStudent --> End
```

---

## 2. Use Case Diagram
Menggambarkan fungsionalitas sistem yang dapat diakses oleh masing-masing aktor (**Siswa** dan **Guru BK**).

```mermaid
flowchart LR
    subgraph Aktor
        Siswa["Siswa"]
        GuruBK["Guru BK / Konselor"]
    end

    subgraph Sistem["Sistem SuaraSiswa"]
        UC_Auth(["Login dengan Akun Google"])
        UC_JoinSchool(["Bergabung ke Ruang Sekolah dan Kelas"])
        UC_CreateReport(["Membuat Laporan dan Aspirasi"])
        UC_UploadProof(["Mengunggah Bukti Foto"])
        UC_TrackReport(["Melacak Status dan Riwayat Laporan"])
        UC_Chat(["Chat Konseling Privat Dua Arah"])
        UC_ReadEdu(["Membaca Konten Edukasi"])
        
        UC_CreateSchool(["Membuat dan Mengatur Profil Sekolah"])
        UC_ManageClass(["Mengelola Data Kelas dan Siswa"])
        UC_InviteCounselor(["Mengundang Guru BK Lain"])
        UC_ManageReport(["Mengelola dan Menindaklanjuti Laporan"])
        UC_PublishEdu(["Menerbitkan Konten Edukasi"])
        UC_Analytics(["Memantau Statistik Laporan"])
    end

    %% Relasi Siswa
    Siswa --> UC_Auth
    Siswa --> UC_JoinSchool
    Siswa --> UC_CreateReport
    Siswa --> UC_UploadProof
    Siswa --> UC_TrackReport
    Siswa --> UC_Chat
    Siswa --> UC_ReadEdu

    %% Relasi Guru BK
    GuruBK --> UC_Auth
    GuruBK --> UC_CreateSchool
    GuruBK --> UC_ManageClass
    GuruBK --> UC_InviteCounselor
    GuruBK --> UC_ManageReport
    GuruBK --> UC_Chat
    GuruBK --> UC_PublishEdu
    GuruBK --> UC_Analytics
```

---

## 3. Activity Diagram
Menggambarkan urutan aktivitas detail pada proses **Pengiriman & Penanganan Laporan Pengaduan**.

```mermaid
flowchart TD
    subgraph Siswa["Aktivitas Siswa"]
        A1[Buka Formulir Laporan] --> A2[Pilih Kategori: Bullying / Saran / Aspirasi]
        A2 --> A3[Tentukan Visibilitas: Nama Asli / Anonim]
        A3 --> A4[Tulis Deskripsi, Tanggal, dan Lokasi]
        A4 --> A5[Lampirkan Bukti Foto Opsional]
        A5 --> A6[Klik Kirim Laporan]
    end

    subgraph Backend["Sistem Backend (Cloudflare Worker & D1)"]
        A6 --> B1[Validasi Token JWT dan Header Sekolah]
        B1 --> B2[Simpan File Bukti ke Storage R2]
        B2 --> B3[Simpan Data Laporan ke Database D1]
        B3 --> B4[Generate Nomor Tiket Laporan Unik]
        B4 --> B5[Buat Log Timeline: Laporan Diterima]
        B5 --> B6[Kirim Notifikasi ke Guru BK]
    end

    subgraph GuruBK["Aktivitas Guru BK"]
        B6 --> C1[Terima Notifikasi Laporan Baru]
        C1 --> C2[Buka Detail Laporan dan Periksa Bukti]
        C2 --> C3[Perbarui Status: Sedang Diinvestigasi]
        C3 --> C4[Buka Ruang Chat Privat Laporan]
        C4 --> C5[Kirim Pesan Pendampingan ke Siswa]
    end

    subgraph Selesai["Penyelesaian Kasus"]
        C5 --> D1[Siswa Membalas Pesan Chat]
        D1 --> D2[Tindakan Konseling di Sekolah]
        D2 --> D3[Guru BK Mengubah Status: Kasus Selesai]
        D3 --> D4[Sistem Mencatat Log Status Akhir]
    end
```

---

## 4. Sequence Diagram
Menggambarkan interaksi antar objek sistem (*Mobile Client*, *API Gateway*, *Database D1*, dan *Storage R2*) saat Siswa mengirimkan laporan dengan bukti.

```mermaid
sequenceDiagram
    autonumber
    actor Siswa as Siswa (Flutter)
    participant API as Cloudflare Worker (Hono API)
    participant R2 as Cloudflare R2 Storage
    participant D1 as Database Cloudflare D1
    actor GuruBK as Guru BK (Flutter)

    Siswa->>API: POST /api/uploads (File Bukti Foto)
    activate API
    API->>R2: PutObject(file_stream, unique_key)
    activate R2
    R2-->>API: file_url tersimpan
    deactivate R2
    API-->>Siswa: 200 OK (file_url)
    deactivate API

    Siswa->>API: POST /api/reports (type, category, desc, file_url, is_anonymous)
    activate API
    API->>API: Verifikasi JWT dan X-School-Id
    API->>D1: INSERT INTO reports (...)
    activate D1
    D1-->>API: Report ID dan Report Code
    deactivate D1

    API->>D1: INSERT INTO report_attachments (...)
    activate D1
    D1-->>API: Attachment Created
    deactivate D1

    API->>D1: INSERT INTO report_timeline (...)
    activate D1
    D1-->>API: Timeline Created
    deactivate D1

    API->>D1: INSERT INTO notifications (...)
    activate D1
    D1-->>API: Notification Saved
    deactivate D1

    API-->>Siswa: 201 Created (report_code)
    deactivate API

    API->>GuruBK: Push Notifikasi Kasus Baru
```

---

## 5. Class Diagram
Menggambarkan relasi antara Model Data inti dan Arsitektur Repository pada aplikasi Flutter.

```mermaid
classDiagram
    class UserModel {
        +String id
        +String googleUid
        +String email
        +String name
        +String photoUrl
        +String status
        +DateTime createdAt
    }

    class SchoolModel {
        +String id
        +String name
        +String schoolCode
        +String address
        +String ownerUserId
        +String status
    }

    class ClassModel {
        +String id
        +String schoolId
        +String name
        +String grade
        +String joinCode
    }

    class ReportModel {
        +String id
        +String schoolId
        +String studentId
        +String reportCode
        +String type
        +String category
        +String description
        +DateTime incidentDate
        +String incidentLocation
        +String reporterType
        +String priority
        +String status
        +String internalNotes
    }

    class ReportAttachment {
        +String id
        +String reportId
        +String fileUrl
        +String fileName
        +int fileSize
    }

    class ChatMessage {
        +String id
        +String reportId
        +String senderUserId
        +String message
        +String attachmentUrl
        +DateTime createdAt
    }

    class ContentModel {
        +String id
        +String schoolId
        +String title
        +String shortDescription
        +String body
        +String imageUrl
        +String type
        +String status
    }

    class ApiClient {
        -Dio dio
        -StorageService storage
        +get(path, queryParams)
        +post(path, data)
        +put(path, data)
        +delete(path)
    }

    class ReportRepository {
        -ApiClient apiClient
        +getReports()
        +getReportDetail(id)
        +createReport(data)
        +updateStatus(id, status)
    }

    UserModel "1" --> "*" ReportModel : melapor
    SchoolModel "1" --> "*" ClassModel : memiliki
    SchoolModel "1" --> "*" ReportModel : menaungi
    ReportModel "1" --> "*" ReportAttachment : memiliki
    ReportModel "1" --> "*" ChatMessage : berisi
    ReportRepository ..> ApiClient : menggunakan
    ReportRepository ..> ReportModel : menghasilkan
```

---

## 6. ERD (Entity Relationship Diagram)
Skema relasional database **Cloudflare D1** (SQLite Relational Edge Engine).

```mermaid
erDiagram
    users ||--o{ schools : "owns"
    users ||--o{ school_memberships : "has"
    schools ||--o{ school_memberships : "includes"
    schools ||--o{ classes : "contains"
    classes ||--o{ student_profiles : "enrolled_in"
    users ||--o{ student_profiles : "profile_of"
    users ||--o{ counselor_profiles : "profile_of"
    schools ||--o{ counselor_profiles : "employs"
    schools ||--o{ counselor_invites : "issued_by"
    schools ||--o{ reports : "recorded_at"
    users ||--o{ reports : "submitted_by"
    reports ||--o{ report_attachments : "has_evidence"
    reports ||--o{ report_messages : "contains_chat"
    reports ||--o{ report_timeline : "tracks_progress"
    schools ||--o{ contents : "publishes"
    users ||--o{ contents : "authored_by"
    users ||--o{ notifications : "receives"
    users ||--o{ device_tokens : "owns_device"

    users {
        string id PK
        string google_uid
        string email
        string name
        string photo_url
        string auth_provider
        string status
        string created_at
    }

    schools {
        string id PK
        string name
        string school_code
        string logo_url
        string address
        string owner_user_id FK
        string status
        string created_at
    }

    school_memberships {
        string id PK
        string school_id FK
        string user_id FK
        string role
        int is_owner
        string status
        string joined_at
    }

    classes {
        string id PK
        string school_id FK
        string name
        string grade
        string join_code
        string status
        string created_at
    }

    student_profiles {
        string id PK
        string user_id FK
        string school_id FK
        string class_id FK
        string student_id
        string name
        string phone
    }

    counselor_profiles {
        string id PK
        string user_id FK
        string school_id FK
        string name
        string employee_id
        string phone
    }

    counselor_invites {
        string id PK
        string school_id FK
        string code_hash
        string created_by FK
        string expires_at
        string status
    }

    reports {
        string id PK
        string school_id FK
        string student_id FK
        string report_code
        string type
        string category
        string description
        string incident_date
        string incident_location
        string reporter_type
        string priority
        string status
        string internal_notes
        string created_at
    }

    report_attachments {
        string id PK
        string report_id FK
        string school_id FK
        string file_url
        string file_name
        int file_size
        string created_at
    }

    report_messages {
        string id PK
        string report_id FK
        string school_id FK
        string sender_user_id FK
        string message
        string attachment_url
        string created_at
    }

    report_timeline {
        string id PK
        string report_id FK
        string school_id FK
        string title
        string description
        string created_at
    }

    contents {
        string id PK
        string school_id FK
        string author_id FK
        string title
        string short_description
        string body
        string image_url
        string type
        string status
        int views_count
    }

    notifications {
        string id PK
        string user_id FK
        string school_id FK
        string title
        string body
        string type
        string reference_id
        int is_read
        string created_at
    }

    device_tokens {
        string id PK
        string user_id FK
        string school_id FK
        string fcm_token
        string platform
        string created_at
    }
```

---

## 7. Arsitektur Sistem
Menjelaskan arsitektur perangkat lunak berbasis Cloud Native Serverless:

```mermaid
flowchart TD
    subgraph ClientLayer["1. Presentation Layer (Mobile Client)"]
        FlutterApp["Flutter Application (Android / Cross-Platform)"]
        RiverpodState["State Management: Flutter Riverpod"]
        GoRoute["Routing: GoRouter"]
        SecureStore["Local Storage: Secure Storage & SharedPreferences"]
    end

    subgraph NetworkGateway["2. Gateway & Edge Security Layer"]
        CF_DNS["Cloudflare DNS & Global Anycast CDN"]
        CF_DDoS["DDoS Protection & SSL/TLS Termination"]
    end

    subgraph BackendLayer["3. Serverless Compute Layer (Cloudflare Workers)"]
        HonoRouter["Hono.js Lightweight Framework Router"]
        AuthMiddleware["JWT Authentication Middleware"]
        TenantMiddleware["Multi-tenant School Context Middleware (X-School-Id)"]
        RateLimiter["Rate Limiting Protection Middleware"]
        API_Services["RESTful Controller Services (Reports, Chat, School, Auth)"]
    end

    subgraph StorageLayer["4. Cloud Data & Storage Layer"]
        D1_DB[("Cloudflare D1 Database<br/>Serverless SQLite Edge")]
        R2_Bucket[("Cloudflare R2 Object Storage<br/>Evidence Images & Media")]
    end

    subgraph ThirdParty["5. External Services"]
        GoogleOAuth["Google Identity Services (OAuth 2.0)"]
        FirebaseFCM["Firebase Cloud Messaging (FCM Notifications)"]
    end

    FlutterApp <--> NetworkGateway
    NetworkGateway <--> HonoRouter
    HonoRouter --> AuthMiddleware
    AuthMiddleware --> TenantMiddleware
    TenantMiddleware --> RateLimiter
    RateLimiter --> API_Services

    API_Services <--> D1_DB
    API_Services <--> R2_Bucket
    API_Services -.-> FirebaseFCM
    FlutterApp -.-> GoogleOAuth
```

---

## Panduan Memulai (Getting Started)

### Prasyarat
* Flutter SDK (versi >= 3.22.0)
* Android SDK / Android Studio
* Node.js (versi >= 18.0.0) untuk pengelolaan backend Cloudflare

### 1. Menjalankan Aplikasi Mobile (Flutter)
```bash
# Clone repository
git clone https://github.com/wahyuhidayatwyh-boop/APK-suarasiswa.git
cd APK-suarasiswa

# Install dependencies
flutter pub get

# Jalankan aplikasi di emulator atau device
flutter run
```
*Aplikasi secara default sudah otomatis terhubung ke backend live yang aktif.*

### 2. Menjalankan Backend Lokal (Cloudflare Worker)
```bash
# Masuk ke direktori worker
cd worker

# Install dependencies
npm install

# Buat file rahasia lokal .dev.vars
cp .dev.vars.example .dev.vars

# Terapkan skema database lokal
npx wrangler d1 migrations apply DB --local

# Jalankan server lokal
npm run dev
```

---

## Keamanan & Privasi
* **Privasi Siswa Terjamin**: Siswa dapat memilih untuk melapor sebagai **Anonim**. Identitas siswa disamarkan pada antarmuka Guru BK.
* **Terenkripsi**: Komunikasi data menggunakan protokol HTTPS/TLS dan autentikasi berbasis stateless JWT token.
* **Isolasi Multi-Tenant**: Akses antar sekolah diisolasi melalui validasi `X-School-Id` pada header setiap request API.

---

## Lisensi
Hak Cipta © 2026 **SuaraSiswa Project**. Dilindungi undang-undang.
