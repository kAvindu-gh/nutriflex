// lib/meal_prep_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/widgets/bottom_nav.dart';
import '../services/api_service.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0A1F12), // Figma background
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
  // nEWLY ADD
  final GlobalKey<_MealCardState> _riceKey = GlobalKey();
  final GlobalKey<_MealCardState> _mallumKey = GlobalKey();
  final GlobalKey<_MealCardState> _veg1Key = GlobalKey();
  final GlobalKey<_MealCardState> _veg2Key = GlobalKey();
  final GlobalKey<_MealCardState> _meatKey = GlobalKey();
  final GlobalKey<_MealCardState> _saladKey = GlobalKey();
  //

  int consumedCalories = 0;
  int maxCalories = 2400;
  int consumedProtein = 0;
  int maxProtein = 150;
  int consumedCarbs = 0;
  int maxCarbs = 620;
  int consumedFat = 0;
  int maxFat = 220;
  bool _saving = false;

  int _parseValue(dynamic raw) {
    if (raw == null) return 0;
    final match = RegExp(r'[\d.]+').firstMatch(raw.toString());
    if (match == null) return 0;
    return double.tryParse(match.group(0)!)?.round() ?? 0;
  }

  Widget _buildNutrientRow(
    String label,
    int current,
    int max,
    Color progressColor,
  ) {
    final double percent = (current / max).clamp(0.0, 1.0);
    final String unit = label == "calories" ? "kcal" : "g";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Text(
                "$current $unit / $max $unit",
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                "${(percent * 100).round()}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
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
                    key: _riceKey,
                    title: "Steamed Rice",
                    imagePath: "lib/assets/rice.jpg",
                    items: const [
                      FoodItem(
                        name: "Rice, Basmati, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Fried Rice",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Milk Rice, Red",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Milk Rice, White",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Rice, Keeri Samba, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Rice, Red Kekulu, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Rice, Samba, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Rice, White Kekulu, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Rice, White Nadu, Boiled",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Yellow Rice",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    key: _mallumKey,
                    title: "Mallum (Greens)",
                    imagePath: "lib/assets/mallum.jpg",
                    items: const [
                      FoodItem(
                        name: "Mallum",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                    ],
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
                    key: _veg1Key,
                    title: "Vegetable Curry 1",
                    imagePath: "lib/assets/veg1.jpg",
                    items: const [
                      FoodItem(
                        name: "Ash Plantain, White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Baby Jackfruit Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Beans Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Beetroot Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Bittergourd Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Breadfruit Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Brinjal Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Cabbage White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Carrot Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Cashew Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Spinach",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Thick",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Watery",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Drumstick (Muranga) Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Kohila Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Leeks Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Mushroom Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Okra White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Potato Curry, White",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Pumpkin Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Radish Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Snakegourd Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Soya Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Sweet Potato Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    key: _veg2Key,
                    title: "Vegetable Curry 2",
                    imagePath: "lib/assets/veg2.jpg",
                    items: const [
                      FoodItem(
                        name: "Ash Plantain, White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Baby Jackfruit Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Beans Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Beetroot Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Bittergourd Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Breadfruit Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Brinjal Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Cabbage White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Carrot Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Cashew Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Spinach",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Thick",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dhal Curry, Watery",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Drumstick (Muranga) Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Kohila Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Leeks Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Mushroom Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Okra White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Potato Curry, White",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Pumpkin Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Radish Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Snakegourd Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Soya Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Sweet Potato Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                    ],
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
                    key: _meatKey,
                    title: "Meat",
                    imagePath: "lib/assets/meat.jpg",
                    items: const [
                      FoodItem(
                        name: "Beef Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Canned Salmon (Mackeral) Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Chicken Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Chili Fish Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Cuttlefish Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Devilled Chicken",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Devilled Fish",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Dry Fish Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Fish Ambul Thiyal",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Fish, White Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Meat Balls Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Prawn Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Sprats Curry",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    key: _saladKey,
                    title: "Fresh Salad",
                    imagePath: "lib/assets/salad.jpg",
                    items: const [
                      FoodItem(
                        name: "Cucumber Salad",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Fruit Salad",
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Parsley",
                        calories: 0,
                        protein: 0,
                        carbs: 9,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Snake Gourd And Onion Salad",
                        calories: 0,
                        protein: 0,
                        carbs: 9,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Tomato Salad",
                        calories: 0,
                        protein: 0,
                        carbs: 9,
                        fat: 0,
                      ),
                      FoodItem(
                        name: "Vegetable Salad",
                        calories: 0,
                        protein: 0,
                        carbs: 9,
                        fat: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// YOUR CUSTOM PLATE (already perfect)
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lines 361-369 — replace all with:
                  _buildNutrientRow(
                    "calories",
                    consumedCalories,
                    maxCalories,
                    Colors.greenAccent,
                  ),
                  _buildNutrientRow(
                    "protein",
                    consumedProtein,
                    maxProtein,
                    Colors.red,
                  ),
                  _buildNutrientRow(
                    "carbs",
                    consumedCarbs,
                    maxCarbs,
                    Colors.yellow,
                  ),
                  _buildNutrientRow("fat", consumedFat, maxFat, Colors.blue),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(
                  Icons.restaurant,
                  color: Colors.black,
                  size: 28,
                ),
                label: const Text(
                  "Save my recipe",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        if ([
                          _riceKey.currentState?.selectedFoodName,
                          _mallumKey.currentState?.selectedFoodName,
                          _veg1Key.currentState?.selectedFoodName,
                          _veg2Key.currentState?.selectedFoodName,
                          _meatKey.currentState?.selectedFoodName,
                          _saladKey.currentState?.selectedFoodName,
                        ].any((s) => s == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select all 6 food items'),
                            ),
                          );
                          return;
                        }

                        setState(() => _saving = true);

                        try {
                          final result = await ApiService.saveMealPrep(
                            rice: _riceKey.currentState!.selectedFoodName!,
                            riceSize: _riceKey.currentState!.currentWeight,
                            meat: _meatKey.currentState!.selectedFoodName!,
                            meatSize: _meatKey.currentState!.currentWeight,
                            vegetable1:
                                _veg1Key.currentState!.selectedFoodName!,
                            vegetable1Size:
                                _veg1Key.currentState!.currentWeight,
                            vegetable2:
                                _veg2Key.currentState!.selectedFoodName!,
                            vegetable2Size:
                                _veg2Key.currentState!.currentWeight,
                            mallum: _mallumKey.currentState!.selectedFoodName!,
                            mallumSize: _mallumKey.currentState!.currentWeight,
                            salad: _saladKey.currentState!.selectedFoodName!,
                            saladSize: _saladKey.currentState!.currentWeight,
                          );

                          // ── Parse backend response into the bars ──
                          setState(() {
                            consumedCalories = _parseValue(
                              result["Calory consumed: "],
                            );
                            maxCalories = _parseValue(
                              result["Calory requirement: "],
                            );
                            consumedProtein = _parseValue(
                              result["Protein consumed: "],
                            );
                            maxProtein = _parseValue(
                              result["Protein requirement: "],
                            );
                            consumedCarbs = _parseValue(
                              result["Carbohydrate consumed: "],
                            );
                            maxCarbs = _parseValue(
                              result["Carbohydrate requirement: "],
                            );
                            consumedFat = _parseValue(result["Fat consumed: "]);
                            maxFat = _parseValue(result["Fat requirement: "]);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Meal saved!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          setState(() => _saving = false);
                        }
                      },
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

/// MEAL CARD — Calorie badge now on image (green box with flame) + Figma background
class MealCard extends StatefulWidget {
  final String title;
  final List<FoodItem> items;

  final String imagePath;

  const MealCard({
    super.key,
    required this.title,
    required this.items,

    required this.imagePath,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  // Newly add
  String? get selectedFoodName => selectedItem?.name;
  int get currentWeight => getWeight();
  //

  int count = 0;
  FoodItem? selectedItem;
  final TextEditingController weightController = TextEditingController(
    text: "100",
  );

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

    setState(() => count++);
  }

  void decrease() {
    if (count > 0 && selectedItem != null) {
      final macros = calculateMacros();

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
        color: const Color(0xFF1A2F22), // Figma card color
      ),
      child: Column(
        children: [
          // IMAGE WITH GREEN CALORIE BADGE (exactly like Figma)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.asset(
                  widget.imagePath,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.items.first.calories}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.title)),
                    const SizedBox(),
                  ],
                ),
                DropdownButton<FoodItem>(
                  value: selectedItem,
                  hint: const Text("Select option"),
                  isExpanded: true,
                  items: widget.items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
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
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.greenAccent,
                      ),
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
