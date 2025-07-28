import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../models/model_model.dart';
import '../theme/app_theme.dart';

class ModelDataInjectionScreen extends StatefulWidget {
  const ModelDataInjectionScreen({super.key});

  @override
  State<ModelDataInjectionScreen> createState() => _ModelDataInjectionScreenState();
}

class _ModelDataInjectionScreenState extends State<ModelDataInjectionScreen> {
  bool _isLoading = false;
  String _status = '';

  // Model data from the provided list
  final List<Map<String, dynamic>> _modelData = [
    {'name': 'Angel', 'date': '2023-01-16'},
    {'name': 'Nicole Z', 'date': '2023-01-23'},
    {'name': 'Lacy', 'date': '2023-01-30'},
    {'name': 'Eugene', 'date': '2023-02-06'},
    {'name': 'Jon', 'date': '2023-02-13'},
    {'name': 'Eli', 'date': '2023-03-06'},
    {'name': 'Lucy', 'date': '2023-04-02'},
    {'name': 'Jons dad (Joel)', 'date': '2023-04-10'},
    {'name': 'Alex', 'date': '2023-04-17'},
    {'name': 'Clare', 'date': '2023-05-01'},
    {'name': 'Sam', 'date': '2023-05-08'},
    {'name': 'Molissa', 'date': '2023-05-15'},
    {'name': 'Sfina', 'date': '2023-05-22'},
    {'name': 'Alex', 'date': '2023-05-29'},
    {'name': 'OFF', 'date': '2023-06-05'},
    {'name': 'Sara', 'date': '2023-06-12'},
    {'name': 'Josh', 'date': '2023-06-19'},
    {'name': 'Kyle Lotfi', 'date': '2023-06-26'},
    {'name': 'Taj Weir', 'date': '2023-07-03'},
    {'name': 'Ciree', 'date': '2023-07-10'},
    {'name': 'Kevin Ricker', 'date': '2023-07-17'},
    {'name': 'Yong', 'date': '2023-07-24'},
    {'name': 'Kristine', 'date': '2023-07-31'},
    {'name': 'Jake Simone', 'date': '2023-08-14'},
    {'name': 'Efe Brock', 'date': '2023-08-21'},
    {'name': 'Jeb', 'date': '2023-08-28'},
    {'name': 'Lauren Preller', 'date': '2023-09-04'},
    {'name': 'Mike Thornton', 'date': '2023-09-11'},
    {'name': 'Faisal Mahmood', 'date': '2023-09-18'},
    {'name': 'Chris Chester', 'date': '2023-09-25'},
    {'name': 'Caitlin Weaver', 'date': '2023-10-02'},
    {'name': 'Olivia Kus', 'date': '2023-10-09'},
    {'name': 'Kat porter', 'date': '2023-10-16'},
    {'name': 'Shannon (spooky lighting)', 'date': '2023-10-23'},
    {'name': 'Ginny', 'date': '2023-11-06'},
    {'name': 'Avi', 'date': '2023-11-20'},
    {'name': 'Caroline Brown', 'date': '2023-11-27'},
    {'name': 'glizzy guy', 'date': '2023-12-04'},
    {'name': 'Aeon Ginsberg', 'date': '2023-12-11'},
    {'name': 'Joshua Ramos', 'date': '2023-12-18'},
    {'name': 'Anna Droege', 'date': '2024-01-08'},
    {'name': 'James McManus', 'date': '2024-01-22'},
    {'name': 'Eugene!', 'date': '2024-01-29'},
    {'name': 'Allen Hiu', 'date': '2024-02-12'},
    {'name': 'Lynn Trumpower', 'date': '2024-02-19'},
    {'name': 'Jon M', 'date': '2024-02-26'},
    {'name': 'Sara', 'date': '2024-03-04'},
    {'name': 'Patrice', 'date': '2024-03-11'},
    {'name': 'Phyllis', 'date': '2024-03-18'},
    {'name': 'Kappy Lanning', 'date': '2024-03-25'},
    {'name': 'Bea Thomas', 'date': '2024-04-01'},
    {'name': 'Laurel Ady', 'date': '2024-04-08'},
    {'name': 'Aditi', 'date': '2024-04-15'},
    {'name': 'Taylor Breeding', 'date': '2024-04-22'},
    {'name': 'Genevieve Laton', 'date': '2024-04-29'},
    {'name': 'Evalyn', 'date': '2024-05-06'},
    {'name': 'Lauren Carlo', 'date': '2024-05-13'},
    {'name': 'Chris Digregorio', 'date': '2024-05-20'},
    {'name': 'Gaeme Thislewaite', 'date': '2024-05-27'},
    {'name': 'Jon Birkholz', 'date': '2024-06-03'},
    {'name': 'Nat Cone', 'date': '2024-06-10'},
    {'name': 'Jesse Sheldon', 'date': '2024-06-17'},
    {'name': 'Ginny Peters-Redbell', 'date': '2024-06-24'},
    {'name': 'Jillian Levine', 'date': '2024-07-01'},
    {'name': 'Ashley Denney', 'date': '2024-07-08'},
    {'name': 'Susan', 'date': '2024-07-15'},
    {'name': 'Ambrym Smith', 'date': '2024-07-22'},
    {'name': 'Diana Winter', 'date': '2024-07-29'},
    {'name': 'Jess Kupper', 'date': '2024-08-05'},
    {'name': 'Kyle Franacis', 'date': '2024-08-12'},
    {'name': 'Sam Sedon', 'date': '2024-08-19'},
    {'name': 'Sabrina', 'date': '2024-08-26'},
    {'name': 'Sara T', 'date': '2024-09-02'},
    {'name': 'Noella Whitney', 'date': '2024-09-09'},
    {'name': 'Jessica Smith', 'date': '2024-09-16'},
    {'name': 'Corey cavalorne', 'date': '2024-09-23'},
    {'name': 'Katie knaber', 'date': '2024-09-30'},
    {'name': 'vinicius', 'date': '2024-10-07'},
    {'name': 'Aaron Pietsch', 'date': '2024-10-14'},
    {'name': 'Chris Digregorio', 'date': '2024-10-28'},
    {'name': 'Diana', 'date': '2024-11-04'},
    {'name': 'Emma Staisloff', 'date': '2024-11-11'},
    {'name': 'Ryan Nicotra', 'date': '2024-11-18'},
    {'name': 'Riley Valentine', 'date': '2024-11-25'},
    {'name': 'bill bradford', 'date': '2024-12-02'},
    {'name': 'Natalia Celine Arias', 'date': '2025-01-13'},
    {'name': 'Lowi Wright-Kerr', 'date': '2025-01-20'},
    {'name': 'Chima Ezenwashi', 'date': '2025-01-27'},
    {'name': 'Taylor Breeding', 'date': '2025-02-03'},
    {'name': 'Ryan Eubanks', 'date': '2025-02-10'},
    {'name': 'Elizabeth Hannifin', 'date': '2025-02-17'},
    {'name': 'Jonathan Birkholz', 'date': '2025-02-24'},
    {'name': 'Vinicius Goecks', 'date': '2025-03-03'},
    {'name': 'Pamela Ahang', 'date': '2025-03-10'},
    {'name': 'Albert Nekimken', 'date': '2025-03-24'},
    {'name': 'Sam Seddon', 'date': '2025-03-31'},
    {'name': 'Alex Miletich', 'date': '2025-04-07'},
    {'name': 'Geroge Hasg', 'date': '2025-04-14'},
    {'name': 'Kenneth Bland', 'date': '2025-04-28'},
    {'name': 'Megan Lackay', 'date': '2025-05-05'},
    {'name': 'Olivia Kus', 'date': '2025-05-12'},
    {'name': 'Danielle Nekimken', 'date': '2025-05-19'},
    {'name': 'GinaBraden', 'date': '2025-06-02'},
    {'name': 'Janna Morton', 'date': '2025-06-09'},
    {'name': 'Larry bruder', 'date': '2025-06-16'},
    {'name': 'Phoebe Cochran', 'date': '2025-06-23'},
    {'name': 'Sarah stahl', 'date': '2025-06-30'},
    {'name': 'r. townsend', 'date': '2025-07-07'},
    {'name': 'Gregory Faith', 'date': '2025-07-14'},
    {'name': 'Cedar Clark', 'date': '2025-07-21'},
    {'name': 'Candy Jovan', 'date': '2025-07-28'},
    {'name': 'Casey', 'date': '2025-08-04'},
    {'name': 'Michael Ivan Schwartz', 'date': '2025-08-11'},
    {'name': 'Carol', 'date': '2025-08-18'},
    {'name': 'Evenlyn', 'date': '2025-08-25'},
    {'name': 'Mecca Lewis', 'date': '2025-09-08'},
    {'name': 'Rachel Glen', 'date': '2025-09-15'},
    {'name': 'Joshua Clarke', 'date': '2025-09-22'},
    {'name': 'Chris Digregorio', 'date': '2025-09-29'},
    {'name': 'Idelee Digregorio', 'date': '2025-10-06'},
    {'name': 'Pamela Pinto', 'date': '2025-10-13'},
    {'name': 'Megan Gelement', 'date': '2025-10-20'},
    {'name': 'Lovi Wright Kerr', 'date': '2025-10-27'},
    {'name': 'Lynn Trumpower', 'date': '2025-11-03'},
    {'name': 'Nadia Nazar', 'date': '2025-11-10'},
    {'name': 'Marissa Vazhappilly', 'date': '2025-11-17'},
    {'name': 'madaline Marland', 'date': '2025-11-24'},
    {'name': 'Dan Motz', 'date': '2025-12-01'},
    {'name': 'Brett Potter', 'date': '2025-12-08'},
    {'name': 'Elizabeth Hannifin', 'date': '2025-12-15'},
    {'name': 'Gabriel Carter', 'date': '2025-12-22'},
    {'name': 'Natalia Celine Aria', 'date': '2025-12-29'},
  ];

  Future<void> _injectModelData() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting model data injection...';
    });

    try {
      final modelProvider = Provider.of<ModelProvider>(context, listen: false);
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < _modelData.length; i++) {
        final modelData = _modelData[i];
        setState(() {
          _status = 'Adding model ${i + 1}/${_modelData.length}: ${modelData['name']}';
        });

        try {
          // Parse the date
          final dateParts = modelData['date'].split('-');
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final date = DateTime(year, month, day);

          // Create model
          await modelProvider.addModel(
            name: modelData['name'],
            date: date,
            imageFile: null, // No image initially
          );

          successCount++;
        } catch (e) {
          errorCount++;
          print('Error adding model ${modelData['name']}: $e');
        }

        // Small delay to avoid overwhelming the database
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _isLoading = false;
        _status = 'Injection complete! Successfully added $successCount models. Errors: $errorCount';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added $successCount models to the database!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error injecting model data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Data Injection'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Data Injection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will add ${_modelData.length} models to the database with their corresponding dates. This action cannot be undone.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isLoading ? Colors.blue.shade200 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _isLoading ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _injectModelData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Injecting Models...'),
                        ],
                      )
                    : const Text('Inject Model Data'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Models to be added:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _modelData.length,
                itemBuilder: (context, index) {
                  final model = _modelData[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.forestGreen,
                      child: Text(
                        model['name'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(model['name']),
                    subtitle: Text('Date: ${model['date']}'),
                    trailing: const Icon(Icons.person, color: AppColors.forestGreen),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 