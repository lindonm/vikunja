# Child Project Tasks Feature - Summary

## Overview

This feature adds hierarchical project task visibility and filtering to Vikunja, enabling users to view tasks from child projects within parent project views and filter saved views by parent project with recursive child inclusion.

## Key Capabilities

### 1. Project View Toggle
- **What**: Toggle control "Show tasks in child projects" in all project views (List, Kanban, Gantt, Table)
- **How**: Works like the existing "Show tasks without a date" toggle
- **Behavior**: When enabled, includes tasks from all descendant projects recursively

### 2. User Preference
- **What**: Default setting for the toggle state
- **Location**: User settings/preferences page
- **Behavior**: When navigating to any project, the toggle initializes to the user's preferred default state (enabled or disabled)

### 3. Saved Filter Enhancement
- **What**: New "parentProject" filter option
- **Location**: "New Saved Filter" / "Edit This Saved Filter" interface
- **Behavior**: Includes tasks from selected project and all descendant child projects recursively
- **Integration**: Works with existing filter system and combines with other filters using AND/OR logic

### 4. Breadcrumb Navigation
- **What**: Visual display of project hierarchy path
- **Display**: "Root Project > Parent Project > Current Project"
- **Behavior**: Each project name is clickable for navigation; hidden for root projects
- **Location**: Consistently positioned across all project views

## Technical Approach

### Backend Implementation
- **Hierarchy Resolution**: New `GetAllChildProjects` function using recursive CTE (Common Table Expression)
  - Pattern: Mirrors existing `GetAllParentProjects` but traverses downward
  - Performance: Single optimized query with caching
  - Safety: Circular reference detection, depth limiting (50 levels max)

- **Task Collection Enhancement**: Extends existing `TaskCollection` struct
  - New field: `IncludeChildTasks bool` for toggle support
  - New field: `ParentProjectIDs []int64` for filter support
  - Reuses existing multi-project aggregation logic from saved filters

- **Permission Enforcement**: Model-level permission checking
  - Checks `CanRead` for each child project
  - Excludes tasks from projects user cannot access
  - Maintains existing security model

### Frontend Implementation
- **User Preference Storage**: Uses existing `frontend_settings` JSON field
  - No database schema changes required
  - Field: `showChildProjectTasksByDefault: boolean`

- **Toggle Component**: Integrated into all project view types
  - Initializes from user preference
  - Local state (not persisted per-project)
  - Triggers task reload on state change

- **Filter UI**: Extends existing filter editor
  - New "Parent Project" option with project picker
  - Integrates with existing filter system

- **Breadcrumb Component**: New navigation component
  - Fetches parent chain via existing API
  - Clickable navigation links
  - Responsive across all views

## Database Impact

**No database schema changes required**

All functionality uses existing schema:
- `projects.parent_project_id` (already exists)
- `users.frontend_settings` (already exists as JSON)
- Task and filter tables unchanged

## Performance Characteristics

- **Query Optimization**: Single query with `IN` clause (no N+1 queries)
- **Caching**: Hierarchy resolution results cached with invalidation on parent changes
- **Depth Limiting**: Maximum 50 levels to prevent infinite loops
- **Target Performance**: Task retrieval with child inclusion ≤ 2x baseline time (up to 10 levels deep)
- **Large Hierarchy Handling**: Logs warning for 100+ descendants but continues processing

## Security Considerations

- **Permission Enforcement**: Always checks `CanRead` for each child project
- **Information Disclosure Prevention**: Never reveals existence of projects user cannot access
- **Circular Reference Protection**: Detects and breaks cycles in hierarchy resolution
- **Query Injection Prevention**: Uses parameterized queries with XORM protection

## Testing Strategy

### Property-Based Testing (6 Properties)
1. **Hierarchy Resolution Completeness**: All descendant levels returned
2. **Task Inclusion Based on Toggle State**: Correct tasks based on toggle
3. **Preference Persistence Round-Trip**: Settings save/load correctly
4. **Filter Combination Correctness**: AND/OR logic works with parentProject
5. **Permission-Based Task Filtering**: Only permitted tasks returned
6. **Cache Invalidation on Hierarchy Change**: Cache updates on parent changes

### Additional Testing
- Unit tests for core logic and edge cases
- Integration tests for API endpoints and filter system
- E2E tests for all view types and workflows
- Performance benchmarks for large hierarchies

## User Experience

### Typical Workflow 1: Using the Toggle
1. User navigates to a parent project
2. Toggle "Show tasks in child projects" appears (initialized from user preference)
3. User enables toggle
4. View updates to show tasks from parent + all child projects
5. Child tasks are visually distinguishable (project name displayed)

### Typical Workflow 2: Setting Default Preference
1. User opens settings/preferences
2. User enables "Show tasks in child projects by default"
3. User saves settings
4. When navigating to any project, toggle is automatically enabled

### Typical Workflow 3: Using Saved Filter
1. User creates new saved filter
2. User selects "Parent Project" filter option
3. User picks a parent project
4. Filter shows tasks from parent + all descendants
5. User can combine with other filters (assignee, due date, etc.)

### Typical Workflow 4: Breadcrumb Navigation
1. User navigates to a child project (e.g., "Team A > Sprint 1 > Backend Tasks")
2. Breadcrumb displays: "Team A > Sprint 1 > Backend Tasks"
3. User clicks "Team A" in breadcrumb
4. View navigates to "Team A" project

## Implementation Phases

### Phase 1: Backend Core (Tasks 1-6)
- Hierarchy resolver (`GetAllChildProjects`)
- Task collection enhancement
- Filter system integration
- API endpoint updates
- Cache invalidation
- Backend testing

### Phase 2: Frontend UI (Tasks 7-12)
- User preference setting
- Toggle component in all views
- Saved filter UI enhancement
- Breadcrumb navigation component
- Task display enhancement
- Frontend testing

### Phase 3: Integration & Validation (Tasks 13-16)
- Translations
- End-to-end testing
- Performance testing
- Final validation

## Backward Compatibility

- All new API parameters are optional
- Existing API behavior unchanged when new parameters not provided
- Frontend settings default to disabled (no surprise behavior changes)
- No breaking changes to existing APIs or data structures

## Rollout Strategy

1. **Backend First**: Deploy backend changes (backward compatible)
2. **Frontend Second**: Deploy frontend changes after backend is stable
3. **User Opt-In**: Toggle defaults to disabled; users opt-in to new functionality
4. **Monitoring**: Track hierarchy resolution performance, cache hit rates, error rates

## Future Enhancements (Not in Scope)

See `FUTURE_ENHANCEMENTS.md` for potential future additions:
- Bulk operations on project hierarchies
- Project hierarchy visualization (tree view, diagrams)
- Aggregate statistics rolled up from child projects
- Hierarchical task dependencies

## Files Modified

### Backend
- `pkg/models/project.go` - Add `GetAllChildProjects` function
- `pkg/models/task_collection.go` - Add fields and hierarchy expansion logic
- `pkg/routes/api/v1/` - Accept `include_child_tasks` parameter

### Frontend
- `frontend/src/modelTypes/IUserSettings.ts` - Add preference field
- `frontend/src/views/user/settings/` - Add preference UI
- `frontend/src/views/project/` - Add toggle to all view types
- `frontend/src/components/tasks/filters/` - Add parentProject filter option
- `frontend/src/components/project/` - Add breadcrumb navigation component
- `frontend/src/i18n/lang/en.json` - Add translation keys

### Testing
- Property-based tests (6 properties using gopter/fast-check)
- Unit tests for core logic
- Integration tests for API and filters
- E2E tests for complete workflows
- Performance benchmarks

## Success Criteria

- [ ] Toggle appears in all project views with consistent styling
- [ ] Toggle initializes from user preference setting
- [ ] Child tasks display correctly with project indicators
- [ ] Breadcrumb navigation shows parent chain for child projects
- [ ] Saved filter with parentProject includes all descendant tasks
- [ ] Permission enforcement prevents unauthorized task access
- [ ] Performance meets target (≤ 2x baseline for 10-level hierarchies)
- [ ] All property-based tests pass (100+ iterations each)
- [ ] All unit, integration, and E2E tests pass
- [ ] No database schema changes required
- [ ] Backward compatible with existing API clients

## Documentation

- Requirements: `.kiro/specs/child-project-tasks/requirements.md`
- Design: `.kiro/specs/child-project-tasks/design.md`
- Tasks: `.kiro/specs/child-project-tasks/tasks.md`
- Future Ideas: `.kiro/specs/child-project-tasks/FUTURE_ENHANCEMENTS.md`
- This Summary: `.kiro/specs/child-project-tasks/FEATURE_SUMMARY.md`
