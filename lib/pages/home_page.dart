import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> recipes = [];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final ingredientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    setState(() {
      recipes = response;
    });
  }

  Future<void> addRecipe() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final ingredients = ingredientsController.text.trim().split(',');

    if (name.isEmpty || ingredients.isEmpty) return;

    await supabase.from('recipes').insert({
      'user_id': widget.userId,
      'title': name,
      'description': description,
      'ingredients': '{${ingredients.join(',')}}',
    });

    Navigator.of(context).pop();
    clearForm();
    fetchRecipes();
  }

  Future<void> updateRecipe(String recipeId) async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final ingredients = ingredientsController.text.trim().split(',');

    if (name.isEmpty || ingredients.isEmpty) return;

    await supabase
        .from('recipes')
        .update({
          'title': name,
          'description': description,
          'ingredients': ingredients.map((e) => e.trim()).toList(),
        })
        .eq('id', recipeId);

    Navigator.of(context).pop();
    clearForm();
    fetchRecipes();
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    ingredientsController.clear();
  }

  void showAddRecipeDialog() {
    clearForm();
    showDialog(
      context: context,
      builder:
          (_) => recipeFormDialog(title: 'Tambah Resep', onSave: addRecipe),
    );
  }

  void showEditRecipeDialog(dynamic recipe) {
    nameController.text = recipe['title']?.toString() ?? '';
    descriptionController.text = recipe['description']?.toString() ?? '';
    ingredientsController.text =
        recipe['ingredients'] is List
            ? (recipe['ingredients'] as List).join(', ')
            : '';
    showDialog(
      context: context,
      builder:
          (_) => recipeFormDialog(
            title: 'Edit Resep',
            onSave:
                () => updateRecipe(recipe['id'].toString()), // ← ubah ke string
          ),
    );
  }

  void showDetailDialog(dynamic recipe) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(recipe['title']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deskripsi:\n${recipe['description'] ?? '-'}'),
                const SizedBox(height: 12),
                Text('Bahan:'),
                const SizedBox(height: 6),
                if (recipe['ingredients'] is List)
                  ...List.generate(
                    (recipe['ingredients'] as List).length,
                    (i) => Text('- ${(recipe['ingredients'] as List)[i]}'),
                  )
                else
                  Text('-'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Widget recipeFormDialog({
    required String title,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Resep'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Bahan (pisahkan dengan koma)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: onSave, child: const Text('Simpan')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          email != null ? 'Hi, ${email.split('@').first}' : 'Resep Saya',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },

            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body:
          recipes.isEmpty
              ? const Center(child: Text('Belum ada resep.'))
              : ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final r = recipes[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      onTap: () => showDetailDialog(r),
                      title: Text(r['title']),
                      subtitle: Text(r['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showEditRecipeDialog(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await supabase
                                  .from('recipes')
                                  .delete()
                                  .eq('id', r['id']);
                              fetchRecipes();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddRecipeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
