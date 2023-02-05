---@param seconds integer The amount of seconds you wish to hold the script by
local function wait(seconds)
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

Mining.uniqueIndexCache = {}
Mining.skillId = 100
Mining.lootTable = require("custom.Mining.lootTable")

function Mining.CreateRecord()
    local recordStore = RecordStores["spell"]
    recordStore.data.permanentRecords["burden_enable"] = {
		name = "Permanent Burden",
		subtype = 1,
		cost = 0,
		flags = 0,
		effects = {
			{
				attribute = -1,
				area = 0,
				duration = 10,
				id = 7,
				rangeType = 0,
				skill = -1,
				magnitudeMin = 900,
				magnitudeMax = 900
			}
		}
	}
	recordStore:Save()
end

---@param pid integer PlayerID
function Mining.updatePlayerSpellbook(pid)
    Players[pid]:LoadSpellbook()
end

---@param player string
---@return boolean hasPick
function Mining.hasPick(player)
    if not inventoryHelper.getItemIndex(player.data.inventory, "miner's pick", -1) then
        log("Miner's Pick not present in " .. player.name .. "'s inventory")
        return false
    end
    log("Miner's Pick Present, " .. player.name .. " is starting to mine.")
    return true
end

---@param pid integer PlayerID
---@param id string Spell ID
---@param action integer Add/Remove
function Mining.sendSpell(pid, id, action)
    tes3mp.ClearSpellbookChanges(pid)
    tes3mp.SetSpellbookChangesAction(pid, action)
    tes3mp.AddSpell(pid, id)
    tes3mp.SendSpellbookChanges(pid)
end

---@return string ore
---@return integer amount
function Mining.determineLoot()
    for ore, info in pairs(Mining.lootTable) do
        local chance = math.random(1, 100)
        if chance > info.chance and chance < info.limit then
            log(ore)
            local amount = math.random(info.min, info.max)
            return ore, amount
        end
    end
end

---@param pid integer PlayerID
function Mining.addLoot(pid)
    local player = Players[pid]
    local ore, amount = Mining.determineLoot()
    log(ore .. tostring(amount))
    inventoryHelper.addItem(player.data.inventory, ore, amount, -1, -1, "")
    player:LoadInventory()
    player:LoadEquipment()
    player:QuicksaveToDrive()
end

---@param pid integer PlayerId
function Mining.mine(pid)
    local player = Players[pid]
    
    if not Mining.hasPick(player) then return end
    log("Hello!")
    Mining.sendSpell(pid, "burden_enable", enumerations.spellbook.ADD)
    wait(3)
    Mining.sendSpell(pid, "burden_enable", enumerations.spellbook.REMOVE)
    Mining.addLoot(pid)
end

function Mining.OnOreActivation(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        for i = 1, 6, 1 do
            local target = "rock_diamond_0" .. tostring(i)
            if object.refId == target then 
                eventStatus.validDefaultHandler = false
                break
            end
        end
    end
    
    if eventStatus.validDefaultHandler then return eventStatus end
    
    Mining.mine(pid)
    return eventStatus
end

customEventHooks.registerHandler("OnServerPostInit", function()
    Mining.CreateRecord()
end)

customEventHooks.registerValidator("OnObjectActivate", Mining.OnOreActivation)