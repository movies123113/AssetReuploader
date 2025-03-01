--!strict
local UiLibrary = require("../../UiLibrary")
local reuploadIds = require("../ReuploadIds")

local Selection = game:GetService("Selection")

return function(ui: UiLibrary.Ui, plugin: Plugin)
	local tab = ui:CreateTab("Animation")
	
	tab:CreateButton("Reupload", function()
		reuploadIds(plugin, ui, game:GetDescendants(), "Animation")
	end)
	
	tab:CreateButton("Reupload Selected", function()
		reuploadIds(plugin, ui, Selection:Get(), "Animation")
	end)
end
