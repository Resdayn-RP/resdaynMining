---@param seconds integer The amount of seconds you wish to hold the script by
local function Wait(seconds)
    local clock = os.clock
    local t0 = clock()
    while clock() - t0 <= seconds do end
end

---@func log message to console
---@param message string The message that is sent to log
---@return nil
local function log(message)
    tes3mp.LogMessage(enumerations.log.VERBOSE, "[ Mining ]: " .. message)
end

---@class Mining
---@field uniqueIndexCache table
---@field skillId integer
---@field lootTable table
---@field mine function
local Mining = {}

Mining.lootTable = require("custom.Mining.lootTable")

---@return string|nil ore
---@return integer|nil amount
function Mining.determineLoot()
    for ore, info in pairs(Mining.lootTable) do
        local chance = math.random(1, 100)
        if info.limit > chance and chance > info.chance then
            log(ore)
            local amount = math.random(info.min, info.max)
            return ore, amount
        end
    end
    return nil, nil
end

---@param pid integer PlayerID
function Mining.addLoot(pid)
    local player = Players[pid]
    local ore, amount = nil, nil
    repeat
        ore, amount = Mining.determineLoot()
    until ore and amount
    log(ore .. tostring(amount))
    ResdaynCore.functions.addItem(player, ore, amount)
end

---@param pid integer PlayerId
function Mining.mine(pid)
    local player = Players[pid]
    if not ResdaynCore.functions.itemCheck(player, "miner's pick") then
        log("Miner's Pick not present in " .. player.name .. "'s inventory")
        return
    end
    log("Miner's Pick Present, " .. player.name .. " is starting to mine.")
    ResdaynCore.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.ADD)
    Wait(3)
    ResdaynCore.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.REMOVE)
    Mining.addLoot(pid)
end

---@param obj table
---@return boolean isDeposit
function Mining.isItDeposit(obj)
    for i = 1, 6, 1 do
        local target = "rock_diamond_0" .. tostring(i)
        if obj.refId == target then return true end
    end
    return false
end

---@param eventStatus table
---@param pid string PlayerID
---@param cellDescription string Location of player
---@param objects table Activated object(s)
---@param players table Target Players
function Mining.OnOreActivation(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do 
        eventStatus.validDefaultHandler = not Mining.isItDeposit(object)
    end
    
    if eventStatus.validDefaultHandler then return eventStatus end
    
    Mining.mine(pid)
    return eventStatus
end

function Mining.OnServerPostInit()
    ResdaynCore.functions.createBurdenSpell("Mining Ore", 900)
end

customEventHooks.registerHandler("OnServerPostInit", Mining.OnServerPostInit)
customEventHooks.registerValidator("OnObjectActivate", Mining.OnOreActivation)

return Mining