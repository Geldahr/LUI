import "Turbine.UI"
import "Turbine.UI.Lotro"

if type(_G.LUI_ENUMS) ~= "table" then
    _G.LUI_ENUMS = {}
end

local e = _G.LUI_ENUMS

e.abbrev_digits = {
    DIGITS_3 = 3,
    DIGITS_4 = 4,
}

e.abbrev_width = {
    CHARS_3 = 3,
    CHARS_4 = 4,
}

e.abbrev_method = {
    K_M_G = 1,
    K_M_B = 2,
    K_m_M = 3,
    E3_E6_E9 = 4,
}

e.side = {
    LEFT = 1,
    RIGHT = 2,
}

e.text_alignment = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3,
}

e.time_format = {
    H24 = 1,
    AMPM = 2,
}

e.font_style = {
    NONE = 1,
    OUTLINE = 2,
}

e.font_name = {
    VERDANA = 1,
    BOOK_ANTIQUA = 2,
    BOOK_ANTIQUA_BOLD = 3,
    TRAJAN_PRO = 4,
    TRAJAN_PRO_BOLD = 5,
    ARIAL = 6,
    FIXED_SYS = 7,
    LUCIDA_CONSOLE = 8,
    VERDANA_BOLD = 9,
}

e.font_name_to_string = {
    [e.font_name.VERDANA] = "Verdana",
    [e.font_name.BOOK_ANTIQUA] = "BookAntiqua",
    [e.font_name.BOOK_ANTIQUA_BOLD] = "BookAntiquaBold",
    [e.font_name.TRAJAN_PRO] = "TrajanPro",
    [e.font_name.TRAJAN_PRO_BOLD] = "TrajanProBold",
    [e.font_name.ARIAL] = "Arial",
    [e.font_name.FIXED_SYS] = "FixedSys",
    [e.font_name.LUCIDA_CONSOLE] = "LucidaConsole",
    [e.font_name.VERDANA_BOLD] = "VerdanaBold",
}

e.vitals_effects_position = {
    ABOVE = 1,
    BELOW = 2,
}

e.bar_mode = {
    LOAD = 1,
    UNLOAD = 2,
}

e.list_flow = {
    TOP_TO_BOTTOM = 1,
    BOTTOM_TO_TOP = 2,
}

e.drop_animation_mode = {
    FADE_THEN_COLLAPSE = 1,
    INSTANT_THEN_COLLAPSE = 2,
    OFF = 3,
}

e.assets_view_mode = {
    ICONS = 1,
    DETAILS = 2,
}

e.side_is_left = {
    [e.side.LEFT] = true,
    [e.side.RIGHT] = false,
}

if type(_G.LUI_TO_LOTRO) ~= "table" then
    _G.LUI_TO_LOTRO = {}
end

local to_lotro = _G.LUI_TO_LOTRO

to_lotro.text_alignment = {
    [e.text_alignment.LEFT] = Turbine.UI.ContentAlignment.MiddleLeft,
    [e.text_alignment.CENTER] = Turbine.UI.ContentAlignment.MiddleCenter,
    [e.text_alignment.RIGHT] = Turbine.UI.ContentAlignment.MiddleRight,
}

to_lotro.font_style = {
    [e.font_style.NONE] = Turbine.UI.FontStyle.None,
    [e.font_style.OUTLINE] = Turbine.UI.FontStyle.Outline,
}
