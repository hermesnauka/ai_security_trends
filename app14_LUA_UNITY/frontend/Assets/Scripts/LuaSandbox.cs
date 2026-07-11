using MoonSharp.Interpreter;

namespace LuaGuard
{
    /// <summary>
    /// D-07: constructs every MoonSharp <see cref="Script"/> instance used by
    /// this app. This is the single most security-critical file in the
    /// entire LuaGuard codebase (both tiers) — no other sibling in this
    /// repo embeds a general-purpose script interpreter inside its own
    /// client, so this is the one place a coding mistake becomes a genuine
    /// remote-code-execution primitive rather than a data-validation bug.
    ///
    /// Rule, enforced here and nowhere else (SR-10): never construct a
    /// Script with CoreModules.Full. Always use the whitelist below. A CI
    /// grep-check (`! grep -rn "CoreModules.Full" Assets/Scripts/`) is a
    /// deliberately blunt backstop alongside this class's own unit tests
    /// (Tests/EditMode/LuaSandboxTests.cs, mirroring user_stories+tests.md
    /// US-14).
    /// </summary>
    public static class LuaSandbox
    {
        // Preset_SoftSandbox already excludes the dangerous modules, but the
        // exclusion is spelled out explicitly below anyway — a future
        // MoonSharp version changing what SoftSandbox includes should not
        // silently reintroduce io/os access here without this line failing
        // to compile or an explicit review of this file.
        private const CoreModules SandboxModules =
            CoreModules.Preset_SoftSandbox & ~CoreModules.IO & ~CoreModules.OS;

        public static Script CreateSandboxedScript()
        {
            var script = new Script(SandboxModules);

            // SR-11: no C# UserData-registered live object is ever exposed
            // to Lua. Every value crossing this boundary is registered as
            // plain data (a table/string/number/bool) via ApiBridge, never
            // via UserData.RegisterType against a live C# class instance.
            return script;
        }
    }
}
