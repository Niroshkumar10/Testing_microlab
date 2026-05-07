const mongoose = require("mongoose");

const studentSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },

  age: {
    type: Number,
    required: true
  },

  department: {
    type: String,
    required: true
  },

  // ✅ NEW ADDRESS FIELD
  address: {
    type: String,
    default: ""
  },

  // ✅ MAP LOCATION
  latitude: {
    type: Number,
    default: null
  },

  longitude: {
    type: Number,
    default: null
  },

  // ✅ HUMAN READABLE LOCATION
  locationAddress: {
    type: String,
    default: ""
  },

  profileImage: {
    type: String,
    default: ""
  },

  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  }

}, { timestamps: true });

module.exports = mongoose.model("Student", studentSchema);