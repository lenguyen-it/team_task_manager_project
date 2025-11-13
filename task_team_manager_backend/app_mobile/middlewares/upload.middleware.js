const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Tạo thư mục uploads/files nếu chưa có
const uploadFileDir = "uploads/files";
if (!fs.existsSync(uploadFileDir)) {
  fs.mkdirSync(uploadFileDir, { recursive: true });
}

const uploadImageDir = "uploads/images";
if (!fs.existsSync(uploadImageDir)) {
  fs.mkdirSync(uploadImageDir, { recursive: true });
}

// Cấu hình storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadFileDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    const nameWithoutExt = path.basename(file.originalname, ext);
    cb(null, `${nameWithoutExt}-${uniqueSuffix}${ext}`);
  },
});

// Giới hạn loại file và kích thước
const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    "image/jpeg",
    "image/png",
    "image/gif",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/plain",
    "application/zip",
    "application/x-rar-compressed",
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new Error(
        "Invalid file type. Only images, PDF, Word, Excel, text, and archive files are allowed."
      ),
      false
    );
  }
};

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadImageDir);
  },
  filename: (req, file, cb) => {
    const employeeId =
      req.employee?.employeeId || req.body.employeeId || "unknown";
    const ext = path.extname(file.originalname).toLowerCase();
    const timestamp = Date.now();

    cb(null, `avatar-${employeeId}-${timestamp}${ext}`);
  },
});

const avatarFileFilter = (req, file, cb) => {
  const allowedTypes = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/gif",
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Chỉ chấp nhận file ảnh: JPEG, PNG, WebP, GIF"), false);
  }
};

const uploadAvatar = multer({
  storage: avatarStorage,
  limits: {
    fileSize: 2 * 1024 * 1024, // 2MB
  },
  fileFilter: avatarFileFilter,
}).single("avatar");

// Cấu hình multer
const uploadFile = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
  },
  fileFilter: fileFilter,
});

module.exports = {
  uploadFile,
  uploadAvatar,
};
