import "Turbine.UI"
import "Turbine.UI.Lotro"

Cooldowns = {
    key = "cooldowns",
    text = TR("Cooldowns"),
}

local function _layout_text_area(entry)
    if entry == nil or entry.control == nil or entry.tb == nil or entry.label == nil then
        return
    end

    local w, h = entry.control:GetSize()
    local label_h = 20
    local gap = 4

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(w, label_h)

    entry.tb:SetPosition(0, label_h + gap)
    entry.tb:SetSize(w, math.max(10, h - label_h - gap))
end

local function _create_text_area(window, ui, key, label_text, help_text)
    local entry = ui.add_custom(key, 89)

    entry.label = Turbine.UI.Label()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(window.field_label_font)
    entry.label:SetMultiline(false)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.label:SetText(label_text)

    entry.tb = Turbine.UI.Lotro.TextBox()
    entry.tb:SetParent(entry.control)
    entry.tb:SetFont(window.input_font)
    entry.tb:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    if entry.tb.SetMultiline ~= nil then
        entry.tb:SetMultiline(true)
    end

    if type(help_text) == "string" and help_text ~= "" then
        local function bind_hint(target)
            if target == nil then
                return
            end
            local prev_enter = target.MouseEnter
            target.MouseEnter = function(sender, args)
                if prev_enter ~= nil then
                    prev_enter(sender, args)
                end
                window:show_hint_for(target, help_text)
            end
            local prev_leave = target.MouseLeave
            target.MouseLeave = function(sender, args)
                if prev_leave ~= nil then
                    prev_leave(sender, args)
                end
                window:hide_hint()
            end
        end

        bind_hint(entry.tb)
    end

    entry.control.SizeChanged = function()
        _layout_text_area(entry)
    end
    _layout_text_area(entry)

    return entry
end

function Cooldowns.create_controls(window, ui)
    local bar_mode_labels = { TR("Load"), TR("Unload") }
    local bar_mode_values = { LUI_ENUMS.bar_mode.LOAD, LUI_ENUMS.bar_mode.UNLOAD }
    local flow_labels = { TR("Top to bottom"), TR("Bottom to top") }
    local flow_values = { LUI_ENUMS.list_flow.TOP_TO_BOTTOM, LUI_ENUMS.list_flow.BOTTOM_TO_TOP }

    ui.add_checkbox("cd_enabled", TR("Enabled"), true)

    ui.add_text("cd_threshold", TR("Threshold (s)"))

    ui.add_custom("cooldowns_preview", 52)

    ui.add_text("cd_item_w", TR("Item width"))
    ui.add_text("cd_item_h", TR("Item height"))
    ui.add_text("cd_spacing", TR("Spacing (px)"))
    ui.add_text("cd_border_width", TR("Border width (px)"))
    ui.add_text("cd_columns", TR("Columns"))
    ui.add_text("cd_rows", TR("Rows"))
    ui.add_dropdown("cd_flow", TR("Order"), flow_labels, flow_values)

    ui.add_dropdown("cd_icon_side", TR("Icon position"), ui.side_labels, ui.side_values)
    ui.add_dropdown("cd_bar_mode", TR("Bar mode"), bar_mode_labels, bar_mode_values)
    ui.add_dropdown("cd_bar_expire_towards", TR("Bar movement towards"), ui.side_labels, ui.side_values)
    ui.add_text("cd_bg_color", TR("Background color"), true)
    ui.add_text("cd_bar_color", TR("Bar color"), true)
    ui.add_text("cd_border_color", TR("Border color"), true)

    local fmt_help = table.concat({
        TR("Tokens:"),
        TR("  %name% - skill name"),
        TR("  %t - remaining time with tenths (X.Ys)"),
        TR("  %s - remaining time without tenths (Xs)"),
        "",
        TR("Examples:"),
        TR("  %name% - %t"),
        TR("  %name% - %s"),
    }, "\n")

    ui.add_text("cd_text_template", TR("Text template"), false, fmt_help, true)
    ui.add_dropdown("cd_text_alignment", TR("Text alignment"), ui.text_alignment_labels, ui.text_alignment_values)
    ui.add_text("cd_text_margin", TR("Text margin (px)"))
    ui.add_text("cd_name_max_chars", TR("Max name chars"))

    ui.add_dropdown("cd_font_name", TR("Font"), ui.font_name_labels, ui.font_name_values)
    ui.add_text("cd_font_size", TR("Font size"))
    ui.add_text("cd_font_color", TR("Font color"), true)
    ui.add_dropdown("cd_font_style", TR("Font style"), ui.font_style_labels, ui.font_style_values)
    ui.add_text("cd_font_outline_color", TR("Outline color"), true)

    local list_help = TR("One skill name per line or comma-separated. Case-insensitive. Exact match or prefix with trailing *.")
    _create_text_area(window, ui, "cd_whitelist", TR("Whitelist"), list_help)
    _create_text_area(window, ui, "cd_blacklist", TR("Blacklist"), list_help)
end

function Cooldowns.register(window, ui)
    return {
        ui.add_title(TR("Cooldowns")),

        ui.add_hr(),
        ui.add_title(TR("General")),
        window.controls.cd_enabled,
        window.controls.cd_threshold,

        ui.add_hr(),
        ui.add_title(TR("Layout")),
        window.controls.cd_item_w,
        window.controls.cd_item_h,
        window.controls.cd_spacing,
        window.controls.cd_border_width,
        window.controls.cd_columns,
        window.controls.cd_rows,
        window.controls.cd_flow,
        window.controls.cd_icon_side,
        window.controls.cd_bar_mode,
        window.controls.cd_bar_expire_towards,
        window.controls.cd_bg_color,
        window.controls.cd_bar_color,
        window.controls.cd_border_color,

        ui.add_hr(),
        ui.add_title(TR("Text")),
        window.controls.cd_text_template,
        window.controls.cd_text_alignment,
        window.controls.cd_text_margin,
        window.controls.cd_name_max_chars,

        ui.add_hr(),
        ui.add_title(TR("Font")),
        window.controls.cd_font_name,
        window.controls.cd_font_size,
        window.controls.cd_font_color,
        window.controls.cd_font_style,
        window.controls.cd_font_outline_color,

        ui.add_hr(),
        ui.add_title(TR("Preview")),
        window.controls.cooldowns_preview,

        ui.add_hr(),
        ui.add_title(TR("Lists")),
        window.controls.cd_whitelist,
        window.controls.cd_blacklist,
    }
end

function Cooldowns.load(window, s, ui)
    local cd = s.self.cooldowns

    window.controls.cd_enabled.cb:SetChecked(cd.enabled == true)
    window.controls.cd_threshold.tb:SetText(tostring(cd.threshold))
    window.controls.cd_item_w.tb:SetText(tostring(cd.item_w))
    window.controls.cd_item_h.tb:SetText(tostring(cd.item_h))
    window.controls.cd_spacing.tb:SetText(tostring(cd.spacing))
    window.controls.cd_border_width.tb:SetText(tostring(cd.border_width))
    window.controls.cd_columns.tb:SetText(tostring(cd.columns))
    window.controls.cd_rows.tb:SetText(tostring(cd.rows))
    window.controls.cd_flow:set_value(cd.flow)
    window.controls.cd_icon_side:set_value(cd.icon_side)
    window.controls.cd_bar_mode:set_value(cd.bar_mode)
    window.controls.cd_bar_expire_towards:set_value(cd.bar_expire_towards)
    window.controls.cd_bg_color.tb:SetText(ui.color_to_hex(cd.color.background))
    window.controls.cd_bar_color.tb:SetText(ui.color_to_hex(cd.color.bar))
    window.controls.cd_border_color.tb:SetText(ui.color_to_hex(cd.color.border))

    window.controls.cd_text_template.tb:SetText(tostring(cd.text_template))
    window.controls.cd_text_alignment:set_value(cd.text_alignment)
    window.controls.cd_text_margin.tb:SetText(tostring(cd.text_margin))
    window.controls.cd_name_max_chars.tb:SetText(tostring(cd.name_max_chars))

    window.controls.cd_font_name:set_value(cd.font.name)
    window.controls.cd_font_size.tb:SetText(tostring(cd.font.size))
    window.controls.cd_font_color.tb:SetText(ui.color_to_hex(cd.font.color))
    window.controls.cd_font_style:set_value(cd.font.style)
    window.controls.cd_font_outline_color.tb:SetText(ui.color_to_hex(cd.font.outline_color))

    window.controls.cd_whitelist.tb:SetText(tostring(cd.whitelist or ""))
    window.controls.cd_blacklist.tb:SetText(tostring(cd.blacklist or ""))
end

function Cooldowns.apply(window, s, ui)
    local cd = s.self.cooldowns

    cd.enabled = window.controls.cd_enabled.cb:IsChecked() == true

    local threshold = tonumber(window.controls.cd_threshold.tb:GetText())
    if threshold ~= nil then
        cd.threshold = threshold
    end

    local item_w = tonumber(window.controls.cd_item_w.tb:GetText())
    if item_w ~= nil then
        cd.item_w = item_w
    end
    local item_h = tonumber(window.controls.cd_item_h.tb:GetText())
    if item_h ~= nil then
        cd.item_h = item_h
    end
    local spacing = tonumber(window.controls.cd_spacing.tb:GetText())
    if spacing ~= nil then
        cd.spacing = spacing
    end
    local border_width = tonumber(window.controls.cd_border_width.tb:GetText())
    if border_width ~= nil then
        cd.border_width = border_width
    end
    local columns = tonumber(window.controls.cd_columns.tb:GetText())
    if columns ~= nil then
        cd.columns = columns
    end
    local rows = tonumber(window.controls.cd_rows.tb:GetText())
    if rows ~= nil then
        cd.rows = rows
    end

    cd.flow = window.controls.cd_flow:get_value()
    cd.icon_side = window.controls.cd_icon_side:get_value()
    cd.bar_mode = window.controls.cd_bar_mode:get_value()
    cd.bar_expire_towards = window.controls.cd_bar_expire_towards:get_value()

    local bg_color = ui.hex_to_color(window.controls.cd_bg_color.tb:GetText())
    if bg_color ~= nil then
        cd.color.background = bg_color
    end
    local bar_color = ui.hex_to_color(window.controls.cd_bar_color.tb:GetText())
    if bar_color ~= nil then
        cd.color.bar = bar_color
    end
    local border_color = ui.hex_to_color(window.controls.cd_border_color.tb:GetText())
    if border_color ~= nil then
        cd.color.border = border_color
    end

    local text_template = window.controls.cd_text_template.tb:GetText()
    if text_template ~= nil then
        cd.text_template = text_template
    end
    cd.text_alignment = window.controls.cd_text_alignment:get_value()
    local text_margin = tonumber(window.controls.cd_text_margin.tb:GetText())
    if text_margin ~= nil then
        cd.text_margin = text_margin
    end
    local name_max_chars = tonumber(window.controls.cd_name_max_chars.tb:GetText())
    if name_max_chars ~= nil then
        cd.name_max_chars = name_max_chars
    end

    cd.font.name = window.controls.cd_font_name:get_value()
    local font_size = tonumber(window.controls.cd_font_size.tb:GetText())
    if font_size ~= nil then
        cd.font.size = font_size
    end
    local font_color = ui.hex_to_color(window.controls.cd_font_color.tb:GetText())
    if font_color ~= nil then
        cd.font.color = font_color
    end
    cd.font.style = window.controls.cd_font_style:get_value()
    local outline_color = ui.hex_to_color(window.controls.cd_font_outline_color.tb:GetText())
    if outline_color ~= nil then
        cd.font.outline_color = outline_color
    end

    cd.whitelist = window.controls.cd_whitelist.tb:GetText() or ""
    cd.blacklist = window.controls.cd_blacklist.tb:GetText() or ""
end
