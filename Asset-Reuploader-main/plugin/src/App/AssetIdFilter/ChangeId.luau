--!strict
local function setScriptIds(scriptInstance: Script | LocalScript | ModuleScript, oldId: number, newId: number)
    local source = scriptInstance.Source
    if not source then
        warn(scriptInstance, "has nil source.")
        return
    end

    local newSource = string.gsub(source, tostring(oldId), tostring(newId))
    if #source > 200_000 then
        (scriptInstance :: any):UpdateSourceAsync(scriptInstance, function() return newSource end)
    else
        scriptInstance.Source = newSource
    end
end

local function setSoundId(sound: Sound, oldId: number, newId: number)
    sound.SoundId = string.gsub(sound.SoundId, tostring(oldId), tostring(newId))  
end

local function setAnimationId(animation: Animation, oldId: number, newId: number)
    animation.AnimationId = string.gsub(animation.AnimationId, tostring(oldId), tostring(newId)) 
end

local function setNumberValueId(numValue: NumberValue | IntValue, _oldId: number, newId: number)
    numValue.Value = newId
end

local function setStringValueIds(strValue: StringValue, oldId: number, newId: number)
    strValue.Value = string.gsub(strValue.Value, tostring(oldId), tostring(newId)) 
end

local instanceIdSetters = {
    Sound = setSoundId,
    Animation = setAnimationId,

    Script = setScriptIds,
    LocalScript = setScriptIds,
    ModuleScript = setScriptIds,

    NumberValue = setNumberValueId,
    IntValue = setNumberValueId,

    StringValue = setStringValueIds,
}

return function(instance: Instance, oldId: number, newId: number)
    local className = instance.ClassName
    assert(instanceIdSetters[className], `{className} is not supported.`)
    instanceIdSetters[className](instance, oldId, newId)
end
