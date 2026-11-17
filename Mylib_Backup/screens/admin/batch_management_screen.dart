import 'package:flutter/material.dart';

import '../../models/batch.dart';
import '../../services/batch_service.dart';
import '../../services/supabase_service.dart';

class BatchManagementScreen extends StatefulWidget {
  const BatchManagementScreen({super.key});

  @override
  State<BatchManagementScreen> createState() =>
      _BatchManagementScreenState();
}

class _BatchManagementScreenState
    extends State<BatchManagementScreen> {

  List<Batch> batches = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response =
      await SupabaseService.getAllBatches();

      batches = response.map((data) {
        return Batch(
          id: data['batch_id']?.toString() ?? '',
          name: data['batch_name']?.toString() ?? '',
          description:
          data['description']?.toString() ?? '',
          createdOn: data['created_at'] != null
              ? DateTime.parse(
            data['created_at'].toString(),
          )
              : DateTime.now(),
          active: data['is_active'] == true,
        );
      }).toList();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to load batches from Supabase: $e",
          ),
        ),
      );
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //
  //   return Scaffold(
  //
  //     appBar: AppBar(
  //       title: const Text(
  //         "Batch Management",
  //       ),
  //     ),
  //
  //     floatingActionButton: FloatingActionButton.extended(
  //
  //       icon: const Icon(Icons.add),
  //
  //       label: const Text("New Batch"),
  //
  //       onPressed: addBatch,
  //
  //     ),
  //
  //     body: ListView.builder(
  //
  //       itemCount: batches.length,
  //
  //       itemBuilder: (_, index) {
  //
  //         final batch = batches[index];
  //
  //         return Card(
  //
  //           margin: const EdgeInsets.all(8),
  //
  //           child: ListTile(
  //
  //             leading: CircleAvatar(
  //               child: Text(
  //                 "${index + 1}",
  //               ),
  //             ),
  //
  //             title: Text(
  //               batch.name,
  //             ),
  //
  //             subtitle: Column(
  //
  //               crossAxisAlignment:
  //               CrossAxisAlignment.start,
  //
  //               children: [
  //
  //                 Text(batch.description),
  //
  //                 const SizedBox(height: 5),
  //
  //                 Text(
  //
  //                   batch.active
  //                       ? "Status : Active"
  //                       : "Status : Archived",
  //
  //                   style: TextStyle(
  //
  //                     color: batch.active
  //                         ? Colors.green
  //                         : Colors.red,
  //
  //                     fontWeight:
  //                     FontWeight.bold,
  //
  //                   ),
  //
  //                 ),
  //
  //               ],
  //
  //             ),
  //
  //             trailing: PopupMenuButton(
  //
  //               itemBuilder: (_) => [
  //
  //                 const PopupMenuItem(
  //
  //                   value: 1,
  //
  //                   child: Text("Open"),
  //
  //                 ),
  //
  //                 const PopupMenuItem(
  //
  //                   value: 2,
  //
  //                   child: Text("Rename"),
  //
  //                 ),
  //
  //                 const PopupMenuItem(
  //
  //                   value: 3,
  //
  //                   child: Text("Archive"),
  //
  //                 ),
  //
  //                 const PopupMenuItem(
  //
  //                   value: 4,
  //
  //                   child: Text("Delete"),
  //
  //                 ),
  //
  //               ],
  //
  //               onSelected: (value) {
  //
  //                 switch (value) {
  //
  //                   case 1:
  //
  //                     Navigator.pushNamed(
  //
  //                       context,
  //
  //                       "/partManagement",
  //
  //                       arguments: batch,
  //
  //                     );
  //
  //                     break;
  //
  //                   case 2:
  //
  //                     renameBatch(batch);
  //
  //                     break;
  //
  //                   case 3:
  //
  //                     archiveBatch(batch);
  //
  //                     break;
  //
  //                   case 4:
  //
  //                     deleteBatch(batch);
  //
  //                     break;
  //
  //                 }
  //
  //               },
  //
  //             ),
  //
  //           ),
  //
  //         );
  //
  //       },
  //
  //     ),
  //
  //   );
  //
  // }
  @override
  Widget build(BuildContext context) {
    final activeCount =
        batches.where((batch) => batch.active).length;

    final archivedCount =
        batches.where((batch) => !batch.active).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF202124),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Batch Management",
          style: TextStyle(
            color: Color(0xFF202124),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: false,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3155C6),
        foregroundColor: Colors.white,

        elevation: 3,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          "New Batch",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        onPressed: addBatch,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              24,
              28,
              90,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // HEADER
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE1E4E8),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.035,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      Container(
                        width: 54,
                        height: 54,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                          BorderRadius.circular(15),
                        ),

                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF3155C6),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "Inspection Batches",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Create, organize and manage your ARR inspection batches.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      _statCard(
                        "Total",
                        batches.length.toString(),
                        const Color(0xFF3155C6),
                      ),

                      const SizedBox(width: 12),

                      _statCard(
                        "Active",
                        activeCount.toString(),
                        const Color(0xFF249653),
                      ),

                      const SizedBox(width: 12),

                      _statCard(
                        "Archived",
                        archivedCount.toString(),
                        const Color(0xFF747B86),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION TITLE
                Row(
                  children: [

                    const Text(
                      "Batches",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F5),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),

                      child: Text(
                        "${batches.length}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // BATCH LIST
                Expanded(
                  child: batches.isEmpty

                      ? Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(18),
                      border: Border.all(
                        color:
                        const Color(0xFFE1E4E8),
                      ),
                    ),

                    child: Center(
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,

                        children: [

                          Container(
                            width: 64,
                            height: 64,

                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFF0F2F5,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                            ),

                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 30,
                              color:
                              Color(0xFF7A8088),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            "No batches yet",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF202124),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Create your first inspection batch to get started.",
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 18),

                          OutlinedButton.icon(
                            onPressed: addBatch,

                            icon: const Icon(
                              Icons.add_rounded,
                            ),

                            label: const Text(
                              "Create Batch",
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
                                Color(0xFF3155C6),
                              ),

                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )

                      : ListView.separated(
                    itemCount: batches.length,

                    separatorBuilder:
                        (_, __) =>
                    const SizedBox(height: 12),

                    itemBuilder: (_, index) {

                      final batch =
                      batches[index];

                      return _batchCard(
                        context,
                        batch,
                        index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Future<void> addBatch() async {
  //
  //   final controller =
  //   TextEditingController();
  //
  //   await showDialog(
  //
  //     context: context,
  //
  //     builder: (_) {
  //
  //       return AlertDialog(
  //
  //         title: const Text(
  //           "Create Batch",
  //         ),
  //
  //         content: TextField(
  //
  //           controller: controller,
  //
  //           decoration:
  //           const InputDecoration(
  //
  //             hintText:
  //             "Batch Name",
  //
  //           ),
  //
  //         ),
  //
  //         actions: [
  //
  //           TextButton(
  //
  //             onPressed: () {
  //
  //               Navigator.pop(context);
  //
  //             },
  //
  //             child:
  //             const Text("Cancel"),
  //
  //           ),
  //
  //           ElevatedButton(
  //
  //             onPressed: () async {
  //
  //               if (controller.text
  //                   .trim()
  //                   .isEmpty) {
  //
  //                 return;
  //
  //               }
  //
  //               final batch = Batch(
  //
  //                 id:
  //                 DateTime.now()
  //                     .millisecondsSinceEpoch
  //                     .toString(),
  //
  //                 name:
  //                 controller.text,
  //
  //                 description:
  //                 "Production Batch",
  //
  //                 createdOn:
  //                 DateTime.now(),
  //
  //               );
  //
  //               await BatchService
  //                   .addBatch(batch);
  //
  //               if (!mounted) return;
  //
  //               Navigator.pop(context);
  //
  //               load();
  //
  //             },
  //
  //             child:
  //             const Text("Save"),
  //
  //           ),
  //
  //         ],
  //
  //       );
  //
  //     },
  //
  //   );
  //
  // }
Widget _statCard(
String label,
String value,
Color color,
) {
return Container(
width: 105,
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 10,
),
decoration: BoxDecoration(
color: const Color(0xFFF8F9FB),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFFE4E7EB),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w500,
color: Color(0xFF747B86),
),
),
const SizedBox(height: 3),
Text(
value,
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
color: color,
),
),
],
),
);
}

Widget _batchCard(
BuildContext context,
Batch batch,
int index,
) {
final isActive = batch.active;

return Container(
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: const Color(0xFFE1E4E8),
),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(
alpha: 0.025,
),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 17,
),
child: Row(
children: [

// NUMBER
Container(
width: 44,
height: 44,
alignment: Alignment.center,
decoration: BoxDecoration(
color: const Color(0xFFEAF0FF),
borderRadius: BorderRadius.circular(12),
),
child: Text(
"${index + 1}",
style: const TextStyle(
color: Color(0xFF3155C6),
fontSize: 16,
fontWeight: FontWeight.w700,
),
),
),

const SizedBox(width: 16),

// BATCH INFORMATION
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [

Row(
children: [

Flexible(
child: Text(
batch.name,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w700,
color: Color(0xFF202124),
),
),
),

const SizedBox(width: 10),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 9,
vertical: 4,
),
decoration: BoxDecoration(
color: isActive
? const Color(0xFFE8F5EC)
: const Color(0xFFF0F1F3),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [

Container(
width: 6,
height: 6,
decoration:
BoxDecoration(
color: isActive
? const Color(
0xFF249653,
)
: const Color(
0xFF7A8088,
),
shape: BoxShape.circle,
),
),

const SizedBox(width: 6),

Text(
isActive
? "Active"
: "Archived",
style: TextStyle(
fontSize: 11,
fontWeight:
FontWeight.w600,
color: isActive
? const Color(
0xFF1D7A43,
)
: const Color(
0xFF666D76,
),
),
),
],
),
),
],
),

const SizedBox(height: 5),

Text(
batch.description,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade600,
),
),
],
),
),

const SizedBox(width: 20),

// OPEN BUTTON
OutlinedButton.icon(
onPressed: () {
Navigator.pushNamed(
context,
"/partManagement",
arguments: batch,
);
},

icon: const Icon(
Icons.open_in_new_rounded,
size: 17,
),

label: const Text(
"Open",
),

style: OutlinedButton.styleFrom(
foregroundColor:
const Color(0xFF3155C6),

side: const BorderSide(
color: Color(0xFFD5DCF1),
),

backgroundColor:
const Color(0xFFF8FAFF),

padding:
const EdgeInsets.symmetric(
horizontal: 15,
vertical: 11,
),

shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(10),
),
),
),

const SizedBox(width: 8),

// MORE OPTIONS
PopupMenuButton<int>(
tooltip: "Batch options",

icon: const Icon(
Icons.more_vert_rounded,
color: Color(0xFF6F7680),
),

shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),

itemBuilder: (_) => [

const PopupMenuItem<int>(
value: 2,
child: ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(
Icons.edit_outlined,
size: 20,
),
title: Text("Rename"),
),
),

PopupMenuItem<int>(
value: 3,
child: ListTile(
contentPadding:
EdgeInsets.zero,
leading: Icon(
isActive
? Icons.archive_outlined
: Icons.unarchive_outlined,
size: 20,
),
title: Text(
isActive
? "Archive"
: "Activate",
),
),
),

const PopupMenuDivider(),

const PopupMenuItem<int>(
value: 4,
child: ListTile(
contentPadding: EdgeInsets.zero,
leading: Icon(
Icons.delete_outline,
size: 20,
color: Colors.red,
),
title: Text(
"Delete",
style: TextStyle(
color: Colors.red,
),
),
),
),
],

onSelected: (value) {
switch (value) {
case 2:
renameBatch(batch);
break;

case 3:
archiveBatch(batch);
break;

case 4:
deleteBatch(batch);
break;
}
},
),
],
),
),
);
}

  // Future<void> addBatch() async {
  //   final controller = TextEditingController();
  //
  //   await showDialog(
  //     context: context,
  //     builder: (_) {
  //       return AlertDialog(
  //         title: const Text(
  //           "Create New Batch",
  //           style: TextStyle(
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //
  //         content: SizedBox(
  //           width: 420,
  //
  //           child: TextField(
  //             controller: controller,
  //
  //             autofocus: true,
  //
  //             decoration: InputDecoration(
  //               labelText: "Batch Name",
  //               hintText: "Enter batch name",
  //               prefixIcon: const Icon(
  //                 Icons.inventory_2_outlined,
  //               ),
  //
  //               border: OutlineInputBorder(
  //                 borderRadius:
  //                 BorderRadius.circular(10),
  //               ),
  //
  //               enabledBorder: OutlineInputBorder(
  //                 borderRadius:
  //                 BorderRadius.circular(10),
  //
  //                 borderSide: const BorderSide(
  //                   color: Color(0xFFD9DDE3),
  //                 ),
  //               ),
  //
  //               focusedBorder: OutlineInputBorder(
  //                 borderRadius:
  //                 BorderRadius.circular(10),
  //
  //                 borderSide: const BorderSide(
  //                   color: Color(0xFF3155C6),
  //                   width: 1.5,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //
  //         actionsPadding: const EdgeInsets.fromLTRB(
  //           20,
  //           0,
  //           20,
  //           18,
  //         ),
  //
  //         actions: [
  //
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //
  //             child: const Text(
  //               "Cancel",
  //             ),
  //           ),
  //
  //           const SizedBox(width: 8),
  //
  //           ElevatedButton.icon(
  //             onPressed: () async {
  //
  //               final name =
  //               controller.text.trim();
  //
  //               if (name.isEmpty) {
  //                 return;
  //               }
  //
  //               final batch = Batch(
  //                 id: DateTime.now()
  //                     .millisecondsSinceEpoch
  //                     .toString(),
  //
  //                 name: name,
  //
  //                 description:
  //                 "Production Batch",
  //
  //                 createdOn:
  //                 DateTime.now(),
  //               );
  //
  //               await BatchService.addBatch(
  //                 batch,
  //               );
  //
  //               if (!mounted) return;
  //
  //               Navigator.pop(context);
  //
  //               load();
  //             },
  //
  //             icon: const Icon(
  //               Icons.add_rounded,
  //               size: 18,
  //             ),
  //
  //             label: const Text(
  //               "Create Batch",
  //             ),
  //
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor:
  //               const Color(0xFF3155C6),
  //
  //               foregroundColor:
  //               Colors.white,
  //
  //               padding:
  //               const EdgeInsets.symmetric(
  //                 horizontal: 18,
  //                 vertical: 12,
  //               ),
  //
  //               shape:
  //               RoundedRectangleBorder(
  //                 borderRadius:
  //                 BorderRadius.circular(10),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  Future<void> addBatch() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController =
    TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Create New Batch",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),

          content: SizedBox(
            width: 480,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // BATCH ID
                TextField(
                  controller: idController,
                  autofocus: true,

                  decoration: InputDecoration(
                    labelText: "Batch ID",
                    hintText:
                    "Example: LAPTOP-2026-01",

                    prefixIcon: const Icon(
                      Icons.tag_outlined,
                    ),

                    helperText:
                    "Must be unique",

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // BATCH NAME
                TextField(
                  controller: nameController,

                  decoration: InputDecoration(
                    labelText: "Batch Name",
                    hintText:
                    "Example: Testing Laptop",

                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // DESCRIPTION
                TextField(
                  controller:
                  descriptionController,

                  maxLines: 3,

                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText:
                    "Describe this inspection batch",

                    prefixIcon: const Padding(
                      padding:
                      EdgeInsets.only(
                        bottom: 38,
                      ),

                      child: Icon(
                        Icons.description_outlined,
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),

                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actionsPadding:
          const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18,
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "Cancel",
              ),
            ),

            const SizedBox(width: 8),

            ElevatedButton.icon(
              onPressed: () async {

                final id =
                idController.text.trim();

                final name =
                nameController.text.trim();

                final description =
                descriptionController.text.trim();

                // VALIDATION
                if (id.isEmpty ||
                    name.isEmpty ||
                    description.isEmpty) {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Enter Batch ID, Batch Name and Description.",
                      ),
                    ),
                  );

                  return;
                }

                // DUPLICATE ID CHECK
                final duplicate =
                batches.any(
                      (batch) =>
                  batch.id.trim().toLowerCase() ==
                      id.toLowerCase(),
                );

                if (duplicate) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batch ID already exists. Enter a unique Batch ID.",
                      ),
                    ),
                  );

                  return;
                }

                final batch = Batch(
                  id: id,
                  name: name,
                  description: description,
                  createdOn: DateTime.now(),
                );

                try {
                  await SupabaseService.createBatch(
                    batchId: id,
                    batchName: name,
                    description: description,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  await load();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batch created successfully.",
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Unable to create batch: $e",
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),

              label: const Text(
                "Create Batch",
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF3155C6),

                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    idController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }
  Future<void> renameBatch(
      Batch batch,
      ) async {

    final idController = TextEditingController(
      text: batch.id,
    );

    final nameController = TextEditingController(
      text: batch.name,
    );

    final descriptionController =
    TextEditingController(
      text: batch.description,
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Edit Batch Details",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF202124),
            ),
          ),

          content: SizedBox(
            width: 480,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // BATCH ID
                TextField(
                  controller: idController,

                  decoration: InputDecoration(
                    labelText: "Batch ID",
                    hintText:
                    "Enter unique Batch ID",

                    prefixIcon: const Icon(
                      Icons.tag_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // BATCH NAME
                TextField(
                  controller: nameController,

                  decoration: InputDecoration(
                    labelText: "Batch Name",
                    hintText:
                    "Enter batch name",

                    prefixIcon: const Icon(
                      Icons.inventory_2_outlined,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // DESCRIPTION
                TextField(
                  controller:
                  descriptionController,

                  maxLines: 3,

                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText:
                    "Describe this inspection batch",

                    prefixIcon: const Padding(
                      padding:
                      EdgeInsets.only(
                        bottom: 38,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFFD9DDE3),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide:
                      const BorderSide(
                        color: Color(0xFF3155C6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actionsPadding:
          const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18,
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                "Cancel",
              ),
            ),

            const SizedBox(width: 8),

            ElevatedButton.icon(
              onPressed: () async {

                final newId =
                idController.text.trim();

                final newName =
                nameController.text.trim();

                final newDescription =
                descriptionController
                    .text
                    .trim();

                // VALIDATION
                if (newId.isEmpty ||
                    newName.isEmpty ||
                    newDescription.isEmpty) {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batch ID, Batch Name and Description are required.",
                      ),
                    ),
                  );

                  return;
                }

                // DUPLICATE ID CHECK
                final duplicate =
                batches.any(
                      (existingBatch) =>
                  existingBatch != batch &&
                      existingBatch.id
                          .trim()
                          .toLowerCase() ==
                          newId.toLowerCase(),
                );

                if (duplicate) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batch ID already exists. Enter a unique Batch ID.",
                      ),
                    ),
                  );

                  return;
                }

                try {

                  final oldId = batch.id;

                  await SupabaseService.updateBatch(
                    oldBatchId: oldId,
                    batchId: newId,
                    batchName: newName,
                    description: newDescription,
                    isActive: batch.active,
                  );

                  batch.id = newId;
                  batch.name = newName;
                  batch.description = newDescription;
                  if (!mounted) return;

                  Navigator.pop(context);

                  load();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batch details updated successfully.",
                      ),
                    ),
                  );

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Unable to update batch: $e",
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(
                Icons.save_outlined,
                size: 18,
              ),

              label: const Text(
                "Save Changes",
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF3155C6),

                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    idController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> archiveBatch(
      Batch batch,
      ) async {

    final newStatus = !batch.active;

    try {
      await SupabaseService.updateBatchStatus(
        batchId: batch.id,
        isActive: newStatus,
      );

      batch.active = newStatus;

      if (!mounted) return;

      await load();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? "Batch Activated"
                : "Batch Archived",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to update batch status: $e",
          ),
        ),
      );
    }

  }
  Future<void> deleteBatch(
      Batch batch,
      ) async {

    final delete =
    await showDialog<bool>(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: const Text(
            "Delete Batch",
          ),

          content: Text(
            "Delete ${batch.name} ?",
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  false,
                );

              },

              child: const Text(
                "Cancel",
              ),

            ),

            ElevatedButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  true,
                );

              },

              child: const Text(
                "Delete",
              ),

            ),

          ],

        );

      },

    );

    if (delete != true) return;

    try {
      await SupabaseService.deleteBatch(
        batch.id,
      );

      if (!mounted) return;

      await load();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Batch deleted successfully.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to delete batch: $e",
          ),
        ),
      );
    }

  }
}