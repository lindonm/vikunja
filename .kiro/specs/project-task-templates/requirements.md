# Requirements Document

## Introduction

This feature adds template functionality to Vikunja, allowing users to create reusable templates for projects and tasks. Users can save projects (with their complete structure including tasks, sub-projects, buckets, and views) as templates, and instantiate new projects or tasks from these templates. Templates are stored in a human-readable JSON or YAML format, making them easy to share, version control, and customize outside of Vikunja.

## Glossary

- **Template**: A reusable blueprint for creating projects or tasks, stored in JSON or YAML format
- **Project_Template**: A template that defines a complete project structure including tasks, sub-projects, buckets, views, and all associated metadata
- **Task_Template**: A template that defines a single task with all its properties (title, description, labels, assignees, etc.)
- **Template_Content**: The JSON or YAML data structure containing the template definition
- **Template_Metadata**: Information about a template (name, description, type, owner, visibility, creation date)
- **Template_Instantiation**: The process of creating a new project or task from a template
- **Template_Parameter**: A placeholder in a template that can be replaced with actual values during instantiation (e.g., dates, assignee names)
- **Template_Visibility**: Whether a template is private (only visible to creator), shared (visible to specific users/teams), or public (visible to all users)
- **Template_Export**: Converting an existing project into a template format
- **Template_Library**: The collection of templates available to a user
- **Backend**: The Go API service that handles template storage, validation, and instantiation
- **Frontend**: The Vue.js web client that provides the template management UI
- **InsertFromStructure**: The existing function that creates projects from imported data structures
- **ProjectWithTasksAndBuckets**: The existing data structure used for project export/import

## Requirements

### Requirement 1: Template Data Model

**User Story:** As a system, I want to store template metadata and content separately, so that templates can be efficiently queried, managed, and instantiated.

#### Acceptance Criteria

1. THE Backend SHALL define a Template model with fields for id, name, description, template_type (project or task), content_format (json or yaml), owner_id, visibility, is_archived, created, and updated
2. THE Backend SHALL store template content in a separate field as JSON or YAML text
3. WHEN a template is created, THE Backend SHALL validate that the template_type is either "project" or "task"
4. WHEN a template is created, THE Backend SHALL validate that the content_format is either "json" or "yaml"
5. THE Backend SHALL validate that the visibility field is one of: "private", "shared", or "public"

### Requirement 2: Create Project Template from Existing Project

**User Story:** As a user, I want to export an existing project as a template, so that I can reuse the project structure for future projects.

#### Acceptance Criteria

1. WHEN a user requests to create a template from a project, THE Backend SHALL export the project using the existing ProjectWithTasksAndBuckets structure
2. THE Backend SHALL include all project fields (title, description, identifier, hex_color, background information, views, buckets, positions) in the template
3. THE Backend SHALL include all tasks with their complete data (title, description, due dates, assignees, labels, attachments, reminders, repeat settings, relations, comments) in the template
4. THE Backend SHALL include all child projects recursively in the template
5. THE Backend SHALL serialize the exported structure to JSON or YAML format based on user preference
6. WHEN creating a template from a project, THE Backend SHALL prompt the user for template metadata (name, description, visibility)
7. THE Backend SHALL store the template with the provided metadata and serialized content

### Requirement 3: Create Task Template from Existing Task

**User Story:** As a user, I want to save an existing task as a template, so that I can quickly create similar tasks in the future.

#### Acceptance Criteria

1. WHEN a user requests to create a template from a task, THE Backend SHALL export the task with all its fields (title, description, due_date, priority, start_date, end_date, hex_color, percent_done, repeat_after, repeat_mode)
2. THE Backend SHALL include all task assignees in the template
3. THE Backend SHALL include all task labels in the template
4. THE Backend SHALL include all task reminders in the template
5. THE Backend SHALL include task attachment metadata (but not file content) in the template
6. THE Backend SHALL serialize the task data to JSON or YAML format based on user preference
7. WHEN creating a template from a task, THE Backend SHALL prompt the user for template metadata (name, description, visibility)

### Requirement 4: Create Template Manually

**User Story:** As a user, I want to create a template from scratch by writing JSON or YAML, so that I can define templates programmatically or share them via version control.

#### Acceptance Criteria

1. WHEN a user creates a new template, THE Frontend SHALL provide a text editor for entering template content
2. THE Frontend SHALL support syntax highlighting for JSON and YAML formats
3. WHEN a user submits template content, THE Backend SHALL validate that the content is valid JSON or YAML
4. WHEN a user submits template content, THE Backend SHALL validate that the content structure matches the expected schema for the template type
5. THE Backend SHALL return descriptive validation errors if the template content is invalid
6. THE Backend SHALL store the validated template with the provided metadata

### Requirement 5: Template CRUD Operations

**User Story:** As a user, I want to create, read, update, and delete templates, so that I can manage my template library.

#### Acceptance Criteria

1. THE Backend SHALL provide an API endpoint to create a new template with metadata and content
2. THE Backend SHALL provide an API endpoint to retrieve a single template by ID
3. THE Backend SHALL provide an API endpoint to retrieve all templates accessible to the user
4. THE Backend SHALL provide an API endpoint to update template metadata (name, description, visibility)
5. THE Backend SHALL provide an API endpoint to update template content
6. THE Backend SHALL provide an API endpoint to delete a template
7. WHEN a user deletes a template, THE Backend SHALL permanently remove the template and its content
8. THE Backend SHALL enforce permission checks for all template operations using the existing Permissions interface

### Requirement 6: Template Permissions

**User Story:** As a user, I want to control who can view and use my templates, so that I can share templates with specific users or teams while keeping others private.

#### Acceptance Criteria

1. WHEN a template visibility is "private", THE Backend SHALL allow only the template owner to read, update, or delete the template
2. WHEN a template visibility is "shared", THE Backend SHALL allow the owner and explicitly granted users/teams to read and use the template
3. WHEN a template visibility is "public", THE Backend SHALL allow all authenticated users to read and use the template
4. THE Backend SHALL allow only the template owner to update or delete a template regardless of visibility
5. THE Backend SHALL provide an API endpoint to grant template access to specific users or teams for shared templates
6. THE Backend SHALL provide an API endpoint to revoke template access from specific users or teams
7. THE Backend SHALL use the existing Permissions interface pattern (CanRead, CanWrite, CanDelete) for template permission checks

### Requirement 7: Instantiate Project from Template

**User Story:** As a user, I want to create a new project from a template, so that I can quickly set up projects with predefined structures.

#### Acceptance Criteria

1. WHEN a user instantiates a project template, THE Backend SHALL deserialize the template content from JSON or YAML
2. THE Backend SHALL use the existing InsertFromStructure function to create the project with all nested tasks, child projects, buckets, views, and positions
3. WHEN instantiating a project template, THE Backend SHALL prompt the user for a project title (overriding the template title)
4. THE Backend SHALL allow the user to optionally specify a parent project for the new project
5. THE Backend SHALL set the current user as the owner of the newly created project
6. THE Backend SHALL create all tasks, child projects, buckets, and views from the template
7. THE Backend SHALL preserve all task relationships (related tasks, labels, assignees) from the template
8. THE Backend SHALL return the newly created project ID and structure to the Frontend

### Requirement 8: Instantiate Task from Template

**User Story:** As a user, I want to create a new task from a template, so that I can quickly add tasks with predefined properties.

#### Acceptance Criteria

1. WHEN a user instantiates a task template, THE Backend SHALL deserialize the template content from JSON or YAML
2. THE Backend SHALL prompt the user to select a target project for the new task
3. THE Backend SHALL create the task with all properties from the template (title, description, priority, dates, labels, assignees, reminders)
4. THE Backend SHALL allow the user to optionally override the task title during instantiation
5. THE Backend SHALL set the current user as the creator of the newly created task
6. THE Backend SHALL preserve all task labels from the template, creating new labels if they don't exist in the target project
7. THE Backend SHALL assign users from the template if they exist in the system, otherwise skip missing assignees
8. THE Backend SHALL return the newly created task ID to the Frontend

### Requirement 9: Template Parameterization

**User Story:** As a user, I want to use placeholders in templates for dynamic values like dates and assignees, so that templates can be customized during instantiation.

#### Acceptance Criteria

1. THE Backend SHALL support date placeholders in template content using the syntax `{{date:offset}}` where offset is a relative time (e.g., `{{date:+7d}}` for 7 days from now)
2. THE Backend SHALL support assignee placeholders using the syntax `{{assignee:current}}` to assign the current user
3. THE Backend SHALL support project owner placeholders using the syntax `{{owner:current}}` to set the current user as owner
4. WHEN instantiating a template, THE Backend SHALL replace all date placeholders with calculated dates based on the instantiation time
5. WHEN instantiating a template, THE Backend SHALL replace all assignee placeholders with the current user's ID
6. THE Backend SHALL support custom parameter placeholders using the syntax `{{param:name}}` that can be provided by the user during instantiation
7. WHEN a template contains custom parameters, THE Frontend SHALL prompt the user to provide values for all parameters before instantiation

### Requirement 10: Template Validation

**User Story:** As a system, I want to validate template content before saving or instantiating, so that invalid templates cannot be created or used.

#### Acceptance Criteria

1. WHEN a template is created or updated, THE Backend SHALL validate that the content is valid JSON or YAML
2. WHEN a template is created or updated, THE Backend SHALL validate that the content structure matches the expected schema for project or task templates
3. THE Backend SHALL validate that all required fields are present in the template content (e.g., project title, task title)
4. THE Backend SHALL validate that field values are within acceptable ranges (e.g., priority is a valid integer, hex colors are valid)
5. THE Backend SHALL return descriptive error messages indicating which fields are invalid and why
6. WHEN instantiating a template, THE Backend SHALL validate that all parameter placeholders can be resolved
7. THE Backend SHALL prevent instantiation if required parameters are missing or invalid

### Requirement 11: Template Library UI

**User Story:** As a user, I want to browse and search my available templates, so that I can find and use templates easily.

#### Acceptance Criteria

1. THE Frontend SHALL display a template library page showing all templates accessible to the user
2. THE Frontend SHALL display template cards showing template name, description, type (project or task), owner, and creation date
3. THE Frontend SHALL provide a search box to filter templates by name or description
4. THE Frontend SHALL provide filter controls to show only project templates, only task templates, or all templates
5. THE Frontend SHALL provide filter controls to show only owned templates, shared templates, or public templates
6. THE Frontend SHALL display a visual indicator for template type (project icon or task icon)
7. WHEN a user clicks on a template card, THE Frontend SHALL display the template details page

### Requirement 12: Template Details UI

**User Story:** As a user, I want to view template details and preview template content, so that I can understand what a template contains before using it.

#### Acceptance Criteria

1. THE Frontend SHALL display a template details page showing all template metadata (name, description, type, owner, visibility, created, updated)
2. THE Frontend SHALL display the template content in a read-only code editor with syntax highlighting
3. THE Frontend SHALL provide a button to instantiate the template (create project or task from template)
4. WHEN the user is the template owner, THE Frontend SHALL provide buttons to edit or delete the template
5. THE Frontend SHALL display a preview of the project or task structure that would be created from the template
6. THE Frontend SHALL display a list of parameters that will be prompted during instantiation (if any)

### Requirement 13: Template Creation UI

**User Story:** As a user, I want an intuitive interface for creating templates from existing projects or tasks, so that I can easily save my work as reusable templates.

#### Acceptance Criteria

1. WHEN viewing a project, THE Frontend SHALL display a "Save as Template" button in the project menu
2. WHEN viewing a task, THE Frontend SHALL display a "Save as Template" option in the task menu
3. WHEN a user clicks "Save as Template", THE Frontend SHALL display a dialog prompting for template metadata (name, description, visibility)
4. THE Frontend SHALL provide a dropdown to select content format (JSON or YAML)
5. THE Frontend SHALL display a preview of the template content before saving
6. WHEN a user confirms template creation, THE Frontend SHALL send the template data to the Backend
7. THE Frontend SHALL display a success message with a link to the newly created template

### Requirement 14: Template Instantiation UI

**User Story:** As a user, I want a guided workflow for creating projects or tasks from templates, so that I can easily customize templates during instantiation.

#### Acceptance Criteria

1. WHEN a user clicks "Use Template" on a project template, THE Frontend SHALL display a dialog prompting for the new project title
2. THE Frontend SHALL provide an optional field to select a parent project for the new project
3. WHEN a user clicks "Use Template" on a task template, THE Frontend SHALL display a dialog prompting for the target project
4. THE Frontend SHALL provide an optional field to override the task title
5. WHEN a template contains custom parameters, THE Frontend SHALL display input fields for each parameter
6. THE Frontend SHALL validate that all required fields are filled before allowing instantiation
7. WHEN instantiation is successful, THE Frontend SHALL navigate to the newly created project or task

### Requirement 15: Template Sharing UI

**User Story:** As a user, I want to share templates with specific users or teams, so that my collaborators can use my templates.

#### Acceptance Criteria

1. WHEN viewing a template details page, THE Frontend SHALL display a "Share" button for template owners
2. WHEN a user clicks "Share", THE Frontend SHALL display a dialog with sharing options
3. THE Frontend SHALL provide a dropdown to select visibility (private, shared, public)
4. WHEN visibility is "shared", THE Frontend SHALL provide a user/team picker to grant access
5. THE Frontend SHALL display a list of users and teams who currently have access to the template
6. THE Frontend SHALL provide a button to revoke access for each user or team
7. WHEN sharing settings are saved, THE Frontend SHALL update the template visibility and access list

### Requirement 16: Template Export and Import

**User Story:** As a user, I want to export templates as files and import templates from files, so that I can share templates outside of Vikunja or back them up.

#### Acceptance Criteria

1. WHEN viewing a template details page, THE Frontend SHALL provide an "Export" button to download the template as a JSON or YAML file
2. THE exported file SHALL contain both template metadata and content in a single file
3. THE Frontend SHALL provide an "Import Template" button in the template library
4. WHEN a user imports a template file, THE Backend SHALL validate the file format and content
5. THE Backend SHALL create a new template from the imported file with the current user as owner
6. THE Backend SHALL preserve template metadata from the imported file (name, description, type)
7. THE Backend SHALL set visibility to "private" for imported templates by default

### Requirement 17: Template Versioning

**User Story:** As a user, I want to track changes to templates over time, so that I can revert to previous versions if needed.

#### Acceptance Criteria

1. WHEN a template is updated, THE Backend SHALL create a new version record with the previous content
2. THE Backend SHALL store version metadata (version number, updated timestamp, updated by user)
3. THE Backend SHALL provide an API endpoint to retrieve all versions of a template
4. THE Backend SHALL provide an API endpoint to retrieve a specific version of a template
5. THE Backend SHALL provide an API endpoint to restore a previous version (making it the current version)
6. THE Frontend SHALL display a version history list on the template details page
7. WHEN a user views a previous version, THE Frontend SHALL display the version content in read-only mode with an option to restore

### Requirement 18: Template Categories and Tags

**User Story:** As a user, I want to organize templates with categories and tags, so that I can find related templates easily.

#### Acceptance Criteria

1. THE Backend SHALL support a category field for templates (e.g., "Work", "Personal", "Team")
2. THE Backend SHALL support multiple tags per template for flexible organization
3. THE Frontend SHALL provide a category dropdown when creating or editing templates
4. THE Frontend SHALL provide a tag input field with autocomplete for existing tags
5. THE Frontend SHALL display category and tags on template cards in the library
6. THE Frontend SHALL provide filter controls to show templates by category or tag
7. THE Backend SHALL provide an API endpoint to retrieve all available categories and tags

### Requirement 19: Template Attachment Handling

**User Story:** As a user, I want templates to preserve attachment metadata, so that I know which attachments should be added when using a template.

#### Acceptance Criteria

1. WHEN creating a project template, THE Backend SHALL include attachment metadata (filename, size, mime type) but not file content
2. THE Backend SHALL include a flag indicating whether attachments should be copied during instantiation
3. WHEN instantiating a template with attachments, THE Frontend SHALL display a list of attachments that need to be uploaded
4. THE Frontend SHALL provide a file upload interface for each attachment in the template
5. THE Backend SHALL create task attachments from uploaded files during instantiation
6. THE Backend SHALL allow users to skip attachment uploads and create the project/task without attachments
7. THE Backend SHALL preserve the cover image attachment reference if the cover image is uploaded

### Requirement 20: Template Performance and Scalability

**User Story:** As a system, I want template operations to perform efficiently, so that users can work with large templates without delays.

#### Acceptance Criteria

1. THE Backend SHALL instantiate templates with up to 1000 tasks within 10 seconds
2. THE Backend SHALL support templates with up to 10 levels of nested child projects
3. THE Backend SHALL use database transactions for template instantiation to ensure atomicity
4. WHEN template instantiation fails, THE Backend SHALL roll back all changes and return a descriptive error
5. THE Backend SHALL cache template content for frequently used templates
6. THE Backend SHALL paginate template library results with a default page size of 50 templates
7. THE Backend SHALL log performance metrics for template operations exceeding 5 seconds

### Requirement 21: Template Content Format Specification

**User Story:** As a developer, I want a clear specification for template content format, so that I can create valid templates programmatically.

#### Acceptance Criteria

1. THE Backend SHALL document the JSON schema for project templates including all supported fields
2. THE Backend SHALL document the JSON schema for task templates including all supported fields
3. THE Backend SHALL document all supported parameter placeholder syntaxes and their behavior
4. THE Backend SHALL provide example templates for common use cases (e.g., sprint planning, onboarding checklist)
5. THE Backend SHALL validate template content against the documented schema
6. THE Backend SHALL support both JSON and YAML formats with equivalent schemas
7. THE Backend SHALL provide a schema validation endpoint that returns detailed validation results

### Requirement 22: Template Duplication

**User Story:** As a user, I want to duplicate an existing template, so that I can create variations of templates without starting from scratch.

#### Acceptance Criteria

1. WHEN viewing a template details page, THE Frontend SHALL provide a "Duplicate" button
2. WHEN a user clicks "Duplicate", THE Frontend SHALL display a dialog prompting for the new template name
3. THE Backend SHALL create a new template with the same content as the original
4. THE Backend SHALL set the current user as the owner of the duplicated template
5. THE Backend SHALL set visibility to "private" for the duplicated template
6. THE Backend SHALL append " (Copy)" to the template name if no custom name is provided
7. THE Frontend SHALL navigate to the newly duplicated template after creation

### Requirement 23: Template Usage Analytics

**User Story:** As a template owner, I want to see how often my templates are used, so that I can understand which templates are most valuable.

#### Acceptance Criteria

1. WHEN a template is instantiated, THE Backend SHALL increment a usage counter for the template
2. THE Backend SHALL record the timestamp of each template instantiation
3. THE Backend SHALL provide an API endpoint to retrieve template usage statistics (total uses, last used date)
4. THE Frontend SHALL display usage statistics on the template details page
5. THE Frontend SHALL display a "Most Used" section in the template library showing top templates by usage count
6. THE Backend SHALL allow template owners to view who has used their shared or public templates
7. THE Backend SHALL respect user privacy by not exposing usage data for private templates to non-owners

### Requirement 24: Template Archiving

**User Story:** As a user, I want to archive templates I no longer use, so that my template library stays organized without permanently deleting templates.

#### Acceptance Criteria

1. THE Backend SHALL support an is_archived boolean field for templates
2. THE Backend SHALL provide an API endpoint to archive a template
3. THE Backend SHALL provide an API endpoint to unarchive a template
4. WHEN a template is archived, THE Backend SHALL exclude it from default template library queries
5. THE Frontend SHALL provide an "Archive" button on the template details page for template owners
6. THE Frontend SHALL provide a filter toggle to show or hide archived templates in the library
7. WHEN viewing an archived template, THE Frontend SHALL display an "Unarchive" button

### Requirement 25: Template Validation Feedback

**User Story:** As a user, I want clear feedback when template validation fails, so that I can fix errors in my template content.

#### Acceptance Criteria

1. WHEN template validation fails, THE Backend SHALL return a structured error response with field-level errors
2. THE Backend SHALL indicate the line number and column for JSON/YAML syntax errors
3. THE Backend SHALL provide human-readable error messages for schema validation failures
4. THE Frontend SHALL display validation errors inline in the template editor
5. THE Frontend SHALL highlight the specific lines with errors in the code editor
6. THE Frontend SHALL provide suggestions for fixing common validation errors
7. THE Frontend SHALL prevent template saving or instantiation until all validation errors are resolved

