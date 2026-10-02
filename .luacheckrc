-- the AddOn's namespace and saved variables are written at runtime
globals = {
  "rggm",
  "GearMenuConfiguration",
  "GearMenuShotLog",
}

-- constant tables defined once by their own file (see the overrides below) and only read everywhere else
read_globals = {
  "RGGM_CONSTANTS",
  "RGGM_ENVIRONMENT",
  "RGGM_SHOTS",
}

files = {
  ["code"] = {std = "lua51"},
  ["gui"] = {std = "lua51"},
  ["localization"] = {std = "lua51"},
  ["test"] = {std = "lua51+busted"},
  ["dev"] = {std = "lua51"},
  ["code/Constants.lua"] = {globals = {"RGGM_CONSTANTS"}},
  ["code/Environment.lua"] = {globals = {"RGGM_ENVIRONMENT"}},
  ["test/headless/Bootstrap.lua"] = {globals = {"RGGM_ENVIRONMENT"}},
  ["dev/ShotManifest.lua"] = {globals = {"RGGM_SHOTS"}}
}

exclude_files = {
  ".luacheckrc",
  "target/"
}
