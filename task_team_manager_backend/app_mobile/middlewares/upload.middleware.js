const multer = require("multer");
const path = require("path");
const fs = require("fs");

const uploadFileDir = "uploads/files";
const uploadImageDir = "uploads/images";

[uploadFileDir, uploadImageDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

const fileStorage = multer.diskStorage({
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

const uploadFile = multer({
  storage: fileStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: fileFilter,
});

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadImageDir);
  },
  filename: (req, file, cb) => {
    const employeeId =
      req.body.employee_id ||
      req.params.employee_id ||
      req.employee?.employee_id ||
      "unknown";

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
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
  fileFilter: avatarFileFilter,
}).single("avatar");

module.exports = {
  uploadFile,
  uploadAvatar,
};
