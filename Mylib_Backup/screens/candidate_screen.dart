import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data.dart';
import '../services/supabase_service.dart';
import 'camera_capture_screen.dart';

class CandidateScreen extends StatefulWidget {
  const CandidateScreen({super.key});

  @override
  State<CandidateScreen> createState() => _CandidateScreenState();
}

class _CandidateScreenState extends State<CandidateScreen> {
  final employeeCodeController = TextEditingController();

  final appraiseeController = TextEditingController();

  final departmentController = TextEditingController();

  final productController = TextEditingController();

  Uint8List? selectedImage;

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      selectedImage = bytes;
    });

    // Keep the selected photo available for the
    // current ARR session.
    AppData.candidatePhoto = bytes;
  }

  Future<void> saveCandidatePhoto({
    required String employeeId,
    required String employeeCode,
    required Uint8List bytes,
  }) async {
    final employee =
    await SupabaseService.saveEmployeePhoto(
      employeeId: employeeId,
      employeeCode: employeeCode,
      bytes: bytes,
    );

    final photoPath =
    employee['photo_path']?.toString();

    AppData.candidatePhoto = bytes;

    AppData.candidatePhotoPath =
        photoPath ?? '';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        toolbarHeight: 72,

        titleSpacing: 28,

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Color(0xFF3155C6),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New ARR",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                    height: 1.1,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Candidate information",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7A8494),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1180,
            ),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                28,
                28,
                28,
                36,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // PAGE INTRO
                  const Text(
                    "Candidate Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Enter the candidate information and capture a photo before starting the ARR assessment.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MAIN CARD
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(16),

                      border: Border.all(
                        color: const Color(0xFFE1E5EA),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.025,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        // FORM SECTION
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              const Text(
                                "Candidate Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  Color(0xFF202124),
                                ),
                              ),

                              const SizedBox(height: 5),

                              const Text(
                                "Provide the details exactly as they appear in the employee record.",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                  Color(0xFF7A8494),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [

                                  Expanded(
                                    child: _buildField(
                                      controller:
                                      employeeCodeController,
                                      label:
                                      "Employee Code",
                                      hint:
                                      "Enter employee code",
                                      icon:
                                      Icons.badge_outlined,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: _buildField(
                                      controller:
                                      appraiseeController,
                                      label:
                                      "Appraisee Name",
                                      hint:
                                      "Enter candidate name",
                                      icon:
                                      Icons.person_outline,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [

                                  Expanded(
                                    child: _buildField(
                                      controller:
                                      departmentController,
                                      label:
                                      "Department",
                                      hint:
                                      "Enter department",
                                      icon:
                                      Icons.business_outlined,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: _buildField(
                                      controller:
                                      productController,
                                      label:
                                      "Product Name",
                                      hint:
                                      "Enter product name",
                                      icon:
                                      Icons
                                          .inventory_2_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 30),

                        // PHOTO SECTION
                        Container(
                          width: 285,

                          padding:
                          const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFF8F9FC),
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(
                              color:
                              const Color(0xFFE3E7ED),
                            ),
                          ),

                          child: Column(
                            children: [

                              const Align(
                                alignment:
                                Alignment.centerLeft,
                                child: Text(
                                  "Candidate Photo",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    Color(0xFF202124),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Align(
                                alignment:
                                Alignment.centerLeft,
                                child: Text(
                                  "Use a clear identification photo.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                    Color(0xFF7A8494),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Container(
                                width: 150,
                                height: 150,

                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFFEFF2F7),
                                  borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                                  border: Border.all(
                                    color:
                                    const Color(
                                      0xFFD9DEE7,
                                    ),
                                  ),
                                ),

                                child:
                                selectedImage == null
                                    ? const Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  children: [

                                    Icon(
                                      Icons
                                          .person_outline,
                                      size: 48,
                                      color:
                                      Color(
                                        0xFF9AA3B2,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 8,
                                    ),

                                    Text(
                                      "No photo",
                                      style:
                                      TextStyle(
                                        fontSize: 11,
                                        color:
                                        Color(
                                          0xFF7A8494,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                    : ClipRRect(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    13,
                                  ),
                                  child:
                                  Image.memory(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [

                                  Expanded(
                                    child:
                                    OutlinedButton.icon(
                                      onPressed:
                                      pickFromGallery,
                                      icon: const Icon(
                                        Icons
                                            .photo_library_outlined,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        "Gallery",
                                      ),
                                      style:
                                      OutlinedButton.styleFrom(
                                        foregroundColor:
                                        const Color(
                                          0xFF3155C6,
                                        ),
                                        side:
                                        const BorderSide(
                                          color:
                                          Color(
                                            0xFFD5DCE8,
                                          ),
                                        ),
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                          vertical: 12,
                                        ),
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                            9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child:
                                    OutlinedButton.icon(
onPressed: () async {
final imageBytes =
await Navigator.push<Uint8List>(
context,
MaterialPageRoute(
builder: (_) =>
const CameraCaptureScreen(),
),
);

if (imageBytes == null ||
imageBytes.isEmpty) {
return;
}

if (!mounted) {
return;
}

setState(() {
selectedImage = imageBytes;
});

AppData.candidatePhoto =
imageBytes;
},
                                      icon: const Icon(
                                        Icons
                                            .camera_alt_outlined,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        "Camera",
                                      ),
                                      style:
                                      OutlinedButton.styleFrom(
                                        foregroundColor:
                                        const Color(
                                          0xFF3155C6,
                                        ),
                                        side:
                                        const BorderSide(
                                          color:
                                          Color(
                                            0xFFD5DCE8,
                                          ),
                                        ),
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                          vertical: 12,
                                        ),
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                            9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ACTION CARD
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE1E5EA),
                      ),
                    ),

                    child: Row(
                      children: [

                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFEAF0FF),
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color:
                            Color(0xFF3155C6),
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Ready to continue?",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  Color(0xFF202124),
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
                                "Review the entered information before selecting the assessment batch.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                  Color(0xFF7A8494),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: 210,
                          height: 46,

                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final employeeCode =
                              employeeCodeController.text.trim();

                              final appraisee =
                              appraiseeController.text.trim();

                              final department =
                              departmentController.text.trim();

                              final product =
                              productController.text.trim();

                              // ----------------------------------------------------------
                              // BASIC VALIDATION
                              // ----------------------------------------------------------

                              if (employeeCode.isEmpty ||
                                  appraisee.isEmpty ||
                                  department.isEmpty ||
                                  product.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please fill all candidate details.",
                                    ),
                                  ),
                                );

                                return;
                              }

                              try {
                                // --------------------------------------------------------
                                // FIND EMPLOYEE
                                // --------------------------------------------------------

                                Map<String, dynamic>? employee =
                                await SupabaseService.getEmployeeByCode(
                                  employeeCode,
                                );

                                // --------------------------------------------------------
                                // CREATE OR UPDATE EMPLOYEE
                                // --------------------------------------------------------

                                if (employee == null) {
                                  employee =
                                  await SupabaseService.createEmployee(
                                    employeeCode: employeeCode,
                                    fullName: appraisee,
                                    department: department,
                                    product: product,
                                  );
                                } else {
                                  final employeeId =
                                  employee['employee_id']?.toString();

                                  if (employeeId == null ||
                                      employeeId.isEmpty) {
                                    throw Exception(
                                      "Employee ID is missing.",
                                    );
                                  }

                                  employee =
                                  await SupabaseService.updateEmployee(
                                    employeeId: employeeId,
                                    fullName: appraisee,
                                    department: department,
                                    product: product,
                                  );
                                }

                                // --------------------------------------------------------
                                // EMPLOYEE ID
                                // --------------------------------------------------------

                                final employeeId =
                                employee['employee_id']?.toString();

                                if (employeeId == null ||
                                    employeeId.isEmpty) {
                                  throw Exception(
                                    "Employee ID is missing.",
                                  );
                                }

                                // --------------------------------------------------------
                                // SAVE / REPLACE PHOTO
                                // --------------------------------------------------------

                                if (selectedImage != null) {
                                  await saveCandidatePhoto(
                                    employeeId: employeeId,
                                    employeeCode: employeeCode,
                                    bytes: selectedImage!,
                                  );
                                }

                                // --------------------------------------------------------
                                // SAVE CURRENT ARR SESSION
                                // --------------------------------------------------------

                                AppData.employeeCode =
                                    employeeCode;

                                AppData.appraiseeName =
                                    appraisee;

                                AppData.department =
                                    department;

                                AppData.productName =
                                    product;

                                // --------------------------------------------------------
                                // CONTINUE
                                // --------------------------------------------------------

                                if (!mounted) {
                                  return;
                                }

                                Navigator.pushNamed(
                                  context,
                                  "/ARR/batch",

                                );
                              } catch (e) {
                                if (!mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Unable to save candidate: $e",
                                    ),
                                    duration:
                                    const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },

                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),

                            label: const Text(
                              "Continue to Batch Selection",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF3155C6,
                              ),
                              foregroundColor:
                              Colors.white,
                              elevation: 0,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 19,
        ),

        filled: true,
        fillColor: const Color(0xFFFAFBFD),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        labelStyle: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF5F6875),
        ),

        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFA0A7B2),
        ),

        prefixIconColor:
        const Color(0xFF6B7280),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFFDDE2E8),
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFF3155C6),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
