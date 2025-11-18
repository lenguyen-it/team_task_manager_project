const express = require("express");
const router = express.Router();
const ActivityLogController = require("../controllers/activitylog.controller");

router.route("/").get(ActivityLogController.getLogs);

module.exports = router;
