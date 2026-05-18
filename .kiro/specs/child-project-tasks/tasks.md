# Implementation Plan: Child Project Tasks Feature

## Overview

This implementation adds hierarchical project task visibility to Vikunja by:
1. Creating a recursive child project resolver using CTE patterns (similar to existing `GetAllParentProjects`)
2. Extending the task collection system to expand project IDs when child inclusion is requested
3. Adding frontend toggle controls and user preferences for default behavior
4. Integrating a new `parentProject` filter into the saved filter system
5. Adding breadcrumb navigation for project hierarchy visualization

The implementation follows existing Vikunja patterns strictly: recursive CTEs for hierarchy, saved filter aggregation for multi-project tasks, frontend_settings JSON for preferences, and model-level permission checking.

## Tasks

- [x] 1. Backend: Implement project hierarchy resolver
  - [x] 1.1 Create `GetAllChildProjects` function in `pkg/models/project.go`
    - Implement recursive CTE query traversing from parent to children (inverse of `GetAllParentProjects`)
    - Return `map[int64]*Project` for efficient lookup
    - Handle circular references by limiting recursion depth to 50 levels
    - Add caching using existing Vikunja cache patterns
    - _Requirements: 3.1, 3.3, 7.1, 7.2, 7.5_
  
  - [ ]* 1.2 Write property test for hierarchy resolution completeness
    - **Property 1: Hierarchy Resolution Completeness**
    - **Validates: Requirements 3.1, 3.4, 7.1**
    - For any project with descendant projects at depth N, calling GetAllChildProjects SHALL return all projects at all depth levels from 1 to N
    - Use gopter library with minimum 100 iterations
    - _Requirements: 3.1, 3.4, 7.1_
  
  - [ ]* 1.3 Write unit tests for `GetAllChildProjects`
    - Test single-level hierarchy (parent with direct children only)
    - Test multi-level hierarchy (grandchildren, great-grandchildren)
    - Test no children case (leaf project)
    - Test circular reference detection and handling
    - Test cache behavior and invalidation
    - _Requirements: 3.1, 3.3, 7.1, 7.5_

- [x] 2. Backend: Extend task collection for child project inclusion
  - [x] 2.1 Add fields to `TaskCollection` struct in `pkg/models/task_collection.go`
    - Add `IncludeChildTasks bool` field with `query:"include_child_tasks"` tag
    - Add `ParentProjectIDs []int64` field with `json:"-"` tag (populated from filter parsing)
    - _Requirements: 1.2, 1.3, 8.1, 8.2_
  
  - [x] 2.2 Modify `getRelevantProjectsFromCollection` in `pkg/models/task_collection.go`
    - When `IncludeChildTasks` is true and `ProjectID` is set, call `GetAllChildProjects` and add descendant IDs to projects list
    - When `ParentProjectIDs` is set, iterate through each parent ID, call `GetAllChildProjects`, and add all descendants to projects list
    - Integrate with existing project ID expansion logic
    - _Requirements: 3.2, 4.3, 4.4, 8.4_
  
  - [x] 2.3 Implement permission filtering for child projects
    - For each child project returned by `GetAllChildProjects`, check `CanRead` permission
    - Exclude projects where user lacks read permission
    - Use existing permission checking patterns from model layer
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [ ]* 2.4 Write property test for task inclusion based on toggle state
    - **Property 2: Task Inclusion Based on Toggle State**
    - **Validates: Requirements 1.2, 1.3, 3.2, 4.3**
    - For any project hierarchy, when IncludeChildTasks is false, returned tasks contain only direct tasks; when true, includes all descendant tasks
    - Use gopter library with minimum 100 iterations
    - _Requirements: 1.2, 1.3, 3.2, 4.3_
  
  - [ ]* 2.5 Write property test for permission-based task filtering
    - **Property 5: Permission-Based Task Filtering**
    - **Validates: Requirements 10.1, 10.2**
    - For any project hierarchy with mixed permissions, returned tasks include only tasks from projects where CanRead returns true
    - Use gopter library with minimum 100 iterations
    - _Requirements: 10.1, 10.2_
  
  - [ ]* 2.6 Write unit tests for task collection with child inclusion
    - Test task retrieval with `IncludeChildTasks=false` (only direct tasks)
    - Test task retrieval with `IncludeChildTasks=true` (includes descendants)
    - Test permission filtering (user lacks permission on some children)
    - Test empty hierarchy (no children)
    - _Requirements: 1.2, 1.3, 3.2, 10.1, 10.2_

- [x] 3. Backend: Integrate parentProject filter into filter system
  - [x] 3.1 Add `parentProject` filter field support in filter parser (`pkg/models/task_collection.go`)
    - Parse `parentProject` filter syntax: `filter=parentProject = 123` and `filter=parentProject in 123,456`
    - Map parsed values to `ParentProjectIDs` field in `TaskCollection`
    - Integrate with existing filter combination logic (AND/OR)
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 8.3, 8.4_
  
  - [ ]* 3.2 Write property test for filter combination correctness
    - **Property 4: Filter Combination Correctness**
    - **Validates: Requirements 4.5**
    - For any saved filter with parentProject and other criteria, returned tasks satisfy both conditions with correct AND/OR logic
    - Use gopter library with minimum 100 iterations
    - _Requirements: 4.5_
  
  - [ ]* 3.3 Write unit tests for parentProject filter parsing
    - Test single project ID parsing
    - Test multiple project IDs parsing (IN clause)
    - Test combination with other filters (AND/OR logic)
    - Test invalid project ID handling
    - _Requirements: 4.1, 4.3, 4.5_

- [x] 4. Backend: Update API endpoints to accept child inclusion parameter
  - [x] 4.1 Modify project task endpoints in `pkg/routes/api/v1/` to accept `include_child_tasks` query parameter
    - Map query parameter to `TaskCollection.IncludeChildTasks` field
    - Follow existing API conventions (snake_case for query params)
    - Apply to all project task retrieval endpoints
    - _Requirements: 8.1, 8.2, 8.5_
  
  - [ ]* 4.2 Write integration tests for API endpoints with child inclusion
    - Test GET `/api/v1/projects/{id}/tasks?include_child_tasks=true`
    - Test GET `/api/v1/projects/{id}/tasks?include_child_tasks=false`
    - Test permission denied scenario (user lacks access to parent)
    - Test saved filter with parentProject field
    - _Requirements: 8.1, 8.2, 8.3, 10.1_

- [ ] 5. Backend: Add cache invalidation for hierarchy changes
  - [ ] 5.1 Implement cache invalidation when project parent_project_id changes
    - Hook into project update logic in `pkg/models/project.go`
    - Invalidate `GetAllChildProjects` cache for affected projects
    - Use existing Vikunja cache invalidation patterns
    - _Requirements: 7.3, 7.4_
  
  - [ ]* 5.2 Write property test for cache invalidation on hierarchy change
    - **Property 6: Cache Invalidation on Hierarchy Change**
    - **Validates: Requirements 7.4**
    - For any project hierarchy, after modifying parent_project_id, subsequent GetAllChildProjects calls return updated hierarchy
    - Use gopter library with minimum 100 iterations
    - _Requirements: 7.4_
  
  - [ ]* 5.3 Write unit tests for cache invalidation
    - Test cache invalidation on project parent change
    - Test cache hit after first call, miss after invalidation
    - Test multiple affected projects in hierarchy
    - _Requirements: 7.3, 7.4_

- [-] 6. Checkpoint - Ensure all backend tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Frontend: Add user preference for default toggle state
  - [ ] 7.1 Update `IFrontendSettings` interface in `frontend/src/modelTypes/IUserSettings.ts`
    - Add `showChildProjectTasksByDefault: boolean` field
    - Default value: `false`
    - _Requirements: 2.1, 2.2_
  
  - [ ] 7.2 Add preference UI in user settings page (`frontend/src/views/user/settings/`)
    - Add checkbox labeled "Show tasks in child projects by default"
    - Place in view-related settings section
    - Bind to `userSettings.frontendSettings.showChildProjectTasksByDefault`
    - Save via existing user settings API
    - _Requirements: 2.1, 2.5_
  
  - [ ]* 7.3 Write property test for preference persistence round-trip
    - **Property 3: Preference Persistence Round-Trip**
    - **Validates: Requirements 2.3**
    - For any boolean value assigned to showChildProjectTasksByDefault, saving and retrieving SHALL return the same value
    - Use fast-check library with minimum 100 iterations
    - _Requirements: 2.3_
  
  - [ ]* 7.4 Write unit tests for user settings preference
    - Test preference save and load
    - Test default value (false)
    - Test preference binding in settings UI
    - _Requirements: 2.2, 2.3_

- [ ] 8. Frontend: Implement project view toggle component
  - [ ] 8.1 Add toggle control to project view components
    - Add fancycheckbox component labeled "Show tasks in child projects"
    - Place alongside existing "Show tasks without a date" toggle
    - Initialize from `userSettings.frontendSettings.showChildProjectTasksByDefault`
    - Store toggle state in component local state (not persisted per-project)
    - Apply to all view types: List (`frontend/src/views/project/ProjectList.vue`), Kanban, Gantt, Table
    - _Requirements: 1.1, 1.4, 1.5, 2.4, 5.1, 5.2, 5.3, 5.4_
  
  - [ ] 8.2 Wire toggle to task collection API
    - Pass toggle state to task collection API via `include_child_tasks` query parameter
    - Reload tasks when toggle state changes
    - Follow existing API request patterns
    - _Requirements: 1.2, 1.3, 8.1, 8.2_
  
  - [ ]* 8.3 Write unit tests for toggle component
    - Test toggle initialization from user preference
    - Test toggle state change triggers task reload
    - Test toggle visibility in all view types
    - _Requirements: 1.1, 1.4, 2.4_

- [ ] 9. Frontend: Add parentProject filter to saved filter UI
  - [ ] 9.1 Add "Parent Project" filter option to filter editor (`frontend/src/components/tasks/filters/`)
    - Add filter option with name "parentProject"
    - Description: "The project the task belongs to and all tasks from all descendant child projects"
    - Use existing project picker component for project selection
    - Map to `parentProject` filter field in API request
    - _Requirements: 4.1, 4.2, 8.3_
  
  - [ ]* 9.2 Write unit tests for parentProject filter UI
    - Test filter option appears in filter dropdown
    - Test project selection via project picker
    - Test filter value mapping to API request
    - _Requirements: 4.1, 4.2_

- [ ] 10. Frontend: Implement breadcrumb navigation component
  - [ ] 10.1 Create breadcrumb navigation component (`frontend/src/components/project/`)
    - Fetch parent chain using existing backend API (similar to `GetAllParentProjects`)
    - Display as: "Root Project > Parent Project > Current Project"
    - Make each project name clickable (navigate to project view)
    - Show only for child projects (hide for root projects)
    - Position consistently across all view types
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
  
  - [ ]* 10.2 Write unit tests for breadcrumb navigation
    - Test parent chain fetching and display
    - Test navigation on project name click
    - Test hiding for root projects
    - Test display for multi-level hierarchies
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 11. Frontend: Enhance task display with project indicators
  - [ ] 11.1 Modify task list/card components to show project name for child tasks
    - Display project name/indicator for tasks from child projects
    - Use existing project display patterns
    - Ensure visual distinction from parent project tasks
    - Apply to all view types (List, Kanban, Gantt, Table)
    - _Requirements: 5.5_
  
  - [ ]* 11.2 Write unit tests for task display enhancement
    - Test project name display for child tasks
    - Test visual distinction from parent tasks
    - Test display in all view types
    - _Requirements: 5.5_

- [ ] 12. Checkpoint - Ensure all frontend tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Add translations for new UI elements
  - [ ] 13.1 Add translation keys to `frontend/src/i18n/lang/en.json`
    - Add `project.show_child_project_tasks`: "Show tasks in child projects"
    - Add `project.show_child_project_tasks_description`: "Include tasks from all descendant child projects"
    - Add `user.settings.show_child_project_tasks_by_default`: "Show tasks in child projects by default"
    - Add `user.settings.show_child_project_tasks_by_default_description`: "Automatically enable child project task visibility when viewing projects"
    - Add `filters.parentProject`: "Parent Project"
    - Add `filters.parentProject_description`: "The project the task belongs to and all tasks from all descendant child projects"
    - _Requirements: All UI-related requirements_

- [ ] 14. Integration testing and wiring
  - [ ] 14.1 Test end-to-end flow: toggle in project view
    - Create test project hierarchy (parent with multiple child levels)
    - Verify toggle appears in all view types
    - Verify toggle off shows only parent tasks
    - Verify toggle on shows parent + all descendant tasks
    - Verify permission filtering (create child project user cannot access)
    - _Requirements: 1.1, 1.2, 1.3, 5.1, 5.2, 5.3, 5.4, 10.1, 10.2_
  
  - [ ] 14.2 Test end-to-end flow: user preference
    - Set preference to true in settings
    - Navigate to project view
    - Verify toggle initializes to enabled state
    - Set preference to false
    - Navigate to different project view
    - Verify toggle initializes to disabled state
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 14.3 Test end-to-end flow: saved filter with parentProject
    - Create saved filter with parentProject field
    - Verify filter includes parent + all descendant tasks
    - Combine with other filters (e.g., assignee, due date)
    - Verify correct AND/OR logic application
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 14.4 Test end-to-end flow: breadcrumb navigation
    - Navigate to child project (2+ levels deep)
    - Verify breadcrumb shows full parent chain
    - Click on parent project name in breadcrumb
    - Verify navigation to parent project
    - Navigate to root project
    - Verify breadcrumb hidden or shows only current project
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [ ]* 14.5 Write E2E tests for complete workflows
    - Test toggle shows child project tasks in list view
    - Test user preference sets default toggle state
    - Test saved filter with parentProject includes child tasks
    - Test breadcrumb navigation shows parent chain
    - Test child tasks display project name
    - Test permission enforcement (user cannot see restricted child tasks)
    - _Requirements: All requirements_

- [ ] 15. Performance testing and optimization
  - [ ]* 15.1 Benchmark hierarchy resolution performance
    - Benchmark `GetAllChildProjects` with depth 10 hierarchy
    - Benchmark task retrieval with child inclusion (100 projects)
    - Verify single optimized query (no N+1 pattern)
    - Verify response time ≤ 2x baseline for hierarchies up to 10 levels
    - _Requirements: 9.1, 9.2, 9.4_
  
  - [ ]* 15.2 Test large hierarchy handling
    - Create hierarchy with 100+ descendants
    - Verify performance warning logged
    - Verify system continues processing
    - Verify no timeout or crash
    - _Requirements: 9.3_

- [ ] 16. Final checkpoint - Complete feature validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at backend, frontend, and integration stages
- Property tests validate universal correctness properties using gopter (backend) and fast-check (frontend)
- Unit tests validate specific examples and edge cases
- Integration and E2E tests validate complete workflows
- The implementation strictly follows existing Vikunja patterns: recursive CTEs, saved filter aggregation, frontend_settings JSON storage, and model-level permission checking
- No database schema changes required - all functionality uses existing tables and fields
