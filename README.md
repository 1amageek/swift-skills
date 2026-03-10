# SwiftSkill

A Swift library for working with [Agent Skills](https://agentskills.io) — the portable skill format used by [Claude Code](https://code.claude.com/docs/en/skills), [OpenAI Codex](https://developers.openai.com/codex/skills/), and other AI coding tools.

SwiftSkill provides parsing, writing, validation, file-system discovery, and drag & drop support (`Transferable`) for the SKILL.md format.

## Requirements

- Swift 6.2+
- macOS 15+ / iOS 18+ / tvOS 18+ / watchOS 11+ / visionOS 2+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/swift-skills.git", from: "0.1.0")
]
```

Then add `"SwiftSkill"` to your target's dependencies.

## Overview

A skill is a directory bundle containing a `SKILL.md` file (YAML frontmatter + Markdown body) and optional supporting files. In Swift, the entire bundle is represented as a single `struct Skill` — no filesystem awareness is needed when working with skills in code.

```
my-skill/
├── SKILL.md              # Frontmatter + instructions (required)
├── scripts/
│   └── deploy.sh         # Executable script
├── references/
│   └── API.md            # Reference documentation
└── agents/
    └── openai.yaml       # Codex configuration
```

SwiftSkill supports the full Agent Skills standard plus provider-specific extensions:

| Provider | Skills Directory | Extensions |
|----------|-----------------|------------|
| Standard | `skills/` | — |
| Claude Code | `.claude/skills/` | `disable-model-invocation`, `model`, `context`, `agent`, `hooks`, etc. |
| OpenAI Codex | `.agents/skills/` | `agents/openai.yaml` (interface, policy, dependencies) |

## Usage

### Creating a Skill

`Skill` is a self-contained bundle. Assemble it in code without thinking about the filesystem:

```swift
import SwiftSkill

var skill = Skill(
    name: "deploy-staging",
    description: "Deploy the current branch to the staging environment",
    license: "MIT",
    allowedTools: ["Bash(git:*)", "Read"],
    body: """
    ## Steps

    1. Run the test suite
    2. Build the project
    3. Deploy to staging using `scripts/deploy.sh`
    """,
    supportingFiles: [
        SupportingFile(relativePath: "scripts/deploy.sh", text: "#!/bin/bash\necho deploy"),
    ]
)

// Claude Code extensions (stored in frontmatter)
skill.disableModelInvocation = true
skill.skillContext = "fork"
skill.agent = "Explore"
skill.model = "opus"

// Codex configuration (stored as bundled data)
try skill.setConfiguration(CodexConfiguration(
    interface: CodexConfiguration.Interface(displayName: "Deploy Staging"),
    policy: CodexConfiguration.Policy(allowImplicitInvocation: false)
))
```

### Reading and Writing (I/O)

Filesystem paths are only relevant when reading from or writing to disk:

```swift
let parser = SkillParser()
let writer = SkillWriter()

// Parse from a string
let skill = try parser.parse(markdownString)

// Parse from a file
let skill = try parser.parse(at: fileURL)

// Parse a full directory bundle
let skill = try parser.parseDirectory(at: directoryURL)

// Write to a string
let markdown = try writer.write(skill)

// Write to a file
try writer.write(skill, to: fileURL)

// Write a full directory bundle
try writer.writeDirectory(skill, to: directoryURL)
```

### SkillStore (CRUD)

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

### Configurations

`ConfigurationRepresentable` defines how provider-specific configurations serialize to and from `Data`. The `Skill` bundle stores them by type name — no file paths involved:

```swift
// Write
try skill.setConfiguration(CodexConfiguration(
    interface: CodexConfiguration.Interface(
        displayName: "My Skill",
        brandColor: "#3B82F6"
    ),
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
))

// Read
let codex = try skill.configuration(CodexConfiguration.self)
print(codex?.interface?.displayName)

// Check
skill.hasConfiguration(CodexConfiguration.self)

// Convenience accessors
skill.codexDisplayName = "My Skill"
skill.allowImplicitInvocation = false
```

### Custom Configurations

Define your own provider configuration by conforming to `ConfigurationRepresentable`:

```swift
struct MyConfig: ConfigurationRepresentable {
    var endpoint: String

    init(configurationData data: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    func configurationData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// Use in a Skill bundle (no path needed)
try skill.setConfiguration(MyConfig(endpoint: "https://api.example.com"))

// For I/O, tell the parser/writer where to find the file
let mappings = ConfigurationFileMapping.defaults + [
    ConfigurationFileMapping(MyConfig.self, relativePath: "agents/myprovider.json")
]
let store = SkillStore(rootURL: url, configurationMappings: mappings)
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

Name rules:
- 1–64 characters
- Lowercase letters, digits, and hyphens only
- No leading, trailing, or consecutive hyphens

### Supporting Files

All files in the skill directory (except `SKILL.md` and configuration files) are bundled as `SupportingFile`:

```swift
skill.supportingFiles = [
    SupportingFile(relativePath: "scripts/run.sh", text: "#!/bin/bash\necho hello"),
    SupportingFile(relativePath: "references/API.md", text: "# API Reference"),
    SupportingFile(relativePath: "assets/config.json", content: jsonData),
]

// Access content
if let text = skill.supportingFiles.first?.textContent {
    print(text)
}
```

### Extensions (Custom Frontmatter)

Non-standard frontmatter fields are stored in the `extensions` dictionary as `SkillValue`:

```swift
skill.extensions["retry-count"] = .int(3)
skill.extensions["timeout"] = .double(30.5)
skill.extensions["tags"] = .array([.string("deploy"), .string("ci")])

let retries = skill.extensions["retry-count"]?.intValue  // 3
```

### Transferable (Drag & Drop)

`Skill` conforms to `Transferable` with the UTType `io.agentskills.skill`:

```swift
.draggable(skill)
.dropDestination(for: Skill.self) { skills, _ in
    // Handle dropped skills
}
```

## Types

| Type | Description |
|------|-------------|
| `Skill` | Core bundle model — `Sendable`, `Hashable`, `Identifiable`, `Codable`, `Transferable` |
| `SkillValue` | Dynamic YAML value enum with typed accessors and literal conformances |
| `SupportingFile` | Bundled file with relative path and content |
| `ConfigurationRepresentable` | Protocol for serializable configurations |
| `ConfigurationFileMapping` | Maps configuration types to file paths for I/O |
| `CodexConfiguration` | OpenAI Codex configuration (interface, policy, dependencies) |
| `SkillProvider` | Provider enum (`standard`, `claudeCode`, `codex`) with path resolution |
| `SkillParser` | Parses SKILL.md files and directory bundles |
| `SkillWriter` | Serializes skills to SKILL.md format and directory bundles |
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
