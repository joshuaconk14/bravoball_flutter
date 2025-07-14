# Core Design Patterns

## SOLID Principles

### Single Responsibility Principle (SRP)
Each class should have only one reason to change.

```python
# Bad: Multiple responsibilities
class UserManager:
    def save_user(self, user): pass
    def send_email(self, user): pass
    def validate_user(self, user): pass

# Good: Single responsibility
class UserRepository:
    def save_user(self, user): pass

class EmailService:
    def send_email(self, user): pass
```

### Dependency Inversion Principle (DIP)
Depend on abstractions, not concretions.

```python
# Good: Depends on abstraction
class UserService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo
    
    def create_user(self, data):
        return self.user_repo.save(User(data))
```

## Repository Pattern
Separates data access logic from business logic.

```python
class UserRepository(ABC):
    @abstractmethod
    def save(self, user: User) -> User: pass
    
    @abstractmethod
    def find_by_id(self, id: int) -> User: pass

class SQLUserRepository(UserRepository):
    def __init__(self, db_session):
        self.db = db_session
    
    def save(self, user: User) -> User:
        self.db.add(user)
        self.db.commit()
        return user
    
    def find_by_id(self, id: int) -> User:
        return self.db.query(User).filter(User.id == id).first()
```

## Factory Pattern
Creates objects without specifying exact classes.

```dart
abstract class DatabaseAdapter {
  Future<void> connect();
}

class DatabaseFactory {
  static DatabaseAdapter create(String type) {
    switch (type) {
      case 'postgresql': return PostgreSQLAdapter();
      case 'sqlite': return SQLiteAdapter();
      default: throw ArgumentError('Unknown database type');
    }
  }
}
```

## Strategy Pattern
Encapsulates algorithms and makes them interchangeable.

```dart
abstract class SortingStrategy {
  List<int> sort(List<int> data);
}

class QuickSort implements SortingStrategy {
  List<int> sort(List<int> data) {
    // Quick sort implementation
    return data;
  }
}

class BubbleSort implements SortingStrategy {
  List<int> sort(List<int> data) {
    // Bubble sort implementation
    return data;
  }
}

class Sorter {
  final SortingStrategy strategy;
  Sorter(this.strategy);
  
  List<int> sortData(List<int> data) => strategy.sort(data);
}
```

## Observer Pattern
Notifies multiple objects about state changes.

```dart
abstract class Observer {
  void update(String event, dynamic data);
}

class Subject {
  final List<Observer> _observers = [];
  
  void subscribe(Observer observer) => _observers.add(observer);
  void unsubscribe(Observer observer) => _observers.remove(observer);
  
  void notify(String event, dynamic data) {
    for (final observer in _observers) {
      observer.update(event, data);
    }
  }
}

class UserCreatedNotifier implements Observer {
  void update(String event, dynamic data) {
    if (event == 'user_created') {
      print('Sending welcome email to ${data.email}');
    }
  }
}
```

## Clean Architecture Layers

### Entities (Core Business Logic)
```dart
class User {
  final String email;
  final String name;
  
  User({required this.email, required this.name});
  
  void changeEmail(String newEmail) {
    if (!newEmail.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
    // Update email
  }
}
```

### Use Cases (Application Logic)
```dart
class CreateUserUseCase {
  final UserRepository userRepo;
  final EmailService emailService;
  
  CreateUserUseCase(this.userRepo, this.emailService);
  
  Future<User> execute(String email, String name) async {
    if (await userRepo.findByEmail(email) != null) {
      throw Exception('User already exists');
    }
    
    final user = User(email: email, name: name);
    final savedUser = await userRepo.save(user);
    await emailService.sendWelcomeEmail(savedUser);
    
    return savedUser;
  }
}
```

### Interface Adapters (Controllers/Gateways)
```dart
class UserController {
  final CreateUserUseCase createUserUseCase;
  
  UserController(this.createUserUseCase);
  
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> request) async {
    try {
      final user = await createUserUseCase.execute(
        request['email'], 
        request['name']
      );
      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
```

## Best Practices
- **Start simple**: Don't over-engineer early
- **Favor composition**: Over inheritance when possible
- **Use interfaces**: For testability and flexibility
- **Single responsibility**: Each class has one job
- **Dependency injection**: For loose coupling
- **Test-driven**: Write tests to drive design decisions 