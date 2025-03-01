--!strict
local List = {}

local Input = require("./List/Input")
local Theme = require(".././Theme")
local ListElement = require("./List/ListElement")

local assets = script.Parent.Parent.Assets
local tabAsset = assets.Tab
local listAsset = assets.List

export type List = {
    _input: Input.Input?,

    elements: { [string]: ListElement.ListElement },
    instance: typeof(listAsset),

    UpdateTheme: (self: List) -> (),
    CreateElement: (self: List, value: string) -> ListElement.ListElement,
    AddInput: (self: List, placeholderText: string, callback: (input: string) -> ()) -> Input.Input,
    RemoveElement: (self: List, value: string) -> (),
    Get: (self: List) -> { string },
    Destroy: (self: List) -> (),
}

function List.new(parent: typeof(tabAsset)): List
    local instance = listAsset:Clone()
    instance.Size = UDim2.new(1, 0, 1, -parent.UIListLayout.AbsoluteContentSize.Y - 7)

    local list = {
        elements = {},
        instance = instance,
    } :: List

    function list.UpdateTheme(self: List)
        local listFrame = self.instance.ScrollingFrame
        Theme.updateFrame(listFrame)

        for _, element in self.elements do
            element:UpdateTheme()
        end

        if self._input then
            self._input:UpdateTheme()
        end
    end

    function list.CreateElement(self: List, value: string): ListElement.ListElement
        local listElement = ListElement.new(
            self.instance.ScrollingFrame :: any, 
            function() self.elements[value] = nil end,
            value
        )

        list.elements[value] = listElement
        return listElement
    end

    function list.AddInput(self: List, placeholderText: string, callback: (input: string) -> ()): Input.Input
        local input = Input.new(list.instance :: any, placeholderText, callback)

        local scrollingFrame = self.instance.ScrollingFrame
        scrollingFrame.Position = UDim2.new(0.5, 0, 0, 23)
        scrollingFrame.Size = UDim2.new(1, 0, 1, -23)

        self._input = input
        return input
    end

    function list.RemoveElement(self: List, value: string)
        assert(self.elements[value], `{value} does not exist in list.`)
        self.elements[value]:Destroy()
        self.elements[value] = nil
    end

    function list.Get(self: List): { string }
        local values = {}
        for i, _ in self.elements do
            table.insert(values, i)
        end
        return values
    end

    function list.Destroy(self: List)
        for _, element in self.elements do
            element:Destroy()
        end

        self.instance:Destroy()

        table.clear(self :: any)
    end

    list:UpdateTheme()
    instance.Parent = parent

    return list
end

return List