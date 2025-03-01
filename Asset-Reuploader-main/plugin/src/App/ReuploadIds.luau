--!strict
local PORT = 51048

local AssetIdFilter = require("./AssetIdFilter")
local Connection = require("./Connection")
local getFilterOptions = require("./GetFilterOptions")
local StatusCodes = require("./StatusCodes")
local UiLibrary = require("../UiLibrary")

local MarketplaceService = game:GetService("MarketplaceService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local HttpService = game:GetService("HttpService")

local version = script.Parent.Parent.Parent.Version.Value
local busy = false

local function scriptInjectionEnabled()
    local testScript = Instance.new("Script")
	local success = pcall(ScriptEditorService.UpdateSourceAsync, ScriptEditorService, testScript, function() 
		return "" 
	end)
	
	testScript:Destroy()
	return success
end

return function(plugin: Plugin, ui: UiLibrary.Ui, Instances: { Instance }, assetType: "Animation" | "Sound", placeArray: { number }?)
    if busy then
        ui:Notify("Notification", "Plugin is busy.")
        return 
    end
    busy = true

    if not scriptInjectionEnabled() then
        ui:Notify("Notification", "Plugin needs script injection permission.")
        busy = false
        return
    end

    local isGroup = false
    local placeId = game.PlaceId
    local creatorId = game.CreatorId
    if creatorId == 0 then
        if placeId == 0 then
            ui:Notify("Notification", "Game needs to be published. Restart place after publishing.")
            busy = false
            return
        end

        local success, result = pcall(MarketplaceService.GetProductInfo, MarketplaceService, placeId)
        if not success then
            ui:Notify("Notification", "Failed to get place info. ")
            busy = false
            return
        end

        local creatorInfo = (result :: any).Creator
        isGroup = creatorInfo.CreatorType == "Group"
        creatorId = creatorInfo.CreatorId
    else
        isGroup = game.CreatorType == Enum.CreatorType.Group
    end

    local filterOptions = getFilterOptions(plugin, Instances)
    local filteredIds = AssetIdFilter.filterInstances(filterOptions)
    if next(filteredIds) == nil then
        ui:Notify("Notification", "No ids found.")
        busy = false
        return
    end

    local connection, response = Connection.new(PORT)
    if not connection then
        ui:Notify("Notification", "Unable to connect to localhost. Did you start the executable?")
        busy = false
        return
    end

    local function onDataRecieved(data: string)
        local success, result = pcall(HttpService.JSONDecode, HttpService, data)
        if not success then
            if data ~= "done" then return end
            
            ui:Notify("Notification", "Finished reuploading all ids. Client is still changing Ids.")
            connection:Destroy()
            busy = false
        end

        AssetIdFilter.replaceIds(filteredIds, result)
        warn(`Replaced {#result} ids`)
    end

    connection.onDataRecieved = onDataRecieved
    connection.onDisconnect = function()
        ui:Notify("Notification", "Disconnected from localhost. (Try reconnecting)")
        busy = false
    end

    local success, statusCode = connection:Send(HttpService:JSONEncode({
        pluginVersion = version,
        assetType = assetType,
        ids = AssetIdFilter.getIdArray(filteredIds),
        
        creatorId = creatorId,
        isGroup = isGroup,
        placeId = placeId,

        defaultPlaceIds = placeArray or {},
        debugMode = plugin:GetSetting("Debug") or false,
        exportJSON = plugin:GetSetting("ExportJSON")
    }))
    if not success then
        local message = StatusCodes[statusCode] or "Unable to send data to localhost."
        ui:Notify("Notification", message)

        busy = false
        connection:Destroy()
        return
    end

    if response then
        onDataRecieved(response)
    end
end
