local json = require("cjson")
local sha256 = require("resty.sha256")
local str = require("resty.string")
local db = require("lapis.db")

-- Per PLAN.md §11: unlike a mobile-app sandbox, this backend runs on a
-- server this team controls end to end, so this check's primary value is
-- catching a bad build/deploy mistake (a corrupted or truncated seed file
-- shipped to production) rather than detecting a malicious runtime
-- tamperer. Mirrors app13_ruby_FastApi's IntegrityChecker.
local IntegrityChecker = {}
IntegrityChecker.__index = IntegrityChecker

function IntegrityChecker.new(seeds_root)
  local self = setmetatable({}, IntegrityChecker)
  self.seeds_root = seeds_root
  return self
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function sha256_hex(input)
  local digest = sha256:new()
  digest:update(input)
  return str.to_hex(digest:final())
end

-- @return table<string, boolean> file_name -> is_valid
function IntegrityChecker:verify()
  local hashes_path = self.seeds_root .. "/hashes.json"
  if not file_exists(hashes_path) then return {} end

  local expected = json.decode(read_file(hashes_path))
  local results = {}

  for file_name, expected_hash in pairs(expected) do
    local deck_path = self.seeds_root .. "/cornucopia/" .. file_name
    local content = read_file(deck_path)
    local is_valid = content ~= nil and sha256_hex(content) == expected_hash
    results[file_name] = is_valid

    -- `file_name` is the primary key — upsert (Postgres `ON CONFLICT ... DO
    -- UPDATE`) so a re-run (e.g. a future periodic re-verification job)
    -- updates the existing row rather than violating the primary-key
    -- constraint.
    db.query(
      "insert into content_hashes (file_name, sha256_hash, verified_at, is_valid) " ..
      "values (?, ?, now(), ?) " ..
      "on conflict (file_name) do update set sha256_hash = excluded.sha256_hash, " ..
      "verified_at = excluded.verified_at, is_valid = excluded.is_valid",
      file_name, expected_hash, is_valid
    )
  end

  return results
end

function IntegrityChecker:all_valid()
  local results = self:verify()
  for _, is_valid in pairs(results) do
    if not is_valid then return false end
  end
  return true
end

return IntegrityChecker
