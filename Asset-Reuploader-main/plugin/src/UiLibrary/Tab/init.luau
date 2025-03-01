--!strict
local Tab = {}

local Button = require("./Tab/Button")
local Label = require("./Tab/Label")
local List = require("./Tab/List")
local Split = require("./Tab/Split")
local Toggle = require("./Tab/Toggle")

local assets = script.Parent.Assets
local tabAsset = assets.Tab
local mainUiFrame = assets.MainFrame.Frame

export type Tab = {
	_elements: { any },

	button: Button.Button,
	instance: typeof(tabAsset),

	UpdateTheme: (self: Tab) -> (),
	CreateButton: (self: Tab, text: string, clickedCallBack: () -> ()) -> Button.Button,
	CreateToggle: (self: Tab, text: string, callback: (state: boolean) -> (), defaultState: boolean?)-> Toggle.Toggle,
	CreateSplit: (self: Tab) -> Split.Split,
	CreateList: (self: Tab) -> List.List,
	CreateLabel: (self: Tab, text: string) -> Label.Label,
	Destroy: (self: Tab) -> (),
}

function Tab.new(uiFrame: typeof(mainUiFrame), clickedCallback: () -> (), name: string): Tab
    local instance = tabAsset:Clone()

	local tab = {
        _elements = {},
        
		button = Button.new(uiFrame.Topbar.Frame, name, false, clickedCallback),
		instance = instance,
	} :: Tab

	function tab.UpdateTheme(self: Tab)
        self.button:UpdateTheme()

        for _, element in self._elements do 
			element:UpdateTheme() 
		end
    end

	function tab.CreateButton(self: Tab, text: string, callback: () -> ()): Button.Button
		local button = Button.new(self.instance, text, true, callback)
		table.insert(self._elements, button)
		return button
	end

	function tab.CreateToggle(self: Tab, text: string, callback: (state: boolean) -> (), defaultState: boolean?): Toggle.Toggle
		local toggle = Toggle.new(self.instance, text, callback, defaultState)
		table.insert(self._elements, toggle)
		return toggle
	end

	function tab.CreateSplit(self: Tab): Split.Split
		local split = Split.new(self.instance)
		table.insert(self._elements, split)
		return split
	end

	function tab.CreateList(self: Tab): List.List
		local list = List.new(self.instance)
		table.insert(self._elements, list)
		return list
	end

	function tab.CreateLabel(self: Tab, text: string): Label.Label
		local label = Label.new(self.instance, text)
		table.insert(self._elements, label)
		return label
	end

	function tab.Destroy(self: Tab)
		for _, element in self._elements do 
			element:Destroy() 
		end

		table.clear(self :: any)
	end

	tab:UpdateTheme()
	instance.Parent =  uiFrame.Main.Tabs

	return tab
end

return Tab
