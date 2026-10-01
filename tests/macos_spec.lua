local path = arg[1] or 'macos/init.lua'
local file = assert(io.open(path, 'r'))
local source = file:read('*a')
file:close()

local requiredFunctions = {
  'loadUserConfig',
  'openApplication',
  'toggleWindow',
  'openUrl',
  'mediaAction',
  'openPouch'
}

for _, name in ipairs(requiredFunctions) do
  assert(source:find('function ' .. name, 1, true), 'missing function: ' .. name)
end

assert(source:find('配置.lua', 1, true), 'local config file is not loaded')
assert(source:find('hs.hotkey.bind', 1, true), 'hotkeys are not registered')
print('macOS contract: PASS')
