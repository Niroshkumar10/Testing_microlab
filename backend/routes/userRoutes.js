const express = require("express");
const router = express.Router();
const User = require("../models/User");

// Create user
router.post("/register", async (req, res) => {
      console.log("Incoming Data:", req.body); // 👈 IMPORTANT
  const user = new User(req.body);
  await user.save();
  res.json(user);
});

// Get users
router.get("/", async (req, res) => {
  const users = await User.find();
  res.json(users);
});

module.exports = router;