# SwiftSkill

A Swift library for working with [Agent Skills](https://agentskills.io) — the portable skill format used by Claude Code, OpenAI Codex, and other AI coding tools.

SwiftSkill provides parsing, writing, validation, file-system discovery, and drag & drop support (`Transferable`) for the SKILL.md format.

## Requirements

- Swift 6.2+
- macOS 15+ / iOS 18+ / tvOS 18+ / watchOS 11+ / visionOS 2+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/SwiftSkill.git", from: "0.1.0")
]
```

Then add `"SwiftSkill"` to your target's dependencies.

## Overview

The Agent Skills open standard defines a portable format for AI coding tool instructions. Each skill is a directory containing a `SKILL.md` file (YAML frontmatter + Markdown body) and optional supporting files.

```
my-skill/
├── SKILL.md              # Frontmatter + instructions
├── scripts/
│   └── deploy.sh         # Supporting script
├── references/
│   └── API.md            # Reference documentation
└── agents/
    └── openai.yaml       # Codex-specific configuration
```

AgentSkill supports the full standard plus provider-specific extensions:

| Provider | Skills Directory | Extensions |
|----------|-----------------|------------|
| Standard | `skills/` | — |
| Claude Code | `.claude/skills/` | `disable-model-invocation`, `model`, `context`, `agent`, etc. |
| OpenAI Codex | `.agents/skills/` | `agents/openai.yaml` (interface, policy, dependencies) |

## Usage

### Creating a Skill

```swift
import SwiftSkill

var skill = Skill(
    name: "deploy-staging",
    description: "Deploy the current branch to the staging environment",
    license: "MIT",
    allowedTools: ["Bash", "Read"],
    body: """
    ## Steps

    1. Run the test suite
    2. Build the project
    3. Deploy to staging using `scripts/deploy.sh`
    """
)

// Claude Code extensions
skill.disableModelInvocation = true
skill.skillContext = "fork"
skill.agent = "Explore"
```

### Parsing a SKILL.md

```swift
let parser = SkillParser()

// From a string
let skill = try parser.parse("""
---
name: lint-fix
description: Run linter and auto-fix issues
allowed-tools: Bash
---

Run `eslint --fix .` and report results.
""")

// From a file
let skill = try parser.parse(at: fileURL)

// From a directory (includes supporting files and Codex config)
let skill = try parser.parseDirectory(at: directoryURL)
```

### Writing a Skill

```swift
let writer = SkillWriter()

// To a string
let content = try writer.write(skill)

// To a file
try writer.write(skill, to: fileURL)

// To a directory (SKILL.md + supporting files + Codex config)
try writer.writeDirectory(skill, to: directoryURL)
```

### Validation

```swift
let validator = SkillValidator()
let errors = validator.validate(skill)

if errors.isEmpty {
    // Skill is valid
} else {
    for error in errors {
        print(error) // e.g. .nameInvalidCharacters, .descriptionEmpty
    }
}
```

Name rules enforced by the validator:
- 1–64 characters
- Lowercase letters, digits, and hyphens only
- No leading, trailing, or consecutive hyphens

### File-System Discovery & CRUD

```swift
let store = SkillStore(rootURL: skillsDirectoryURL)

// Discover all skills
let skills = try store.discover()

// Read a specific skill
let skill = try store.skill(named: "deploy-staging")

// Save (creates directory structure)
try store.save(skill)

// Delete
try store.delete(named: "deploy-staging")
```

### Provider Path Resolution

```swift
let provider = SkillProvider.claudeCode

// ~/.claude/skills/
let personal = provider.personalSkillsURL

// <project>/.claude/skills/
let project = provider.projectSkillsURL(in: projectRootURL)

// Both paths, priority-ordered
let candidates = provider.discoveryURLs(projectRoot: projectRootURL)
```

### Codex Configuration

```swift
var skill = Skill(
    name: "codex-skill",
    description: "A skill with Codex configuration",
    body: "Instructions here.",
    codexConfiguration: CodexConfiguration(
        interface: CodexConfiguration.Interface(displayName: "My Skill"),
        policy: CodexConfiguration.Policy(allowImplicitInvocation: false),
        dependencies: CodexConfiguration.Dependencies(
            tools: [
                CodexConfiguration.ToolDependency(
                    type: "mcp",
                    value: "my-server",
                    transport: "streamable_http",
                    url: "https://example.com"
                )
            ]
        )
    )
)

// Convenience accessors
skill.codexDisplayName = "My Skill"
skill.allowImplicitInvocation = false
```

### Transferable (Drag & Drop)

`Skill` conforms to `Transferable` with the UTType `io.agentskills.skill`, enabling drag & drop between apps:

```swift
// In your View
.draggable(skill)
.dropDestination(for: Skill.self) { skills, _ in
    // Handle dropped skills
}
```

### Supporting Files

```swift
var skill = Skill(
    name: "with-files",
    description: "A skill with bundled files",
    body: "See the bundled script.",
    supportingFiles: [
        SupportingFile(relativePath: "scripts/run.sh", text: "#!/bin/bash\necho 'hello'"),
        SupportingFile(relativePath: "assets/config.json", content: jsonData),
    ]
)

// Access file content
if let text = skill.supportingFiles.first?.textContent {
    print(text)
}
```

### Extensions (Custom Frontmatter Fields)

Provider-specific or custom fields are stored in the `extensions` dictionary as `SkillValue`:

```swift
var skill = Skill(name: "custom", description: "Custom extensions")

// Typed via SkillValue enum
skill.extensions["retry-count"] = .int(3)
skill.extensions["timeout"] = .double(30.5)
skill.extensions["tags"] = .array([.string("deploy"), .string("ci")])

// Read back
let retries = skill.extensions["retry-count"]?.intValue  // 3
```

## Types

| Type | Description |
|------|-------------|
| `Skill` | Core model — `Sendable`, `Hashable`, `Identifiable`, `Codable`, `Transferable` |
| `SkillValue` | Dynamic YAML value enum with typed accessors and literal conformances |
| `SupportingFile` | Bundled file with relative path and content |
| `SkillProvider` | Provider enum (`standard`, `claudeCode`, `codex`) with path resolution |
| `CodexConfiguration` | OpenAI Codex `agents/openai.yaml` model |
| `SkillParser` | Parses SKILL.md files and directories |
| `SkillWriter` | Serializes skills to SKILL.md format |
| `SkillValidator` | Validates skills against the Agent Skills spec |
| `SkillStore` | File-system CRUD operations |

## Error Types

| Error | Cases |
|-------|-------|
| `SkillParserError` | `fileNotFound`, `invalidEncoding`, `missingFrontmatter`, `invalidFrontmatter`, `missingRequiredField` |
| `SkillWriterError` | `serializationFailed`, `directoryCreationFailed`, `fileWriteFailed` |
| `SkillValidationError` | `nameEmpty`, `nameTooLong`, `nameInvalidCharacters`, `nameStartsOrEndsWithHyphen`, `nameConsecutiveHyphens`, `descriptionEmpty`, `descriptionTooLong`, `compatibilityTooLong` |

## License

MIT
