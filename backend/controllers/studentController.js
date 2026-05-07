const Student = require("../models/Student");

// ➕ Create (with optional image)
exports.createStudent = async (req, res) => {
  try {
    const {
      name,
      age,
      department,
      mobileNumber,
      address,
      latitude,
      longitude,
      locationAddress,   // ✅ add this
    } = req.body;

    const student = await Student.create({
      name,
      age,
      department,
      mobileNumber,
      address,
      latitude,          // ✅ flat — not nested in location: {}
      longitude,         // ✅ flat
      locationAddress,   // ✅ add this
      userId: req.user.id,
      profileImage: req.file
        ? `/uploads/${req.file.filename}`
        : "",
    });

    res.status(201).json(student);

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 📋 Get All
exports.getStudents = async (req, res) => {
  try {
    const students = await Student.find({ userId: req.user.id });
    res.json(students);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 🖼️ Upload / Update Profile Image
exports.uploadStudentImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    const student = await Student.findByIdAndUpdate(
      req.params.id,
      { profileImage: `/uploads/${req.file.filename}` },
      { new: true }
    );

    res.json(student);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ✏️ Update
exports.updateStudent = async (req, res) => {
  try {
    const student = await Student.findOneAndUpdate(
      {
        _id: req.params.id,
        userId: req.user.id
      },
      req.body,
      { new: true }
    );

    if (!student) {
      return res.status(404).json({
        message: "Student not found"
      });
    }

    res.json(student);

  } catch (err) {
    res.status(500).json({
      message: err.message
    });
  }
};

// 🗑️ Delete
exports.deleteStudent = async (req, res) => {
  try {
    await Student.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};