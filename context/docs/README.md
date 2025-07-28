# BravoBall Development Context

## 🎯 AI-Optimized Context System

This directory contains focused documentation designed for AI assistants. Instead of large monolithic files, we use small, targeted context files that can be selectively provided based on the specific task.

## 📏 Context Guidelines

### File Size Limits
- **Individual files**: Max 200 lines (~5KB)
- **Total AI context**: Max 3-4 files per session
- **Focus principle**: Only provide relevant context

### Quick Start
1. **Check** `CONTEXT_GUIDE.md` for task-specific file recommendations
2. **Choose** 1-2 relevant files based on your current task
3. **Provide** focused context to AI assistant
4. **Iterate** by adding more specific context if needed

## 📁 File Structure

### 🚀 Quick References (50 lines each)
- `flutter_quick_ref.md` - Essential Flutter patterns
- `python_quick_ref.md` - Essential Python/FastAPI patterns  
- `state_coordination.md` - State management & race condition prevention

### 🎯 Focused Topics (100-200 lines each)
- `flutter_state_management.md` - Provider, BLoC, Riverpod patterns
- `flutter_widgets.md` - Widget best practices & performance
- `python_api_design.md` - FastAPI endpoints & validation
- `python_database.md` - SQLAlchemy patterns & optimization
- `design_patterns_core.md` - SOLID, Clean Architecture
- `security_patterns.md` - Authentication & data protection

## 🛠️ Usage Examples

### For Flutter State Issues
```
📂 Provide: flutter_quick_ref.md + state_coordination.md
🎯 Perfect for: Race conditions, state management bugs
```

### For API Development
```
📂 Provide: python_quick_ref.md + python_api_design.md
🎯 Perfect for: New endpoints, validation, error handling
```

### For Architecture Planning
```
📂 Provide: design_patterns_core.md + state_coordination.md
🎯 Perfect for: System design, refactoring, scalability
```

## 📋 Context Selection Workflow

1. **Identify Task**: What are you trying to accomplish?
2. **Check Guide**: Look at `CONTEXT_GUIDE.md` for recommendations
3. **Start Small**: Begin with 1-2 most relevant files
4. **Add Iteratively**: Include more context only if needed
5. **Stay Focused**: Avoid unrelated documentation

## 🔄 Context Rotation Strategy

Instead of dumping all context at once:
- **Session 1**: Basic patterns (quick refs)
- **Session 2**: Add specific patterns (focused topics)
- **Session 3**: Start fresh if context gets too large

## 💡 Best Practices

### For AI Context
- **Task-driven**: Let the specific task guide context selection
- **Start minimal**: Begin with the smallest relevant context
- **Iterate**: Add more context incrementally as needed
- **Refresh**: Start new conversations for different tasks

### For File Creation
- **Single responsibility**: Each file focuses on one topic
- **Practical examples**: Include real-world usage patterns
- **Actionable**: Provide copy-pasteable code snippets
- **Searchable**: Use clear headings and structure

## 📊 Context Effectiveness

### High-Value Context (Always useful)
- `flutter_quick_ref.md` - Common patterns you'll use daily
- `python_quick_ref.md` - Essential backend patterns
- `state_coordination.md` - Critical for race condition prevention

### Specialized Context (Task-specific)
- Architecture patterns for planning/refactoring
- Security patterns for authentication/validation
- Performance patterns for optimization tasks

## 🎓 Context Training

### For New Team Members
1. Start with quick references
2. Practice with focused topics
3. Learn context selection strategies
4. Build task-specific context combinations

### For AI Assistants
1. Provide context selection guide first
2. Use focused, relevant files only
3. Iterate based on AI responses
4. Refresh context for new tasks

---

**Remember**: The goal is to provide just enough context for the AI to understand your specific task without overwhelming it with irrelevant information. 