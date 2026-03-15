import "Turbine.UI.Lotro"

import "Geldahr.LUI.Vitals.effects_area"

---@class BuffArea : EffectsArea
BuffArea = class(EffectsArea)

function BuffArea:Constructor(frame_width, effects_settings, effects_height)
    EffectsArea.Constructor(self, frame_width, effects_settings, effects_height)
end

function BuffArea:_settings_group()
    return "buffs"
end

function BuffArea:_default_dynamic_height()
    return true
end

function BuffArea:_default_icon_size()
    return 32
end

function BuffArea:_default_timer_font()
    return {
        name = LUI_ENUMS.font_name.VERDANA,
        size = 12,
        lotro = Turbine.UI.Lotro.Font.Verdana12,
        style = LUI_ENUMS.font_style.OUTLINE,
    }
end

function BuffArea:_reset_max_height_on_apply_settings()
    return true
end
