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
    -- PageUpdate is delivered automatically via EventListener:handleEvent
    -- (onPageUpdate). KOReader has no ui:registerEventListener API.
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

function WetaoEInkRefresh:doWetaoRefresh()
    return WetaoEPD.send()
end

function WetaoEInkRefresh:onWetaoFullEinkRefresh()
    local ok, err = self:doWetaoRefresh()
    if not ok then
        UIManager:show(InfoMessage:new{
            text = _("WeTao/DEXP full E-Ink refresh failed: ") .. tostring(err),
        })
    end
    return true
end

-- Official KOReader page-turn hook: ReaderUI broadcasts Event("PageUpdate", pageno)
-- during input handling, *before* UIManager:_repaint paints the new page.
-- Refreshing immediately would flash the previous page; tickAfterNext runs after that paint.
function WetaoEInkRefresh:onPageUpdate(pageno)
    if pageno == false then
        -- Document close sentinel used by ReaderStatistics / ReaderUI.
        self._refresh_gen = (self._refresh_gen or 0) + 1
        return
    end
    if self._last_page == pageno then
        return
    end
    self._last_page = pageno
    self._refresh_gen = (self._refresh_gen or 0) + 1
    local gen = self._refresh_gen
    UIManager:tickAfterNext(function()
        if gen ~= self._refresh_gen then
            return
        end
        self:doWetaoRefresh()
    end)
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
