# Requirements Document

## Introduction

This feature adds hierarchical project task visibility and filtering to Vikunja, allowing users to view tasks from child projects within parent project views and to filter saved views by parent project with recursive child inclusion. This enables better task management across project hierarchies without requiring users to navigate to each child project individually.

## Glossary

- **Project**: A container for tasks in Vikunja (formerly called "List" in earlier versions)
- **Child_Project**: A project that has a parent project in the project hierarchy
- **Parent_Project**: A project that has one or more child projects
- **Descendant_Project**: A child project or any of its recursive children (grandchildren, great-grandchildren, etc.)
- **Project_View**: Any of the four view types for displaying tasks: List, Kanban, Gantt, or Table
- **Saved_Filter**: A user-created filter configuration that aggregates tasks from multiple projects based on specified criteria
- **Task_Aggregation_System**: The existing system that combines tasks from multiple projects in saved filters
- **Toggle**: A UI control that enables or disables a feature (on/off state)
- **Breadcrumb_Navigation**: A UI element showing the hierarchical path from root to current location, allowing navigation to parent levels
- **User_Preference**: A persistent setting stored per user that controls default behavior across sessions
- **Backend**: The Go API service that handles business logic and data persistence
- **Frontend**: The Vue.js web client that provides the user interface

## Requirements

### Requirement 1: Project View Child Task Toggle

**User Story:** As a user viewing a parent project, I want to toggle visibility of tasks from child projects, so that I can see all related work in one view without navigating to each child project.

#### Acceptance Criteria

1. WHEN a user views a project in any Project_View (List, Kanban, Gantt, Table), THE Frontend SHALL display a toggle control labeled "Show tasks in child projects"
2. WHEN the toggle is disabled, THE Project_View SHALL display only tasks that belong directly to the current project
3. WHEN the toggle is enabled, THE Project_View SHALL display tasks from the current project and all Descendant_Projects
4. WHEN a user navigates to a project, THE Frontend SHALL initialize the toggle state from the user's default preference setting
5. THE toggle control SHALL follow the same UI pattern and placement as the existing "Show tasks without a date" toggle

### Requirement 2: User Preference for Default Toggle State

**User Story:** As a user, I want to set a default preference for showing child project tasks, so that the toggle is automatically set to my preferred state when I navigate to any project.

#### Acceptance Criteria

1. WHEN a user accesses their user preferences/settings, THE Frontend SHALL display a preference option labeled "Show tasks in child projects by default"
2. THE preference option SHALL be a boolean setting (enabled/disabled) with disabled as the system default
3. WHEN a user changes this preference, THE Backend SHALL persist the preference value in the user's settings
4. WHEN a user navigates to any project, THE Frontend SHALL initialize the "Show tasks in child projects" toggle to match the user's saved preference
5. THE user preference SHALL follow the same UI pattern and placement as other view-related preferences in the settings interface

### Requirement 3: Recursive Child Project Task Retrieval

**User Story:** As a user, I want child project task visibility to include all descendant levels, so that deeply nested project hierarchies show all relevant tasks.

#### Acceptance Criteria

1. WHEN the child task toggle is enabled for a Parent_Project, THE Backend SHALL identify all Descendant_Projects recursively (children, grandchildren, etc.)
2. WHEN retrieving tasks for display, THE Backend SHALL return tasks from the parent project and all identified Descendant_Projects
3. THE Backend SHALL expand a single parent project ID into a list of all descendant project IDs without requiring database schema changes
4. FOR ALL project hierarchies with depth N, retrieving tasks SHALL include all N levels of descendants

### Requirement 4: Saved Filter Parent Project Option

**User Story:** As a user creating or editing a saved filter, I want to filter by parent project with automatic child inclusion, so that I can create persistent views of hierarchical project groups.

#### Acceptance Criteria

1. WHEN a user accesses the "New Saved Filter" or "Edit This Saved Filter" interface, THE Frontend SHALL display a filter option named "parentProject"
2. THE "parentProject" filter option SHALL have the description "The project the task belongs to and all tasks from all descendant child projects"
3. WHEN a user selects a project using the "parentProject" filter, THE Backend SHALL include tasks from the selected project and all Descendant_Projects
4. THE "parentProject" filter SHALL integrate with the existing Task_Aggregation_System used by saved filters
5. WHEN multiple "parentProject" filters are combined with other filter criteria, THE Backend SHALL apply all filters correctly using AND/OR logic consistent with existing filter behavior

### Requirement 5: Multi-View Compatibility

**User Story:** As a user, I want child project task visibility to work consistently across all view types, so that I have a uniform experience regardless of how I prefer to view my tasks.

#### Acceptance Criteria

1. WHEN the child task toggle is enabled, THE List_View SHALL display child project tasks in the task list
2. WHEN the child task toggle is enabled, THE Kanban_View SHALL display child project tasks in the appropriate board columns
3. WHEN the child task toggle is enabled, THE Gantt_View SHALL display child project tasks in the timeline
4. WHEN the child task toggle is enabled, THE Table_View SHALL display child project tasks in the table rows
5. FOR ALL Project_Views, child project tasks SHALL be visually distinguishable from parent project tasks (e.g., via project name display or visual indicator)

### Requirement 6: Project Hierarchy Breadcrumb Navigation

**User Story:** As a user viewing a child project, I want to see the full parent chain in a breadcrumb navigation, so that I understand where the project sits in the hierarchy and can easily navigate to parent projects.

#### Acceptance Criteria

1. WHEN a user views a Child_Project, THE Frontend SHALL display a breadcrumb navigation showing the full parent chain from root to current project
2. THE breadcrumb navigation SHALL display project names in hierarchical order (e.g., "Root Project > Parent Project > Current Project")
3. WHEN a user clicks on any project name in the breadcrumb, THE Frontend SHALL navigate to that project's view
4. WHEN a user views a root project (no parent), THE Frontend SHALL display only the current project name without breadcrumb separators
5. THE breadcrumb navigation SHALL be positioned consistently across all Project_Views (List, Kanban, Gantt, Table)
6. THE breadcrumb navigation SHALL follow existing Vikunja UI patterns for navigation elements

### Requirement 7: Backend Project Hierarchy Resolution

**User Story:** As a system, I want to efficiently resolve project hierarchies without database changes, so that the feature can be implemented with minimal infrastructure impact.

#### Acceptance Criteria

1. THE Backend SHALL provide a function that accepts a project ID and returns all Descendant_Project IDs
2. THE Backend SHALL compute descendant project lists using existing project parent-child relationships in the database
3. THE Backend SHALL cache project hierarchy computations to minimize repeated database queries
4. WHEN a project hierarchy changes (project parent is modified), THE Backend SHALL invalidate relevant hierarchy caches
5. THE hierarchy resolution function SHALL handle circular references gracefully by detecting and breaking cycles

### Requirement 8: Frontend-Backend Communication

**User Story:** As a system, I want clean communication between frontend and backend for child task requests, so that the implementation is maintainable and follows existing patterns.

#### Acceptance Criteria

1. WHEN the child task toggle is enabled, THE Frontend SHALL include a query parameter or request field indicating child task inclusion is requested
2. THE Backend SHALL accept the child task inclusion parameter in all project task retrieval endpoints
3. WHEN the "parentProject" filter is used, THE Frontend SHALL send the filter to the Backend using the existing saved filter API structure
4. THE Backend SHALL process the "parentProject" filter using the same filter processing pipeline as existing filter types
5. THE API request and response formats SHALL follow existing Vikunja API conventions for consistency

### Requirement 9: Performance and Scalability

**User Story:** As a user with large project hierarchies, I want child task retrieval to perform efficiently, so that my views load quickly even with many nested projects.

#### Acceptance Criteria

1. WHEN retrieving tasks with child project inclusion, THE Backend SHALL use a single optimized database query rather than N+1 queries per child project
2. THE Backend SHALL limit the maximum depth of project hierarchy traversal to prevent infinite loops and excessive computation
3. WHEN a project has more than 100 Descendant_Projects, THE Backend SHALL log a performance warning but continue processing
4. THE task retrieval response time with child inclusion SHALL not exceed 2x the response time without child inclusion for hierarchies up to 10 levels deep

### Requirement 10: Permissions and Security

**User Story:** As a user, I want to see only child project tasks I have permission to view, so that project access controls are respected in hierarchical views.

#### Acceptance Criteria

1. WHEN retrieving child project tasks, THE Backend SHALL check read permissions for each Descendant_Project
2. THE Backend SHALL exclude tasks from Descendant_Projects where the user lacks read permission
3. WHEN a user has read permission on a Parent_Project but not on a Child_Project, THE Backend SHALL include only tasks from projects with granted permissions
4. THE permission checking SHALL use the existing Vikunja permissions system without introducing new permission types
5. FOR ALL child project task retrievals, permission checks SHALL be enforced at the model level consistent with existing CRUD operations
