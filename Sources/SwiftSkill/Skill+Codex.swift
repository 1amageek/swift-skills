// MARK: - OpenAI Codex convenience properties

extension Skill {

    /// Whether the skill allows implicit (automatic) invocation by Codex.
    public var allowImplicitInvocation: Bool? {
        get {
            do {
                return try configuration(CodexConfiguration.self)?.policy?.allowImplicitInvocation
            } catch {
                assertionFailure("Corrupted CodexConfiguration: \(error)")
                return nil
            }
        }
        set {
            do {
                var config = (try configuration(CodexConfiguration.self)) ?? CodexConfiguration()
                if config.policy == nil {
                    config.policy = CodexConfiguration.Policy()
                }
                config.policy?.allowImplicitInvocation = newValue
                try setConfiguration(config)
            } catch {
                assertionFailure("Failed to update CodexConfiguration: \(error)")
            }
        }
    }

    /// Display name from Codex interface configuration.
    public var codexDisplayName: String? {
        get {
            do {
                return try configuration(CodexConfiguration.self)?.interface?.displayName
            } catch {
                assertionFailure("Corrupted CodexConfiguration: \(error)")
                return nil
            }
        }
        set {
            do {
                var config = (try configuration(CodexConfiguration.self)) ?? CodexConfiguration()
                if config.interface == nil {
                    config.interface = CodexConfiguration.Interface()
                }
                config.interface?.displayName = newValue
                try setConfiguration(config)
            } catch {
                assertionFailure("Failed to update CodexConfiguration: \(error)")
            }
        }
    }
}
