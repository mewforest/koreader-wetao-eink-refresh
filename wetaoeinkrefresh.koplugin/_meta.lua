local _ = require("gettext")

return {
    fullname = _("WeTao/DEXP E-Ink refresh"),
    description = _([[
Requests manual and automatic full E-Ink refresh through the WeTao firmware broadcast com.flash.force_epd_full, including beta double refresh with a configurable delay.
]]),
}
