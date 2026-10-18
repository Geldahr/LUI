-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.UI.sized_icon"

local UI = _G.LUI.UI
local AssetIds = UI.Assets

UI.AssetIds = AssetIds

AssetIds.gold_coin = 0x41007e7b
AssetIds.silver_coin = 0x41007e7c
AssetIds.copper_coin = 0x41007e7d
AssetIds.durability = 0x41003061


AssetIds.feather = 0x41004D92

AssetIds.party_leader_banner = 0x4113F18F

AssetIds.backpack = 0x41008113
AssetIds.backpack_alt = 0x411AD881

AssetIds.anvil_silver = "LUI/assets/ui/anvil-silver.tga"
AssetIds.anvil_silver_glow = "LUI/assets/ui/anvil-silver-glow.tga"
AssetIds.anvil_gold = "LUI/assets/ui/anvil-gold.tga"
-- Anvil LotRO alternatives: 0x410F2EA5 original, 0x410F2EA2, 0x410F2EAE bright contour.
AssetIds.anvil_lotro_original = 0x410F2EA5
AssetIds.anvil_lotro_alt = 0x410F2EA2
AssetIds.anvil_lotro_bright_contour = 0x410F2EAE

AssetIds.chest = 0x41003830
AssetIds.chest_alt_1 = 0x4111BE35
AssetIds.chest_dark = 0x4111BE44
AssetIds.chest_alt_2 = 0x4111BE3E
AssetIds.chest_alt_3 = 0x411BA042

AssetIds.compass = "LUI/assets/ui/compass_64.tga"

AssetIds.book_shortcut = 0x410031FB
AssetIds.book_open = 0x410E0435
AssetIds.parchment = 0x410E9288
AssetIds.book_no_background = 0x41003199
AssetIds.book_background = 0x41002DC3
AssetIds.book_pressed_25 = 0x41005F00
AssetIds.book_normal_25 = 0x41005F07
AssetIds.book_hover_25 = 0x41005F0F
AssetIds.book = 0x4112E6D1
AssetIds.book_red = 0x41133491
AssetIds.book_cyan = 0x41133492
AssetIds.book_green = 0x41133493
AssetIds.book_purple = 0x41133494
AssetIds.book_yellow = 0x41133496
AssetIds.book_light_gray = 0x4113349A
AssetIds.book_orange = 0x4113349C
AssetIds.book_dark_gray = 0x4113349F
AssetIds.book_old = 0x41138432
AssetIds.book_magic = 0x41139D6B
AssetIds.book_orange_cover = 0x4113B263
AssetIds.book_blue_cover = 0x4113BC91

AssetIds.plus_25 = 0x41116576
AssetIds.minus_25 = 0x41116579
-- There are other +/- colors available as 25x25 icons.

-- LUI's white, tintable icons (tools/icons/build_icons.py), drawn tinted with
-- the ICON_* style colors through Widgets.Icons.path(name). Lucide icons come
-- in both line weights (Style.ICON_WEIGHT); sized ones are pre-scaled
-- (UI.sized_icon) and drawn unstretched, so they clip inside scrolling lists.
local ICON_DIR = "LUI/assets/ui/icons/"
local sized = UI.sized_icon

local function lucide(name)
    return { thin = ICON_DIR .. name .. "_thin_64.tga", bold = ICON_DIR .. name .. "_bold_64.tga" }
end

local function lucide_sized(name)
    return { thin = sized(ICON_DIR .. name .. "_thin_"), bold = sized(ICON_DIR .. name .. "_bold_") }
end

AssetIds.icons = {
    -- LUI's own shapes (single weight)
    window_close = sized(ICON_DIR .. "window_close_"),
    window_maximize = ICON_DIR .. "window_maximize_64.tga",
    window_restore = ICON_DIR .. "window_restore_64.tga",

    chevron_down = lucide("chevron_down"),
    chevron_up = lucide("chevron_up"),
    chevron_left = lucide("chevron_left"),
    chevron_right = lucide("chevron_right"),
    dropdown_arrow = lucide_sized("dropdown_arrow"),
    submenu_arrow = lucide("submenu_arrow"),
    chevron_up_small = lucide_sized("chevron_up_small"),
    chevron_down_small = lucide_sized("chevron_down_small"),
    chevron_left_small = lucide("chevron_left_small"),
    chevron_right_small = lucide("chevron_right_small"),
    plus = lucide("plus"),
    minus = lucide("minus"),
    check = lucide_sized("check"),
    search = lucide("search"),
    resize_horizontal = lucide("resize_horizontal"),
    resize_vertical = lucide("resize_vertical"),
    resize_tl_br = lucide("resize_tl_br"),
    resize_tr_bl = lucide("resize_tr_bl"),
    -- stretched: tinted on light (selected) rows, where a pre-scaled icon's
    -- tint shows a square; the recipe table is paged by default
    star = lucide("star"),
    star_filled = lucide("star_filled"),
    map_pinned = lucide_sized("map_pinned"),
    x = lucide("x"),
    level = lucide_sized("level"),

    -- search keyword chips
    tag = lucide_sized("tag"),
    gem = lucide_sized("gem"),
    shield = lucide_sized("shield"),
    gauge = lucide_sized("gauge"),
    scroll_text = lucide_sized("scroll_text"),
    hammer = lucide_sized("hammer"),
    award = lucide_sized("award"),
    package_check = lucide_sized("package_check"),
    boxes = lucide_sized("boxes"),
    user = lucide_sized("user"),
    archive = lucide_sized("archive"),

    -- menu icons (status bar, LUI Menu, window titles)
    settings = lucide("settings"),
    backpack = lucide("backpack"),
    anvil = lucide("anvil"),
    compass = lucide("compass"),
    briefcase = lucide("briefcase"),
    book_open_text = lucide_sized("book_open_text"),
    users = lucide("users"),
    refresh_cw = lucide("refresh_cw"),
    family = lucide_sized("family"),

    -- money (Modern coin icons)
    coins = lucide("coins"),
}
