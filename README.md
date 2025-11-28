# TASK TEAM MANAGER

Hệ thống quản lý dự án và công việc toàn diện cho các nhóm làm việc

---

## MỤC LỤC

1. [Giới Thiệu](#giới-thiệu)
2. [Kiến Trúc Hệ Thống](#kiến-trúc-hệ-thống)
3. [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)
4. [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
5. [Cài Đặt](#cài-đặt)
6. [Chạy Ứng Dụng](#chạy-ứng-dụng)
7. [API Endpoints](#api-endpoints)
8. [Cấu Trúc Thư Mục](#cấu-trúc-thư-mục)
9. [Tính Năng Chính](#tính-năng-chính)
10. [Hướng Dẫn Sử Dụng](#hướng-dẫn-sử-dụng)
11. [Bảo Mật](#bảo-mật)
12. [Troubleshooting](#troubleshooting)

---

## GIỚI THIỆU

**Task Team Manager** là ứng dụng quản lý dự án và công việc hiện đại, cung cấp các tính năng:

- Tạo và quản lý các dự án
- Phân công và theo dõi công việc
- Quản lý nhân viên và phân quyền
- Ghi nhận hoạt động và thống kê
- Giao tiếp thời gian thực qua chat

---

## KIẾN TRÚC HỆ THỐNG

```
┌─────────────────────────────────────────────────────┐
│       Task Team Frontend Mobile (Flutter)           │
│            (iOS, Android, Web Support)              │
└────────────────────────┬────────────────────────────┘
                         │
                    HTTP/HTTPS
                         │
┌────────────────────────▼────────────────────────────┐
│           Task Team Backend (Node.js)               │
│                                                     │
│   - REST API                                        │
│   - WebSocket (Socket.io)                          │
│   - Real-time Notifications                        │
└────────────────────────┬────────────────────────────┘
                         │
                     MongoDB
                         │
┌────────────────────────▼────────────────────────────┐
│              Database (MongoDB)                     │
│                                                     │
│   - Users & Authentication                          │
│   - Projects & Tasks                               │
│   - Employees & Roles                              │
│   - Messages & Notifications                       │
│   - Activity Logs                                  │
└─────────────────────────────────────────────────────┘
```

---

## CÔNG NGHỆ SỬ DỤNG

### Frontend Mobile

| Công Nghệ              | Mục Đích                               |
| ---------------------- | -------------------------------------- |
| **Flutter 3.x**        | Cross-platform mobile development      |
| **Dart**               | Programming language                   |
| **Provider**           | State management                       |
| **HTTP**               | RESTful API client                     |
| **Socket.io Client**   | Real-time communication                |
| **Intl**               | Internationalization & date formatting |
| **Image Picker**       | Select images from device              |
| **File Picker**        | Select files                           |
| **Shared Preferences** | Local storage                          |

### Backend

| Công Nghệ      | Mục Đích                |
| -------------- | ----------------------- |
| **Node.js**    | JavaScript runtime      |
| **Express.js** | Web framework           |
| **MongoDB**    | NoSQL database          |
| **Mongoose**   | ODM for MongoDB         |
| **JWT**        | Authentication          |
| **Socket.io**  | Real-time communication |
| **Bcrypt**     | Password hashing        |

### DevOps & Tools

- **Git** - Version control

---

### Công cụ sử dụng

- **VS Code** - Công cụ code cùng với các extension

### Extension sử dụng cho VS Code

- **Dart** - Ngôn ngữ lập trình cho mobile
- **Flutter** - Framework cho Dart
- **Path Intellisense**
- **Prettier**
- **Pubspec Assist**

---

---

## YÊU CẦU HỆ THỐNG

- Flutter SDK 3.27.4
- Dart SDK: 3.6.2
- Node.js: v22.19.0
- MongoDB: mongosh --version 2.5.7
- Android SDK (cho phát triển Android) Platform android-36, build-tools 36.0.0
- Xcode (cho phát triển iOS - chỉ trên macOS)
- Java JDK-17

---

## CÀI ĐẶT

### **1. Cài Đặt Frontend Mobile**

```bash
# Clone repository
git clone <repository-url>
cd task_team_frontend_mobile

# Cài đặt dependencies
flutter pub get

# Tạo file .env từ .env.example
cp .env.example .env

# Cấu hình API endpoint trong .env
# Ví dụ: API_BASE_URL=http://10.0.2.2:3000/api

# Chạy code generation (nếu cần)
flutter pub run build_runner build
```

### **2. Cài Đặt Backend**

```bash
# Clone repository
git clone <backend-repository-url>
cd task_team_backend

# Cài đặt dependencies
npm install

# Tạo file .env
cp .env.example .env

# Cấu hình biến môi trường:
# MONGODB_URI=mongodb://localhost:27017/yourdatabase
# JWT_SECRET=your_jwt_secret_key
# NODE_ENV=development
# PORT=5000

# Chạy seeding database (optional)
npm run seed

# Khởi động server
npm start
```

---

## CHẠY ỨNG DỤNG

### **Frontend Mobile**

```bash
# Development mode
flutter run

# Release mode (Android)
flutter build apk --release
flutter install

# Release mode (iOS)
flutter build ios --release

# Build web
flutter build web
```

### **Backend**

```bash
# Development mode
npm run dev hoặc node server.js

# Production mode
npm start

# Chạy tests
npm test
```

---

## API ENDPOINTS

### **Authentication**

```
POST   /api/auth/login          - Đăng nhập
POST   /api/auth/register       - Đăng ký
POST   /api/auth/refresh-token  - Refresh token
POST   /api/auth/logout         - Đăng xuất
```

### **Projects**

```
GET    /api/projects            - Lấy tất cả dự án
GET    /api/projects/:id        - Lấy chi tiết dự án
POST   /api/projects            - Tạo dự án mới
PUT    /api/projects/:id        - Cập nhật dự án
DELETE /api/projects/:id        - Xóa dự án
DELETE /api/projects            - Xóa tất cả dự án
```

### **Tasks**

```
GET    /api/tasks               - Lấy tất cả công việc
GET    /api/tasks/:id           - Lấy chi tiết công việc
POST   /api/tasks               - Tạo công việc mới
PUT    /api/tasks/:id           - Cập nhật công việc
DELETE /api/tasks/:id           - Xóa công việc
PUT    /api/tasks/:id/status    - Cập nhật trạng thái
```

### **Employees**

```
GET    /api/employees           - Lấy tất cả nhân viên
GET    /api/employees/:id       - Lấy chi tiết nhân viên
POST   /api/employees           - Tạo nhân viên mới
PUT    /api/employees/:id       - Cập nhật nhân viên
DELETE /api/employees/:id       - Xóa nhân viên
```

### **Messages**

```
GET    /api/messages/:conversationId  - Lấy tin nhắn
POST   /api/messages                  - Gửi tin nhắn
```

### **Activity Logs**

```
GET    /api/activity-logs        - Lấy nhật ký hoạt động
GET    /api/activity-logs/:taskId - Lấy nhật ký theo task
```

---

## CẤU TRÚC THƯ MỤC

### **Frontend Mobile**

```
lib/
│
├── main.dart                           # Entry point
│
├── config/
│   ├── api_config.dart                 # API configuration
│   └── env.dart                        # Environment variables
│
├── models/
│   ├── project_model.dart
│   ├── task_model.dart
│   ├── employee_model.dart
│   └── ...
│
├── providers/
│   ├── auth_provider.dart
│   ├── project_provider.dart
│   ├── task_provider.dart
│   ├── employee_provider.dart
│   └── ...
│
├── services/
│   ├── project_service.dart
│   ├── task_service.dart
│   ├── auth_service.dart
│   └── ...
│
├── screens/
│   ├── login_screen.dart
│   │
│   ├── manager/
│   │   ├── list_project_screen.dart
│   │   ├── detail_project_screen.dart
│   │   ├── add_project_screen.dart
│   │   ├── add_task_screen.dart
│   │   └── manager_detail_task_screen.dart
│   │
│   └── employee/
│       └── ...
│
├── widgets/
│   └── custom_widgets.dart
│
└── assets/
    └── images/
```

### **Backend**

```
backend/
│
├── server.js                           # Entry point
│
├── config/
│   └── index.js
│
├── models/
│   ├── employee.model.js
│   ├── project.model.js
│   ├── task.model.js
│   ├── task_types.model.js
│   └── ...
│
├── routes/
│   ├── auth.route.js
│   ├── projects.route.js
│   ├── tasks.route.js
│   ├── employees.route.js
│   └── ...
│
├── controllers/
│   ├── auth.controller.js
│   ├── project.controller.js
│   ├── task.controller.js
│   └── ...
│
├── middleware/
│   ├── auth.middleware.js
│   ├── upload.middleware.js
│   └── ...
│
├── services/
│   ├── projects.service.js
│   └── ...
│
└── .env.example
```

---

## TÍNH NĂNG CHÍNH

### **1. Quản Lý Người Dùng**

- Đăng nhập/Đăng ký
- JWT authentication
- Phân quyền (Roles & Permissions)
- Profile management
- Password reset

### **2. Quản Lý Dự Án**

- Tạo/Chỉnh sửa/Xóa dự án
- Xem danh sách dự án
- Phân công người quản lý
- Theo dõi tiến độ
- Thống kê dự án

### **3. Quản Lý Công Việc**

- Tạo/Chỉnh sửa/Xóa công việc
- Phân công công việc cho nhân viên
- Cập nhật trạng thái (New, In Progress, Done, Overdue, etc.)
- Đặt priority (High, Medium, Low)
- Deadline tracking
- Attachment support

### **4. Quản Lý Nhân Viên**

- Quản lý danh sách nhân viên
- Phân quyền người dùng
- Theo dõi hoạt động nhân viên
- Xem kỹ năng & chuyên môn

### **5. Giao Tiếp Thời Gian Thực**

- Chat giữa các thành viên
- Thảo luận công việc
- Notifications
- Activity logs

### **6. Báo Cáo & Thống Kê**

- Thống kê công việc hoàn thành
- Báo cáo tiến độ dự án
- Lịch sử hoạt động
- Performance metrics

---

## HƯỚNG DẪN SỬ DỤNG

### **Quản Lý Dự Án**

**Tạo dự án mới:**

1. Nhấn nút "+" trên màn hình danh sách dự án
2. Nhập thông tin: ID, Tên, Mô tả
3. Chọn người quản lý
4. Đặt ngày bắt đầu và kết thúc
5. Nhấn "Lưu"

**Chỉnh sửa dự án:**

1. Nhấn vào dự án cần chỉnh sửa
2. Sửa thông tin cần thiết
3. Nhấn "Cập nhật"

**Xóa dự án:**

1. Nhấn vào dự án
2. Nhấn nút xóa
3. Xác nhận xóa

### **Quản Lý Công Việc**

**Tạo công việc:**

1. Vào chi tiết dự án
2. Nhấn "Thêm công việc"
3. Nhập thông tin chi tiết
4. Chọn người phụ trách
5. Nhấn "Tạo"

**Cập nhật trạng thái:**

1. Mở chi tiết công việc
2. Chọn trạng thái mới từ dropdown
3. Lưu thay đổi

### **Chat & Thảo Luận**

**Gửi tin nhắn:**

1. Vào màn hình Chat
2. Chọn người hoặc nhóm cần chat
3. Nhập tin nhắn
4. Nhấn gửi

---

## BẢO MẬT

Hệ thống được bảo vệ bởi các lớp bảo mật sau:

- JWT token authentication
- Password hashing with bcrypt
- Input validation
- Rate limiting

---

## TROUBLESHOOTING

### **Frontend Issues**

**API Connection Failed:**

```bash
# Kiểm tra cấu hình API trong .env
cat .env
```

**Build Error:**

```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter run
```

### **Backend Issues**

**MongoDB Connection Error:**

```bash
# Kiểm tra connection string trong .env
# Đảm bảo MongoDB đang chạy
```

---

## THÔNG TIN PHIÊN BẢN

- **Version:** 1.0.0
- **Last Updated:** November 28, 2025

---
