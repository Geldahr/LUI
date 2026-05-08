GroupLayout = GroupLayout or {}

local function _normalize_rows(rows)
    if rows == nil or rows < 1 then
        return 1
    end

    return rows
end

function GroupLayout.member_height(vitals_settings)
    local border_width = vitals_settings.frame.border_width
    local member_height = vitals_settings.morale.height + vitals_settings.power.height - border_width
    if vitals_settings.info.enabled == true then
        member_height = member_height + vitals_settings.info.height - border_width
    end
    if member_height < 1 then
        member_height = 1
    end

    return member_height
end

function GroupLayout.compute_size(member_count, rows, spacing_x, spacing_y, member_width, member_height)
    local normalized_rows = _normalize_rows(rows)
    local normalized_count = member_count
    if normalized_count < 0 then
        normalized_count = 0
    end

    local columns = 1
    if normalized_count > 0 then
        columns = math.ceil(normalized_count / normalized_rows)
        if columns < 1 then
            columns = 1
        end
    end

    local used_rows = normalized_count
    if used_rows > normalized_rows then
        used_rows = normalized_rows
    end
    if used_rows < 1 then
        used_rows = 1
    end

    local total_width = (columns * member_width) + ((columns - 1) * spacing_x)
    local total_height = (used_rows * member_height) + ((used_rows - 1) * spacing_y)
    if total_width < member_width then
        total_width = member_width
    end
    if total_height < member_height then
        total_height = member_height
    end

    return total_width, total_height
end

function GroupLayout.apply_positions(member_windows, member_count, rows, spacing_x, spacing_y, member_width, member_height)
    local normalized_rows = _normalize_rows(rows)

    for i = 1, #member_windows do
        local member_window = member_windows[i]
        if i <= member_count then
            local index = i - 1
            local column = math.floor(index / normalized_rows)
            local row = index - (column * normalized_rows)
            local x = column * (member_width + spacing_x)
            local y = row * (member_height + spacing_y)
            member_window:SetPosition(x, y)
        else
            member_window:SetPosition(0, 0)
        end
    end
end
