---
name: tdd-implementation
description: Enforces Test-Driven Development methodology
license: MIT
metadata:
  audience: developers
  workflow: bolt-cycle
---
Implements strict Test-Driven Development workflow:
## TDD Cycle
### 1. Red Phase
- Write a failing test that clearly specifies desired behavior
- Test should be specific, readable, and focused on one piece of functionality
- Use descriptive test names that explain what is being tested
- Include edge cases and error conditions in test scenarios
### 2. Green Phase  
- Write the minimal code required to make the test pass
- Focus on making the test work, not on perfect implementation
- Avoid adding functionality beyond what the test requires
- Use simple, straightforward solutions initially
### 3. Refactor Phase
- Improve code design while keeping tests green
- Apply design patterns and clean code principles
- Remove duplication and improve readability
- Ensure all tests still pass after refactoring
## Verification Steps
After each TDD cycle:
1. **Test Execution**: Run `uv run pytest` to verify all tests pass
2. **Quality Checks**: Run `uv run black .` for formatting
3. **Linting**: Run `uv run flake8 .` for style compliance  
4. **Type Checking**: Run `uv run mypy .` for type safety
5. **Coverage**: Periodically run `uv run pytest --cov=ras_balancer`
## Chunking Strategy
- Work in small, manageable pieces of functionality
- Each chunk should implement one specific feature or behavior
- Verify each chunk completely before moving to the next
- Maintain a continuous green state throughout development
## Integration with AGENTS.md
Follow project conventions for:
- Test structure and naming
- Assertion patterns (`np.allclose`, `pytest.raises`)
- Fixture usage and test organization
- Coverage requirements and quality gates
This skill ensures systematic, test-first development that maintains high code quality throughout the implementation process.
