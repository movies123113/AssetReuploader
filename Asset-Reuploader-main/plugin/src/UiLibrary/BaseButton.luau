--!strict
local BaseButton = {}

local Theme = require("./Theme")

export type BaseButton<T> = {
	_connections: { RBXScriptConnection },

	instance: T,

	ColorSelected: (self: BaseButton<T>) -> (),
	ColorUnselected: (self: BaseButton<T>) -> (),
	Destroy: (self: BaseButton<T>) -> (),
}

function BaseButton.new(button: GuiButton, autoColor: boolean, clickedCallBack: () -> ()): BaseButton<GuiButton>
	local connections = {}
	local baseButton = {
		_connections = connections,

		instance = button,
	} :: BaseButton<GuiButton>

	table.insert(connections, button.MouseButton1Down:Connect(function()
		if autoColor then 
			baseButton:ColorSelected() 
		end
		
		clickedCallBack()
	end))

	if autoColor then
		local function colorUnselected()
			baseButton:ColorUnselected()
		end

		table.insert(connections, button.MouseButton1Up:Connect(colorUnselected))
		table.insert(connections, button.MouseLeave:Connect(colorUnselected))
	end

	function baseButton.ColorSelected(self: BaseButton<GuiButton>)
		local theme = Theme.get()
		self.instance.BackgroundColor3 = theme.SelectedColor
	end

	function baseButton.ColorUnselected(self: BaseButton<GuiButton>)
		local theme = Theme.get()
		self.instance.BackgroundColor3 = theme.UnselectedColor
	end

	function baseButton.Destroy(self: BaseButton<GuiButton>)
		for _, connection in self._connections do
			connection:Disconnect()
		end

		table.clear(self :: { any })
	end

	return baseButton
end

return BaseButton
