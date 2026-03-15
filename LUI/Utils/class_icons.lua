import "Turbine.Gameplay"

_G.CLASS_ICON_NAMES = {
    [Turbine.Gameplay.Class.Beorning]     = "Geldahr/LUI/PluginAssets/scaled/beorning",
    [Turbine.Gameplay.Class.Brawler]      = "Geldahr/LUI/PluginAssets/scaled/brawler",
    [Turbine.Gameplay.Class.Burglar]      = "Geldahr/LUI/PluginAssets/scaled/burglar",
    [Turbine.Gameplay.Class.Captain]      = "Geldahr/LUI/PluginAssets/scaled/captain",
    [Turbine.Gameplay.Class.Champion]     = "Geldahr/LUI/PluginAssets/scaled/champion",
    [Turbine.Gameplay.Class.Guardian]     = "Geldahr/LUI/PluginAssets/scaled/guardian",
    [Turbine.Gameplay.Class.Hunter]       = "Geldahr/LUI/PluginAssets/scaled/hunter",
    [Turbine.Gameplay.Class.LoreMaster]   = "Geldahr/LUI/PluginAssets/scaled/lore-master",
    [Turbine.Gameplay.Class.Mariner]      = "Geldahr/LUI/PluginAssets/scaled/mariner",
    [Turbine.Gameplay.Class.Minstrel]     = "Geldahr/LUI/PluginAssets/scaled/minstrel",
    [Turbine.Gameplay.Class.RuneKeeper]   = "Geldahr/LUI/PluginAssets/scaled/rune-keeper",
    [Turbine.Gameplay.Class.Warden]       = "Geldahr/LUI/PluginAssets/scaled/warden",
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
    local name = _G.CLASS_ICON_NAMES[class]
    if name == nil then
        return nil
    end

    return name .. "_" .. size .. ".tga"
end
