--!strict
local UiLibrary = require("../../UiLibrary")

local reuploadIds = require("../ReuploadIds")

local MarketplaceService = game:GetService("MarketplaceService")
local Selection = game:GetService("Selection")

return function(ui: UiLibrary.Ui, plugin: Plugin)
    local tab = ui:CreateTab("Sound")

    tab:CreateButton("Reupload", function()
		reuploadIds(plugin, ui, game:GetDescendants(), "Animation")
	end)
	
	tab:CreateButton("Reupload Selected", function()
        reuploadIds(plugin, ui, Selection:Get(), "Animation")
	end)

    local placeList = tab:CreateList()
	local placeInput = placeList:AddInput("Place Id", function(input)
		local placeId = tonumber(input)
        local success, productInfo = pcall(MarketplaceService.GetProductInfo, MarketplaceService, placeId)

        if not success then
            ui:Notify("Notification", "Error getting product info.") 
            return 
        end

        local assetTypeId = (productInfo :: any).AssetTypeId
		if assetTypeId ~= 9 then
            ui:Notify("Notification", "Invalid place id.") 
            return 
        end

        placeId = tostring(placeId)
        if placeList.elements[placeId] then
            ui:Notify("Notification", "Place id is in list.") 
            return 
        end

        local element = placeList:CreateElement(placeId)
            :AddRemoveButton()
        
        element.instance.TextLabel.Text = `({placeId}) {(productInfo :: any).Name}`
	end)
	placeInput:AddTip(ui:CreateTip(
		"Reuploading audio needs a place id. Public games are found automatically."
	))

    local textBox = placeInput.instance.TextBox
    textBox:GetPropertyChangedSignal("Text"):Connect(function() 
        textBox.Text = string.gsub(textBox.Text, "%D", "") 
    end)
end
