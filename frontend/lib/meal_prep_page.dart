// lib/meal_prep_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/widgets/bottom_nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal Prep Builder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MealPrepPage(),
    );
  }
}

class MealPrepPage extends StatefulWidget {
  const MealPrepPage({super.key});

  @override
  State<MealPrepPage> createState() => _MealPrepPageState();
}

class _MealPrepPageState extends State<MealPrepPage> {
  int totalCalories = 0;
  int totalProtein = 0;
  int totalCarbs = 0;
  int totalFat = 0;

  void updateMacros(int calDelta, int proDelta, int carbDelta, int fatDelta) {
    setState(() {
      totalCalories += calDelta;
      totalProtein += proDelta;
      totalCarbs += carbDelta;
      totalFat += fatDelta;

      if (totalCalories < 0) totalCalories = 0;
      if (totalProtein < 0) totalProtein = 0;
      if (totalCarbs < 0) totalCarbs = 0;
      if (totalFat < 0) totalFat = 0;
    });
  }

  // PERFECT MATCH TO YOUR FIGMA
  Widget _buildNutrientRow(String label, int current, int max, Color progressColor) {
    final double percent = (current / max).clamp(0.0, 1.0);
    final String unit = label == "calories" ? "cal" : "g";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              Text(
                "$current $unit / $max $unit",
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                "${(percent * 100).round()}%",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            color: progressColor,
            backgroundColor: Colors.grey[800],
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Meal Prep Builder"),
            Text(
              "Create your perfect Sri Lankan Meal plate",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {}),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// ROW 1
            Row(
              children: [
                Expanded(
                  child: MealCard(
                    title: "Steamed Rice",
                    items: const [
                      FoodItem(name: "Basmati", calories: 180, protein: 3, carbs: 39, fat: 0),
                      FoodItem(name: "Red Rice", calories: 170, protein: 4, carbs: 36, fat: 1),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/rice.jpg",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Mallum (Greens)",
                    items: const [
                      FoodItem(name: "Gotukola", calories: 85, protein: 3, carbs: 8, fat: 3),
                      FoodItem(name: "Mukunuwenna", calories: 90, protein: 4, carbs: 10, fat: 2),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/mallum.jpg",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ROW 2
            Row(
              children: [
                Expanded(
                  child: MealCard(
                    title: "Vegetable Curry 1",
                    items: const [
                      FoodItem(name: "Carrots", calories: 120, protein: 2, carbs: 25, fat: 4),
                      FoodItem(name: "Potato", calories: 130, protein: 3, carbs: 28, fat: 2),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/veg1.jpg",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Vegetable Curry 2",
                    items: const [
                      FoodItem(name: "Beans", calories: 95, protein: 4, carbs: 16, fat: 2),
                      FoodItem(name: "Bell Pepper", calories: 100, protein: 1, carbs: 20, fat: 1),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/veg2.jpg",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ROW 3
            Row(
              children: [
                Expanded(
                  child: MealCard(
                    title: "Meat",
                    items: const [
                      FoodItem(name: "Chicken", calories: 250, protein: 25, carbs: 0, fat: 15),
                      FoodItem(name: "Fish", calories: 220, protein: 22, carbs: 0, fat: 12),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/meat.jpg",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Fresh Salad",
                    items: const [
                      FoodItem(name: "Lettuce", calories: 65, protein: 1, carbs: 3, fat: 0),
                      FoodItem(name: "Cucumber", calories: 50, protein: 1, carbs: 11, fat: 0),
                    ],
                    onChanged: updateMacros,
                    imagePath: "lib/assets/salad.jpg",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// YOUR CUSTOM PLATE — PERFECT MATCH TO FIGMA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3D1F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your custom plate",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildNutrientRow("calories", totalCalories, 2400, Colors.greenAccent),
                  _buildNutrientRow("protein", totalProtein, 150, Colors.red),
                  _buildNutrientRow("carbs", totalCarbs, 620, Colors.yellow),
                  _buildNutrientRow("fat", totalFat, 220, Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.restaurant, color: Colors.black, size: 28),
                label: const Text(
                  "Save my recipe",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) => print('Tab tapped: $index'),
      ),
    );
  }
}

/// MODEL
class FoodItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

/// MEAL CARD
class MealCard extends StatefulWidget {
  final String title;
  final List<FoodItem> items;
  final Function(int cal, int pro, int carb, int fat) onChanged;
  final String imagePath;

  const MealCard({
    super.key,
    required this.title,
    required this.items,
    required this.onChanged,
    required this.imagePath,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  int count = 0;
  FoodItem? selectedItem;
  final TextEditingController weightController = TextEditingController(text: "100");

  int getWeight() => int.tryParse(weightController.text) ?? 100;

  Map<String, int> calculateMacros() {
    if (selectedItem == null) return {'cal': 0, 'pro': 0, 'carb': 0, 'fat': 0};
    final factor = getWeight() / 100.0;
    return {
      'cal': (selectedItem!.calories * factor).round(),
      'pro': (selectedItem!.protein * factor).round(),
      'carb': (selectedItem!.carbs * factor).round(),
      'fat': (selectedItem!.fat * factor).round(),
    };
  }

  void increase() {
    if (selectedItem == null) return;
    final macros = calculateMacros();
    widget.onChanged(macros['cal']!, macros['pro']!, macros['carb']!, macros['fat']!);
    setState(() => count++);
  }

  void decrease() {
    if (count > 0 && selectedItem != null) {
      final macros = calculateMacros();
      widget.onChanged(-macros['cal']!, -macros['pro']!, -macros['carb']!, -macros['fat']!);
      setState(() => count--);
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[900],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.asset(
              widget.imagePath,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.title)),
                    Text("${widget.items.first.calories}"),
                  ],
                ),
                DropdownButton<FoodItem>(
                  value: selectedItem,
                  hint: const Text("Select option"),
                  isExpanded: true,
                  items: widget.items.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item.name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedItem = value;
                      count = 0;
                    });
                  },
                ),
                Row(
                  children: [
                    const Text("Weight:"),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "grams", isDense: true),
                      ),
                    ),
                    const Text("g"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle), onPressed: decrease),
                    Text("$count"),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                      onPressed: increase,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}