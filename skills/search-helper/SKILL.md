---
name: search-helper
description: Grep-oriented code navigation assistant. Use when searching for code, understanding where things are defined, or navigating unfamiliar codebases. Provides systematic search strategies and grep patterns for common queries like "where is X defined?", "what calls Y?", "how is Z used?"
---

# Search Helper

Systematic grep-based code navigation strategies.

## Search Strategies

### Strategy 1: Finding Definitions

"Where is X defined?"

```bash
# Function definition (JavaScript/TypeScript)
grep -rn "function\s+functionName\|const\s+functionName\s*=" --include="*.ts" --include="*.js"

# Class definition
grep -rn "class\s+ClassName" --include="*.ts" --include="*.js"

# Interface/type definition
grep -rn "interface\s+TypeName\|type\s+TypeName" --include="*.ts"

# Variable/constant definition
grep -rn "const\s+CONSTANT_NAME\|let\s+variableName" --include="*.ts"

# Python function
grep -rn "def\s+function_name" --include="*.py"

# Go function
grep -rn "func\s+FunctionName\|func\s+(.*)\s+MethodName" --include="*.go"
```

### Strategy 2: Finding Usages

"What uses X?"

```bash
# Find all references
grep -rn "functionName" --include="*.ts" --include="*.js"

# Find imports
grep -rn "import.*functionName\|from.*module.*functionName" --include="*.ts"

# Find method calls
grep -rn "\.methodName\(" --include="*.ts"
```

### Strategy 3: Finding Callers

"What calls X?"

```bash
# Direct function calls
grep -rn "functionName\(" --include="*.ts"

# Method calls
grep -rn "\.methodName\(" --include="*.ts"

# Exclude the definition itself
grep -rn "functionName\(" --include="*.ts" | grep -v "function\s+functionName"
```

### Strategy 4: Finding Routes/Endpoints

"Where is this API endpoint?"

```bash
# Express/Node routes
grep -rn "router\.\(get\|post\|put\|delete\|patch\).*'/path'" --include="*.ts" --include="*.js"

# Path patterns
grep -rn "'/api/v1/resource'" --include="*.ts"

# Route decorators
grep -rn "@\(Get\|Post\|Put\|Delete\).*path" --include="*.ts"
```

### Strategy 5: Finding Database Operations

"Where does this table get accessed?"

```bash
# SQL queries
grep -rn "FROM\s+table_name\|INTO\s+table_name\|UPDATE\s+table_name" --include="*.ts" --include="*.sql"

# ORM models
grep -rn "model.*TableName\|entity.*TableName" --include="*.ts"

# Repository patterns
grep -rn "Repository.*findOne\|Repository.*save" --include="*.ts"
```

### Strategy 6: Finding Tests

"Where are tests for X?"

```bash
# Test files
grep -rn "describe.*ComponentName\|test.*functionName" --include="*.test.ts" --include="*.spec.ts"

# Jest/Mocha patterns
grep -rn "it\(.*should.*\)" --include="*.test.ts"
```

### Strategy 7: Finding Configuration

"Where is X configured?"

```bash
# Environment variables
grep -rn "process\.env\.VAR_NAME\|env\.VAR_NAME" --include="*.ts"

# Config files
grep -rn "configKey" --include="*.json" --include="*.yaml" --include="*.toml"

# Feature flags
grep -rn "featureFlag.*FEATURE_NAME" --include="*.ts"
```

## Search Patterns Reference

### JavaScript/TypeScript
```
PATTERN: "export (const|function|class|interface|type) Name" - Exports
PATTERN: "import .* from" - Imports
PATTERN: "async function|async \(" - Async functions
PATTERN: "await " - Await calls
PATTERN: "new ClassName" - Instantiations
PATTERN: "extends BaseClass" - Inheritance
PATTERN: "implements Interface" - Implementation
```

### Python
```
PATTERN: "def function_name\(" - Functions
PATTERN: "class ClassName" - Classes
PATTERN: "from module import" - Imports
PATTERN: "async def" - Async functions
PATTERN: "@decorator" - Decorators
```

### Go
```
PATTERN: "func FunctionName\(" - Functions
PATTERN: "func (r *Type) Method\(" - Methods
PATTERN: "type TypeName struct" - Structs
PATTERN: "type InterfaceName interface" - Interfaces
```

## Search Workflow

1. **Start broad**: Search for the exact term
2. **Narrow down**: Add file type filters
3. **Exclude noise**: Filter out tests, mocks, generated code
4. **Follow the trail**: Search for what you found

```bash
# Example workflow for "how does login work?"

# 1. Find login-related files
grep -rn "login\|Login" --include="*.ts" -l

# 2. Find the main login function
grep -rn "function.*login\|async.*login" --include="*.ts"

# 3. Find what calls login
grep -rn "login\(" --include="*.ts" | grep -v "function.*login"

# 4. Find login routes
grep -rn "post.*login\|router.*login" --include="*.ts"
```

## Output Format

When helping with searches, provide:

```markdown
## Search: [Query]

### Strategy
[Which strategy applies]

### Commands
[Grep commands to run]

### Results
[Key findings with file:line references]

### Next Steps
[Follow-up searches to try]
```

## Guidelines

- Start with the Atlas if available (ATLAS.md)
- Use file type filters to reduce noise
- Consider case sensitivity (-i flag)
- Use context flags (-B, -A, -C) for surrounding code
- Exclude common noise (node_modules, dist, build)

## Common Exclusions

```bash
# Exclude noise directories
--exclude-dir=node_modules
--exclude-dir=dist
--exclude-dir=build
--exclude-dir=.git
--exclude-dir=coverage
--exclude-dir=__pycache__
```

## Guardrails

- Don't search for secrets or credentials
- Be mindful of large result sets (use head/limit)
- Verify findings by reading full context
- Check multiple potential locations before concluding "not found"
