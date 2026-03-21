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

  void updateCalories(int calories) {
    setState(() {
      totalCalories += calories;
      if (totalCalories < 0) totalCalories = 0;
    });
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
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
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
                    calories: 180,
                    imagePath: "lib/assets/rice.jpg",
                    items: const [
                      FoodItem(name: "Basmati", calories: 180),
                      FoodItem(name: "Red Rice", calories: 170),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Mallum (Greens)",
                    calories: 85,
                    imagePath: "lib/assets/mallum.jpg",
                    items: const [
                      FoodItem(name: "Gotukola", calories: 85),
                      FoodItem(name: "Mukunuwenna", calories: 90),
                    ],
                    onChanged: updateCalories,
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
                    calories: 120,
                    imagePath: "lib/assets/veg1.jpg",
                    items: const [
                      FoodItem(name: "Carrots", calories: 120),
                      FoodItem(name: "Potato", calories: 130),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Vegetable Curry 2",
                    calories: 95,
                    imagePath: "lib/assets/veg2.jpg",
                    items: const [
                      FoodItem(name: "Beans", calories: 95),
                      FoodItem(name: "Bell Pepper", calories: 100),
                    ],
                    onChanged: updateCalories,
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
                    calories: 250,
                    imagePath: "lib/assets/meat.jpg",
                    items: const [
                      FoodItem(name: "Chicken", calories: 250),
                      FoodItem(name: "Fish", calories: 220),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Fresh Salad",
                    calories: 65,
                    imagePath: "lib/assets/salad.jpg",
                    items: const [
                      FoodItem(name: "Lettuce", calories: 65),
                      FoodItem(name: "Cucumber", calories: 50),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// TOTAL CALORIES
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Meal Calories"),
                      Text(
                        "$totalCalories cal",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: totalCalories / 2400,
                    color: Colors.greenAccent,
                    backgroundColor: Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),
                icon: const Icon(Icons.save, color: Colors.black),
                label: const Text(
                  "Save my recipe",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),

      // ── FANCY ANIMATED BOTTOM NAV ──
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // 1 = Meal Prep tab
        onTap: (index) {
          print('Tab tapped: $index');
          // TODO: Add real navigation later
        },
      ),
    );
  }
}

/// MODEL
class FoodItem {
  final String name;
  final int calories;
  const FoodItem({required this.name, required this.calories});
}

/// FINAL MEAL CARD
class MealCard extends StatefulWidget {
  final String title;
  final int calories;
  final List<FoodItem> items;
  final Function(int) onChanged;
  final String imagePath;

  const MealCard({
    super.key,
    required this.title,
    required this.calories,
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

  int calculateCalories() {
    if (selectedItem == null) return 0;
    return ((selectedItem!.calories * getWeight()) / 100).round();
  }

  void increase() {
    if (selectedItem == null) return;
    widget.onChanged(calculateCalories());
    setState(() => count++);
  }

  void decrease() {
    if (count > 0 && selectedItem != null) {
      widget.onChanged(-calculateCalories());
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
                    Text("${widget.calories}"),
                  ],
                ),
                DropdownButton<FoodItem>(
                  value: selectedItem,
                  hint: const Text("Select option"),
                  isExpanded: true,
                  items: widget.items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    );
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
                        decoration: const InputDecoration(
                          hintText: "grams",
                          isDense: true,
                        ),
                      ),
                    ),
                    const Text("g"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: decrease,
                    ),
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