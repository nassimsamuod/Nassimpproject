import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String department;
  final String technician;
  final String salle;
  final DateTime date;

  Event({
    required this.department,
    required this.technician,
    required this.salle,
    required this.date,
  });
}

class tachesAdmin extends StatefulWidget {
  @override
  _tachesAdminState createState() => _tachesAdminState();
}

class _tachesAdminState extends State<tachesAdmin> {
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  List<Event> tasks = [];
  List<String> technicians = [''];
  List<String> departments = [''];
  List<String> salles = [''];
  String? selectedTechnician;
  String? selectedDepartment;
  String? selectedSalle;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    fetchTasks(_selectedDay!); // Fetch tasks for the current selected day
    fetchDepartments();
  }

  Future<void> fetchTasks(DateTime selectedDay) async {
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('Taches')
        .where('Date', isGreaterThanOrEqualTo: _startOfDay(selectedDay))
        .where('Date', isLessThan: _endOfDay(selectedDay))
        .get();
    tasksSnapshot.docs.forEach((doc) {
      print('Departement: ${doc['Departement']}');
      print('nom: ${doc['nom']}');
      print('Salle: ${doc['Salle']}');
      print('Date: ${doc['Date']}');
    });

    setState(() {
      tasks = tasksSnapshot.docs.map((doc) {
        return Event(
          department: doc['Departement'] ,
          technician: doc['nom'] ,
          salle: doc['Salle'],
          date: (doc['Date'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<void> fetchTechnicians() async {
    final techniciansSnapshot = await FirebaseFirestore.instance.collection('Utilisateurs').where('role', isEqualTo: 'technicien').get();

    setState(() {
      technicians = [''] + techniciansSnapshot.docs.map<String>((doc) => doc['nom'] as String).toList();
    });
  }

  Future<void> fetchDepartments() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Departements').get();
    List<String> departmentNames = [];
    for (DocumentSnapshot doc in querySnapshot.docs) {
      departmentNames.add(doc['nom'] as String);
    }
    setState(() {
      departments.addAll(departmentNames); // Add department names to the list
      selectedDepartment = departments.isNotEmpty ? departments[0] : '';
      fetchSalles(selectedDepartment!);
      fetchTechnicians();
    });
  }

  Future<void> fetchSalles(String departmentName) async {
    if (departmentName.isNotEmpty) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Departements')
          .where('nom', isEqualTo: departmentName)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot departmentDoc = querySnapshot.docs.first;
        QuerySnapshot roomNumbersSnapshot = await departmentDoc.reference.collection('SallesServeurs').get();
        List<String> roomNumberList = roomNumbersSnapshot.docs.map((doc) => doc['numéro_salle'].toString()).toList();
        print('Fetched Salles: $roomNumberList');
        salles = [''] + roomNumberList; // Add room numbers to the list
        setState(() {
          salles.clear();
          salles.addAll(roomNumberList); // Add room numbers to the list
          selectedSalle = salles.isNotEmpty ? salles[0] : '';
        });
      } else {
        print('No document found for department: $departmentName');
      }
    } else {
      print('Department name is empty');
    }
  }

  Timestamp _startOfDay(DateTime day) {
    return Timestamp.fromMillisecondsSinceEpoch(day.millisecondsSinceEpoch);
  }

  Timestamp _endOfDay(DateTime day) {
    return Timestamp.fromMillisecondsSinceEpoch(
        day.millisecondsSinceEpoch + 86399999); // 86399999 milliseconds = 23 hours, 59 minutes, 59 seconds, and 999 milliseconds
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
    fetchTasks(selectedDay); // Refresh tasks based on the selected date
  }

  void _resetLists() {
    setState(() {
      selectedDepartment = null;
      selectedTechnician = null;
      selectedSalle = null;
      salles.clear();
      departments.clear();
      technicians.clear();
      departments = [''];
      technicians = [''];
      salles = [''];
      fetchDepartments();
      fetchTechnicians();// Fetch departments again after resetting
    });
  }

  void _addTask() {
    showModalBottomSheet(
      backgroundColor: Colors.blue.shade50,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Text(
                    'Ajouter tâche',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          hint: Text('Choisir un département'),
                          items: departments.map((department) {
                            return DropdownMenuItem<String>(
                              value: department,
                              child: Text(department),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedDepartment = value!;
                              fetchSalles(selectedDepartment!); // Fetch salles based on the selected department
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: DropdownButtonFormField<String>(
                          value: selectedTechnician,
                          hint: Text('Choisir un technicien'),
                          items: technicians.map((technician) {
                            return DropdownMenuItem<String>(
                              value: technician,
                              child: Text(technician),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedTechnician = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: DropdownButtonFormField<String>(
                          value: selectedSalle,
                          hint: Text('Choisir une salle'),
                          items: salles.map((salle) {
                            return DropdownMenuItem<String>(
                              value: salle,
                              child: Text(salle),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedSalle = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Ensure all required fields are selected
                      if (selectedDepartment != null && selectedTechnician != null && selectedSalle != null) {
                        try {
                          // Add task to Firebase Cloud Storage
                          FirebaseFirestore.instance.collection('Taches').add({
                            'Departement': selectedDepartment,
                            'nom': selectedTechnician,
                            'Salle': selectedSalle,
                          'Date': Timestamp.fromDate(_selectedDay!),
                          });
                          Navigator.of(context).pop();
                          // Show scaffold message after adding task
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task added successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Reset lists
                          _resetLists();
                        } catch (e) {
                          print('Error adding task: $e');

                          // Show error message if task addition fails
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add task. Please try again.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        // Show error message if any field is not selected
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select all fields.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Image.asset("Images/valider.png", width: 40),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _resetLists();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text('TableCalendrier - Taches'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2024, 5, 1),
                lastDay: DateTime.utc(2040, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(340, 0, 0, 0),
                child: FloatingActionButton(
                  backgroundColor: Colors.blue.shade50,
                  onPressed: _addTask,
                  child: Icon(Icons.add),
                ),
              ),
              Expanded(
                child: ListView(
                  children: tasks.map((task) {
                    return Card(
                      color: Colors.blue.shade50,
                      elevation: 4,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: Image.asset('Images/to do.png', width: 43),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(Icons.business_outlined, color: Colors.grey.shade800, size: 23),
                                SizedBox(width: 5),
                                Text(
                                  'Département: ${task.department}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(Icons.meeting_room_outlined, color: Colors.grey.shade800, size: 23),
                                SizedBox(width: 5),
                                Text(
                                  'Salle: ${task.salle}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(Icons.person_outline, color: Colors.grey.shade800, size: 23),
                                SizedBox(width: 5),
                                Text(
                                  'Technicien: ${task.technician}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
