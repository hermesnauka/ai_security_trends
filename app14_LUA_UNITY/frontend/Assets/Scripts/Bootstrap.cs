using System.IO;
using MoonSharp.Interpreter;
using UnityEngine;

namespace LuaGuard
{
    /// <summary>
    /// C# owns exactly three things (PLAN.md §3): booting Unity, mounting
    /// the MoonSharp sandbox (LuaSandbox), and marshalling ApiBridge
    /// responses into Lua tables. Every decision about what to render, how a
    /// STRIDE match resolves, and how reputation changes is made in Lua —
    /// this class never contains gameplay/domain logic itself.
    /// </summary>
    public class Bootstrap : MonoBehaviour
    {
        [SerializeField] private ApiBridge apiBridge;

        private Script script;

        private void Awake()
        {
            script = LuaSandbox.CreateSandboxedScript();
            apiBridge.Init(script);

            RegisterApiBridgeFunctions();
            LoadGameplayScripts();

            script.Call(script.Globals.Get("bootstrap"));
        }

        private void RegisterApiBridgeFunctions()
        {
            // Plain closures, not a UserData-registered ApiBridge instance
            // (D-07/SR-11) — Lua only ever sees these three functions, never
            // the MonoBehaviour itself.
            script.Globals["native_http_get"] = (System.Func<string, string, Closure, Closure, DynValue>)((path, query, onSuccess, onError) =>
            {
                apiBridge.Get(path, query, onSuccess, onError);
                return DynValue.Nil;
            });

            script.Globals["native_http_post"] = (System.Func<string, string, Closure, Closure, DynValue>)((path, jsonBody, onSuccess, onError) =>
            {
                apiBridge.Post(path, jsonBody, onSuccess, onError);
                return DynValue.Nil;
            });

            script.Globals["native_get_pref"] = (System.Func<string, string>)(key => PlayerPrefs.GetString(key, null));
            script.Globals["native_set_pref"] = (System.Action<string, string>)((key, value) =>
            {
                PlayerPrefs.SetString(key, value);
                PlayerPrefs.Save();
            });
        }

        private void LoadGameplayScripts()
        {
            // Only ever loads from this app's own StreamingAssets/lua path —
            // SR-13: no feature in this codebase loads Lua from any other
            // source (no "custom card deck" upload, no server-side eval
            // endpoint).
            var luaRoot = Path.Combine(Application.streamingAssetsPath, "lua");
            foreach (var fileName in new[] { "i18n.lua", "api_client.lua", "card_engine.lua", "game_modes.lua", "main.lua" })
            {
                var path = Path.Combine(luaRoot, fileName);
                script.DoFile(path);
            }
        }
    }
}
