import 'package:flutter/material.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Meal Prep Builder",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Create your perfect Sri Lankan Meal plate",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          )
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
                    imagePath: "assets/images/rice.jpg",
                    items: const [
                      FoodItem(name: "Basmati", calories: 180),
                      FoodItem(name: "Basmati", calories: 180),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Mallum (Greens)",
                    calories: 85,
                    imagePath: "assets/images/mallum.jpg",
                    items: const [
                      FoodItem(name: "Gotukola", calories: 85),
                      FoodItem(name: "Mukunuwenna", calories: 85),
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
                    imagePath: "assets/images/veg1.jpg",
                    items: const [
                      FoodItem(name: "Carrots", calories: 120),
                      FoodItem(name: "Potato", calories: 120),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Vegetable Curry 2",
                    calories: 95,
                    imagePath: "assets/images/veg2.jpg",
                    items: const [
                      FoodItem(name: "Beans", calories: 95),
                      FoodItem(name: "Bell Pepper", calories: 95),
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
                    imagePath: "assets/images/meat.jpg",
                    items: const [
                      FoodItem(name: "Chicken", calories: 250),
                      FoodItem(name: "Salmon", calories: 250),
                    ],
                    onChanged: updateCalories,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MealCard(
                    title: "Fresh Salad",
                    calories: 65,
                    imagePath: "assets/images/salad.jpg",
                    items: const [
                      FoodItem(name: "Lettuce", calories: 65),
                      FoodItem(name: "Cucumber", calories: 65),
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
                      const Text("Total Meal Calories",
                          style: TextStyle(fontSize: 18)),
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
                    backgroundColor: Colors.grey,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("0 cal"),
                      Text("2400 cal goal"),
                    ],
                  )
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.black),
                label: const Text(
                  "Save my recipe",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAV BAR
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Meal Prep"),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: "BMI"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
        ],
      ),
    );
  }
}

/// FOOD MODEL
class FoodItem {
  final String name;
  final int calories;

  const FoodItem({required this.name, required this.calories});
}

/// MEAL CARD WITH IMAGE
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
  late List<int> counts;

  @override
  void initState() {
    super.initState();
    counts = List.generate(widget.items.length, (_) => 0);
  }

  void increase(int index) {
    setState(() => counts[index]++);
    widget.onChanged(widget.items[index].calories);
  }

  void decrease(int index) {
    if (counts[index] > 0) {
      setState(() => counts[index]--);
      widget.onChanged(-widget.items[index].calories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(widget.imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.2),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE + CALORIES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${widget.calories}",
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),

            const Spacer(),

            /// ITEMS
            Column(
              children: List.generate(widget.items.length, (index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.items[index].name,
                        style: const TextStyle(color: Colors.white)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.grey),
                          onPressed: () => decrease(index),
                        ),
                        Text("${counts[index]}",
                            style: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.greenAccent),
                          onPressed: () => increase(index),
                        ),
                      ],
                    )
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}