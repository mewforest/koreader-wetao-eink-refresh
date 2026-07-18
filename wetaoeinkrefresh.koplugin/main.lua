local Device = require("device")

if not Device:isAndroid() then
    return { disabled = true }
end

local Dispatcher = require("dispatcher")
local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local WetaoEPD = require("wetaoepd")

local action_title = "Full E-Ink refresh (WeTao/DEXP)"

local WetaoEInkRefresh = WidgetContainer:extend{
    name = "wetaoeinkrefresh",
    is_doc_only = false,
}

function WetaoEInkRefresh:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function WetaoEInkRefresh:onDispatcherRegisterActions()
    Dispatcher:registerAction("wetao_full_eink_refresh", {
        category = "none",
        event = "WetaoFullEinkRefresh",
        title = _(action_title),
        general = true,
    })
end

function WetaoEInkRefresh:onWetaoFullEinkRefresh()
    local ok, err = WetaoEPD.send()
    if not ok then
        UIManager:show(InfoMessage:new{
            text = _("WeTao/DEXP full E-Ink refresh failed: ") .. tostring(err),
        })
    end
    return true
end

function WetaoEInkRefresh:addToMainMenu(menu_items)
    menu_items.wetao_eink_refresh = {
        text = _(action_title),
        sorting_hint = "more_tools",
        callback = function()
            self:onWetaoFullEinkRefresh()
        end,
    }
end

return WetaoEInkRefresh
