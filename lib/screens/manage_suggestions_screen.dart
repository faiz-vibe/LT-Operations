import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManageSuggestionsScreen extends StatefulWidget {
  const ManageSuggestionsScreen({super.key});

  @override
  State<ManageSuggestionsScreen> createState() => _ManageSuggestionsScreenState();
}

class _ManageSuggestionsScreenState extends State<ManageSuggestionsScreen> {
  String _selectedCategory = 'Vehicle Number';
  final _textController = TextEditingController();

  // Category aur unke Hive Box names ka mapping
  final Map<String, String> _categoryBoxes = {
    'Vehicle Number': 'vehicles',
    'Driver Name': 'drivers',
    'Driver Mobile': 'driver_mobiles',
    'Company Name': 'companies',
    'Damage Details': 'damage_details',
    'Locations': 'locations',
  };

  void _addWord() {
    // PRO FIX: Extra spaces hatao (trim)
    final rawWord = _textController.text.trim();
    if (rawWord.isEmpty) return;

    final boxName = _categoryBoxes[_selectedCategory]!;
    final box = Hive.box<String>(boxName);

    // Vehicle number ko uppercase banao
    final word = _selectedCategory == 'Vehicle Number'
        ? rawWord.toUpperCase()
        : rawWord;

    // PRO FIX: Case-insensitive check (bade-chhote letter ka farq na khe)
    final exists = box.values.any((val) => val.toLowerCase() == word.toLowerCase());

    if (!exists) {
      box.put(word, word);
    }

    _textController.clear();
    Navigator.pop(context);
  }

  void _showAddEditDialog({String? existingWord}) {
    _textController.text = existingWord ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingWord == null ? 'Add New Word' : 'Edit Word'),
        content: TextField(
          controller: _textController,
          textCapitalization: _selectedCategory == 'Vehicle Number'
              ? TextCapitalization.characters
              : TextCapitalization.words,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (existingWord != null) {
                // Pehle purana word delete karein
                final boxName = _categoryBoxes[_selectedCategory]!;
                Hive.box<String>(boxName).delete(existingWord);
              }
              _addWord();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boxName = _categoryBoxes[_selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Dictionary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Selector Dropdown
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categoryBoxes.keys.map((String category) {
                return DropdownMenuItem<String>(value: category, child: Text(category));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                });
              },
            ),
          ),

          // List of Words
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<String>(boxName).listenable(),
              builder: (context, Box<String> box, _) {
                final words = box.values.toList();

                if (words.isEmpty) {
                  return const Center(child: Text('Koi word save nahi hai.\nNiche + button dabakar add karein.', textAlign: TextAlign.center));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return Card(
                      child: ListTile(
                        title: Text(word, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(existingWord: word),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                box.delete(word);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}