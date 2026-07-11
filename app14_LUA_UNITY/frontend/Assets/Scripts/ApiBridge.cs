using System.Collections;
using System.Collections.Generic;
using MoonSharp.Interpreter;
using UnityEngine;
using UnityEngine.Networking;

namespace LuaGuard
{
    /// <summary>
    /// The only networking code in this project — plain UnityWebRequest, no
    /// third-party package (PLAN.md §2). Marshals JSON responses into plain
    /// Lua tables so `api_client.lua` never needs to know this is C#
    /// underneath. Every call here passes only strings/tables/numbers/bools
    /// across the C#&lt;-&gt;Lua boundary (D-07/SR-11) — never a live C#
    /// object reference.
    /// </summary>
    public class ApiBridge : MonoBehaviour
    {
        [SerializeField] private string baseUrl = "https://localhost:9292";
        private Script script;

        public void Init(Script sandboxedScript)
        {
            script = sandboxedScript;
        }

        public void Get(string path, string queryString, Closure onSuccess, Closure onError)
        {
            StartCoroutine(RequestCoroutine("GET", path + queryString, null, onSuccess, onError));
        }

        public void Post(string path, string jsonBody, Closure onSuccess, Closure onError)
        {
            StartCoroutine(RequestCoroutine("POST", path, jsonBody, onSuccess, onError));
        }

        private IEnumerator RequestCoroutine(string method, string path, string jsonBody, Closure onSuccess, Closure onError)
        {
            var url = baseUrl + path;
            using var request = new UnityWebRequest(url, method);

            if (jsonBody != null)
            {
                var bodyRaw = System.Text.Encoding.UTF8.GetBytes(jsonBody);
                request.uploadHandler = new UploadHandlerRaw(bodyRaw);
                request.SetRequestHeader("Content-Type", "application/json");
            }

            // D-08: PlayerPrefs is plaintext on disk (a .plist/registry
            // key/.dat file depending on platform) — a stated Phase-1
            // caveat, not an oversight. Do not "fix" this without updating
            // PLAN.md D-01/D-08 first.
            var token = PlayerPrefs.GetString("luaguard.token", null);
            if (!string.IsNullOrEmpty(token))
            {
                request.SetRequestHeader("Authorization", "Bearer " + token);
            }

            request.downloadHandler = new DownloadHandlerBuffer();

            yield return request.SendWebRequest();

            if (request.result != UnityWebRequest.Result.Success)
            {
                onError?.Call((double)request.responseCode, request.error ?? "");
                yield break;
            }

            var parsed = MiniJson.Deserialize(request.downloadHandler.text);
            var table = ToDynValue(parsed);
            onSuccess?.Call(table);
        }

        private DynValue ToDynValue(object value)
        {
            switch (value)
            {
                case null:
                    return DynValue.Nil;
                case bool b:
                    return DynValue.NewBoolean(b);
                case double d:
                    return DynValue.NewNumber(d);
                case string s:
                    return DynValue.NewString(s);
                case Dictionary<string, object> dict:
                    {
                        var table = new Table(script);
                        foreach (var kv in dict)
                        {
                            table.Set(kv.Key, ToDynValue(kv.Value));
                        }
                        return DynValue.NewTable(table);
                    }
                case List<object> list:
                    {
                        var table = new Table(script);
                        for (var i = 0; i < list.Count; i++)
                        {
                            // Lua arrays are 1-indexed.
                            table.Set(i + 1, ToDynValue(list[i]));
                        }
                        return DynValue.NewTable(table);
                    }
                default:
                    return DynValue.Nil;
            }
        }
    }
}
