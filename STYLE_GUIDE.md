# PSLab Coding Guide

This document provides the official style and coding conventions for the PSLab project. Adhering to these guidelines ensures that our codebase is readable, maintainable, and consistent.

## General Principles

* **Clarity over Brevity**: Write code that is easy to understand. Variable and method names should be descriptive.
* **DRY (Don't Repeat Yourself)**: Avoid duplicating code. Use helper methods, utility classes, or shared services to promote reuse.
* **Single Responsibility Principle**: Each class and method should have one clear purpose.

## Apex Style Guide

### 1. Naming Conventions

* **Classes**: Use `PascalCase`. Class names should be nouns that clearly describe their purpose, and always start with `PSLab_`. Test classes must end with `Test`.

  ✅ `PSLab_PermissionAnalysisHelper`, `PSLab_PermissionHierarchyBuilderTest`

  ❌ `permissionAnalysis`, `MyTestClass`

* **Methods**: Use `camelCase`. Method names should be verbs that describe what the method does.

  ✅ `getDetectedPermissions`, `buildGroupsBranch`

  ❌ `GetPermissions`, `Permissions_Builder`

* **Variables**: Use `camelCase`. Names should be descriptive. Boolean variables should be prefixed with `is`, `has`, or `can`.

  ✅ `permissionSetId`, `isProcessingComplete`

  ❌ `id`, `processing`

* **Constants**: Use `UPPER_SNAKE_CASE`. Constants must be declared as `private static final`.

  ✅ `private static final Integer MAX_RECORDS = 200;`

  ❌ `private static final Integer maxRecords = 200;`

### 2. Formatting

* **Indentation**: Use 4 spaces for indentation, not tabs.
* **Braces**: Opening brace `{` should be on the same line as the declaration. Closing brace `}` should be on a new line.

    ```apex
    // Good
    public class PSLab_MyClass {
        public void myMethod() {
            // ...
        }
    }

    // Bad
    public class MyClass
    {
        public void myMethod()
        {
            // ...
        }
    }
    ```

* **SOQL Queries**: For long queries, place each major clause (`SELECT`, `FROM`, `WHERE`) on a new line.
  * Always use `WITH SYSTEM_MODE` or `WITH USER_MODE`

      ```apex
      // Good
      List<Account> accounts = [
          SELECT Id, Name, Industry
          FROM Account
          WHERE Industry = 'Technology'
          WITH USER_MODE
          ORDER BY Name ASC
      ];
      ```

### 3. Best Practices

* **Comments**: Use Javadoc-style comments (`/** ... */`) for all classes and methods to explain their purpose, parameters, and return values.
* **Assertions**: In test classes, always use `Assert` class

  ✅ `Assert.areEqual(1, results.size(), 'Should find exactly one detected permission.');`

* **Bulkification**: Never place SOQL queries or DML statements inside a loop, unless you have a good reason to do so.

## Lightning Web Components (LWC) Style Guide

### 1. Naming Conventions

* **Components**: Use `camelCase` for folder and file names, and always start with `psLab`. The component tag in HTML will be `kebab-case`.

  ✅ Folder/Files: `psLabPermissionTreeGrid` -> HTML Tag: `<c-ps-lab-permission-tree-grid>`

* **JavaScript Properties**: Use `camelCase`.

  ✅ `@api recordId;`

  ❌ `@api RecordId;`

* **Event Names**: Use lowercase with no spaces or special characters.

  ✅ `this.dispatchEvent(new CustomEvent('rowselect'));`

### 2. HTML Template Best Practices

* **Conditionals**: Use `lwc:if` and `lwc:else` for rendering conditional blocks. Avoid using multiple `if:true` directives where an `if/else` is more appropriate.
* **Iteration**: Always use a unique `key` attribute within a `for:each` loop.

    ```html
    <template for:each={permissionSets} for:item="ps">
        <li key={ps.Id}>
            {ps.Label}
        </li>
    </template>
    ```

### 3. JavaScript Best Practices

* **Imports**: Clearly import all references from `@salesforce` modules at the top of the file.
* **API Properties**: Use the `@api` decorator for public properties that can be set by a parent component.
* **Constants**: Define constants at the top of the file for labels, event names, or magic strings.