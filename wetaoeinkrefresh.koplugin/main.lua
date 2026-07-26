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
local refresh_after_page_turn_key = "wetao_refresh_after_page_turn"
local double_refresh_after_page_turn_key = "wetao_double_refresh_after_page_turn"
local double_refresh_delay_key = "wetao_double_refresh_delay_ms"
local double_refresh_delay_default = 500
local double_refresh_delay_min = 100
local double_refresh_delay_max = 3000

local function get_double_refresh_delay_ms()
    local delay = tonumber(G_reader_settings:readSetting(
        double_refresh_delay_key,
        double_refresh_delay_default
    )) or double_refresh_delay_default
    return math.max(double_refresh_delay_min, math.min(double_refresh_delay_max, delay))
end

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
    if not G_reader_settings:nilOrTrue(refresh_after_page_turn_key) then
        self._last_page = pageno
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
        if gen ~= self._refresh_gen
            or not G_reader_settings:nilOrTrue(refresh_after_page_turn_key)
        then
            return
        end
        local ok = self:doWetaoRefresh()
        if not ok
            or not G_reader_settings:isTrue(double_refresh_after_page_turn_key)
        then
            return
        end
        UIManager:scheduleIn(get_double_refresh_delay_ms() / 1000, function()
            if gen ~= self._refresh_gen
                or not G_reader_settings:nilOrTrue(refresh_after_page_turn_key)
                or not G_reader_settings:isTrue(double_refresh_after_page_turn_key)
            then
                return
            end
            self:doWetaoRefresh()
        end)
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
    menu_items.wetao_refresh_after_page_turn = {
        text = _("Refresh after page turn"),
        sorting_hint = "more_tools",
        checked_func = function()
            return G_reader_settings:nilOrTrue(refresh_after_page_turn_key)
        end,
        callback = function()
            if G_reader_settings:nilOrTrue(refresh_after_page_turn_key) then
                G_reader_settings:saveSetting(refresh_after_page_turn_key, false)
            else
                G_reader_settings:delSetting(refresh_after_page_turn_key)
            end
        end,
    }
    menu_items.wetao_double_refresh_after_page_turn = {
        text = _("Double refresh after page turn (beta)"),
        sorting_hint = "more_tools",
        checked_func = function()
            return G_reader_settings:isTrue(double_refresh_after_page_turn_key)
        end,
        callback = function()
            if G_reader_settings:isTrue(double_refresh_after_page_turn_key) then
                G_reader_settings:delSetting(double_refresh_after_page_turn_key)
            else
                G_reader_settings:saveSetting(double_refresh_after_page_turn_key, true)
            end
        end,
    }
    menu_items.wetao_double_refresh_delay = {
        text_func = function()
            return string.format(
                _("Double refresh delay: %d ms"),
                get_double_refresh_delay_ms()
            )
        end,
        sorting_hint = "more_tools",
        enabled_func = function()
            return G_reader_settings:isTrue(double_refresh_after_page_turn_key)
        end,
        keep_menu_open = true,
        callback = function(touchmenu_instance)
            local SpinWidget = require("ui/widget/spinwidget")
            UIManager:show(SpinWidget:new{
                title_text = _("Double refresh delay (ms)"),
                info_text = _("Increase this delay if the second refresh is unstable."),
                ok_text = _("Set delay"),
                value = get_double_refresh_delay_ms(),
                value_min = double_refresh_delay_min,
                value_max = double_refresh_delay_max,
                value_step = 50,
                value_hold_step = 250,
                unit = "ms",
                default_value = double_refresh_delay_default,
                callback = function(spin)
                    G_reader_settings:saveSetting(double_refresh_delay_key, spin.value)
                    touchmenu_instance:updateItems()
                end,
            })
        end,
    }
end

return WetaoEInkRefresh
