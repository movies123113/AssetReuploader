--!strict
local Toggle = {}

local BaseButton = require("../BaseButton")
local Theme = require("../Theme")
local Tip = require("../Tip")

local toggleAsset = script.Parent.Parent.Assets.Toggle

export type Toggle = {
    _tip: Tip.Tip?,
    _button: BaseButton.BaseButton<typeof(toggleAsset.Button)>,
    _callback: (state: boolean) -> (),

    state: boolean,
    instance: typeof(toggleAsset),

    Toggle: (self: Toggle) -> (),
    AddTip: (self: Toggle, tip: Tip.Tip) -> (),
    UpdateTheme: (self: Toggle) -> (),
    Destroy: (self: Toggle) -> ()
}

function Toggle.new(parent: GuiObject, text: string, callback: (state: boolean) -> (), defaultState: boolean?): Toggle
    local instance = toggleAsset:Clone()
    instance.TextLabel.Text = text

    local toggle: Toggle; toggle = {
        _callback = callback,
		_button = BaseButton.new(instance.Button, false, function()
			toggle:Toggle()
		end),

        state = false,
        instance = instance
    } :: Toggle

    function toggle.Toggle(self: Toggle)
        self.state = not self.state
        self._callback(self.state)

        local theme = Theme.get()
        self.instance.Button.BackgroundColor3 = self.state and theme.SelectedColor or theme.UnselectedColor
    end

    function toggle.AddTip(self: Toggle, tip: Tip.Tip)
        local tipFrame = tip.instance
        local toggleFrame = self.instance
        tipFrame.Position = UDim2.new(0, toggleFrame.TextLabel.TextBounds.X + 5, 0.5, 0)
		tipFrame.Parent = toggleFrame.TextLabel

        self._tip = tip
    end

    function toggle.UpdateTheme(self: Toggle)
        local toggleFrame = self.instance
        Theme.updateFrame(toggleFrame)        
        Theme.updateText(toggleFrame.TextLabel, false)
	
        local theme = Theme.get()
		toggleFrame.Button.BorderColor3 = theme.BorderColor
        toggleFrame.Button.BackgroundColor3 = self.state and theme.SelectedColor or theme.UnselectedColor

        if self._tip then 
            self._tip:UpdateTheme() 
        end
    end

    function toggle.Destroy(self: Toggle)
        if self._tip then 
            self._tip:Destroy()
        end

        self._button:Destroy()
        self.instance:Destroy()

        table.clear(self :: any)
    end

    toggle:UpdateTheme()
    if defaultState then
        toggle:Toggle()
    end

    instance.Parent = parent
    
    return toggle
end

return Toggle