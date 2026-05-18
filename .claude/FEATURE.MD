You are modifying Vikunja (Go backend + Vue frontend) from https://vikunja.io/
This feature branch "child-project-tasks" has been created to implement this feature and nothing else.

Follow existing patterns strictly:
- Naming, structure, conventions must match repo
- Reuse existing logic wherever possible
- DO NOT invent new patterns

Goal:
Implement hierarchical project task visibility and filtering.

Features:
1. Add toggle "Show tasks in child projects" in project views (List, Gantt, etc)
   - Works like "Show tasks without a date"
   - When enabled: include tasks from all descendant projects (recursive)
   - Use existing saved view multi-project aggregation logic if possible (DO NOT reimplement)

2. Add filter option to "New Saved Filter" / "Edit This Saved Filter" - Filter name: *parentProject*
   - Description: The project the task belongs to and all tasks from all decendent child projectds
   - Recursive: includes all children
   - Integrates into existing filter system

Constraints:
- Minimal DB changes preferred (none if possible)
- Backend should expand project IDs → list of descendant IDs
- Frontend should pass toggle/filter cleanly
- Must work across all views
- Modify only files required. Prefer NOT to add new skills or refactor any code that is not strictly necessary to deliver the feature.

Deliverables:
- Code changes
- Short reasoning
- MD file explaining feature

Be concise.
