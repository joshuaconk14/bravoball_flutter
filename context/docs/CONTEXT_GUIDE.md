# AI Context Selection Guide

## 🎯 Purpose
This guide helps you choose the right context files for specific AI tasks to avoid overwhelming the model with too much information.

## 📏 File Size Guidelines
- **Individual files**: Keep under 200 lines (~5KB)
- **Total context**: Max 3-4 files per AI session
- **Focus**: Provide only relevant context for the current task

## 🏗️ BravoBall Design Philosophy

### Single-File Architecture with Clean Principles
**Core Approach**: Maintain good app design principles while keeping related functionality in single files for optimal AI context and development efficiency.

#### Design Principles We Follow
- **Separation of Concerns**: Clear logical sections within files
- **Modularity**: Well-defined interfaces between components
- **Single Responsibility**: Each class/service has one clear purpose
- **Clean Architecture**: Proper dependency flow and abstraction
- **State Coordination**: Prevent race conditions with proper guards

#### Why Single-File When Possible
```
Traditional Approach:            Our AI-Optimized Approach:
├── service/                     ├── app_state_service.dart (1700 lines)
│   ├── user_service.dart        │   ├── // ===== SERVICES SECTION =====
│   ├── session_service.dart     │   ├── // ===== SYNC COORDINATION =====
│   ├── progress_service.dart    │   ├── // ===== SESSION MANAGEMENT =====
│   └── 15+ other files          │   ├── // ===== SEARCH SECTION =====
└── Hard for AI+humans to parse  │   └── // ===== PROGRESS TRACKING =====
                                 └── Easy for AI to understand full context
```

#### Key Benefits
- **AI Comprehension**: Complete context in one place
- **Faster Development**: No jumping between files
- **Easier Debugging**: See all related code together
- **Reduced Complexity**: Fewer import dependencies
- **Better State Management**: Centralized coordination

#### When to Split vs. Keep Together
**Keep in Single File:**
- Related state management (AppStateService)
- Coordinated operations (session generation, sync)
- Shared data models and utilities
- Feature-complete functionality

**Split When Necessary:**
- Truly independent features
- Platform-specific implementations
- Large view components (>300 lines)
- Reusable utility functions

## 🗂️ Context Categories

### For Flutter Development Tasks
```
Choose 1-2 files based on your specific task:
├── flutter_state_management.md     # State management patterns
├── flutter_widgets.md              # Widget best practices  
├── flutter_performance.md          # Performance optimization
├── flutter_testing.md              # Testing strategies
└── flutter_navigation.md           # Navigation patterns
```

### For Backend Development Tasks
```
Choose 1-2 files based on your specific task:
├── python_api_design.md            # FastAPI patterns
├── python_database.md              # SQLAlchemy & database
├── python_testing.md               # Testing strategies
├── python_security.md              # Security best practices
└── python_performance.md           # Performance optimization
```

### For Architecture & Design Tasks
```
Choose 1-2 files based on your specific task:
├── design_patterns_core.md         # SOLID, Clean Architecture
├── design_patterns_behavioral.md   # Observer, Strategy, Command
├── design_patterns_structural.md   # Repository, Factory, Adapter
├── state_coordination.md           # State machines, Coordinators
└── scalability_patterns.md         # CQRS, Event Sourcing
```

## 🎯 Task-Specific Context Selection

### Common Development Tasks

| Task | Recommended Context Files |
|------|---------------------------|
| **Flutter State Management** | `flutter_state_management.md` + `state_coordination.md` |
| **API Development** | `python_api_design.md` + `python_database.md` |
| **UI Bug Fixes** | `flutter_widgets.md` + `flutter_performance.md` |
| **Architecture Planning** | `design_patterns_core.md` + `scalability_patterns.md` |
| **Testing Implementation** | `flutter_testing.md` + `python_testing.md` |
| **Performance Issues** | `flutter_performance.md` + `python_performance.md` |
| **Security Review** | `python_security.md` + `general_security.md` |

### Example Usage
```
🎯 Task: "Fix race condition in Flutter app"
📂 Context: flutter_state_management.md + state_coordination.md

🎯 Task: "Optimize database queries" 
📂 Context: python_database.md + python_performance.md

🎯 Task: "Implement new API endpoint"
📂 Context: python_api_design.md + design_patterns_core.md
```

## 📝 Quick Reference Files
For rapid development, use these condensed references:
- `flutter_quick_ref.md` - Essential Flutter patterns (50 lines)
- `python_quick_ref.md` - Essential Python patterns (50 lines)
- `patterns_quick_ref.md` - Key design patterns (50 lines)

## 🔄 Context Rotation Strategy
Instead of providing all context at once:
1. **Start focused**: 1-2 relevant files
2. **Iterate**: Add more context if needed
3. **Refresh**: Start new conversation if context gets too large
4. **Specialize**: Use task-specific combinations

## 💡 Best Practices
- **Start small**: Begin with 1 relevant file
- **Stay focused**: Only add context related to current task
- **Use summaries**: Prefer quick reference versions when possible
- **Regular cleanup**: Remove outdated or irrelevant context
- **Task-driven**: Let the specific task guide context selection
- **Embrace single-file**: When it makes sense for AI comprehension
- **Maintain clean structure**: Use clear section comments and organization 