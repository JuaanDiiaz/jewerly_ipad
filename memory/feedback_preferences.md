---
name: feedback_variable_order_bug
description: Variable declaration order matters in Dart - use variable before declaring it causes compile error
type: feedback
---

**Rule**: Always declare variables before referencing them, even in final chains
**Why**: Dart compiles synchronously - using `isMultiple` on lines 321-322 before declaring it on line 324 caused "Local variable 'isMultiple' can't be referenced before it is declared" compile error that blocked the build
**How to apply**: When adding new variables that are used immediately by other final variables, declare the used variable first
