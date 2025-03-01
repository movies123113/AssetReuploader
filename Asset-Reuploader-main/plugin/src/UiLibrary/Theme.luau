--!strict
local Theme = {}

local DEFAULT_THEME_PARAMETERS = {
	Name = "",
	
	Font = "SourceSansPro",
	TextColor = { Enum.StudioStyleGuideColor.MainText.Name },
	DimmedTextColor = { Enum.StudioStyleGuideColor.DimmedText.Name },
	StrokeColor = Color3.new(),
	StrokeTransparency = 0.75, -- varies based on theme 1 for light, 0.75 for dark

	MainBackgroundColor = { Enum.StudioStyleGuideColor.MainBackground.Name },
	BackgroundColor = { Enum.StudioStyleGuideColor.Light.Name },
	BorderColor = { Enum.StudioStyleGuideColor.Border.Name },

	UnselectedColor = { Enum.StudioStyleGuideColor.Tab.Name },
	SelectedColor = { Enum.StudioStyleGuideColor.Button.Name, Enum.StudioStyleGuideModifier.Hover.Name },

	BackgroundImage = "",
	NotificationImage = "",
	NotificationBackgroundImage = "",
} :: RawTheme

local HttpService = game:GetService("HttpService")

local currentTheme: Theme
local plugin: Plugin
local themes: RawTheme = { Studio = { Name = "Studio" } }

type RawTheme = { [string]: any }

export type Theme = {
	Name: string,
	Id: string,

	Font: Font,
	TextColor: Color3,
	DimmedTextColor: Color3,
	StrokeColor: Color3,
	StrokeTransparency: number,

	MainBackgroundColor: Color3,
	BackgroundColor: Color3,
	BorderColor: Color3,

	UnselectedColor: Color3,
	SelectedColor: Color3,

	BackgroundImage: string,
	NotificationImage: string,
	NotificationBackgroundImage: string,
}

local function deepCopy<T>(original: T): T
	assert(type(original) == "table", "can only deep copy tables")

	local copy = {}
	for i, v in original :: any do
		copy[i] = (type(v) == "table" and deepCopy(v) or v)
	end

	return copy
end

local function getFont(rawThemeFont: { any } | string): Font
	if type(rawThemeFont) == "string" then return Font.fromName(rawThemeFont) end
	assert(#rawThemeFont > 3, "Font options is too large")

	local name, weight, style = table.unpack(rawThemeFont)
		
	local weightEnum: Enum.FontWeight? = Enum.FontWeight:FromName(weight) -- ignore, selene and luau-lsp bug: https://github.com/Kampfkarren/selene/issues/619
	assert(weightEnum, "Font has invalid weight")

	local styleEnum: Enum.FontStyle? = Enum.FontStyle:FromName(style)
	assert(styleEnum, "Font has invalid weight")

	return Font.fromName(name, weightEnum, styleEnum)
end

local function normalizeRawTheme(rawTheme: RawTheme, themeId: string): Theme
	local studioTheme = settings().Studio.Theme :: StudioTheme
	local theme: { [string]: any } = {}

	local function normalizeValue(key: string, value: any): any
		if type(value) ~= "table" then return value end

		local valueType = type( (value :: { any })[1] )
		if valueType == "string" then
			assert(#value <= 2, `{key} could not create a StudioStyleGuide.`)

			local color, modifier = table.unpack(value :: any)

			local colorEnum: Enum.StudioStyleGuideColor? = Enum.StudioStyleGuideColor:FromName(color)
			assert(colorEnum, `{key} has invalid StudioStyleGuideColor.`)

			local modifierEnum: Enum.StudioStyleGuideModifier?
			if modifier then
				modifierEnum = Enum.StudioStyleGuideModifier:FromName(modifier :: any)
				assert(modifierEnum, `{key} has invalid StudioStyleGuideModifier.`)
			end

			return studioTheme:GetColor(colorEnum, modifierEnum)
		elseif valueType == "number" then
			assert(#value == 3, `{key} needs 3 values to create a Color3.`)

			local R, G, B = table.unpack(value :: any)
			local success, result = pcall(Color3.fromRGB, R, G, B)
			assert(success, `{key} could not create a Color3.`)
			return result
		end

		error(`{key} is an invalid type.`)
	end

	for k, v in DEFAULT_THEME_PARAMETERS do
		if k == "Font" then
			theme[k] = rawTheme[k] and getFont(rawTheme[k]) or getFont(v)
			continue
		end

		if rawTheme[k] then
			theme[k] = normalizeValue(k, rawTheme[k])
			continue
		end

		if k == "StrokeTransparency" then
			theme[k] = studioTheme.Name == "Light" and 1 or 0.75
			continue
		end

		theme[k] = normalizeValue(k, v)
	end

	theme.Id = themeId
	return theme
end

local function save()
	assert(plugin, "Theme needs to be initialized")
	
	local themesToSave = {}
	for themeId, theme in themes do
		if themeId == "Studio" then continue end
		themesToSave[themeId] = theme
	end

	plugin:SetSetting("Themes", themesToSave)
end

function Theme.init(currentPlugin: Plugin)
	assert(not plugin, "Theme is already initialized")
	plugin = currentPlugin

	local savedThemes = plugin:GetSetting("Themes") or {}
	for themeId, theme in savedThemes do
		themes[themeId] = theme
	end

	local savedThemeId = plugin:GetSetting("CurrentTheme")
	if themes[savedThemeId] then
		Theme.set(savedThemeId)
		return
	end

	Theme.set("Studio")
end

function Theme.getThemes(): { [string]: RawTheme }
	return themes
end

function Theme.get(): Theme
	return currentTheme
end

function Theme.set(themeId: string)
	local theme: RawTheme? = themes[themeId]
	assert(theme, "Theme does not exist")

	currentTheme = normalizeRawTheme(theme, themeId)
	plugin:SetSetting("CurrentTheme", themeId)
end

function Theme.add(rawTheme: RawTheme): string
	assert(type(rawTheme["Name"]) == "string", "Theme requires a name")

	local id = HttpService:GenerateGUID(false)
	while themes[id] do 
		id = HttpService:GenerateGUID(false) 
	end
	themes[id] = rawTheme

	local success, result = pcall(normalizeRawTheme, rawTheme, id)
	assert(success, result)

	save()
	return id
end

function Theme.updateFrame(frame: GuiObject)
	frame.BackgroundColor3 = currentTheme.MainBackgroundColor
	frame.BorderColor3 = currentTheme.BorderColor
end

function Theme.updateText(text: TextBox | TextLabel | TextButton, updateBackground: boolean?)
	text.FontFace = currentTheme.Font
	text.TextColor3 = currentTheme.TextColor
	text.TextStrokeColor3 = currentTheme.StrokeColor
	text.TextStrokeTransparency = currentTheme.StrokeTransparency

	if text:IsA("TextBox") then
		text.PlaceholderColor3 = currentTheme.DimmedTextColor
	end

	if updateBackground then 
		Theme.updateFrame(text) 
	end
end

function Theme.remove(themeId: string)
	themes[themeId] = nil
	save()
end

return Theme
