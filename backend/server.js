// const express = require("express");
// const mongoose = require("mongoose");
// const cors = require("cors");

// const userRoutes = require("./routes/userRoutes");
// const authRoutes = require("./routes/authRoutes");
// const studentRoutes = require("./routes/studentRoutes");

// const app = express();

// // ✅ CORS (this alone is enough)
// app.use(cors({
//   origin: "*",
//   methods: ["GET", "POST", "PUT", "DELETE"],
//   allowedHeaders: ["Content-Type", "Authorization"]
// }));

// app.use(express.json());

// // MongoDB
// mongoose.connect("mongodb://127.0.0.1:27017/myapp")
// .then(() => console.log("MongoDB Connected"))
// .catch(err => console.log(err));

// // Routes
// app.get("/", (req, res) => {
//   res.send("API Working");
// });

// app.use("/api/users", userRoutes);
// app.use("/api/auth", authRoutes);
// app.use("/api/students", studentRoutes);
// app.use("/uploads", express.static("uploads"));


// // Server
// app.listen(5000, () => {
//   console.log("Server running on port 5000");
// });

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const studentRoutes = require("./routes/studentRoutes");

const app = express();

// ✅ Wrap Express with HTTP server
const server = http.createServer(app);

// ✅ Socket.io setup
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// ✅ Express CORS
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());

// ✅ MongoDB Connection
mongoose.connect("mongodb://127.0.0.1:27017/myapp")
.then(() => console.log("✅ MongoDB Connected"))
.catch(err => console.log(err));


// ─────────────────────────────────────────────────────────
// ✅ SOCKET.IO LIVE TRACKING
// ─────────────────────────────────────────────────────────

io.on("connection", (socket) => {

  console.log("🟢 Socket Connected:", socket.id);

  // Viewer joins tracking room
  socket.on("join_tracking", (trackingId) => {

    socket.join(trackingId);

    console.log(`👁 Watching Tracking ID: ${trackingId}`);
  });

  // Driver sends live location
  socket.on("send_location", (data) => {

    // data = {
    //   trackingId,
    //   latitude,
    //   longitude,
    //   name
    // }

    io.to(data.trackingId).emit("location_update", data);

    console.log(
      `📍 ${data.name} → ${data.latitude}, ${data.longitude}`
    );
  });

  // Driver stopped tracking
  socket.on("stop_tracking", (data) => {

    io.to(data.trackingId).emit("tracking_stopped");

    console.log(`🛑 Tracking stopped: ${data.trackingId}`);
  });

  // Disconnect
  socket.on("disconnect", () => {

    console.log("🔴 Socket Disconnected:", socket.id);
  });
});


// ─────────────────────────────────────────────────────────
// ✅ API ROUTES
// ─────────────────────────────────────────────────────────

app.get("/", (req, res) => {
  res.send("API Working");
});

app.use("/api/users", userRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/uploads", express.static("uploads"));


// ─────────────────────────────────────────────────────────
// ✅ START SERVER
// ─────────────────────────────────────────────────────────

server.listen(5000, () => {
  console.log("🚀 Server running on port 5000");
});