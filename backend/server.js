const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const studentRoutes = require("./routes/studentRoutes");

const app = express();

// ✅ CORS (this alone is enough)
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());

// MongoDB
mongoose.connect("mongodb://127.0.0.1:27017/myapp")
.then(() => console.log("MongoDB Connected"))
.catch(err => console.log(err));

// Routes
app.get("/", (req, res) => {
  res.send("API Working");
});

app.use("/api/users", userRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/uploads", express.static("uploads"));


// Server
app.listen(5000, () => {
  console.log("Server running on port 5000");
});