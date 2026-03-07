import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final Color primaryGreen = const Color(0xFF1ED760);
  final Color cardColor = const Color(0xFF121212);

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {

    final filteredRecipes = recipes
        .where((recipe) =>
        recipe['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,

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

              if (filteredRecipes.isEmpty && searchQuery.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'Searched Recipe Not Found',
                      style: TextStyle(color: Colors.grey),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'NutriFlex',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 4),

            Text(
              'Discover premium meals',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),

        Row(
          children: [

            IconButton(
              icon: Icon(Icons.shopping_cart, color: primaryGreen),
              onPressed: () {},
            ),

            IconButton(
              icon: Icon(Icons.logout, color: primaryGreen),
              onPressed: _logout,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          icon: Icon(Icons.search, color: primaryGreen),
          hintText: 'Search recipes...',
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _statCard('2,400', 'Daily calories'),
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
          color: primaryGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        const Text(
          'Trending Recipes',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),

        InkWell(
          onTap: () {},
          child: Text(
            'See all',
            style: TextStyle(color: primaryGreen),
          ),
        ),
      ],
    );
  }

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
        color: cardColor,
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

                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                const SizedBox(height: 4),

                Text(
                  '$calories Calories • $protein Protein',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 6),

                /// Modified Chip
                Chip(
                  label: Text(tag),
                  backgroundColor: const Color(0xFF064E3B), // dark green
                  labelStyle: const TextStyle(
                    color: Color(0xFF34F5A3), // light green
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [

              IconButton(
                icon: Icon(Icons.remove_circle, color: primaryGreen),
                onPressed: _decreaseMeals,
              ),

              IconButton(
                icon: Icon(Icons.add_circle, color: primaryGreen),
                onPressed: _increaseMeals,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,

      onTap: (i) {
        setState(() {
          _selectedIndex = i;
        });
      },

      backgroundColor: Colors.black,

      type: BottomNavigationBarType.fixed,

      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Meal Prep',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: 'BMI',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
      ],
    );
  }
}
