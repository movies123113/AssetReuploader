--!strict
local Split = {}

local Toggle = require("./Toggle")
local Button = require("./Button")
local Theme = require("../Theme")

export type Split = {
    _elements: { any },

    instance: Frame,

    UpdateTheme: (self: Split) -> (),
    AddButton: (self: Split, text: string, clickedCallBack: () -> ()) -> Button.Button,
    AddToggle: (self: Split, text: string, callback: (state: boolean) -> (), defaultState: boolean?) -> Toggle.Toggle,
    Destroy: (self: Split) -> ()
}

local function sizeElement(self: Split, instance: GuiObject)
    if #self._elements == 0 then
        instance.Size = UDim2.new(0.5, -5, 1, 0)
        instance.Parent = self.instance
    else
        instance.Size = UDim2.new(0.5, -5, 1, 0)
        instance.AnchorPoint = Vector2.new(1, 0)
        instance.Position = UDim2.new(1, 0, 0, 0)
        instance.Parent = self.instance
    end
end

function Split.new(parent: GuiObject): Split
    local instance = Instance.new("Frame")
    instance.Size = UDim2.new(1, 0, 0, 20)
    instance.BackgroundTransparency = 1
    instance.Parent = parent

    local split = {
        _elements = {},

        instance = instance
    } :: Split

    function split.UpdateTheme(self: Split)
        for _, element in self._elements do
            element:UpdateTheme()
        end
    end

    function split.AddButton(self: Split, text: string, clickedCallBack: () -> ()): Button.Button
        assert(#self._elements <= 2, "Split can only have 2 elements.")

        local button = Button.new(self.instance, text, true, clickedCallBack)
        sizeElement(split, button.instance)
        table.insert(self._elements, button)
        
		local theme = Theme.get()
		button:UpdateTheme()

		return button
    end

    function split.AddToggle(self: Split, text: string, callback: (state: boolean) -> (), defaultState: boolean?): Toggle.Toggle
        assert(#self._elements <= 2, "Split can only have 2 elements.")

        local toggle = Toggle.new(self.instance, text, callback, defaultState)
        sizeElement(split, toggle.instance)
		table.insert(self._elements, toggle)

		local theme = Theme.get()
		toggle:UpdateTheme()

		return toggle
    end

    function split.Destroy(self: Split)
        for _, element in self._elements do
            element:Destroy()
        end
        table.clear(self._elements)

        self.instance:Destroy()

        table.clear(self :: any)
    end

    return split
end

return Split