// MARK: - OpenAI Codex convenience properties

extension Skill {

    /// Whether the skill allows implicit (automatic) invocation by Codex.
    public var allowImplicitInvocation: Bool? {
        get { codexConfiguration?.policy?.allowImplicitInvocation }
        set {
            if codexConfiguration == nil {
                codexConfiguration = CodexConfiguration()
            }
            if codexConfiguration?.policy == nil {
                codexConfiguration?.policy = CodexConfiguration.Policy()
            }
            codexConfiguration?.policy?.allowImplicitInvocation = newValue
        }
    }

    /// Display name from Codex interface configuration.
    public var codexDisplayName: String? {
        get { codexConfiguration?.interface?.displayName }
        set {
            if codexConfiguration == nil {
                codexConfiguration = CodexConfiguration()
            }
            if codexConfiguration?.interface == nil {
                codexConfiguration?.interface = CodexConfiguration.Interface()
            }
            codexConfiguration?.interface?.displayName = newValue
        }
    }
}
