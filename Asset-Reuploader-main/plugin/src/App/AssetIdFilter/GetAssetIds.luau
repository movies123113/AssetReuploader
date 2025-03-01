--!strict
export type FilterOptions = {
    WhitelistedInstances: { string },
    Instances: { Instance },
}

local function isValidId(id: number): boolean
	if id == 0 then return false end

	local idLength = math.floor(math.log10(math.abs(id))) + 1
	return idLength >= 6 and idLength <= 15
end

local function getId(filteredInstance: Instance, possibleId: any): { [number]: { Instance } }
    local id = tonumber(possibleId)
    if not id or not isValidId(id) then return {} end

    return { [id] = { filteredInstance } }
end

local function getStringIds(filteredInstance: Instance, str: string): { [number]: { Instance } }
    local idMap = {}
	for matchedString in string.gmatch(str, "%d+") do
		local id = tonumber(matchedString)
		if not id or idMap[id] or not isValidId(id) then continue end

		idMap[id] = { filteredInstance }
	end
    return idMap
end

local function getSoundId(sound: Sound): { [number]: { Instance } }
    return getId(sound, string.match(sound.SoundId, "%d+"))
end

local function getAnimationId(animation: Animation): { [number]: { Instance } }
    return getId(animation, string.match(animation.AnimationId, "%d+"))
end

local function getScriptIds(scriptInstance: Script | LocalScript | ModuleScript): { [number]: { Instance } }
    return getStringIds(scriptInstance, scriptInstance.Source)
end

local function getStringValueIds(strValue: StringValue): { [number]: { Instance } }
    return getStringIds(strValue, strValue.Value) -- incase a game wants to put multiple ids
end

local function getNumberValueId(numValue: NumberValue | IntValue): { [number]: { Instance } }
    return getId(numValue, numValue.Value)
end

local instanceIdGetters = {
    Sound = getSoundId,
    Animation = getAnimationId,

    Script = getScriptIds,
    LocalScript = getScriptIds,
    ModuleScript = getScriptIds,

    NumberValue = getNumberValueId,
    IntValue = getNumberValueId,

    StringValue = getStringValueIds,
}

local function createFilterMap(instanceFilter: { string }): {[string]: boolean}
    local filterMap = {}
    for _, className in instanceFilter do
        assert(instanceIdGetters[className], `{className} is not a supported instance.`)
        filterMap[className] = true
    end
    return filterMap
end

local function merge(originalIdMap: { [number]: { Instance } }, otherIdMap: { [number]: { Instance } })
    for id, instanceArray in otherIdMap do
        local idInstances = originalIdMap[id]
        if not idInstances then
            originalIdMap[id] = instanceArray
            continue
        end

        for _, instance in instanceArray do
            if table.find(idInstances, instance) then continue end
            table.insert(idInstances :: { Instance }, instance)
        end
    end
end

return function(filterOptions: FilterOptions): { [number]: { Instance } }
    local idMap = {}

    local filterMap = createFilterMap(filterOptions.WhitelistedInstances)
    for _, instance in filterOptions.Instances do
        local className = instance.ClassName
        if not filterMap[className] then continue end

        merge(idMap, instanceIdGetters[className](instance))
    end

    return idMap
end
