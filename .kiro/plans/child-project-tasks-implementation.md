# Implementation Plan: Child Project Tasks Feature

## Quick Reference

**Feature Branch**: `child-project-tasks`  
**Spec Location**: `.kiro/specs/child-project-tasks/`  
**Status**: Ready for implementation

## What This Feature Does

Adds hierarchical project task visibility to Vikunja:
1. **Toggle in project views** - Show/hide tasks from child projects
2. **User preference** - Set default toggle state in settings
3. **Saved filter enhancement** - New "parentProject" filter option
4. **Breadcrumb navigation** - Visual project hierarchy path

## Key Design Decisions

### ✅ Reuses Existing Patterns
- **Recursive CTE**: Mirrors `GetAllParentProjects` pattern
- **Saved Filter Aggregation**: Leverages existing multi-project logic
- **Frontend Settings**: Uses existing `frontend_settings` JSON field
- **Permission Checking**: Model-level `CanRead` enforcement

### ✅ No Database Changes
- All functionality uses existing schema
- `projects.parent_project_id` already exists
- `users.frontend_settings` already exists as JSON
- Zero migrations required

### ✅ Performance Optimized
- Single query with `IN` clause (no N+1)
- Caching with invalidation
- Depth limiting (50 levels max)
- Target: ≤ 2x baseline time for 10-level hierarchies

## Files to Modify

### Backend (Go)
```
pkg/models/project.go              - Add GetAllChildProjects function
pkg/models/task_collection.go      - Add IncludeChildTasks, ParentProjectIDs fields
                                    - Modify getRelevantProjectsFromCollection
pkg/routes/api/v1/                 - Accept include_child_tasks parameter
```

### Frontend (Vue/TypeScript)
```
frontend/src/modelTypes/IUserSettings.ts           - Add showChildProjectTasksByDefault
frontend/src/views/user/settings/                  - Add preference UI
frontend/src/views/project/ProjectList.vue         - Add toggle (+ Kanban, Gantt, Table)
frontend/src/components/tasks/filters/             - Add parentProject filter option
frontend/src/components/project/                   - Add breadcrumb component (new)
frontend/src/i18n/lang/en.json                     - Add translation keys
```

### Testing
```
Property-based tests (6 properties)
Unit tests for core logic
Integration tests for API
E2E tests for workflows
Performance benchmarks
```

## Implementation Sequence

### Phase 1: Backend Core (Tasks 1-6)
**Goal**: Hierarchy resolution and task collection working

1. Create `GetAllChildProjects` with recursive CTE
2. Add fields to `TaskCollection` struct
3. Modify `getRelevantProjectsFromCollection` for expansion
4. Add permission filtering for child projects
5. Integrate `parentProject` filter parsing
6. Update API endpoints to accept `include_child_tasks`
7. Implement cache invalidation
8. Write property-based tests (6 properties)
9. Write unit and integration tests

**Checkpoint**: All backend tests pass

### Phase 2: Frontend UI (Tasks 7-12)
**Goal**: User-facing controls and preferences working

1. Add `showChildProjectTasksByDefault` to settings interface
2. Add preference UI in settings page
3. Add toggle to all project views (List, Kanban, Gantt, Table)
4. Wire toggle to API with `include_child_tasks` parameter
5. Add `parentProject` filter to filter editor
6. Create breadcrumb navigation component
7. Enhance task display with project indicators
8. Add translation keys
9. Write unit tests for components

**Checkpoint**: All frontend tests pass

### Phase 3: Integration & Validation (Tasks 13-16)
**Goal**: End-to-end workflows validated

1. Test toggle in all view types
2. Test user preference initialization
3. Test saved filter with parentProject
4. Test breadcrumb navigation
5. Test permission enforcement
6. Run performance benchmarks
7. Write E2E tests

**Checkpoint**: Complete feature validation

## Testing Strategy

### Property-Based Tests (6 Properties)
Using `gopter` (backend) and `fast-check` (frontend), minimum 100 iterations each:

1. **Hierarchy Resolution Completeness** - All descendant levels returned
2. **Task Inclusion Based on Toggle State** - Correct tasks based on toggle
3. **Preference Persistence Round-Trip** - Settings save/load correctly
4. **Filter Combination Correctness** - AND/OR logic with parentProject
5. **Permission-Based Task Filtering** - Only permitted tasks returned
6. **Cache Invalidation on Hierarchy Change** - Cache updates correctly

### Additional Testing
- Unit tests for edge cases (circular refs, no children, deep nesting)
- Integration tests for API endpoints
- E2E tests for complete user workflows
- Performance benchmarks for large hierarchies

## Key Implementation Notes

### Backend: GetAllChildProjects Function
```go
// Pattern: Recursive CTE traversing from parent to children
// Similar to GetAllParentProjects but inverted direction
// Returns: map[int64]*Project for efficient lookup
// Safety: Depth limit 50, circular reference detection
// Performance: Cached with invalidation on parent changes
```

### Backend: Task Collection Enhancement
```go
// Add to TaskCollection struct:
IncludeChildTasks bool    `query:"include_child_tasks"`
ParentProjectIDs  []int64 `json:"-"`

// In getRelevantProjectsFromCollection:
if tf.IncludeChildTasks && tf.ProjectID != 0 {
    childProjects, err := GetAllChildProjects(s, tf.ProjectID)
    // Add child IDs to projects list
    // Filter by CanRead permission
}
```

### Frontend: User Preference
```typescript
// Add to IFrontendSettings:
showChildProjectTasksByDefault: boolean  // Default: false

// Stored in User.FrontendSettings JSON (no DB change)
```

### Frontend: Toggle Component
```vue
<!-- Pattern: Similar to "Show tasks without a date" toggle -->
<fancycheckbox
    v-model="showChildProjectTasks"
    @update:modelValue="loadTasks"
>
    {{ $t('project.show_child_project_tasks') }}
</fancycheckbox>

<!-- Initialize from: userSettings.frontendSettings.showChildProjectTasksByDefault -->
<!-- Pass to API: ?include_child_tasks=true -->
```

### Frontend: Breadcrumb Navigation
```vue
<!-- Display: "Root Project > Parent Project > Current Project" -->
<nav class="breadcrumb">
    <ul>
        <li v-for="project in parentChain" :key="project.id">
            <router-link :to="projectRoute(project.id)">
                {{ project.title }}
            </router-link>
        </li>
        <li class="is-active">
            <a>{{ currentProject.title }}</a>
        </li>
    </ul>
</nav>
```

## Common Pitfalls to Avoid

### ❌ Don't
- Create new database tables or columns
- Reimplement multi-project aggregation logic
- Store toggle state per-project (use user preference instead)
- Skip permission checking for child projects
- Use N+1 queries for hierarchy resolution
- Invent new patterns (follow existing Vikunja conventions)

### ✅ Do
- Reuse existing recursive CTE pattern
- Leverage saved filter aggregation system
- Store preference in `frontend_settings` JSON
- Check `CanRead` for every child project
- Use single query with `IN` clause
- Follow existing naming and structure conventions

## Performance Targets

- **Hierarchy Resolution**: Cached, single CTE query
- **Task Retrieval**: ≤ 2x baseline time (up to 10 levels)
- **Large Hierarchies**: Log warning at 100+ descendants, continue processing
- **Query Pattern**: Single optimized query (no N+1)
- **Depth Limit**: Maximum 50 levels to prevent infinite loops

## Security Checklist

- [ ] Permission check (`CanRead`) for every child project
- [ ] Exclude tasks from projects user cannot access
- [ ] Never reveal existence of restricted projects
- [ ] Circular reference detection and breaking
- [ ] Parameterized queries (XORM protection)
- [ ] Model-level permission enforcement (defense in depth)

## Rollout Plan

1. **Deploy Backend** - Backward compatible, new parameters optional
2. **Deploy Frontend** - After backend is stable
3. **User Opt-In** - Toggle defaults to disabled
4. **Monitor** - Track performance, cache hit rates, errors

## Success Criteria

- [ ] Toggle appears in all project views
- [ ] Toggle initializes from user preference
- [ ] Child tasks display with project indicators
- [ ] Breadcrumb shows parent chain for child projects
- [ ] Saved filter with parentProject works correctly
- [ ] Permission enforcement prevents unauthorized access
- [ ] Performance meets targets (≤ 2x baseline)
- [ ] All property-based tests pass (100+ iterations)
- [ ] All unit, integration, E2E tests pass
- [ ] No database schema changes
- [ ] Backward compatible

## Documentation

- **Requirements**: `.kiro/specs/child-project-tasks/requirements.md` (10 requirements)
- **Design**: `.kiro/specs/child-project-tasks/design.md` (architecture, components, testing)
- **Tasks**: `.kiro/specs/child-project-tasks/tasks.md` (16 tasks, 45 sub-tasks)
- **Summary**: `.kiro/specs/child-project-tasks/FEATURE_SUMMARY.md` (user-facing overview)
- **Future Ideas**: `.kiro/specs/child-project-tasks/FUTURE_ENHANCEMENTS.md` (not in scope)
- **This Plan**: `plans/child-project-tasks-implementation.md` (quick reference)

## Quick Start

```bash
# Review the spec
cat .kiro/specs/child-project-tasks/FEATURE_SUMMARY.md

# Start with backend
# Task 1: Implement GetAllChildProjects in pkg/models/project.go

# Then frontend
# Task 7: Add user preference to IUserSettings.ts

# Run tests frequently
mage test:feature
cd frontend && pnpm test:unit

# Before committing
mage lint:fix
cd frontend && pnpm lint:fix && pnpm lint:styles:fix
```

## Questions or Issues?

Refer to:
- **AGENTS.md** - Development workflows and conventions
- **FEATURE.MD** - Original feature requirements
- **Design Document** - Technical architecture and patterns
- **Tasks Document** - Detailed implementation steps with requirement traceability

## Additional Recommendations (Future)

Documented in `FUTURE_ENHANCEMENTS.md` (not in current scope):
- Bulk operations on project hierarchies
- Project hierarchy visualization (tree view, diagrams)
- Aggregate statistics rolled up from child projects
- Hierarchical task dependencies
