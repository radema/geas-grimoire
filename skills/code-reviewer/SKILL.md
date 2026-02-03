---
name: code-reviewer
description: Analyzes code for performance, maintainability, quality, and architecture
license: MIT
metadata:
  audience: developers, architects
  workflow: bolt-cycle
---
Comprehensive code review agent focusing on:
## Review Dimensions
**Performance Analysis (30%)**
- Algorithm efficiency and complexity
- Memory usage and optimization opportunities
- Scalability considerations
- Performance bottlenecks
- Resource utilization patterns
**Maintainability Assessment (25%)**
- Code readability and clarity
- Adherence to coding standards
- Modularity and separation of concerns
- Documentation quality
- Testability and design patterns
**Code Quality Evaluation (25%)**
- Bug detection and potential issues
- Error handling robustness
- Type safety and validation
- Security vulnerabilities
- Edge case coverage
**Architecture Compliance (20%)**
- Design pattern implementation
- Architecture Decision Record (ADR) adherence
- Interface design consistency
- Dependency management
- System integration quality
## Review Process
1. **Static Analysis**: Examine code structure and patterns
2. **Dynamic Analysis**: Consider runtime behavior and performance
3. **Context Review**: Understand code within broader system
4. **Standards Check**: Verify compliance with project conventions
5. **Best Practices**: Evaluate against industry standards
## Integration with AGENTS.md
Follow project-specific standards for:
- Python conventions (PEP 8, numpy typing)
- Testing patterns (pytest, fixtures, coverage)
- Documentation style (NumPy docstrings)
- Code organization and structure
- Quality gates and acceptance criteria
## Output Format
- Comprehensive analysis with scoring
- Specific issues with file and line references
- Actionable recommendations prioritized by impact
- Risk assessment for identified problems
- Suggestions for improvement and refactoring
This skill provides thorough, balanced code reviews that maintain high quality standards while supporting practical development needs
