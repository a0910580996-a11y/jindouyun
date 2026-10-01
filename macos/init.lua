local defaults = {
  applications = {
    obsidian = 'Obsidian',
    chrome = 'Google Chrome',
    wechat = 'WeChat'
  },
  urls = {
    chatgpt = 'https://chatgpt.com/',
    gemini = 'https://gemini.google.com/',
    translate = 'https://translate.google.com/'
  },
  pouchDirectory = hs.configdir .. '/筋斗云/袖里乾坤/锦囊'
}

local function merge(base, override)
  local result = {}
  for key, value in pairs(base) do
    if type(value) == 'table' then
      result[key] = merge(value, {})
    else
      result[key] = value
    end
  end
  for key, value in pairs(override or {}) do
    if type(value) == 'table' and type(result[key]) == 'table' then
      result[key] = merge(result[key], value)
    else
      result[key] = value
    end
  end
  return result
end

function loadUserConfig()
  local path = hs.configdir .. '/筋斗云/配置.lua'
  local attributes = hs.fs.attributes(path)
  if not attributes then
    return defaults
  end
  local ok, userConfig = pcall(dofile, path)
  if not ok or type(userConfig) ~= 'table' then
    hs.alert.show('筋斗云：配置.lua 加载失败')
    return defaults
  end
  return merge(defaults, userConfig)
end

local config = loadUserConfig()
local previousFrames = {}

function openApplication(key)
  local applicationName = config.applications[key]
  if not applicationName or applicationName == '' then
    hs.alert.show('筋斗云：未配置应用 ' .. key)
    return
  end
  if not hs.application.launchOrFocus(applicationName) then
    hs.alert.show('筋斗云：未找到 ' .. applicationName)
  end
end

function toggleWindow()
  local window = hs.window.frontmostWindow()
  if not window then
    return
  end
  local id = window:id()
  if previousFrames[id] then
    window:setFrame(previousFrames[id])
    previousFrames[id] = nil
  else
    previousFrames[id] = window:frame()
    window:maximize()
  end
end

function openUrl(key)
  local url = config.urls[key]
  if not url or url == '' then
    hs.alert.show('筋斗云：未配置网址 ' .. key)
    return
  end
  hs.urlevent.openURL(url)
end

function mediaAction(action)
  hs.eventtap.event.newSystemKeyEvent(action, true):post()
  hs.eventtap.event.newSystemKeyEvent(action, false):post()
end

function openPouch()
  local directory = config.pouchDirectory
  local choices = {}
  local iterator = hs.fs.dir(directory)
  if not iterator then
    hs.alert.show('筋斗云：锦囊目录不存在')
    return
  end
  for fileName in iterator do
    if fileName:sub(-3) == '.md' then
      table.insert(choices, {
        text = fileName:sub(1, -4),
        path = directory .. '/' .. fileName
      })
    end
  end
  table.sort(choices, function(a, b) return a.text < b.text end)
  if #choices == 0 then
    hs.alert.show('筋斗云：锦囊目录为空')
    return
  end
  local chooser = hs.chooser.new(function(choice)
    if not choice then
      return
    end
    local file = io.open(choice.path, 'r')
    if not file then
      hs.alert.show('筋斗云：无法读取锦囊')
      return
    end
    local content = file:read('*a')
    file:close()
    local oldClipboard = hs.pasteboard.getContents()
    hs.pasteboard.setContents(content)
    hs.eventtap.keyStroke({'cmd'}, 'v')
    hs.timer.doAfter(0.2, function()
      if oldClipboard then
        hs.pasteboard.setContents(oldClipboard)
      end
    end)
  end)
  chooser:choices(choices)
  chooser:show()
end

hs.hotkey.bind({'alt'}, 'return', toggleWindow)
hs.hotkey.bind({'alt'}, 'o', function() openApplication('obsidian') end)
hs.hotkey.bind({'alt'}, 'c', function() openApplication('chrome') end)
hs.hotkey.bind({'alt'}, 'w', function() openApplication('wechat') end)
hs.hotkey.bind({'alt'}, '1', function() openUrl('chatgpt') end)
hs.hotkey.bind({'alt'}, '2', function() openUrl('gemini') end)
hs.hotkey.bind({'alt'}, 't', function() openUrl('translate') end)
hs.hotkey.bind({'alt', 'shift'}, 'p', openPouch)
hs.hotkey.bind({}, 'f7', function() mediaAction('PREVIOUS') end)
hs.hotkey.bind({}, 'f8', function() mediaAction('PLAY') end)
hs.hotkey.bind({}, 'f9', function() mediaAction('NEXT') end)

hs.alert.show('筋斗云已加载')
