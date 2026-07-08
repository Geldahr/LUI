#!/usr/bin/env python3
"""Extract the LUI databases (Items + Recipes) straight from the LOTRO
client DAT files into the packed Lua format under src/Data — no
intermediate files. Packing is done by tools/lore2lua/convert.py,
called in-process with the extracted records.

Extracts exactly the fields our databases use. Localized
names come from the client's own locale archives (en/de/fr); enum label
tables (item classes, qualities, crafting categories, professions,
player classes) come from the game's enum mappers.

Usage:
  python3 extract.py <game_dir> [--out <dir>] [--langs de,en,fr] [--db items,recipes]
  (--json <path> optionally dumps the raw records for inspection)
"""
import argparse
import json
import os
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.join(_HERE, os.pardir, "lore2lua"))
from lotrodat import DatFacade, DBPROPERTIES_OFFSET, StringInfo  # noqa: E402
import convert as lore2lua  # noqa: E402

# WState class codes accepted as items
ITEM_TYPES = {2097, 2814, 799, 798, 797, 796, 795, 794, 804, 805, 802,
              3663, 803, 815, 1722, 3924, 4178}

RECIPE_WSTATE_CLASS = 1024
ACCOMPLISHMENT_WSTATE_CLASS = 1398  # quests + deeds
NPC_WSTATE_CLASS = 1724

# equipment-category codes that are armour (incl. shields)
ARMOUR_CODES = {11, 17, 40, 9, 10, 18, 31}

# equipment-category codes that are weapons (stable game constants)
WEAPON_EQUIP_CODES = {3, 4, 5, 6, 8, 12, 13, 14, 15, 16, 20, 22, 24, 26,
                      27, 28, 39, 41, 48}

# Item_Quality codes -> stable keys
QUALITY_KEYS = {1: "LEGENDARY", 2: "RARE", 3: "INCOMPARABLE",
                4: "UNCOMMON", 5: "COMMON"}

# profession DIDs -> stable keys
PROFESSION_KEYS = {
    1879054946: "SCHOLAR", 1879055079: "METALSMITH", 1879055299: "JEWELLER",
    1879055477: "TAILOR", 1879055778: "WEAPONSMITH", 1879055941: "WOODWORKER",
    1879061252: "COOK", 1879062816: "FARMER", 1879062817: "FORESTER",
    1879062818: "PROSPECTOR",
}

ESSENCE_CLASS_CODE = 235  # Item_Class code shared by all socketables
CARRY_ALL_WEENIE_TYPE = 15728769

# socket type codes that are essences (not traceries/runes)
ESSENCE_SOCKET_CODES = {1, 18, 19, 20, 22, 23}

# Inventory_CompatibleSlot bit patterns -> equipment slot
SLOT_BY_ALLOWED = {
    -1073741824: None,
    -536870910: "HEAD", -536870908: "CHEST", -536870904: "LEGS",
    -536870896: "HAND", -536870880: "FEET", -536870848: "SHOULDER",
    -536870784: "BACK", -536870400: "LEFT_WRIST", -536870656: "RIGHT_WRIST",
    -536870144: "WRIST", -536869888: "NECK", -536866816: "LEFT_FINGER",
    -536868864: "RIGHT_FINGER", -536864768: "FINGER", -536854528: "LEFT_EAR",
    -536862720: "RIGHT_EAR", -536846336: "EAR", -536838144: "POCKET",
    -536805376: "MAIN_HAND", -536739840: "OFF_HAND", -536674304: "EITHER_HAND",
    -536608768: "RANGED_ITEM", -536346624: "TOOL", -535822336: "CLASS_SLOT",
    -534773760: "BRIDLE", -507510784: "AURA",
}

# socket type codes that are NOT "new legendary" sockets
CLASSIC_SOCKET_BITS = {1, 131072, 262144, 524288, 2097152, 4194304}


def remove_marks(text):
    """Strip [..] gender/declension marks, trimming after each removal."""
    while True:
        start = text.find("[")
        if start == -1:
            return text
        end = text.find("]", start + 1)
        if end == -1:
            text = text[:start]
        else:
            text = text[:start] + text[end + 1:]
        text = text.strip()


def cleanup_string(text):
    """Unescape newlines and trim."""
    return text.replace("\\n", "\n").strip()


def fix_name(text):
    """Strip a [..] mark only at the very end of the name."""
    index = text.rfind("[")
    if index != -1 and text.find("]", index) == len(text) - 1:
        return text[:index].strip()
    return text


# word-of-mastery socket type code -> required player class
SOCKET_CLASS_KEYS = {
    6: "Beorning", 7: "Brawler", 8: "Burglar", 9: "Captain", 10: "Champion",
    11: "Guardian", 12: "Hunter", 13: "Lore-master", 14: "Minstrel",
    15: "Rune-keeper", 16: "Warden",
}

# synthesized socketable class codes: 235*10000 + kind*100
ENHANCEMENT_RUNE_CLASS = 2350100
HERALDIC_TRACERY_CLASS = 2350200
WORD_OF_POWER_CLASS = 2350300
WORD_OF_MASTERY_CLASS = 2350400
WORD_OF_CRAFT_CLASS = 2350500
BOX_OF_ESSENCES_CLASS = 2350700

# display labels for the synthesized socketable classes (not game enum
# entries; de intentionally falls back to en)
SYNTH_CLASS_LABELS = {
    "en": {2350100: "Enhancement Rune", 2350200: "Heraldric Tracery",
           2350300: "Word of Power", 2350400: "Word of Mastery",
           2350500: "Word of Craft", 2350700: "Box of Essences"},
    "de": {2350100: "Enhancement Rune", 2350200: "Heraldric Tracery",
           2350300: "Word of Power", 2350400: "Word of Mastery",
           2350500: "Word of Craft", 2350700: "Box of Essences"},
    "fr": {2350100: "Rune d'amélioration",
           2350200: "Gravure héraldique",
           2350300: "Gravure de pouvoir", 2350400: "Gravure de maîtrise",
           2350500: "Gravure d'artisanat", 2350700: "Boîte d'essences"},
}


def socketable_class(props, name):
    """Socketable subtype -> (synthesized class code, required class).

    Only called for Item_Class == 235. Returns (None, req) when the item
    class stays 235 (plain essences / unmanaged socket types).
    """
    if name is not None and "Mordor - Essences" in name:
        return BOX_OF_ESSENCES_CLASS, None
    socket_type = props.get("Item_Socket_Type")
    if socket_type is None:
        return None, None
    if socket_type == 0:
        return ENHANCEMENT_RUNE_CLASS, None
    code = lowest_bit_code(socket_type)
    if code in ESSENCE_SOCKET_CODES:
        return None, None
    required_class = SOCKET_CLASS_KEYS.get(code)
    if code == 3:
        return HERALDIC_TRACERY_CLASS, required_class
    if code == 4:
        return WORD_OF_POWER_CLASS, required_class
    if code == 5:
        return WORD_OF_CRAFT_CLASS, required_class
    if 6 <= code <= 16 or code == 21:
        return WORD_OF_MASTERY_CLASS, required_class
    return None, required_class


class Progressions:
    """Progression tables: array lookup or linear interpolation."""

    def __init__(self, facade):
        self.facade = facade
        self.cache = {}

    def get(self, prog_id):
        if prog_id in self.cache:
            return self.cache[prog_id]
        props = self.facade.load_object_properties(prog_id)
        prog = None
        if props is not None:
            linear = props.get("LinearInterpolatingProgression_Array")
            if linear is not None:
                xs = [p["LinearInterpolatingProgression_Key"] for p in linear]
                ys = [p["LinearInterpolatingProgression_Value"] for p in linear]
                prog = ("linear", xs, ys)
            else:
                for array_prop in ("FloatProgression_Array",
                                   "PropertyProgression_Array",
                                   "Combat_BaseDPSArray"):
                    values = props.get(array_prop)
                    if values is not None:
                        min_x = props.get("Progression_MinimumIndexValue")
                        prog = ("array", min_x if min_x is not None else 1,
                                values)
                        break
        self.cache[prog_id] = prog
        return prog

    def value(self, prog_id, x):
        prog = self.get(prog_id)
        if prog is None:
            return None
        if prog[0] == "array":
            _, min_x, ys = prog
            index = x - min_x
            if index < 0:
                return None
            if index >= len(ys):
                index = len(ys) - 1
            v = ys[index]
            return None if v is None else float(v)
        _, xs, ys = prog
        if x < xs[0]:
            return None
        last = len(xs) - 1
        if x >= xs[last]:
            slope = (ys[last] - ys[last - 1]) / (xs[last] - xs[last - 1])
            return ys[last - 1] + (x - xs[last - 1]) * slope
        for i in range(last):
            if xs[i] <= x <= xs[i + 1]:
                return ys[i] + (ys[i + 1] - ys[i]) * (x - xs[i]) / (xs[i + 1] - xs[i])
        return None


def munge_level(props, level, category, progressions):
    """ItemMunging min-level tweak: scaling items report their scaled level."""
    min_munge = props.get("ItemMunging_MinMungeLevel")
    if level is None or min_munge is None or level >= min_munge:
        return level
    if category.startswith("LEGENDARY"):
        return level
    prog_id = props.get("ItemMunging_ItemLevelOverrideProgression")
    level = min_munge
    if prog_id is None:
        return level
    value = progressions.value(prog_id, level)
    return None if value is None else int(value)


def lowest_bit_code(value):
    """1-based index of the lowest set bit; 0 when value is 0."""
    if not value:
        return 0
    return (value & -value).bit_length()


def use_item(item_id, name, item_class):
    """Filter out test/placeholder items."""
    if item_id == 1879465779:
        return True
    if name is None or item_class is None:
        return False
    for bad in ("TBD", "DNT", "GNDN", "Tester", "Barter Test"):
        if bad in name:
            return False
    if "Test of Will" in name:
        return True
    if name.startswith("Test "):
        return False
    return True


def build_icon(props):
    """Compose the icon layer DIDs into the icon key string."""
    image = props.get("Icon_Layer_ImageDID")
    background = props.get("Icon_Layer_BackgroundDID")
    shadow = props.get("Icon_Layer_ShadowDID")
    underlay = props.get("Icon_Layer_UnderlayDID")
    if image is None and background is None and shadow is None and underlay is None:
        return None
    icon = "%s-%s" % (image if image is not None else "0",
                      background if background is not None else "0")
    if (shadow is not None and shadow != 0) or (underlay is not None and underlay != 0):
        icon += "-%s" % (shadow if shadow is not None else "0")
        if shadow != underlay and underlay is not None and underlay != 0:
            icon += "-%s" % underlay
    return icon


def build_category(props, weapon_codes):
    """Derive the item category from equipment/legendary/socket data."""
    eq_cat = props.get("Item_EquipmentCategory")
    eq_code = lowest_bit_code(eq_cat or 0)
    is_legendary = props.get("ItemAdvancement_Item") == 1
    sockets = props.get("Item_Socket_Array")
    is_new_legendary = False
    if sockets:
        for socket in sockets:
            if socket["Item_Socket_Type"] not in CLASSIC_SOCKET_BITS:
                is_new_legendary = True
                break
    if eq_code in weapon_codes:
        if is_legendary:
            return "LEGENDARY_WEAPON"
        if is_new_legendary:
            return "LEGENDARY_WEAPON2"
        return "WEAPON"
    if eq_code in ARMOUR_CODES:
        return "ARMOUR"
    if is_legendary:
        return "LEGENDARY_ITEM"
    if is_new_legendary:
        return "LEGENDARY_ITEM2"
    if props.get("WeenieType") == CARRY_ALL_WEENIE_TYPE:
        return "CARRY_ALL"
    if props.get("Item_Class") == ESSENCE_CLASS_CODE:
        socket_type = props.get("Item_Socket_Type")
        if socket_type:
            if lowest_bit_code(socket_type) in ESSENCE_SOCKET_CODES:
                return "ESSENCE"
    return "ITEM"


def localized(facade, info, lang):
    """Resolve + cleanup + strip marks; None when unresolvable."""
    if info is None:
        return None
    text = facade.resolve_string(info, lang)
    if text is None:
        return None
    return remove_marks(cleanup_string(text))


def localized_name(facade, info, lang):
    """Like localized() but keeps inner marks, stripping only a trailing
    one (recipe names keep inline gender variants)."""
    if info is None:
        return None
    text = facade.resolve_string(info, lang)
    if text is None:
        return None
    return fix_name(cleanup_string(text))


def enum_labels(facade, property_name, langs):
    """{lang: {code: label}} for the enum behind a property, with
    gender/declension marks stripped."""
    enum_did = facade.property_def(property_name).data
    return {lang: {code: remove_marks(cleanup_string(label))
                   for code, label in facade.enum_names(enum_did, lang).items()}
            for lang in langs}


class Scan:
    """Everything collected in the single pass over client_gamelogic."""

    def __init__(self):
        self.items = {}          # id -> record dict
        self.traceries = {}      # item id -> (type, minIL, maxIL, channel)
        self.consumable_ids = set()
        self.recipe_dids = []
        self.recipe_scrolls = {}  # recipe id -> scroll item id
        self.quest_dids = []      # quests + deeds
        self.npc_dids = []


def scan(facade, langs):
    langs = [l for l in langs if l in facade.locales]
    decoder_langs = [l for l in langs if l != "en"]
    # class enum EN labels are the requiredClass keys ("Beorning", ...);
    # AdvTable_Class carries the agent/player class enum
    class_names = enum_labels(facade, "AdvTable_Class", ["en"])["en"]

    out = Scan()
    items = out.items
    archive = facade.archives["gamelogic"]
    progressions = Progressions(facade)
    t0 = time.time()
    scanned = 0
    for entry in archive.iter_entries():
        did = entry.file_id
        if not 0x70000000 <= did <= 0x77FFFFFF:
            continue
        data = archive.load_entry(entry)
        wstate_class = int.from_bytes(data[4:8], "little")
        if wstate_class == RECIPE_WSTATE_CLASS:
            out.recipe_dids.append(did)
        elif wstate_class == ACCOMPLISHMENT_WSTATE_CLASS:
            out.quest_dids.append(did)
        elif wstate_class == NPC_WSTATE_CLASS:
            out.npc_dids.append(did)
        if wstate_class not in ITEM_TYPES:
            continue
        scanned += 1
        props = facade.load_object_properties(did)
        if props is None:
            continue
        recipe_id = props.get("RecipeItem_Recipe")
        if recipe_id is not None:
            out.recipe_scrolls[recipe_id] = did
        name_info = props.get("Name")
        name = localized(facade, name_info, "en")
        if not use_item(did, name, props.get("Item_Class")):
            continue

        if props.get("EffectGenerator_UsageEffectList") is not None:
            out.consumable_ids.add(did)

        category = build_category(props, WEAPON_EQUIP_CODES)
        level = munge_level(props, props.get("Item_Level"), category,
                            progressions)

        item_class = props.get("Item_Class")
        tracery_class = None
        if item_class == ESSENCE_CLASS_CODE:
            new_class, tracery_class = socketable_class(props, name)
            if new_class is not None:
                item_class = new_class
            socket_type = props.get("Item_Socket_Type")
            if socket_type:  # non-rune socketable
                code = lowest_bit_code(socket_type)
                if code not in ESSENCE_SOCKET_CODES:
                    # tracery side data (LI item-level band, channel)
                    channel = props.get("Item_UniquenessChannel")
                    out.traceries[did] = (
                        code,
                        props.get("Item_Socket_GemMinLevel") or 0,
                        props.get("Item_Socket_GemMaxLevel") or 0,
                        channel if channel is not None else 0,
                    )

        quality_code = props.get("Item_Quality")
        slot = None
        compatible_slot = props.get("Inventory_CompatibleSlot")
        if compatible_slot is not None:
            if compatible_slot >= 2**31:  # BIT_FIELD32 decodes unsigned; Java is signed
                compatible_slot -= 2**32
            slot = SLOT_BY_ALLOWED.get(compatible_slot)

        required_class = None
        class_list = props.get("Usage_RequiredClassList")
        if class_list:
            keys = [class_names.get(code, str(code)) for code in class_list]
            required_class = ";".join(keys)
        if tracery_class is not None:
            required_class = tracery_class

        required_profession = None
        prof = props.get("Usage_RequiredCraftProfession")
        if prof is not None:
            proficiency = props.get("Usage_RequiredCraftProficiency")
            if proficiency is None:
                proficiency = props.get("Usage_RequiredCraftTier")
            required_profession = ("%d;%d" % (prof, proficiency)
                                   if proficiency is not None else str(prof))

        record = {
            "name": name,
            "quality": QUALITY_KEYS.get(quality_code) if quality_code is not None else None,
            "level": level,
            "class": item_class,
            "category": category,
            "slot": slot,
            "icon": build_icon(props),
            "minLevel": props.get("Usage_MinLevel"),
            "maxLevel": props.get("Usage_MaxLevel"),
            "requiredClass": required_class,
            "requiredProfession": required_profession,
        }
        for lang in decoder_langs:
            record["name_" + lang] = localized(facade, name_info, lang)
        items[did] = record
        if len(items) % 20000 == 0:
            print("... %d items (%.0fs)" % (len(items), time.time() - t0),
                  flush=True)

    # crop-field items get their icons from the farming recipes
    def field_icon(item_id, icon_id):
        if icon_id is not None and icon_id > 0:
            record = items.get(item_id)
            if record is not None and record["icon"] is None:
                record["icon"] = str(icon_id)

    for did in out.recipe_dids:
        props = facade.load_object_properties(did)
        if props is None:
            continue
        result_icon = props.get("CraftRecipe_Field_ResultIcon")
        crit_icon = props.get("CraftRecipe_Field_CritResultIcon")
        result = props.get("CraftRecipe_ResultItem")
        if result is not None:
            field_icon(result, result_icon)
        crit = props.get("CraftRecipe_CriticalResultItem")
        if crit is not None and crit > 0:
            field_icon(crit, crit_icon)
        for output in props.get("CraftRecipe_MultiOutputArray") or ():
            result = output.get("CraftRecipe_ResultItem")
            if result is not None and result > 0:
                field_icon(result, result_icon)
            crit = output.get("CraftRecipe_CriticalResultItem")
            if crit is not None and crit > 0:
                field_icon(crit, crit_icon)

    print("scanned %d item-type entries -> %d items, %d recipes (%.0fs)" % (
        scanned, len(items), len(out.recipe_dids), time.time() - t0))
    return out


# -------------------------------------------------------------- recipes ----

def _percent(value):
    """Java's (int)(floatValue * 100): the multiply happens in 32-bit
    float arithmetic, so 0.45f*100f is exactly 45.0f (not 44.999...)."""
    import struct as _struct
    (f32,) = _struct.unpack("<f", _struct.pack("<f", value * 100.0))
    return int(f32)


def extract_recipes(facade, langs, scan_result):
    """Decode all crafting recipes into packer-ready records."""
    langs = [l for l in langs if l in facade.locales]
    decoder_langs = [l for l in langs if l != "en"]

    # XP values (CraftControl weenie at 0x7000021E)
    xp_map = {}
    control = facade.load_properties(0x7900021E)
    for entry in control["CraftControl_XPRewardArray"]:
        xp_map[entry["CraftControl_XPRewardEnum"]] = \
            entry["CraftControl_XPRewardValue"]
    # cooldown durations (CooldownControl weenie)
    cooldown_map = {}
    cooldowns = facade.weenie_props("CooldownControl")
    for entry in cooldowns["CooldownControl_DurationMapList"]:
        cooldown_map[entry["CooldownControl_DurationType"]] = \
            entry["CooldownControl_DurationValue"]

    def ingredient_list(props, prop_name, optional):
        out = []
        for entry in props.get(prop_name) or ():
            iid = entry["CraftRecipe_Ingredient"]
            qty = entry.get("CraftRecipe_IngredientQuantity")
            qty = 1 if qty is None else qty
            if optional:
                bonus = entry.get("CraftRecipe_IngredientCritBonus")
                bonus = _percent(bonus) if bonus is not None else 0
                out.append((iid, qty, bonus))
            else:
                out.append((iid, qty))
        return out

    def build_version(props):
        """Base recipe version: results + crit chance."""
        v = {"crit": 0, "ing": [], "opt": [], "res": [], "cres": []}
        result = props.get("CraftRecipe_ResultItem")
        if result is not None:
            qty = props.get("CraftRecipe_ResultItemQuantity")
            v["res"].append((result, 1 if qty is None else qty))
        crit_result = props.get("CraftRecipe_CriticalResultItem")
        if crit_result is not None and crit_result > 0:
            qty = props.get("CraftRecipe_CriticalResultItemQuantity")
            v["cres"].append((crit_result, 1 if qty is None else qty))
            chance = props.get("CraftRecipe_CriticalSuccessChance")
            if chance is not None:
                v["crit"] = _percent(chance)
        return v

    recipes = {}
    t0 = time.time()
    for did in scan_result.recipe_dids:
        props = facade.load_object_properties(did)
        if props is None:
            continue
        name_info = props.get("CraftRecipe_Name")
        name = localized_name(facade, name_info, "en")

        first = build_version(props)
        first["ing"] = ingredient_list(props, "CraftRecipe_IngredientList",
                                       False)
        first["opt"] = ingredient_list(
            props, "CraftRecipe_OptionalIngredientList", True)
        versions = [first]
        for output in props.get("CraftRecipe_MultiOutputArray") or ():
            # multi-output: clone base version, patch results + 1st ingredient
            version = {"crit": first["crit"],
                       "ing": list(first["ing"]), "opt": list(first["opt"]),
                       "res": list(first["res"]), "cres": list(first["cres"])}
            result = output.get("CraftRecipe_ResultItem")
            if result is not None and result > 0:
                v_res = version["res"]
                version["res"] = [(result, v_res[0][1] if v_res else 1)]
            crit_result = output.get("CraftRecipe_CriticalResultItem")
            if crit_result is not None and crit_result > 0:
                v_cres = version["cres"]
                version["cres"] = [(crit_result,
                                    v_cres[0][1] if v_cres else 1)]
            ingredient = output.get("CraftRecipe_Ingredient")
            if ingredient is not None and version["ing"]:
                version["ing"][0] = (ingredient, version["ing"][0][1])
            versions.append(version)

        tier = props.get("CraftRecipe_Tier")
        if tier is None:
            tier = props["CraftRecipe_TierArray"][0]
        xp_id = props.get("CraftRecipe_XPReward")
        cooldown_id = props.get("CraftRecipe_CooldownDuration")
        guild = props.get("CraftRecipe_RequiredCraftGuild")
        pack = props.get("CraftRecipe_IngredientPack")
        pack_count = props.get("CraftRecipe_IngredientPackQuantity")

        record = {
            "name": name,
            "profession": PROFESSION_KEYS[props["CraftRecipe_Profession"]],
            "tier": tier,
            "category": props.get("CraftRecipe_UICategory") or 0,
            "xp": xp_map.get(xp_id, 0) if xp_id is not None else 0,
            "cooldown": (int(cooldown_map[cooldown_id])
                         if cooldown_id is not None
                         and cooldown_id in cooldown_map else 0),
            "guild": bool(guild),
            "single_use": props.get("CraftRecipe_OneTimeRecipe") == 1,
            "scroll": scan_result.recipe_scrolls.get(did, 0),
            "pack": pack or 0,
            "pack_count": (1 if pack_count is None else pack_count) if pack else 0,
            "versions": versions,
        }

        # localized name chain: recipe label -> result item label -> en
        def result_item():
            for v in versions:
                if v["res"]:
                    return v["res"][0][0]
                if v["cres"]:
                    return v["cres"][0][0]
            return 0

        result_id = result_item()
        item_name_info = None
        if result_id:
            item_props = facade.load_object_properties(result_id)
            if item_props is not None:
                item_name_info = item_props.get("Name")
        if name is None:  # nameless recipes use the root result item's name
            root_result = props.get("CraftRecipe_ResultItem")
            if root_result:
                root_props = facade.load_object_properties(root_result)
                if root_props is not None:
                    record["name"] = localized(facade,
                                               root_props.get("Name"), "en")
        for lang in decoder_langs:
            value = localized_name(facade, name_info, lang)
            if value is None:
                value = localized(facade, item_name_info, lang)
            record["name_" + lang] = value
        recipes[did] = record
    print("decoded %d recipes (%.0fs)" % (len(recipes), time.time() - t0))
    return recipes


# ------------------------------------------------------ quests + deeds ----

# quest boolean flags -> bit positions in the packed flags field
QUEST_FLAGS = (
    ("Quest_IsInstanceQuest", 1),
    ("Quest_IsShareable", 2),
    ("Quest_IsFellowshipRecommended", 4),
    ("Quest_IsSmallFellowshipRecommended", 8),
    ("Quest_IsMonsterPlayQuest", 16),
    ("Quest_IsSessionQuest", 32),
    ("Quest_ShowRaidInJournal", 64),
)


def extract_quests(facade, langs, scan_result):
    """Decode all quests and deeds (accomplishment entries) into records,
    including description, objectives, bestower dialogs, rewards, chains
    and flags."""
    langs = [l for l in langs if l in facade.locales]
    decoder_langs = [l for l in langs if l != "en"]

    quests = {}
    t0 = time.time()
    for did in scan_result.quest_dids:
        props = facade.load_object_properties(did)
        if props is None:
            continue
        name_info = props.get("Quest_Name")
        name = localized(facade, name_info, "en")
        if name is None or not use_item(did, name, 0):  # same test filters
            continue
        is_deed = props.get("Quest_IsAccomplishment") == 1

        flags = 0
        for prop, bit in QUEST_FLAGS:
            if props.get(prop) == 1:
                flags |= bit
        max_times = props.get("Quest_MaxTimesCompletable")

        prereqs = []
        for entry in props.get("Quest_QuestsToComplete") or ():
            if isinstance(entry, int):
                prereqs.append(entry)

        rewards = []
        virtue_xp = 0
        treasure = props.get("Quest_QuestTreasureDID")
        if treasure:
            tprops = facade.load_object_properties(treasure)
            if tprops is not None:
                for entry in tprops.get("QuestTreasure_FixedItemArray") or ():
                    item = entry.get("QuestTreasure_Item")
                    if item:
                        qty = entry.get("QuestTreasure_ItemQuantity")
                        rewards.append((item, 1 if qty is None else qty))
                virtue_xp = tprops.get("QuestTreasure_Virtue_XP_Tier") or 0

        objectives = props.get("Quest_ObjectiveArray") or ()
        objectives = sorted(objectives,
                            key=lambda o: o.get("Quest_ObjectiveIndex") or 0)
        # completion conditions per objective; entries may be nested
        # OR-groups (lists), flatten them
        conditions = []
        for o in objectives:
            flat = []
            for c in o.get("Quest_CompletionConditionArray") or ():
                if isinstance(c, list):
                    flat.extend(x for x in c if isinstance(x, dict))
                elif isinstance(c, dict):
                    flat.append(c)
            conditions.append(flat)
        objective_conds = [[(max(c.get("QuestEvent_ID") or 0, 0),
                             max(c.get("QuestEvent_Number") or 0, 0))
                            for c in flat] for flat in conditions]
        roles = props.get("Quest_RoleArray") or ()
        # action 6 @ objective 0 = bestower (quest giver); action 5 =
        # end/turn-in dialog; others belong to their objective
        dialogs = [(r.get("Quest_ObjectiveIndex") or 0,
                    r.get("QuestDispenser_Action") or 0,
                    r.get("QuestDispenser_NPC") or 0)
                   for r in roles]

        record = {
            "kind": "deed" if is_deed else "quest",
            "name": name,
            "level": props.get("Quest_ChallengeLevel") or 0,
            "minLevel": props.get("Accomplishment_MinLevelToStart") or 0,
            "category": (props.get("Accomplishment_Category") if is_deed
                         else props.get("Quest_Category")) or 0,
            "expTier": props.get("Quest_ExpTier") or 0,
            "goldTier": props.get("Quest_GoldTier") or 0,
            "flags": flags,
            # 0 = not repeatable, 1 = unlimited, n+1 = n times
            "maxTimes": (0 if max_times is None
                         else 1 if max_times < 0 else max_times + 1),
            "lockType": props.get("Quest_LockType") or 0,
            "nextQuest": props.get("Quest_NextQuest") or 0,
            "prereqs": prereqs,
            "rewards": rewards,
            "virtueXpTier": virtue_xp,
            "dialogNpcs": dialogs,
            "objectiveConds": objective_conds,
        }
        for lang in langs:
            desc = localized(facade, props.get("Quest_Description"), lang)
            objective_texts = []
            for o, flat in zip(objectives, conditions):
                entry = [localized(facade,
                                   o.get("Quest_ObjectiveDescription"),
                                   lang) or ""]
                for c in flat:
                    # "how to complete": progress text, else deed lore
                    text = localized(facade,
                                     c.get("QuestEvent_ProgressOverride"),
                                     lang)
                    if text is None:
                        text = localized(facade,
                                         c.get("Accomplishment_LoreInfo"),
                                         lang)
                    entry.append(text or "")
                objective_texts.append(entry)
            dialog_texts = [
                localized(facade, r.get("QuestDispenser_RoleSuccessText"),
                          lang) or ""
                for r in roles]
            record["text_" + lang] = (desc or "", objective_texts,
                                      dialog_texts)
            if lang != "en":
                record["name_" + lang] = localized(facade, name_info, lang)
        quests[did] = record
        if len(quests) % 5000 == 0:
            print("... %d quests/deeds (%.0fs)" % (len(quests),
                                                   time.time() - t0),
                  flush=True)
    counts = {"quest": 0, "deed": 0}
    for r in quests.values():
        counts[r["kind"]] += 1
    print("decoded %d quests + %d deeds (%.0fs)" % (
        counts["quest"], counts["deed"], time.time() - t0))
    return quests


# --------------------------------------------------------------- npcs ----

def quest_npc_ids(quests):
    """NPC ids referenced by quest/deed dialogs."""
    referenced = set()
    for r in quests.values():
        for _obj_idx, _action, npc in r["dialogNpcs"]:
            if npc:
                referenced.add(npc)
    return referenced


def extract_npcs(facade, langs, scan_result, referenced):
    """id -> localized name + occupation title, only for NPCs that are
    referenced by quest/deed dialogs."""
    langs = [l for l in langs if l in facade.locales]
    npcs = {}
    t0 = time.time()
    for did in scan_result.npc_dids:
        if did not in referenced:
            continue
        props = facade.load_object_properties(did)
        if props is None:
            continue
        name_info = props.get("Name")
        name = localized(facade, name_info, "en")
        if name is None or not use_item(did, name, 0):
            continue
        title_info = props.get("OccupationTitle")
        record = {}
        for lang in langs:
            record["name_" + lang] = localized(facade, name_info, lang) or ""
            record["title_" + lang] = localized(facade, title_info, lang) or ""
        record["name"] = record.pop("name_en")
        record["title"] = record.pop("title_en")
        npcs[did] = record
    print("decoded %d quest-linked NPCs (of %d referenced, %.0fs)" % (
        len(npcs), len(referenced), time.time() - t0))
    return npcs


# ------------------------------------------------------------------ main ----

_REPO_ROOT = os.path.abspath(os.path.join(_HERE, os.pardir, os.pardir))


def normalize_game_dir(path):
    """Accept Windows paths (G:\\...) when running under WSL."""
    import re
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", path)
    if m and not os.path.isdir(path):
        return "/mnt/%s/%s" % (m.group(1).lower(),
                               m.group(2).replace("\\", "/"))
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("game_dir",
                    help="LOTRO install dir (Windows or WSL path)")
    ap.add_argument("--out",
                    default=os.path.join(_REPO_ROOT, "src", "Data"),
                    help="Lua output dir (Items/ + Recipes/ inside)")
    ap.add_argument("--langs", default="de,en,fr",
                    help="languages to emit (client locales)")
    ap.add_argument("--db", default="items,recipes,quests,npcs")
    ap.add_argument("--json", help="also dump raw records for inspection")
    args = ap.parse_args()
    game_dir = normalize_game_dir(args.game_dir)
    langs = args.langs.split(",")
    dbs = args.db.split(",")

    facade = DatFacade(game_dir)
    missing = [l for l in langs if l not in facade.locales]
    if missing:
        raise SystemExit("client is missing locale(s): %s" % ",".join(missing))

    if "npcs" in dbs and "quests" not in dbs:
        raise SystemExit("--db npcs requires quests (NPCs are filtered to"
                         " the ones quest dialogs reference)")
    scan_result = scan(facade, langs)
    recipes = extract_recipes(facade, langs, scan_result)
    quests = (extract_quests(facade, langs, scan_result)
              if "quests" in dbs else {})
    npcs = (extract_npcs(facade, langs, scan_result, quest_npc_ids(quests))
            if "npcs" in dbs else {})

    class_labels = enum_labels(facade, "Item_Class", langs)
    for lang in langs:
        class_labels[lang].update(
            SYNTH_CLASS_LABELS.get(lang, SYNTH_CLASS_LABELS["en"]))

    aux = {
        "traceries": scan_result.traceries,
        "consumable_ids": scan_result.consumable_ids,
        "recipes": recipes,
        "class_labels": class_labels,
        "quality_labels": {
            lang: {QUALITY_KEYS[code]: label
                   for code, label in
                   enum_labels(facade, "Item_Quality", [lang])[lang].items()
                   if code in QUALITY_KEYS}
            for lang in langs},
        "player_class_labels": enum_labels(facade, "AdvTable_Class", langs),
        "category_labels": enum_labels(facade, "CraftRecipe_UICategory", langs),
        "profession_labels": {
            lang: {key: localized(
                       facade,
                       facade.load_object_properties(did)["CraftProfession_Name"],
                       lang)
                   for did, key in PROFESSION_KEYS.items()}
            for lang in langs},
        "quest_category_labels": enum_labels(facade, "Quest_Category", langs),
        "deed_category_labels": enum_labels(facade, "Accomplishment_Category",
                                            langs),
    }

    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({"items": scan_result.items, "recipes": recipes,
                       "quests": quests},
                      f, ensure_ascii=False, default=list)
        print("dumped records to %s" % args.json)

    if "items" in dbs:
        lore2lua.convert_items(None, os.path.join(args.out, "Items"), langs,
                               records=scan_result.items, aux=aux)
    if "recipes" in dbs:
        lore2lua.convert_recipes(None, os.path.join(args.out, "Recipes"),
                                 langs, records=recipes, aux=aux)
    if "quests" in dbs:
        lore2lua.convert_quests(os.path.join(args.out, "Quests"), langs,
                                quests, aux)
    if "npcs" in dbs:
        lore2lua.convert_npcs(os.path.join(args.out, "Npcs"), langs, npcs)
    facade.close()


if __name__ == "__main__":
    main()
