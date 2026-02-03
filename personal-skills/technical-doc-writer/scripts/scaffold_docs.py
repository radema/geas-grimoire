import os
import argparse
import sys

def create_file(path, content):
    if os.path.exists(path):
        print(f"Skipping {path} (already exists)")
        return
    with open(path, 'w') as f:
        f.write(content)
    print(f"Created {path}")

def main():
    parser = argparse.ArgumentParser(description="Scaffold technical documentation structure.")
    parser.add_argument("output_dir", help="Target directory for documentation (e.g., docs/technical)")
    args = parser.parse_args()

    base_dir = args.output_dir
    if not os.path.exists(base_dir):
        try:
            os.makedirs(base_dir)
            print(f"Created directory {base_dir}")
        except OSError as e:
            print(f"Error creating directory {base_dir}: {e}")
            sys.exit(1)

    files = {
        "01_system_architecture.md": """# System Architecture

## Application Review
<!-- Purpose and scope of the application -->

## Technology Stack 
<!-- The following applies when available -->
### Front End
### Infrastructure
### Backend
### Third Party Integrations

## High-Level Architecture Diagram
<!-- Mermaid diagrams are welcomed! -->
<!-- 
```mermaid
graph TD;
    A-->B;
```
-->
""",
        "02_database_schema.md": """# Database Schema

## Core tables
<!-- List schemas, ddls, data contracts, constraints, etc. -->

## Relationship summary
<!-- Entity Relationship refinements -->
""",
        "03_api_specifications.md": """# API Specifications

## Authentication & Onboarding

## Base URL

## Core Endpoints
<!-- List key endpoints -->

## Error Responses

## Rate Limiting
""",
        "04_integration_requirements.md": """# Integration Requirements

<!-- External systems, webhooks, data exchange protocols -->
""",
        "05_data_synchronization.md": """# Data Synchronization

<!-- Strategies for keeping data in sync across systems or clients -->
""",
        "06_security_compliance.md": """# Security & Compliance

## Authentication & Authorization

## Data Encryption
<!-- At rest and in transit -->

## GDPR Compliance

## PCI Compliance
""",
        "07_performance_requirements.md": """# Performance Requirements

## Response Time Targets

## Scalability Targets

## Database Optimization
### Indexing Strategy
### Query Optimization
### Database Partitioning
""",
        "08_monitoring_logging.md": """# Monitoring & Logging

## Application monitoring
### Tools
### Key Metrics
### Alerts

## Logging Standards
### Log Levels
### Sensitive Data Masking
### LogFormat(JSON)
""",
        "09_testing_requirements.md": """# Testing Requirements

## Unit Testing
* Coverage Target: 
* Critical Components:

## Integration Testing
* Scenarios:

## E2E Testing
* User Journeys:

## Performance Testing
* Load Tests:
* Stress Tests:
""",
        "10_deployment_cicd.md": """# Deployment & CI/CD

## Deployment Strategy
* Environments:
* Blue-Green Deployment:

## Database Migrations
* Process:
* Rollback Strategy:

## Feature Flags
* Flag System:
* Key Flags:
""",
        "11_edge_cases.md": """# Edge Cases & Error Handling

## Task-Related Edge Cases

## Household Edge Cases
<!-- Application specific domain edge cases -->

## Data Synchronization Edge Cases
""",
        "12_future_considerations.md": """# Future Considerations

## Planned Features

## Scalability/Roadmap
""",
        "13_appendix.md": """# Appendix

## Glossary

## External Dependencies

## API Versioning Strategy
"""
    }

    for filename, content in files.items():
        create_file(os.path.join(base_dir, filename), content)

    print("\nDocumentation scaffolding complete.")

if __name__ == "__main__":
    main()
