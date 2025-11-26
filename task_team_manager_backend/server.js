// require("dotenv").config();

// const app = require("./app_mobile");
// const config = require("./app_mobile/config");
// const MongoDB = require("./app_mobile/utils/mongodb.util");

// if (!process.env.JWT_SECRET) {
//   console.error("FATAL ERROR: JWT_SECRET is not defined.");
//   process.exit(1);
// }

// async function startServer() {
//   try {
//     await MongoDB.connect(config.db.url);
//     console.log("Connect to the database!");

//     const PORT = config.app.port;
//     app.listen(PORT, () => {
//       console.log(`Server is running on port ${PORT}`);
//     });
//   } catch (error) {
//     console.log("Cannot connect to the database!", error);
//     process.exit();
//   }
// }

// startServer();

require("dotenv").config();
const app = require("./app_mobile");
const config = require("./app_mobile/config");
const mongoose = require("mongoose");
const http = require("http");
const { initSocket } = require("./app_mobile/sockets/socket.js");

if (!process.env.JWT_SECRET) {
  console.error("FATAL ERROR: JWT_SECRET is not defined.");
  process.exit(1);
}

async function startServer() {
  try {
    await mongoose.connect(config.db.url, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log("Connected to MongoDB via Mongoose!");

    // Tạo HTTP server từ Express app
    const server = http.createServer(app);

    // Khởi tạo Socket.IO
    initSocket(server);

    const PORT = config.app.port || 3000;

    server.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
      console.log(`Socket.IO is ready!`);
    });
  } catch (error) {
    console.error("Cannot connect to the database!", error);
    process.exit(1);
  }
}

startServer();
