import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WelcomeScreen(),
  ));
}

// --- SCREEN 1: WELCOME SCREEN ---
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            Container(
              height: 120, width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withAlpha((0.3 * 255).round()),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.track_changes, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 50),
            const Text(
              "Welcome to NutriFlex",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Let's personalize your fitness journey.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalSelectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 2: GOAL SELECTION (1/5) ---
class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? selectedGoal;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> goals = [
      {"title": "Build Muscle", "icon": Icons.fitness_center},
      {"title": "Lose Weight", "icon": Icons.trending_down},
      {"title": "Maintain Weight", "icon": Icons.monitor_weight_outlined},
      {"title": "Improve Fitness", "icon": Icons.bolt},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar("1/5", 0.2),
              const SizedBox(height: 40),
              const Text(
                "What is your primary\ngoal?",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "This helps us personalize your meals.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return _buildSelectionCard(
                      goals[index]['title'],
                      goals[index]['icon'],
                      selectedGoal == goals[index]['title'],
                      () {
                        setState(() {
                          selectedGoal = goals[index]['title'];
                        });
                      },
                    );
                  },
                ),
              ),
              _buildContinueButton(
                isEnabled: selectedGoal != null,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActivitySelectionScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 3: ACTIVITY SELECTION (2/5) ---
class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({super.key});

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  String? selectedActivity;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activities = [
      {"title": "Sedentary", "icon": Icons.coffee},
      {"title": "Lightly Active", "icon": Icons.favorite_border},
      {"title": "Active", "icon": Icons.directions_bike},
      {"title": "Very Active", "icon": Icons.local_fire_department},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar("2/5", 0.4),
              const SizedBox(height: 40),
              const Text(
                "How active are you daily?",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We'll adjust your calorie needs accordingly.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    return _buildSelectionCard(
                      activities[index]['title'],
                      activities[index]['icon'],
                      selectedActivity == activities[index]['title'],
                      () {
                        setState(() {
                          selectedActivity = activities[index]['title'];
                        });
                      },
                    );
                  },
                ),
              ),
              // FIXED: Navigation added to move from 2/5 to 3/5
              _buildContinueButton(
                isEnabled: selectedActivity != null,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutPreferenceScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 4: WORKOUT PREFERENCES (3/5) ---
class WorkoutPreferenceScreen extends StatefulWidget {
  const WorkoutPreferenceScreen({super.key});

  @override
  State<WorkoutPreferenceScreen> createState() => _WorkoutPreferenceScreenState();
}

class _WorkoutPreferenceScreenState extends State<WorkoutPreferenceScreen> {
  String? selectedWorkout;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> workouts = [
      {"title": "Strength Training", "icon": Icons.fitness_center},
      {"title": "Yoga / Flexibility", "icon": Icons.favorite_outline},
      {"title": "Cardio", "icon": Icons.air},
      {"title": "Sports", "icon": Icons.emoji_events_outlined},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar("3/5", 0.6),
              const SizedBox(height: 40),
              const Text(
                "What type of workouts\ndo you prefer?",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Choose what you enjoy most.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return _buildSelectionCard(
                      workouts[index]['title'],
                      workouts[index]['icon'],
                      selectedWorkout == workouts[index]['title'],
                      () {
                        setState(() {
                          selectedWorkout = workouts[index]['title'];
                        });
                      },
                    );
                  },
                ),
              ),
              // FIXED: Navigation added to move from 3/5 to 4/5
              _buildContinueButton(
                isEnabled: selectedWorkout != null,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DietSelectionScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 5: DIET SELECTION (4/5) ---
class DietSelectionScreen extends StatefulWidget {
  const DietSelectionScreen({super.key});

  @override
  State<DietSelectionScreen> createState() => _DietSelectionScreenState();
}

class _DietSelectionScreenState extends State<DietSelectionScreen> {
  String? selectedDiet;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> diets = [
      {"title": "Non-Vegetarian", "icon": Icons.adjust},
      {"title": "Vegetarian", "icon": Icons.apple},
      {"title": "Vegan", "icon": Icons.eco}, // Replaced leaf_rounded with eco
      {"title": "No Preference", "icon": Icons.star_border_rounded},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar("4/5", 0.8),
              const SizedBox(height: 40),
              const Text(
                "Do you follow a specific\ndiet?",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "We'll recommend suitable recipes.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: diets.length,
                  itemBuilder: (context, index) {
                    return _buildSelectionCard(
                      diets[index]['title'],
                      diets[index]['icon'],
                      selectedDiet == diets[index]['title'],
                      () {
                        setState(() {
                          selectedDiet = diets[index]['title'];
                        });
                      },
                    );
                  },
                ),
              ),
              _buildContinueButton(
                isEnabled: selectedDiet != null,
                onPressed: () {
                  // Final navigation to Screen 5/5 or Completion
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SHARED REUSABLE WIDGETS ---

Widget _buildProgressBar(String text, double value) {
  return Row(
    children: [
      Text(text, style: const TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
      const SizedBox(width: 15),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFF1A1A1A),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
            minHeight: 8,
          ),
        ),
      ),
    ],
  );
}

Widget _buildSelectionCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF1DB954) : Colors.white.withAlpha((0.05 * 255).round()),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF1DB954) : Colors.white, size: 30),
          const SizedBox(height: 15),
          Text(title, style: TextStyle(color: isSelected ? const Color(0xFF1DB954) : Colors.white, fontSize: 14)),
        ],
      ),
    ),
  );
}

Widget _buildContinueButton({required bool isEnabled, required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1DB954),
        disabledBackgroundColor: const Color(0xFF1DB954).withAlpha((0.2 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        "Continue",
        style: TextStyle(
          color: isEnabled ? Colors.black : Colors.white24, 
          fontSize: 18, 
          fontWeight: FontWeight.bold
        ),
      ),
    ),
  );
}