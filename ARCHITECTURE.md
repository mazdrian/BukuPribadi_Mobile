# 🏗️ Architecture & Code Structure

## Overview

The Kerja Praktik App follows a **Widget-Based Architecture** with clear separation of concerns, making it maintainable, scalable, and easy to understand. Built with Flutter and Dart.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  (Widgets: main.dart, Components)       │
│  - Stateful/Stateless Widgets           │
│  - User Interactions                    │
│  - Visual Presentation                  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Business Logic Layer           │
│  (internship_service.dart)              │
│  - CRUD Operations                      │
│  - Data Validation                      │
│  - Business Rules                       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Utility Layer                  │
│  (utils.dart, theme.dart)               │
│  - Helper Functions                     │
│  - Date Calculations                    │
│  - Design System                        │
└─────────────────────────────────────────┘
```

## File Structure & Responsibilities

### Root Level Files

#### `lib/main.dart` (Main Application)
**Purpose**: Root widget that orchestrates the entire app

**Key Responsibilities**:
- App initialization with MaterialApp
- State management with StatefulWidget
- Rendering main layout (header, stats, filters, list)
- Event handling (add, update, delete)
- Data fetching on mount

**State Variables**:
```dart
- internships: List<Internship>  // All internship data
- activeFilter: String           // Current filter selection
- _service: InternshipService    // Service instance
```

**Key Methods**:
```dart
- _loadInternships()           // Fetch data from service
- _handleAddInternship()       // Add new entry
- _handleUpdateStatus()        // Update status
- _handleDeleteInternship()    // Delete entry
```

---

### Code Folder Structure

#### `lib/code/theme.dart` (Design System)
**Purpose**: Centralized design tokens and styling constants

**Exports**:
- `AppColors`: Color palette (primary, secondary, status colors)
- `AppSpacing`: Spacing scale (xs, sm, md, lg, xl, xxl)
- `AppBorderRadius`: Border radius scale
- `AppFontSize`: Typography scale
- `AppTheme`: ThemeData configuration
- `StatusColors`: Status-specific color mappings

**Usage Pattern**:
```dart
import 'package:kerja_praktik_app/code/theme.dart';

Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
  ),
)
```

---

#### `lib/code/utils.dart` (Utility Functions)
**Purpose**: Reusable helper functions for common operations

**Key Functions**:

##### Date & Time
- `formatDate(DateTime, {format})` - Format dates to Indonesian locale
- `getDaysRemaining(DateTime, [DateTime?])` - Calculate days left
- `getDuration(DateTime, DateTime)` - Calculate duration
- `calculateProgress(DateTime, DateTime, [DateTime?])` - Calculate percentage
- `isPastDate(DateTime)` - Check if date is past
- `isToday(DateTime)` - Check if date is today
- `getRelativeTime(DateTime)` - Get relative time string

##### Validation
- `isValidEmail(String)` - Validate email format
- `isValidPhone(String)` - Validate Indonesian phone numbers

##### Data Manipulation
- `generateId()` - Generate unique IDs
- `truncateText(String, [int])` - Truncate long text
- `capitalizeFirst(String)` - Capitalize first letter
- `sortByDate<T>(List, Function, {bool})` - Sort by date field
- `groupBy<T, K>(List, Function)` - Group list by field

**Usage Pattern**:
```dart
import 'package:kerja_praktik_app/code/utils.dart';

final formatted = Utils.formatDate(DateTime.now(), format: 'medium');
final remaining = Utils.getDaysRemaining(endDate);
```

---

#### `lib/code/internship_service.dart` (Business Logic)
**Purpose**: Data management and business logic

**Data Structure** (from `models/internship.dart`):
```dart
class Internship {
  final String id;              // Unique identifier
  final String studentName;     // Student name
  final String company;         // Company name
  final String position;        // Job position
  final DateTime startDate;     // Start date
  final DateTime endDate;       // End date
  final String status;          // pending|active|completed|cancelled
  final String supervisor;      // Supervisor name
  final String phone;           // Phone number
  final String email;           // Email address
  final String description;     // Description
  final List<String> tasks;     // Task list
  final String notes;           // Additional notes
  final DateTime createdAt;     // Creation timestamp
  final DateTime? updatedAt;    // Update timestamp (optional)
}
```

**CRUD Operations**:
- `getAllInternships()` - Retrieve all records
- `getInternshipById(String)` - Get single record
- `addInternship(Internship)` - Create new record
- `updateInternship(String, Internship)` - Update record
- `updateStatus(String, String)` - Update status only
- `deleteInternship(String)` - Delete record

**Query Operations**:
- `searchInternships(String)` - Text search
- `filterByStatus(String)` - Filter by status
- `filterByDateRange(DateTime, DateTime)` - Date range filter
- `getActiveInternships()` - Get non-completed entries
- `getUpcomingInternships()` - Get future entries
- `getExpiringInternships()` - Get entries ending soon

**Analytics**:
- `getStatistics(List<Internship>)` - Calculate statistics
  - Returns: `Map<String, int>` with total, pending, active, completed, cancelled

**Data Storage**:
Currently uses in-memory storage (static List).

**Future Enhancement**:
```dart
// Replace with shared_preferences for persistence
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveData(List<Internship> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('internships', jsonEncode(data));
}
```

---

### Components Folder

#### `lib/code/components/internship_card.dart`
**Purpose**: Display individual internship in card format

**Props** (Constructor Parameters):
- `internship: Internship` - Internship data
- `onUpdateStatus: Function(String, String)` - Status update callback
- `onDelete: Function(String)` - Delete callback

**Features**:
- Card display with summary info
- Status badge with color coding
- Progress bar for active internships
- Detail modal with full information
- Action buttons (Activate, Complete, Delete)

**Subwidgets**:
- `_StatusBadge` - Colored status indicator
- `_InfoRow` - Information row in card
- `_DetailModal` - Full detail modal
- `_Section` - Information section in modal
- `_DetailRow` - Detail row in modal

---

#### `lib/code/components/stat_card.dart`
**Purpose**: Display statistics in compact card

**Props**:
- `title: String` - Card title
- `value: int` - Statistic value
- `color: Color` - Accent color
- `icon: String` - Emoji icon

**Features**:
- Color-coded left border
- Icon + text layout
- Large numeric display

---

#### `lib/code/components/add_internship_modal.dart`
**Purpose**: Form modal for adding new internship

**Props**:
- `onAdd: Function(Internship)` - Add callback

**State** (StatefulWidget):
- Form controllers for each field (TextEditingController)
- `_status: String` - Selected status
- `_formKey: GlobalKey<FormState>` - Form validation key

**Validation**:
- Required fields check (name, company, position, dates)
- Email format validation
- Phone format validation
- Date logic validation (end > start)

**Features**:
- Scrollable form
- Grouped sections
- Status toggle buttons
- Real-time validation with FormState
- Form reset on close/submit

**Subwidgets**:
- `_Section` - Form section grouping
- `_TextField` - Custom text field with label
- `_StatusButton` - Status toggle button

---

## Data Flow

### Adding New Internship

```
User Taps [+] Button (FloatingActionButton)
       ↓
HomePage: showModalBottomSheet(AddInternshipModal)
       ↓
AddInternshipModal: Widget Renders
       ↓
User Fills Form & Taps "Simpan"
       ↓
AddInternshipModal: Validates Data (_formKey.validate())
       ↓
AddInternshipModal: Calls widget.onAdd(internship)
       ↓
HomePage: _handleAddInternship(newInternship)
       ↓
InternshipService.addInternship(newInternship)
       ↓
HomePage: _loadInternships() [Refresh Data via setState]
       ↓
Navigator.pop() - Modal Closes
       ↓
UI Rebuilds with New Card
```

### Updating Status

```
User Taps Card (GestureDetector)
       ↓
InternshipCard: showModalBottomSheet(_DetailModal)
       ↓
User Taps "Aktifkan" or "Selesai"
       ↓
_DetailModal: Calls onUpdateStatus(id, newStatus)
       ↓
HomePage: _handleUpdateStatus(id, newStatus)
       ↓
InternshipService.updateStatus(id, newStatus)
       ↓
HomePage: _loadInternships() [Refresh via setState]
       ↓
Navigator.pop() - Modal Closes
       ↓
UI Updates Status Badge & Progress
```

### Filtering

```
User Taps Filter Button
       ↓
_FilterButton: onTap() callback
       ↓
HomePage: setState(() => activeFilter = status)
       ↓
HomePage: build() method called
       ↓
filteredInternships getter recalculates
       ↓
ListView.builder rebuilds with filtered data
       ↓
InternshipCard List Updates
```

---

## State Management

### Current Approach: setState
Using Flutter's built-in `setState` in StatefulWidget

**Advantages**:
- Simple and straightforward
- No external dependencies
- Sufficient for small/medium apps
- Part of Flutter framework

**State Updates**:
```dart
// Add
setState(() {
  _service.addInternship(newItem);
  internships = _service.getAllInternships();
});

// Update
setState(() {
  _service.updateStatus(id, status);
  internships = _service.getAllInternships();
});

// Delete
setState(() {
  _service.deleteInternship(id);
  internships = _service.getAllInternships();
});
```

### Future Scalability Options

#### Option 1: Provider
For app-wide state without complexity

```dart
// Create provider
class InternshipProvider extends ChangeNotifier {
  List<Internship> internships = [];
  
  void addInternship(Internship item) {
    internships.add(item);
    notifyListeners();
  }
}

// Use in widget
final provider = Provider.of<InternshipProvider>(context);
```

#### Option 2: Riverpod
Modern, compile-safe provider

```dart
// Define provider
final internshipsProvider = StateNotifierProvider<InternshipNotifier, List<Internship>>((ref) {
  return InternshipNotifier();
});

// Use in widget
final internships = ref.watch(internshipsProvider);
```

#### Option 3: BLoC
For complex state with business logic separation

```dart
// Define BLoC
class InternshipBloc extends Bloc<InternshipEvent, InternshipState> {
  @override
  Stream<InternshipState> mapEventToState(InternshipEvent event) async* {
    if (event is AddInternship) {
      yield InternshipAdded();
    }
  }
}

// Use in widget
BlocBuilder<InternshipBloc, InternshipState>(
  builder: (context, state) => /* widget */
)
```

---

## Error Handling

### Current Implementation
- AlertDialog for user errors
- Form validation with validators
- Debug print for development

### Enhancement Opportunities

#### Snackbar Notifications
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Data berhasil disimpan'),
    backgroundColor: AppColors.success,
  ),
);
```

#### Global Error Handler
```dart
void main() {
  FlutterError.onError = (details) {
    // Log error to service
    print(details.exception);
  };
  runApp(KerjaPraktikApp());
}
```

---

## Performance Optimizations

### Current Optimizations
- `const` constructors for immutable widgets
- `ListView.builder` for efficient list rendering
- StatelessWidget where state not needed

### Future Optimizations

#### Const Widgets
```dart
const Text('Static text'); // More efficient than Text('Static text')
```

#### Keys for List Items
```dart
ListView.builder(
  itemBuilder: (context, index) => InternshipCard(
    key: ValueKey(internships[index].id),
    internship: internships[index],
  ),
)
```

#### Computed Properties with Caching
```dart
late final int progress = _calculateProgress();
```

---

## Testing Strategy

### Unit Tests (Recommended)

#### Utils Testing
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kerja_praktik_app/code/utils.dart';

void main() {
  test('formatDate formats correctly', () {
    final date = DateTime(2026, 2, 10);
    expect(Utils.formatDate(date, format: 'short'), '10/02/2026');
  });
}
```

#### Service Testing
```dart
test('addInternship creates new record', () {
  final service = InternshipService();
  final newItem = Internship(/* ... */);
  final result = service.addInternship(newItem);
  expect(result.id, isNotEmpty);
});
```

### Widget Tests

```dart
import 'package:flutter_test/flutter_test.dart';

testWidgets('StatCard displays value', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StatCard(title: 'Total', value: 5, color: Colors.blue, icon: '📊'),
    ),
  );
  
  expect(find.text('5'), findsOneWidget);
  expect(find.text('Total'), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('adding internship updates list', (WidgetTester tester) async {
  await tester.pumpWidget(KerjaPraktikApp());
  
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  // Fill and submit form
  // Verify new card appears
});
```

---

## Security Considerations

### Current Implementation
- Input validation (email, phone)
- Date logic validation
- Confirmation dialogs for destructive actions

### Enhancement Recommendations

#### Data Sanitization
```dart
String sanitizeInput(String input) {
  return input.trim().replaceAll(RegExp(r'[<>]'), '');
}
```

#### Secure Storage
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'userToken', value: token);
```

---

## Extensibility Points

### Adding New Features

#### 1. File Upload
Add to internship data:
```dart
class Internship {
  // ... existing fields
  final List<Document> documents;
}

class Document {
  final String name;
  final String path;
}
```

#### 2. Notifications
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notifications = FlutterLocalNotificationsPlugin();

// Remind before internship ends
await notifications.schedule(
  0,
  'Internship ending soon!',
  'Your internship ends in 3 days',
  scheduledDate,
  notificationDetails,
);
```

#### 3. Reports/Export
```dart
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> exportToCSV(List<Internship> data) async {
  final rows = data.map((item) => [
    item.studentName,
    item.company,
    // ...
  ]).toList();
  
  final csv = const ListToCsvConverter().convert(rows);
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/export.csv');
  await file.writeAsString(csv);
}
```

#### 4. Multi-user Support
Add authentication with Firebase:
```dart
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;
await auth.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

---

## Naming Conventions

### Files
- snake_case for all files: `internship_card.dart`, `internship_service.dart`
- lowercase for config: `pubspec.yaml`, `analysis_options.yaml`

### Variables & Functions
- lowerCamelCase: `internships`, `handleAddInternship`
- Constants: `kUpperCamelCase` or `UPPER_SNAKE_CASE`
- Booleans: `isVisible`, `hasError`
- Private members: `_privateField`, `_privateMethod`

### Classes & Widgets
- UpperCamelCase: `InternshipCard`, `StatCard`, `HomePage`
- Private widgets: `_StatusBadge`, `_DetailModal`

---

## Code Style

### Formatting
- 2 spaces indentation
- Prefer single quotes for strings
- Trailing commas for better formatting
- Use `dart format` for automatic formatting

### Organization
- Imports at top (dart, flutter, package, relative)
- Widget/Class definition
- Build method (for widgets)
- Private methods
- No styles at bottom (inline with BoxDecoration)

### Comments
- DartDoc (`///`) for public APIs
- Inline comments for complex logic
- Section headers with `//`

### Dart-specific Conventions
```dart
// Use final for immutable variables
final String name = 'John';

// Use const for compile-time constants
const int maxAttempts = 3;

// Use late for late initialization
late final String computed;

// Prefer expression syntax for simple functions
int add(int a, int b) => a + b;
```

---

## Conclusion

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Reusable widgets
- ✅ Maintainable codebase
- ✅ Room for growth
- ✅ Easy testing
- ✅ Developer-friendly structure

Perfect foundation for a production-ready Flutter mobile app! 🚀
