const express = require('express');
const ApiError = require("./app_mobile/api-error");



const app = express();

// app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  return next(new ApiError(404, "Resource not found"));
});

app.use((err, req, res, next) => {
  return res.status(err.statusCode || 500).json({
    message: err.message || "Internal Server Error",
  });
});

app.get('/', (req, res) => {
	res.json({ message: "Welcome to connect Server" });
});



module.exports = app;