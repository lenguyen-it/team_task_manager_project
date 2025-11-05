require("dotenv").config();

const app = require("./app_mobile");
const config = require("./app_mobile/config");
const MongoDB = require("./app_mobile/utils/mongodb.util");

if (!process.env.JWT_SECRET) {
  console.error("FATAL ERROR: JWT_SECRET is not defined.");
  process.exit(1);
}

async function startServer() {
  try {
    await MongoDB.connect(config.db.url);
    console.log("Connect to the database!");

    const PORT = config.app.port;
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  } catch (error) {
    console.log("Cannot connect to the database!", error);
    process.exit();
  }
}

startServer();
