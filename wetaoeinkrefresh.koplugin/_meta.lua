local _ = require("gettext")

return {
    fullname = _("WeTao/DEXP E-Ink refresh"),
    description = _([[
Adds a KOReader action that requests a full E-Ink refresh through the WeTao firmware broadcast com.flash.force_epd_full.
]]),
}
