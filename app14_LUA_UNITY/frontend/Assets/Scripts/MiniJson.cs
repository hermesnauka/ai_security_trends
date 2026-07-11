using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace LuaGuard
{
    /// <summary>
    /// A minimal, self-contained JSON parser (no external package dependency,
    /// PLAN.md §2 "no third-party networking package" extends to no
    /// third-party JSON package either — this project's only two JSON
    /// consumers, ApiBridge and this file, are both hand-rolled). Parses
    /// into plain Dictionary&lt;string, object&gt;/List&lt;object&gt;/
    /// string/double/bool/null — deliberately NOT into any typed class, so
    /// ApiBridge.ToDynValue can walk it generically regardless of which API
    /// response shape it represents.
    /// </summary>
    public static class MiniJson
    {
        public static object Deserialize(string json)
        {
            if (json == null) return null;
            var index = 0;
            return ParseValue(json, ref index);
        }

        private static void SkipWhitespace(string s, ref int i)
        {
            while (i < s.Length && char.IsWhiteSpace(s[i])) i++;
        }

        private static object ParseValue(string s, ref int i)
        {
            SkipWhitespace(s, ref i);
            switch (s[i])
            {
                case '{': return ParseObject(s, ref i);
                case '[': return ParseArray(s, ref i);
                case '"': return ParseString(s, ref i);
                case 't': i += 4; return true;
                case 'f': i += 5; return false;
                case 'n': i += 4; return null;
                default: return ParseNumber(s, ref i);
            }
        }

        private static Dictionary<string, object> ParseObject(string s, ref int i)
        {
            var result = new Dictionary<string, object>();
            i++; // {
            SkipWhitespace(s, ref i);
            if (s[i] == '}') { i++; return result; }

            while (true)
            {
                SkipWhitespace(s, ref i);
                var key = ParseString(s, ref i);
                SkipWhitespace(s, ref i);
                i++; // :
                var value = ParseValue(s, ref i);
                result[key] = value;
                SkipWhitespace(s, ref i);
                if (s[i] == ',') { i++; continue; }
                i++; // }
                break;
            }
            return result;
        }

        private static List<object> ParseArray(string s, ref int i)
        {
            var result = new List<object>();
            i++; // [
            SkipWhitespace(s, ref i);
            if (s[i] == ']') { i++; return result; }

            while (true)
            {
                var value = ParseValue(s, ref i);
                result.Add(value);
                SkipWhitespace(s, ref i);
                if (s[i] == ',') { i++; continue; }
                i++; // ]
                break;
            }
            return result;
        }

        private static string ParseString(string s, ref int i)
        {
            i++; // opening quote
            var sb = new StringBuilder();
            while (s[i] != '"')
            {
                if (s[i] == '\\')
                {
                    i++;
                    switch (s[i])
                    {
                        case 'n': sb.Append('\n'); break;
                        case 't': sb.Append('\t'); break;
                        case 'r': sb.Append('\r'); break;
                        case '"': sb.Append('"'); break;
                        case '\\': sb.Append('\\'); break;
                        default: sb.Append(s[i]); break;
                    }
                }
                else
                {
                    sb.Append(s[i]);
                }
                i++;
            }
            i++; // closing quote
            return sb.ToString();
        }

        private static double ParseNumber(string s, ref int i)
        {
            var start = i;
            while (i < s.Length && (char.IsDigit(s[i]) || s[i] == '-' || s[i] == '+' || s[i] == '.' || s[i] == 'e' || s[i] == 'E'))
                i++;
            return double.Parse(s.Substring(start, i - start), CultureInfo.InvariantCulture);
        }
    }
}
