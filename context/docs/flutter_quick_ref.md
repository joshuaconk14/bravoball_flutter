# Flutter Quick Reference

## State Management Essentials

### Provider Pattern
```dart
class AppStateService extends ChangeNotifier {
  String _data = '';
  bool _isLoading = false;
  
  String get data => _data;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _data = await fetchData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Consumer Usage
```dart
Consumer<AppStateService>(
  builder: (context, service, child) {
    if (service.isLoading) return CircularProgressIndicator();
    return Text(service.data);
  },
)
```

## Common Widget Patterns

### Stateless Widget
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Stateful Widget
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
```

## Performance Patterns

### ListView for Large Lists
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

### FutureBuilder
```dart
FutureBuilder<String>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    if (!snapshot.hasData) return CircularProgressIndicator();
    return Text(snapshot.data!);
  },
)
```

## Navigation
```dart
// Push
Navigator.push(context, MaterialPageRoute(builder: (_) => NewScreen()));

// Pop
Navigator.pop(context);

// Replace
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NewScreen()));
```

## Common Patterns
- **Always use const**: `const Text('Hello')`
- **Null safety**: Use `!` only when certain, prefer `?.` 
- **Async/await**: Wrap in try-catch blocks
- **Dispose**: Clean up controllers, timers, streams
- **Keys**: Use for lists and complex widgets 