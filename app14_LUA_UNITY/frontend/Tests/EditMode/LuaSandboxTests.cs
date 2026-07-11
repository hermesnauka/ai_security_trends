using MoonSharp.Interpreter;
using NUnit.Framework;
using LuaGuard;

namespace LuaGuard.Tests.EditMode
{
    /// <summary>
    /// US-14 (user_stories+tests.md): the MoonSharp sandbox boundary is
    /// this project's one genuinely novel risk class. These tests execute
    /// real adversarial Lua snippets against the actual sandboxed Script
    /// instance and assert they raise — a dynamic check that sits between
    /// classic SAST and DAST (SDLC_analysis.md §5).
    /// </summary>
    public class LuaSandboxTests
    {
        [Test]
        public void CannotReadArbitraryFiles()
        {
            var script = LuaSandbox.CreateSandboxedScript();
            Assert.Throws<ScriptRuntimeException>(() =>
                script.DoString("return io.open('/etc/passwd'):read('*a')"));
        }

        [Test]
        public void CannotSpawnProcesses()
        {
            var script = LuaSandbox.CreateSandboxedScript();
            Assert.Throws<ScriptRuntimeException>(() =>
                script.DoString("return os.execute('echo pwned')"));
        }

        [Test]
        public void CannotAccessOsDate()
        {
            // os.date is also excluded by the explicit IO/OS mask in
            // LuaSandbox — gameplay code that needs a timestamp receives one
            // from native_http_get's response payload instead, never by
            // calling os.* directly.
            var script = LuaSandbox.CreateSandboxedScript();
            Assert.Throws<ScriptRuntimeException>(() =>
                script.DoString("return os.date()"));
        }

        [Test]
        public void CanStillRunOrdinaryGameplayLogic()
        {
            // The sandbox must not be so restrictive it breaks legitimate
            // card_engine.lua-style logic — tables, string formatting, and
            // basic math all need to keep working.
            var script = LuaSandbox.CreateSandboxedScript();
            var result = script.DoString("local t = {1,2,3}; return #t + string.len('abc')");
            Assert.AreEqual(6, result.Number);
        }
    }
}
