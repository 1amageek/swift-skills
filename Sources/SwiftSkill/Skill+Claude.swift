// MARK: - Claude Code extension properties

extension Skill {

    /// Prevent Claude from automatically loading this skill. (Claude Code)
    public var disableModelInvocation: Bool? {
        get { extensions["disable-model-invocation"]?.boolValue }
        set { extensions["disable-model-invocation"] = newValue.map { .bool($0) } }
    }

    /// Hide from the `/` menu when set to false. (Claude Code)
    public var userInvocable: Bool? {
        get { extensions["user-invocable"]?.boolValue }
        set { extensions["user-invocable"] = newValue.map { .bool($0) } }
    }

    /// Hint shown during autocomplete to indicate expected arguments. (Claude Code)
    public var argumentHint: String? {
        get { extensions["argument-hint"]?.stringValue }
        set { extensions["argument-hint"] = newValue.map { .string($0) } }
    }

    /// Model to use when this skill is active. (Claude Code)
    public var model: String? {
        get { extensions["model"]?.stringValue }
        set { extensions["model"] = newValue.map { .string($0) } }
    }

    /// Set to "fork" to run in a forked subagent context. (Claude Code)
    public var skillContext: String? {
        get { extensions["context"]?.stringValue }
        set { extensions["context"] = newValue.map { .string($0) } }
    }

    /// Subagent type to use when context is "fork". (Claude Code)
    public var agent: String? {
        get { extensions["agent"]?.stringValue }
        set { extensions["agent"] = newValue.map { .string($0) } }
    }
}
