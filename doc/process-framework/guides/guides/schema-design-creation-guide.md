---
id: PF-GDE-034
type: Document
category: General
version: 1.1
created: 2025-07-27
updated: 2025-01-27
related_script: New-SchemaDesign.ps1
guide_description: Guide for customizing database schema design templates
guide_status: Active
related_tasks: PF-TSK-021
guide_title: Schema Design Creation Guide
change_notes: "v1.1 - Updated for IMP-097/IMP-098: Added separation of concerns guidance and cross-referencing standards"
---

# Schema Design Creation Guide

## Overview

This guide provides comprehensive instructions for creating and customizing Database Schema Design documents using the New-SchemaDesign.ps1 script and schema-design-template.md. It helps you plan and document database schema changes, relationships, and migration strategies for the BreakoutBuddies project.

## When to Use

Use this guide when you need to:

- Design new database schemas or modify existing ones
- Plan data model changes and table relationships
- Document database migration strategies and rollback procedures
- Create comprehensive database design documentation
- Support database design reviews and implementation planning
- Ensure data integrity and performance considerations are addressed

> **🚨 CRITICAL**: Always use the New-SchemaDesign.ps1 script to create schema designs - never create them manually. This ensures proper ID assignment, metadata integration, and framework compatibility. Schema designs must be completed and reviewed before implementing database changes to prevent data integrity issues.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Background](#background)
3. [Template Structure Analysis](#template-structure-analysis) _(Optional - for template customization guides)_
4. [Customization Decision Points](#customization-decision-points) _(Optional - for template customization guides)_
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Quality Assurance](#quality-assurance) _(Optional - for template customization guides)_
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)
9. [Related Resources](#related-resources)

## Prerequisites

Before you begin, ensure you have:

- Access to PowerShell and the New-SchemaDesign.ps1 script in `doc/product-docs/technical/database/schemas/`
- Understanding of database design principles and normalization concepts
- Knowledge of the current database schema and data relationships
- Familiarity with the project's data requirements and business logic
- Access to the Database Schema Design Task (PF-TSK-021) documentation
- Understanding of database migration strategies and rollback procedures

## Background

Database Schema Designs provide comprehensive planning and documentation for database structure changes, ensuring data integrity, performance, and maintainability. They serve as blueprints for database evolution and migration strategies.

### Purpose of Schema Designs

- **Structure Planning**: Define table structures, relationships, and constraints
- **Migration Strategy**: Plan safe database changes with rollback procedures
- **Performance Optimization**: Consider indexing, partitioning, and query performance
- **Data Integrity**: Ensure referential integrity and business rule enforcement
- **Documentation**: Create comprehensive reference for database structure and evolution

### Framework Integration

Schema Designs integrate with API Data Models to ensure consistency between database structure and API contracts. They support the broader system architecture and data flow requirements.

### Separation of Concerns and Cross-Referencing

**Database Schema Design Task Scope** (IMP-097/IMP-098):

This task focuses exclusively on **database-level concerns**:

- ✅ **Owns**: Data structures, relationships, constraints, migrations, database security (RLS), database performance
- ❌ **Does NOT own**: API endpoint specifications, service integration patterns, comprehensive test plans

**Cross-Reference Standards**:

When schema designs reference other tasks:

- **Integration Impact**: Brief database-level notes (2-5 sentences) + link to API Design task for detailed specifications
- **Testing Strategy**: Brief database-specific testing considerations + link to Test Specification task for comprehensive test plans
- **Data Migration**: Conditional section (only for production deployments with existing data)

**Decision Framework** - When to document vs. reference:

- **Document in Schema Design**: Database structures, constraints, RLS policies, migration scripts, database indexes
- **Reference API Design**: API endpoints, service integration, data access patterns from application layer
- **Reference Test Specification**: Comprehensive test plans, test cases, testing procedures

> **📋 See Also**: [Task Transition Guide - Information Flow Section](task-transition-guide.md#task-transitions) for comprehensive cross-referencing patterns.

## Template Structure Analysis

The Schema Design template (schema-design-template.md) provides a comprehensive structure for documenting database schema changes and design decisions:

### Core Template Sections

**Required sections:**

- **Overview**: Feature name, schema type, and high-level description
- **Context & Requirements**: Feature requirements, current schema state, and data flow requirements
- **Data Model Design**: Entity definitions, relationships, and constraints/validation rules
- **Performance Considerations**: Indexing strategy, query optimization, and scalability planning
- **Migration Strategy**: Migration steps, rollback procedures, and testing approach

**Critical design sections:**

- **Entity Definitions**: Detailed table structures with fields, data types, and constraints
- **Relationships**: Entity relationships and foreign key definitions
- **Indexing Strategy**: Performance optimization through strategic index placement
- **Migration Steps**: Step-by-step implementation and rollback procedures

**Optional sections:**

- **Data Validation**: Additional business rule validation beyond basic constraints
- **Security Considerations**: Data access controls and sensitive data handling
- **Monitoring & Maintenance**: Ongoing schema maintenance and monitoring requirements

### Section Interdependencies

- **Context & Requirements** drives all design decisions in **Data Model Design**
- **Entity Definitions** determine the **Relationships** and **Constraints** needed
- **Performance Considerations** influence **Entity Definitions** and **Migration Strategy**
- **Migration Strategy** must account for all changes defined in **Data Model Design**
- **Testing Approach** validates all aspects of the schema design implementation

### Customization Impact Areas

- **Entity complexity** determines the depth of field definitions and constraint documentation
- **Performance requirements** affect indexing strategy detail and optimization planning
- **Migration complexity** influences the granularity of migration steps and rollback procedures
- **Integration requirements** impact relationship definitions and data flow documentation

## Customization Decision Points

When creating database schema designs, you must make several key decisions that impact data integrity, performance, and maintainability:

### Schema Change Scope Decision

**Decision**: New schema creation vs. existing schema modification vs. schema refactoring
**Criteria**:

- New schema for entirely new features with no existing data dependencies
- Modification for feature enhancements that extend existing functionality
- Refactoring for performance improvements or architectural changes to existing schemas
  **Impact**: Determines migration complexity, rollback procedures, and testing requirements

### Normalization Level Decision

**Decision**: Highly normalized (3NF+) vs. partially denormalized vs. performance-optimized denormalization
**Criteria**:

- High normalization for transactional systems with strong consistency requirements
- Partial denormalization for balanced read/write performance with acceptable redundancy
- Performance denormalization for read-heavy systems where query performance is critical
  **Impact**: Affects data integrity, storage requirements, query performance, and maintenance complexity

### Indexing Strategy Decision

**Decision**: Minimal essential indexes vs. comprehensive indexing vs. query-specific optimization
**Criteria**:

- Minimal indexing for write-heavy systems or storage-constrained environments
- Comprehensive indexing for balanced workloads with predictable query patterns
- Query-specific optimization for known performance bottlenecks or critical queries
  **Impact**: Determines query performance, storage overhead, and write operation costs

### Migration Approach Decision

**Decision**: Single-step migration vs. phased migration vs. blue-green schema deployment
**Criteria**:

- Single-step for simple changes with minimal downtime tolerance
- Phased migration for complex changes requiring gradual rollout and validation
- Blue-green deployment for zero-downtime requirements or high-risk changes
  **Impact**: Affects deployment complexity, downtime requirements, and rollback capabilities

### Data Validation Strategy Decision

**Decision**: Database-level constraints vs. application-level validation vs. hybrid approach
**Criteria**:

- Database-level for critical data integrity that must be enforced regardless of application
- Application-level for complex business rules or user experience considerations
- Hybrid approach for comprehensive validation with performance optimization
  **Impact**: Determines data integrity guarantees, performance characteristics, and development complexity

## Step-by-Step Instructions

### 1. Analyze Feature Requirements and Current Schema

1. **Review feature requirements and data needs**:

   - Understand the feature's data storage and retrieval requirements
   - Identify new entities, relationships, and data flows needed
   - Analyze performance and scalability requirements

2. **Assess current database schema**:

   - Document existing tables that will be affected
   - Understand current relationships and constraints
   - Identify potential conflicts or integration points

3. **Gather schema design parameters**:
   - **Feature Name**: Descriptive name for the feature requiring schema changes
   - **Schema Type**: Type of change (New, Modification, Optimization)
   - **Description**: Brief explanation of the schema changes needed

**Expected Result:** Complete understanding of feature requirements and current schema state

### 2. Create Schema Design Using New-SchemaDesign.ps1

1. **Navigate to the database documentation directory**:

   ```powershell
   cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\database
   ```

2. **Execute the New-SchemaDesign.ps1 script**:

   ```powershell
   # Basic schema design creation
   .\New-SchemaDesign.ps1 -FeatureName "User Authentication" -SchemaType "New"

   # With description and editor opening
   .\New-SchemaDesign.ps1 -FeatureName "User Profile Enhancement" -SchemaType "Modification" -Description "Add new fields for user preferences" -OpenInEditor
   ```

3. **Verify schema design creation**:
   - Check the success message for the assigned ID (PD-SCH-XXX)
   - Note the file path in the database documentation directory
   - Confirm the basic template structure and metadata are properly populated

**Expected Result:** New schema design file created with proper ID, metadata, and template structure ready for detailed design

### 3. Complete Comprehensive Schema Design Documentation

1. **Define data model design**:

   - Create detailed entity definitions with fields, data types, and constraints
   - Document relationships between entities with foreign key specifications
   - Define validation rules and business constraints

2. **Plan performance optimization**:

   - Design indexing strategy based on expected query patterns
   - Identify potential performance bottlenecks and optimization approaches
   - Plan for scalability and future growth requirements

3. **Develop migration strategy**:

   - Create step-by-step migration procedures with specific SQL commands
   - Design rollback procedures for safe deployment
   - Plan testing approach to validate schema changes

4. **Document database-level integration notes**:

   - Add brief notes on database access requirements and cross-schema dependencies
   - Include cross-reference sections linking to API Design task for detailed API specifications
   - Include cross-reference sections linking to Test Specification task for comprehensive test plans
   - Ensure Data Migration section is marked as conditional if no production data exists

5. **Apply separation of concerns**:
   - Focus exclusively on database-level concerns (structures, constraints, migrations)
   - Use cross-references for API specifications and comprehensive testing strategies
   - Keep integration notes brief (2-5 sentences) with links to owner tasks

**Expected Result:** Comprehensive schema design with detailed entity definitions, performance planning, safe migration procedures, and proper cross-references to related tasks

### Validation and Testing

1. **Validate schema design completeness**:

   - Verify that all entities have complete field definitions with appropriate data types
   - Check that relationships are properly defined with foreign key constraints
   - Ensure indexing strategy covers expected query patterns
   - Confirm migration steps are detailed and include rollback procedures

2. **Test schema design feasibility**:

   - Review entity definitions against feature requirements for completeness
   - Validate that performance considerations address expected load and usage patterns
   - Check that migration procedures are safe and reversible
   - Ensure data validation rules align with business requirements

3. **Review integration compatibility**:

   - Verify consistency with existing API data models and contracts
   - Check compatibility with current application data access patterns
   - Validate that schema changes don't break existing functionality
   - Ensure proper integration with existing database constraints and relationships

4. **Validate framework integration**:
   - Check that metadata fields are properly completed
   - Verify that the schema design follows established documentation patterns
   - Ensure compatibility with existing database management and deployment processes

## Quality Assurance

Comprehensive quality assurance ensures schema designs meet project standards and provide reliable database evolution:

### Self-Review Checklist

- [ ] Schema design clearly identifies feature requirements and current state
- [ ] All entities have complete field definitions with appropriate data types and constraints
- [ ] Relationships between entities are properly defined with foreign key specifications
- [ ] Indexing strategy addresses expected query patterns and performance requirements
- [ ] Migration steps are detailed, safe, and include rollback procedures
- [ ] Performance considerations address scalability and optimization needs
- [ ] Integration with API data models and existing systems is documented
- [ ] Cross-references and links to related documentation are correct and accessible

### Validation Criteria

- **Functional validation**: Schema design supports all feature requirements and use cases
- **Content validation**: Entity definitions and migration procedures are accurate and complete
- **Integration validation**: Schema design integrates properly with existing database and API structures
- **Standards validation**: Follows database design best practices and project conventions
- **Performance validation**: Indexing and optimization strategies address expected load and usage patterns

### Integration Testing Procedures

- **Data Model Consistency**: Verify that schema design aligns with API data models and contracts
- **Migration Safety**: Test migration procedures in development environment to ensure safety and reversibility
- **Performance Impact**: Validate that indexing strategy and schema changes meet performance requirements
- **Application Compatibility**: Confirm that schema changes don't break existing application functionality
- **Documentation Integration**: Ensure schema design is properly integrated into project database documentation

## Examples

### Example 1: User Profile Enhancement Schema Design

Creating a schema design for enhancing user profiles with preferences and settings:

```powershell
# Navigate to database documentation directory
cd c:\Users\ronny\VS_Code\BreakoutBuddies\breakoutbuddies\doc\product-docs\technical\database

# Create schema design for user profile enhancement
.\New-SchemaDesign.ps1 -FeatureName "User Profile Enhancement" -SchemaType "Modification" -Description "Add user preferences and notification settings" -OpenInEditor
```

**Customization approach:**

- **Context & Requirements**: Document need for user customization features, current user table structure, and preference storage requirements
- **Data Model Design**: Add user_preferences table with foreign key to users, define preference categories and values
- **Performance Considerations**: Index on user_id for fast preference lookups, consider JSON column for flexible preference storage
- **Migration Strategy**: Add new table, migrate existing default preferences, update application code gradually

**Result:** Comprehensive schema design that safely extends user functionality with proper performance optimization

### Example 2: Booking System Schema Design

Creating a new schema design for escape room booking functionality:

```powershell
# Create new booking system schema design
.\New-SchemaDesign.ps1 -FeatureName "Booking System" -SchemaType "New" -Description "Complete booking and reservation management system"
```

**Customization approach:**

- **Context & Requirements**: Document booking workflow requirements, room availability tracking, and payment integration needs
- **Data Model Design**: Create bookings, rooms, time_slots, and booking_payments tables with proper relationships
- **Performance Considerations**: Composite indexes on room_id + date for availability queries, partitioning strategy for historical data
- **Migration Strategy**: Create all tables in correct order, populate initial room and time slot data, implement booking constraints

**Result:** Complete new schema design that supports complex booking workflows with scalability planning

## Troubleshooting

### Script Execution Fails with Path Error

**Symptom:** New-SchemaDesign.ps1 script fails with "Cannot find common helpers" error

**Cause:** Script cannot locate the Common-ScriptHelpers.psm1 module due to incorrect path resolution

**Solution:**

1. Verify you're running the script from the correct directory: `doc/product-docs/technical/database/`
2. Check that the Common-ScriptHelpers.psm1 file exists at `doc/process-framework/scripts/Common-ScriptHelpers.psm1`
3. Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Schema Design Lacks Performance Considerations

**Symptom:** Schema design doesn't address query performance or includes inefficient data structures

**Cause:** Insufficient analysis of expected query patterns or lack of performance planning

**Solution:**

1. Analyze expected query patterns and data access requirements from feature specifications
2. Design appropriate indexes based on WHERE clauses, JOIN conditions, and ORDER BY requirements
3. Consider denormalization for read-heavy scenarios or normalization for write-heavy scenarios
4. Plan for data growth and include partitioning or archiving strategies where appropriate

### Migration Strategy Too Risky or Complex

**Symptom:** Migration procedures lack rollback plans or could cause data loss or extended downtime

**Cause:** Insufficient planning for safe database changes or complex schema modifications

**Solution:**

1. Break complex migrations into smaller, safer steps that can be individually rolled back
2. Create comprehensive rollback procedures for each migration step
3. Plan for data backup and validation at each migration stage
4. Test migration procedures in development environment before production deployment

## Related Resources

- [Database Schema Design Task (PF-TSK-021)](../../tasks/02-design/database-schema-design-task.md) - The task that uses this guide
- [New-SchemaDesign.ps1 Script](../../scripts/file-creation/New-SchemaDesign.ps1) - Script for creating schema designs
- [Schema Design Template](../../templates/templates/schema-design-template.md) - Template customized by this guide
- [API Data Model Creation Guide (PF-GDE-030)](api-data-model-creation-guide.md) - Guide for creating related API data models
- [Guide Creation Best Practices Guide (PF-GDE-024)](guide-creation-best-practices-guide.md) - Best practices for guide creation
- [Database Design Best Practices](https://www.postgresql.org/docs/current/ddl.html) - External resource for database design principles
- [Supabase Database Documentation](https://supabase.com/docs/guides/database) - External resource for Supabase-specific database features

<!--
TEMPLATE USAGE GUIDANCE:

ENHANCED METADATA:
- related_script: Include if this guide helps customize templates created by a specific script
- related_tasks: Include task IDs that this guide supports (comma-separated)
- These fields enhance traceability and make guides easier to discover and maintain

TEMPLATE CUSTOMIZATION GUIDE SECTIONS:
For guides that help customize templates created by scripts, use these optional sections:
- Template Structure Analysis: Break down the template structure and explain each section
- Customization Decision Points: Guide users through key customization decisions
- Validation and Testing: Include within Step-by-Step Instructions for testing procedures
- Quality Assurance: Provide comprehensive QA guidance with checklists and validation criteria

GENERAL GUIDE SECTIONS:
All guides use the standard sections: Overview, When to Use, Prerequisites, Background,
Step-by-Step Instructions, Examples, Troubleshooting, Related Resources
-->
