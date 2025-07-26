class CSVParser {
  // Parse 2024 CSV format: "January 9,TRUE,Kristine"
  static List<Map<String, dynamic>> parse2024CSV(String csvData) {
    final lines = csvData.trim().split('\n');
    final models = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 3) {
        final dateStr = parts[0].trim();
        final name = parts[2].trim();
        
        // Skip empty names, special events, or invalid entries
        if (name.isEmpty || 
            name == 'OFF' || 
            name == 'cancelled' || 
            name == 'holiday!' ||
            name == 'PUMPKIN CARVING' ||
            name == 'SHOW AUGUST 13' ||
            name == 'SHOW MARCH 30' ||
            name == 'SHOW October 17th' ||
            name == 'Canceled' ||
            name == 'SNOW DAY' ||
            name == 'x') {
          continue;
        }
        
        // Parse date
        final date = _parse2024Date(dateStr);
        if (date == null) continue;
        
        // Determine notes
        String? notes;
        String cleanName = name;
        if (name.contains('(') && name.contains(')')) {
          // Extract notes from parentheses
          final nameParts = name.split('(');
          cleanName = nameParts[0].trim();
          notes = nameParts[1].replaceAll(')', '').trim();
        }
        
        models.add({
          'name': cleanName,
          'date': date,
          'isActive': true, // All imported models are active
          'notes': notes,
        });
      }
    }
    
    return models;
  }
  
  // Parse 2025 CSV format: "1/6/2025 21:00:00,Geoffrey Barber"
  static List<Map<String, dynamic>> parse2025CSV(String csvData) {
    final lines = csvData.trim().split('\n');
    final models = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 2) {
        final dateStr = parts[0].trim();
        final name = parts[1].trim();
        
        // Skip empty names
        if (name.isEmpty) continue;
        
        // Parse date
        final date = _parse2025Date(dateStr);
        if (date == null) continue;
        
        models.add({
          'name': name,
          'date': date,
          'isActive': true,
          'notes': null,
        });
      }
    }
    
    return models;
  }
  
  // Parse 2024 date format: "January 9"
  static DateTime? _parse2024Date(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 2) {
        final month = parts[0];
        final day = int.parse(parts[1]);
        
        final monthMap = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4,
          'May': 5, 'June': 6, 'July': 7, 'August': 8,
          'September': 9, 'October': 10, 'November': 11, 'December': 12,
        };
        
        final monthNum = monthMap[month];
        if (monthNum != null) {
          return DateTime(2024, monthNum, day);
        }
      }
    } catch (e) {
      print('Error parsing 2024 date: $dateStr - $e');
    }
    return null;
  }
  
  // Parse 2025 date format: "1/6/2025 21:00:00"
  static DateTime? _parse2025Date(String dateStr) {
    try {
      // Extract just the date part before the time
      final datePart = dateStr.split(' ')[0];
      final parts = datePart.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing 2025 date: $dateStr - $e');
    }
    return null;
  }
} 