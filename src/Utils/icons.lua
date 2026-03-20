import "Turbine.Gameplay"
import "Turbine.UI"

local LEADER_ICON = Turbine.UI.Graphic(0x4113F18F) -- 64x64
local BEORNING_ICON = Turbine.UI.Graphic(0x41153709) -- 50x50
local BRAWLER_ICON = "LUI/src/PluginAssets/brawler.tga"
local BURGLAR_ICON = Turbine.UI.Graphic(0x410000E4) -- 50x50
local CAPTAIN_ICON = Turbine.UI.Graphic(0x410000E5) -- 50x50
local CHAMPION_ICON = Turbine.UI.Graphic(0x410000E6) -- 50x50
local GUARDIAN_ICON = Turbine.UI.Graphic(0x410000E7) -- 50x50
local HUNTER_ICON = Turbine.UI.Graphic(0x410000E8) -- 50x50
local LORE_MASTER_ICON = Turbine.UI.Graphic(0x410000E9) -- 50x50
local MARINER_ICON = "LUI/src/PluginAssets/mariner.tga"
local MINSTREL_ICON = Turbine.UI.Graphic(0x410000EA) -- 50x50
local RUNE_KEEPER_ICON = Turbine.UI.Graphic(0x410E81CB) -- 48x48
local WARDEN_ICON = Turbine.UI.Graphic(0x410E0DCA) -- 48x48

_G.PARTY_LEADER_ICON = LEADER_ICON

_G.CLASS_ICON_NAMES = {
    [Turbine.Gameplay.Class.Beorning]     = BEORNING_ICON,
    [Turbine.Gameplay.Class.Brawler]      = BRAWLER_ICON,
    [Turbine.Gameplay.Class.Burglar]      = BURGLAR_ICON,
    [Turbine.Gameplay.Class.Captain]      = CAPTAIN_ICON,
    [Turbine.Gameplay.Class.Champion]     = CHAMPION_ICON,
    [Turbine.Gameplay.Class.Guardian]     = GUARDIAN_ICON,
    [Turbine.Gameplay.Class.Hunter]       = HUNTER_ICON,
    [Turbine.Gameplay.Class.LoreMaster]   = LORE_MASTER_ICON,
    [Turbine.Gameplay.Class.Mariner]      = MARINER_ICON,
    [Turbine.Gameplay.Class.Minstrel]     = MINSTREL_ICON,
    [Turbine.Gameplay.Class.RuneKeeper]   = RUNE_KEEPER_ICON,
    [Turbine.Gameplay.Class.Warden]       = WARDEN_ICON,
}

_G.CLASS_ICON_CLASSES = {
    Turbine.Gameplay.Class.Hunter,
    Turbine.Gameplay.Class.Warden,
    Turbine.Gameplay.Class.Burglar,
    Turbine.Gameplay.Class.Captain,
    Turbine.Gameplay.Class.Champion,
    Turbine.Gameplay.Class.Guardian,
    Turbine.Gameplay.Class.Minstrel,
    Turbine.Gameplay.Class.Beorning,
    Turbine.Gameplay.Class.LoreMaster,
    Turbine.Gameplay.Class.RuneKeeper,
    Turbine.Gameplay.Class.Brawler,
    Turbine.Gameplay.Class.Mariner,
}

_G.get_class_icon = function(class, size)
    local icon = _G.CLASS_ICON_NAMES[class]
    if icon == nil then
        return nil
    end

    return icon
end

_G.get_party_leader_icon = function()
    return _G.PARTY_LEADER_ICON
end
