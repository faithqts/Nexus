local ADDON = ...

if not LibStub then
    return
end

local LSM = LibStub("LibSharedMedia-3.0", true)
if not LSM then
    return
end

local function FontPath(file)
    return ("Interface\\AddOns\\%s\\media\\fonts\\%s"):format(ADDON, file)
end

local function TexturePath(file)
    return ("Interface\\AddOns\\%s\\media\\textures\\%s"):format(ADDON, file)
end

local FONTS = {
    { "ASAP",                     "asap.ttf" },
    { "ASAP (Bold)",              "asap_bold.ttf" },
    { "Avant Garde",              "avantgardestd_bkobl.otf" },
    { "Avant Garde (Bold)",       "avantgardestd_boldobl.otf" },
    { "Avant Garde (Medium)",     "avantgardestd_mdobl.otf" },
    { "Avant Garde (Thin)",       "avantgardestd_xltcn.otf" },
    { "Futura Condensed Plain",   "futura_condensed_plain.ttf" },
    { "Futura Condensed Regular", "futura_condensed_regular.ttf" },
    { "Futura CondExtraBold Oblique", "futura_condextraeold_oblique.otf" },
    { "Gotham Narrow Ultra",      "gotham_narrow_ultra.otf" },
    { "Naowh",                    "naowh.ttf" },
    { "PlutoSansBold",            "plutosansbold.ttf" },
    { "Ubuntu (Light)",           "ubuntu_light.ttf" },
    { "Ubuntu (Medium)",          "ubuntu_medium.ttf" },
    { "Ubuntu (Regular)",         "ubuntu_regular.ttf" },
    { "Ubuntu (Bold)",            "ubuntu_bold.ttf" },
    { "Vodafone",                 "vodafone.otf" },
    { "Vodafone (Bold)",          "vodafone_bold.otf" },
}

local STATUS_BARS = {
    { "Better Blizzard (Nexus)", "BetterBlizzard.blp" },
}

for _, row in ipairs(FONTS) do
    local name, file = row[1], row[2]
    LSM:Register(LSM.MediaType.FONT, name, FontPath(file))
end

for _, row in ipairs(STATUS_BARS) do
    local name, file = row[1], row[2]
    LSM:Register(LSM.MediaType.STATUSBAR, name, TexturePath(file))
end
