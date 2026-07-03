require "cmic/Initialization"
require "cmic/IconPacksList"
require "cmic/Utils"

--ContextMenuIcons.ModPreferences = ContextMenuIcons.ModPreferences or {}
--local v = ContextMenuIcons.ModPreferences
local utils = ContextMenuIcons.Utils

ContextMenuIcons.preferences = ContextMenuIcons.preferences or {}

local onApplyCallbacks = {}

ContextMenuIcons.Events = {
    OnPreferencesApplied = nil
}

function ContextMenuIcons.Events.OnPreferencesApplied(func)
    table.insert(onApplyCallbacks, func)
end 

local sortedPacks = {}

local function getIconPackName(options)
    local packIndex = options:getOption("icons_iconpack_selection"):getValue()
    local packName = sortedPacks[packIndex]
    if packName then
        ContextMenuIcons.isNoneIconPackSelected = false
        return packName
    end
    ContextMenuIcons.isNoneIconPackSelected = true
    return nil
end

local function ContextMenuIconsPreferences() 
    local options = PZAPI.ModOptions:create("ContextMenuIcons", "Context Menu Icons")
    
    local comboBox = options:addComboBox("icons_iconpack_selection", getText("UI_ContextMenuIcons_IconPackSelector_Name"), getText("UI_ContextMenuIcons_IconPackSelector_Tooltip"))

    table.wipe(sortedPacks)
    for packName, _ in pairs(ContextMenuIcons.iconPacksList) do
        table.insert(sortedPacks, packName)
    end
    table.sort(sortedPacks)

    for _, packName in ipairs(sortedPacks) do
        comboBox:addItem(getText(packName), false)
    end

    if #sortedPacks == 0 then
        comboBox:addItem(getText("UI_None"), true)
    end

    local colorPicker = options:addColorPicker("icons_color_picker",  getText("UI_ContextMenuIcons_ColorPicker_Name"), 1, 1, 1, 1,  getText("UI_ContextMenuIcons_ColorPicker_Tooltip"))
    
    options.apply = function (self)
        local iconPackName = getIconPackName(options)
        local iconPackSettings = nil
        if iconPackName ~= nil and not ContextMenuIcons.isNoneIconPackSelected then
            iconPackSettings = ContextMenuIcons.iconPacksList[iconPackName].settings
        end 
        local colorData = {r = 1, g = 1, b = 1, a = 1}
        if iconPackSettings and iconPackSettings.isColorable then 
            colorData = options:getOption("icons_color_picker"):getValue()
        end
        
        ContextMenuIcons.preferences.iconPackName = iconPackName
        ContextMenuIcons.preferences.iconsColor = colorData

        if onApplyCallbacks then
            for _, callback in pairs(onApplyCallbacks) do
                callback()
            end
        end
        
        utils.log("ContextMenuIcons: Settings Applied!")
    end
end

local function initialize()
    ContextMenuIconsPreferences()
end
Events.OnResetLua.Add(initialize)

local function applyPreferences()
    local options = PZAPI.ModOptions:getOptions("ContextMenuIcons")
    options:apply()
end
Events.OnGameStart.Add(applyPreferences)