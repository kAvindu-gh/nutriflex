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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int mealsThisWeek = 12;
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, String>> recipes = [
    {
      'image': 'assets/images/protein_bowl.jpg',
      'title': 'Power Protein Bowl',
      'calories': '520',
      'protein': '40g',
      'tag': 'Muscle Gain',
    },
    {
      'image': 'assets/images/grilled_chicken.jpg',
      'title': 'Lean Grilled Chicken',
      'calories': '380',
      'protein': '50g',
      'tag': 'Weight Loss',
    },
    {
      'image': 'assets/images/green_salad.jpg',
      'title': 'Fresh Green Salad',
      'calories': '220',
      'protein': '12g',
      'tag': 'Weight Loss',
    },
    {
      'image': 'assets/images/smoothie.jpg',
      'title': 'Energy Smoothie',
      'calories': '318',
      'protein': '20g',
      'tag': 'Muscle Gain',
    },
  ];

  void _increaseMeals() {
    setState(() => mealsThisWeek++);
  }

  void _decreaseMeals() {
    setState(() {
      if (mealsThisWeek > 0) mealsThisWeek--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = recipes
        .where((recipe) =>
            recipe['title']!
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildStats(),
              const SizedBox(height: 30),
              _buildTrendingHeader(),
              const SizedBox(height: 16),

              // 🔍 SEARCH RESULT HANDLING
              if (filteredRecipes.isEmpty && searchQuery.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'Searched Recipe Not Found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ...filteredRecipes.map((recipe) => _recipeCard(
                      image: recipe['image']!,
                      title: recipe['title']!,
                      calories: recipe['calories']!,
                      protein: recipe['protein']!,
                      tag: recipe['tag']!,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NutriFlex',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Discover premium meals',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.green),
          onPressed: () {
            debugPrint('Cart clicked');
          },
        ),
      ],
    );
  }

  // 🔹 SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.green),
          hintText: 'Search recipes...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 🔹 STATS
  Widget _buildStats() {
    return Row(
      children: [
        _statCard('2,400', 'Daily Calories'),
        const SizedBox(width: 16),
        _statCard(mealsThisWeek.toString(), 'Meals This Week'),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 🔹 TRENDING HEADER (NOW CLICKABLE ✅)
  Widget _buildTrendingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Trending Recipes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: () {
            debugPrint('See all clicked');
          },
          child: const Text(
            'See all',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  // 🔹 RECIPE CARD
  Widget _recipeCard({
    required String image,
    required String title,
    required String calories,
    required String protein,
    required String tag,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              image,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$calories Calories • $protein Protein',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Chip(
                  label: Text(tag),
                  backgroundColor: Colors.green.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.green),
                onPressed: _decreaseMeals,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: _increaseMeals,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 BOTTOM NAV
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu), label: 'Meal Prep'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined), label: 'BMI'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts'),
      ],
    );
  }
}