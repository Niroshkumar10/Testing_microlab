import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../location_picker.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  bool isLoading = true;
  List students = [];
  String searchQuery = "";

  // ── Theme colours (matches screenshot)
  static const Color _primary = Color(0xFF1A3A6B);
  static const Color _accent = Color(0xFF4A90D9);
  static const Color _bgCard = Colors.white;
  static const Color _bgPage = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  // ── Resolve image URL per platform
  String getImageUrl(String path) {
    if (kIsWeb) return "http://localhost:5000$path";
    return "http://10.0.2.2:5000$path"; // adb reverse
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);
    final data = await ApiService.getStudents();
    setState(() {
      students = data is List ? data : [];
      isLoading = false;
    });
  }

  // ── Filtered list
  List get filteredStudents {
    if (searchQuery.isEmpty) return students;
    final q = searchQuery.toLowerCase();
    return students.where((s) {
      return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
          (s['mobileNumber'] ?? '').toString().contains(q) ||
          (s['address'] ?? '').toString().toLowerCase().contains(q) ||
          (s['locationAddress'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  // ── Stats
  int get totalCount => students.length;
  int get withLocationCount =>
      students.where((s) => s['latitude'] != null).length;

  // ── Avatar initials
  String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Show location bottom sheet (map preview + actions)
  void showLocationSheet(dynamic student) {
    final lat = (student['latitude'] as num).toDouble();
    final lng = (student['longitude'] as num).toDouble();
    final label = student['locationAddress'] ?? student['address'] ?? '';
    final name = student['name'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _primary,
                child: Text(initials(name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (label.isNotEmpty)
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // ── Map preview using Google Static Maps
          Expanded(
            child: ClipRRect(
              child: Image.network(
                'https://maps.googleapis.com/maps/api/staticmap'
                '?center=$lat,$lng'
                '&zoom=15'
                '&size=600x400'
                '&markers=color:red%7C$lat,$lng'
                '&key=YOUR_GOOGLE_MAPS_API_KEY', // 🔴 replace with your key
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _mapFallback(lat, lng),
              ),
            ),
          ),

          // ── Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Open in Maps
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.open_in_new, color: _primary, size: 18),
                  label: const Text("Open in Maps",
                      style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Navigate
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 18),
                  label: const Text("Navigate",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  onPressed: () async {
                    Navigator.pop(context);
                    // Try Google Maps app first
                    final googleNav = Uri.parse(
                        'google.navigation:q=$lat,$lng&mode=d');
                    final browserNav = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
                    if (await canLaunchUrl(googleNav)) {
                      await launchUrl(googleNav);
                    } else {
                      await launchUrl(browserNav,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Fallback when no API key — shows pin on colored background
  Widget _mapFallback(double lat, double lng) {
    return Container(
      color: const Color(0xFFE8EDF5),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text('$lat, $lng',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ]),
      ),
    );
  }

  // ── Pick & upload image
  Future<void> pickAndUploadImage(String studentId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;
    await ApiService.uploadStudentImage(studentId, picked);
    fetchStudents();
  }

  // ── Delete with confirm dialog
  void confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Student"),
        content: Text("Are you sure you want to delete \"$name\"?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.deleteStudent(id);
              fetchStudents();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student deleted")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Add student dialog
  void showAddDialog() {
    final name = TextEditingController();
    final age = TextEditingController();
    final dept = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();

    double? selLat, selLng;
    String? selLocAddress;
    bool loading = false;
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Student",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (picked != null) setD(() => pickedImage = picked);
                },
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: _primary.withOpacity(0.1),
                  backgroundImage: pickedImage != null
                      ? (kIsWeb
                          ? NetworkImage(pickedImage!.path)
                          : FileImage(File(pickedImage!.path)) as ImageProvider)
                      : null,
                  child: pickedImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 32, color: _primary)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _field(name, "Name", Icons.person),
              const SizedBox(height: 10),
              _field(age, "Age", Icons.cake,
                  type: TextInputType.number),
              const SizedBox(height: 10),
              _field(dept, "Department", Icons.school),
              const SizedBox(height: 10),
              _field(mobile, "Mobile Number", Icons.phone,
                  type: TextInputType.phone),
              const SizedBox(height: 10),
              _field(address, "Address", Icons.home, maxLines: 2),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => LocationPicker(
                          initialLatitude: selLat,
                          initialLongitude: selLng,
                          initialAddress: selLocAddress,
                          onLocationSelected: (lat, lng, addr) {
                            selLat = lat;
                            selLng = lng;
                            selLocAddress = addr;
                            setD(() {});
                          },
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                      selLat != null ? Icons.location_on : Icons.add_location,
                      color: _primary),
                  label: Text(
                    selLat != null ? "Location Added ✓" : "Add Map Location",
                    style: const TextStyle(color: _primary),
                  ),
                ),
              ),
              if (selLocAddress != null) ...[
                const SizedBox(height: 8),
                Text(selLocAddress!,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (name.text.isEmpty ||
                          age.text.isEmpty ||
                          dept.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content:
                                Text("Please fill all required fields")));
                        return;
                      }
                      setD(() => loading = true);
                      final result = await ApiService.addStudent({
                        "name": name.text,
                        "age": age.text,
                        "department": dept.text,
                        "mobileNumber": mobile.text,
                        "address": address.text,
                        "latitude": selLat,
                        "longitude": selLng,
                        "locationAddress": selLocAddress,
                      });
                      if (pickedImage != null &&
                          result != null &&
                          result['_id'] != null) {
                        await ApiService.uploadStudentImage(
                            result['_id'], pickedImage!);
                      }
                      Navigator.pop(ctx);
                      fetchStudents();
                    },
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("Add",
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit student dialog
  void showEditDialog(student) {
    final name = TextEditingController(text: student['name']);
    final age =
        TextEditingController(text: student['age']?.toString() ?? '');
    final dept =
        TextEditingController(text: student['department'] ?? '');
    final mobile =
        TextEditingController(text: student['mobileNumber'] ?? '');
    final address =
        TextEditingController(text: student['address'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Student",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(name, "Name", Icons.person),
            const SizedBox(height: 10),
            _field(age, "Age", Icons.cake, type: TextInputType.number),
            const SizedBox(height: 10),
            _field(dept, "Department", Icons.school),
            const SizedBox(height: 10),
            _field(mobile, "Mobile Number", Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 10),
            _field(address, "Address", Icons.home, maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await ApiService.updateStudent(student['_id'], {
                "name": name.text,
                "age": int.tryParse(age.text) ?? 0,
                "department": dept.text,
                "mobileNumber": mobile.text,
                "address": address.text,
              });
              Navigator.pop(context);
              fetchStudents();
            },
            child: const Text("Update",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Reusable text field
  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Customers",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () {}, // future: toggle grid/list
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Customer",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── Stats row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  _statCard("Total", totalCount.toString(),
                      Icons.people_alt_rounded, const Color(0xFFE8F5F0),
                      const Color(0xFF2E9E6E)),
                  const SizedBox(width: 12),
                  _statCard("With Location", withLocationCount.toString(),
                      Icons.location_on_rounded, const Color(0xFFEAEEF8),
                      _accent),
                ]),
              ),

              // ── Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by name, mobile, or address",
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.black38),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                ),
              ),
              const SizedBox(height: 10),

              // ── Student list
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(
                        child: Text("No students found",
                            style: TextStyle(color: Colors.black38)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filteredStudents.length,
                        itemBuilder: (_, i) =>
                            _studentCard(filteredStudents[i]),
                      ),
              ),
            ]),
    );
  }

  // ── Stat card widget
  Widget _statCard(String label, String value, IconData icon,
      Color bg, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.1)),
          ]),
        ]),
      ),
    );
  }

  // ── Student card widget
  Widget _studentCard(dynamic student) {
    final hasLocation =
        student['latitude'] != null && student['longitude'] != null;
    final lat = hasLocation ? (student['latitude'] as num).toDouble() : 0.0;
    final lng = hasLocation ? (student['longitude'] as num).toDouble() : 0.0;
    final locLabel =
        student['locationAddress'] ?? student['address'] ?? '';
    final hasImage = student['profileImage'] != null &&
        student['profileImage'] != '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          GestureDetector(
            onTap: () => pickAndUploadImage(student['_id']),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _primary,
              backgroundImage: hasImage
                  ? NetworkImage(getImageUrl(student['profileImage']))
                  : null,
              child: !hasImage
                  ? Text(initials(student['name'] ?? ''),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(student['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 4),

                  // Phone
                  if (student['mobileNumber'] != null &&
                      student['mobileNumber'] != '') ...[
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 13, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(student['mobileNumber'],
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ]),
                    const SizedBox(height: 3),
                  ],

                  // Address
                  if (locLabel.isNotEmpty) ...[
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.black45),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(locLabel,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 6),
                  ],

                  // Location saved badge
                  if (hasLocation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accent.withOpacity(0.3), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_on,
                            size: 12, color: _accent),
                        const SizedBox(width: 4),
                        Text("Location saved",
                            style: TextStyle(
                                fontSize: 11,
                                color: _accent,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),

                  const SizedBox(height: 10),

                  // Action buttons
                  Row(children: [
                    // Navigate (opens sheet)
                    _actionBtn(
                      icon: Icons.navigation_rounded,
                      color: _primary,
                      enabled: hasLocation,
                      onTap: () => showLocationSheet(student),
                    ),
                    const SizedBox(width: 8),

                    // View on map (opens sheet)
                    _actionBtn(
                      icon: Icons.location_on_rounded,
                      color: _accent,
                      enabled: hasLocation,
                      onTap: () => showLocationSheet(student),
                    ),
                    const SizedBox(width: 8),

                    // Edit
                    _actionBtn(
                      icon: Icons.edit_rounded,
                      color: Colors.orange,
                      onTap: () => showEditDialog(student),
                    ),
                    const SizedBox(width: 8),

                    // Delete
                    _actionBtn(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onTap: () =>
                          confirmDelete(student['_id'], student['name'] ?? ''),
                    ),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }

  // ── Small icon action button
  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18, color: enabled ? color : Colors.grey.shade300),
      ),
    );
  }
}