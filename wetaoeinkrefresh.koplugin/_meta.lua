local _ = require("gettext")

return {
    fullname = _("WeTao/DEXP E-Ink refresh"),
    description = _([[
Requests a full E-Ink refresh through the WeTao firmware broadcast com.flash.force_epd_full. Refreshes automatically on each page turn, and also exposes a manual Full E-Ink refresh (WeTao/DEXP) action.
]]),
}
