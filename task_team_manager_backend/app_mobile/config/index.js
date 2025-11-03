const config = {
  app: {
    port: process.env.PORT || 3000,
  },

  db: {
    url: process.env.MONGO_URL || "mongodb://127.0.0.1:27017/team_task_manager",
  },
};

module.exports = config;