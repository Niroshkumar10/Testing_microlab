const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const upload = require("../middleware/upload"); // ❌ this line is missing in your file!

const {
  createStudent,
  getStudents,
  updateStudent,
  deleteStudent,
  uploadStudentImage
} = require("../controllers/studentController");

router.post("/",                auth, upload.single("profileImage"), createStudent);
router.get("/",                 auth, getStudents);
router.put("/:id",              auth, updateStudent);
router.delete("/:id",           auth, deleteStudent);
router.put("/:id/upload-image", auth, upload.single("profileImage"), uploadStudentImage);

module.exports = router;