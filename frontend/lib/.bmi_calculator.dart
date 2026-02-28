import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(ChangeNotifierProvider(
      create: (_) => BMIData(),
      child: const MaterialApp(home: BMICalculatorScreen(), debugShowCheckedModeBanner: false),
    ));

// --- LOGIC LAYER (The "Brain") ---
// --- LOGIC LAYER (The "Brain") ---
class BMIData extends ChangeNotifier {
  double height = 170.0, weight = 70.0;
  int age = 25;
  String gender = "Male", goal = "Keep", activity = "Moderate";
  List<String> conditions = [];

  // --- ADD THESE THREE GETTERS HERE ---
  double get bmi => weight / ((height / 100) * (height / 100));
  
  String get category {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    return "Overweight";
  }

  int get calories {
    // Mifflin-St Jeor formula as seen in your intake requirements
    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (gender == "Male" ? 5 : -161);
    return (bmr * 1.5).round(); 
  }
  // ------------------------------------

  void setGoal(String g) { goal = g; notifyListeners(); }
  void setGender(String g) { gender = g; notifyListeners(); }
  void setActivity(String a) { activity = a; notifyListeners(); }

  void toggleCondition(String condition) {
    if (condition == "None") {
      conditions = ["None"];
    } else {
      conditions.remove("None");
      conditions.contains(condition) ? conditions.remove(condition) : conditions.add(condition);
    }
    notifyListeners();
  }
}

// --- UI LAYER ---
class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});
  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  late TextEditingController hCtrl, wCtrl, aCtrl;

  @override
  void initState() {
    super.initState();
    final data = context.read<BMIData>();
    // Listeners update the data class whenever you type
    hCtrl = TextEditingController(text: "170")..addListener(() => data.height = double.tryParse(hCtrl.text) ?? 0);
    wCtrl = TextEditingController(text: "70")..addListener(() => data.weight = double.tryParse(wCtrl.text) ?? 0);
    aCtrl = TextEditingController(text: "25")..addListener(() => data.age = int.tryParse(aCtrl.text) ?? 0);
  }

  @override
  void dispose() {
    hCtrl.dispose();
    wCtrl.dispose();
    aCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BMIData>();
    const green = Color(0xFF14D97D);
    // const bg = Color(0xFF161D18); // Removed as it was unused

    return Scaffold(
      backgroundColor: const Color(0xFF080D0A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 50),
          const Text("Advanced BMI Calculator", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Personalized nutrition planning", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // Row 1: Height & Weight
          Row(children: [
            Expanded(child: _field("Height (cm)", hCtrl, Icons.straighten)),
            const SizedBox(width: 15),
            Expanded(child: _field("Weight (kg)", wCtrl, Icons.fitness_center)),
          ]),
          const SizedBox(height: 15),

          // Row 2: Age & Gender
          Row(children: [
            Expanded(child: _field("Age", aCtrl, Icons.cake)),
            const SizedBox(width: 15),
            Expanded(child: _dropdown("Gender", data.gender, ["Male", "Female"], (v) => data.setGender(v!))),
          ]),
          const SizedBox(height: 25),
          
          const Text("Fitness Goal", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(children: [
            _goal("Loss", Icons.local_fire_department, data.goal == "Loss", () => data.setGoal("Loss")),
            const SizedBox(width: 10),
            _goal("Keep", Icons.balance, data.goal == "Keep", () => data.setGoal("Keep")),
            const SizedBox(width: 10),
            _goal("Gain", Icons.bolt, data.goal == "Gain", () => data.setGoal("Gain")),
          ]),
          const SizedBox(height: 25),

          const Text("Activity Level", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          _dropdown("", data.activity, ["Sedentary", "Moderate", "Active"], (v) => data.setActivity(v!)),

          const SizedBox(height: 25),
          const Text("Health Conditions", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: ["Diabetes", "Blood Pressure", "None"].map((c) => 
            _chip(c, data.conditions.contains(c), () => data.toggleCondition(c))).toList()),

          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 60, child: ElevatedButton(
            onPressed: () {
              // The `bmi` and `cat` variables were correctly calculated
              // but then not used before navigating.
              // If they were meant to be passed to the BMIResultsScreen,
              // that logic would need to be added to the navigation.
              // For now, removing the unused local variables.
              // double bmi = data.weight / ((data.height / 100) * (data.height / 100));
              // String cat = (bmi < 18.5) ? "Underweight" : (bmi < 25) ? "Normal" : "Overweight";
              
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BMIResultsScreen()), // Removed unused bmi/cat for now
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("Calculate My Stats", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  // --- COMPACT UI HELPERS ---
  Widget _field(String l, TextEditingController c, IconData i) => TextField(
    controller: c, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.grey, fontSize: 12), prefixIcon: Icon(i, color: const Color(0xFF14D97D), size: 18), filled: true, fillColor: const Color(0xFF161D18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  Widget _dropdown(String l, String val, List<String> items, Function(String?) onChg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFF161D18), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: val, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: onChg, isExpanded: true, dropdownColor: const Color(0xFF161D18))));

  Widget _goal(String l, IconData i, bool active, VoidCallback t) => Expanded(child: GestureDetector(
    onTap: t, child: Container(padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(color: active ? const Color(0xFF1E3A2B) : const Color(0xFF161D18), borderRadius: BorderRadius.circular(15), border: Border.all(color: active ? const Color(0xFF14D97D) : Colors.transparent)),
    child: Column(children: [Icon(i, color: active ? const Color(0xFF14D97D) : Colors.grey), Text(l, style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12))]))));

  Widget _chip(String l, bool active, VoidCallback t) => ActionChip(
    label: Text(l, style: TextStyle(color: active ? const Color(0xFF14D97D) : Colors.white, fontSize: 12)),
    backgroundColor: const Color(0xFF161D18),
    shape: StadiumBorder(side: BorderSide(color: active ? const Color(0xFF14D97D) : Colors.transparent)),
    onPressed: t);
}

// --- New Screen for BMI Results (Placeholder) ---
class BMIResultsScreen extends StatelessWidget {
  const BMIResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You would typically pass BMI and category data to this screen
    // For now, it's a simple placeholder.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your BMI Results", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF161D18),
        iconTheme: const IconThemeData(color: Colors.white), // For back button
      ),
      backgroundColor: const Color(0xFF080D0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "BMI Results will appear here!",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Implement the calculation logic and display for BMI, category, etc.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}