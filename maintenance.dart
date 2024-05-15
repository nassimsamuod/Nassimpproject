import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'camera.dart';

class maintenance extends StatefulWidget {
  final String numeroSalle;
  final String nomDepartement;
  final String nomUtilisateur;
  final String idSalle;

  maintenance({
    required this.numeroSalle,
    required this.nomDepartement,
    required this.nomUtilisateur,
    required this.idSalle,
  });

  @override
  maintenanceState createState() => maintenanceState();
}

class maintenanceState extends State<maintenance> {
  List<String> questionTypes = [];
  int currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Departements').get();

      for (QueryDocumentSnapshot departementDoc in querySnapshot.docs) {
        QuerySnapshot sallesSnapshot = await FirebaseFirestore.instance
            .collection('Departements')
            .doc(departementDoc.id)
            .collection('SallesServeurs')
            .where('id_salle', isEqualTo: widget.idSalle)
            .get();

        if (sallesSnapshot.docs.isNotEmpty) {
          QuerySnapshot salleDoc = await FirebaseFirestore.instance
              .collection('Departements')
              .doc(departementDoc.id)
              .collection('SallesServeurs')
              .where('id_salle', isEqualTo: widget.idSalle)
              .get();

          if (salleDoc.docs.isNotEmpty) {
            DocumentSnapshot document = salleDoc.docs.first;

            List<dynamic> questions = document['Questions'];

            await fetchQuestionTypes(questions);

            break;
          } else {
            print(
                'La salle correspondante à l\'ID ${widget.idSalle} dans le département ${departementDoc.id} n\'existe pas.');
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des questions : $e');
    }
  }

  Future<void> fetchQuestionTypes(List<dynamic> questions) async {
    try {
      for (var idQuestion in questions) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Questions')
            .where('id_question', isEqualTo: idQuestion)
            .get();

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          String typeQuestion = doc['type_question'];
          if (!questionTypes.contains(typeQuestion)) {
            setState(() {
              questionTypes.add(typeQuestion);
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des types de questions : $e');
    }
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questionTypes.length - 1) {
        takePicture(); // Take picture before changing the question
      } else {
        // After taking picture of the last question, close the camera widget

        showDialog(
          context: context,
          builder: (BuildContext context) {
            String comment = ''; // Variable to store the comment text
            return AlertDialog(
              backgroundColor: Colors.blue.shade50,
              title: Text("Visite terminée"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire',
                    ),
                    onChanged: (value) {
                      comment = value; // Update the comment text as the user types
                    },
                  ),
                ],
              ),
              actions: [Row(children:[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {

                    print("Numéro de salle: ${widget.numeroSalle}");
                    print("Nom du département: ${widget.nomDepartement}");
                    print("Nom de l'utilisateur: ${widget.nomUtilisateur}");
                    print("ID de la salle: ${widget.idSalle}");
                    print('Commentaire: $comment');
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();// Close the AlertDialog
                  },
                ),
            TextButton(
            child: Text("Annuler"),
            onPressed: () {
            Navigator.of(context).pop(); // Close the AlertDialog
            Navigator.of(context).pop(); // Close the AlertDialog
            },
            ),
              ],
            ),
           ], );
          },
        );
      }
      currentQuestionIndex = (currentQuestionIndex + 1) % questionTypes.length;
    });
  }


  Future<void> takePicture() async {
    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(camera: firstCamera, onPictureTaken: (String) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questionTypes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (currentQuestionIndex < questionTypes.length) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Center(child:
              Image.asset('Images/maintenance.png',width:250),),
              SizedBox(height:20),
              Container(
                width: 350,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.grey.shade50,
                  border: Border.all(
                    color: Colors.blue.shade900.withOpacity(1),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(1),
                      spreadRadius: 3,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Text(
                    'Est-ce que la ${questionTypes[currentQuestionIndex]} ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue.shade800,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
               SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red, size: 50),
                    onPressed: () {
                      nextQuestion();
                    },
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green, size: 50),
                    onPressed: () {
                      nextQuestion();
                    },
                  ),
                ],
              ),],),
          ),
         ] ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Text('Vérification terminée !'),
        ),
      );
    }
  }
}
