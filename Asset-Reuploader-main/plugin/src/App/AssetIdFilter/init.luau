--!strict
local AssetIdFilter = {}

local getAssetIds = require("./AssetIdFilter/GetAssetIds")
local changeId = require("./AssetIdFilter/ChangeId")

export type FilterOptions = getAssetIds.FilterOptions

function AssetIdFilter.filterInstances(filterOptions: getAssetIds.FilterOptions): { [number]: { Instance } }
    return getAssetIds(filterOptions)
end

function AssetIdFilter.getIdArray(filteredIds: { [number]: { Instance } } )
    local idArray = {}
    for id, _ in filteredIds do
        table.insert(idArray, id)
    end
    return idArray
end

function AssetIdFilter.replaceIds(filteredIds: { [number]: { Instance } }, idsToReplace: { [number]: number })
    for oldId, newId in idsToReplace do
        local instanceArray = filteredIds[oldId]
        if not instanceArray then continue end

        for _, instance in instanceArray do
            changeId(instance, oldId, newId)
        end
    end
end

return AssetIdFilter
