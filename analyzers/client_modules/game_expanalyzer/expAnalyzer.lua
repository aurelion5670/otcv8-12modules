expAnalyzerWindow = nil
EXP_ANALYZER_OPCODE = 121
storedExp = 0
startingTime = 0

EXP_REFRESH_SPEED = 5 * 1000

function init()
	-- 5th analyzer: Exp Analyzer
	expAnalyzerWindow = g_ui.loadUI('expAnalyzer', modules.game_interface.getRightPanel())
	expAnalyzerWindow:setup()
	expAnalyzerWindow:setContentMinimumHeight(110)
	expAnalyzerWindow:setContentMaximumHeight(115)
	
		sessionAmount = expAnalyzerWindow:recursiveGetChildById('sessionAmount')
		expValueAmount = expAnalyzerWindow:recursiveGetChildById('expValueAmount')
		expValuePerHourAmount = expAnalyzerWindow:recursiveGetChildById('expValuePerHourAmount')
		nextLevelAmount = expAnalyzerWindow:recursiveGetChildById('nextLevelAmount')
		timetoLevelAmount = expAnalyzerWindow:recursiveGetChildById('timetoLevelAmount')
	
	-- Opcodes Registering
	ProtocolGame.registerExtendedOpcode(EXP_ANALYZER_OPCODE, onExperienceChange)
	
	-- Extra tasks
	connect(LocalPlayer, {
		onLevelChange = onLevelChange,
	})
	
	connect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	
	if (g_game.isOnline()) then
		refresh()
	end
	
	setup()
	clean()
end

function terminate()
	expAnalyzerWindow:destroy()
	
	disconnect(LocalPlayer, {
		onLevelChange = onLevelChange
	})
	
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	

	-- Opcodes unRegistering
	ProtocolGame.unregisterExtendedOpcode(EXP_ANALYZER_OPCODE)
end

function refresh()
	expAnalyzerWindow:close()
	
	local player = g_game.getLocalPlayer()
	if not player then return end
	
	startingTime = os.time()
	clean()
	startExpEvent()
	onLevelChange(player, player:getLevel(), player:getLevelPercent())
end

function getSessionTime(storedTime)
	local seconds = tonumber(os.time() - storedTime)

	if seconds <= 0 then
		return "00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		
    return ""..hours..":"..mins..""
	end
end

function startExpEvent()
	expSpeedEvent = addEvent(checkExpSpeed, EXP_REFRESH_SPEED)
end

function offline()
	removeEvent(expSpeedEvent)
	clean()
end

function toggle()
	if expAnalyzerWindow:isVisible() then
		expAnalyzerWindow:close()
	else
		expAnalyzerWindow:open()
	end
end

function setup()
	sessionAmount:setText("00:00")
	expValueAmount:setText("000000000000000000000")
	expValuePerHourAmount:setText("000000000000000000000")
	nextLevelAmount:setText("000000000000000000000")
	timetoLevelAmount:setText("00000000000000:00000000000000")
end

function clean()
	storedExp = 0

	sessionAmount:setText("00:00")
	expValueAmount:setText("0")
	expValuePerHourAmount:setText("0")
	nextLevelAmount:setText("0")
	timetoLevelAmount:setText("00:00")
	
	if (g_game.isOnline()) then
		local localPlayer = g_game.getLocalPlayer()
		localPlayer.expSpeed = nil
		localPlayer.lastExps = nil
	end
end

function checkExpSpeed()
	local player = g_game.getLocalPlayer()
	if not player then return end

	local currentExp = player:getExperience()
	local currentTime = g_clock.seconds()
	if player.lastExps ~= nil then
		player.expSpeed = (currentExp - player.lastExps[1][1]) / (currentTime - player.lastExps[1][2])
	else
		player.lastExps = {}
	end
	
	table.insert(player.lastExps, {currentExp, currentTime})
	
	if #player.lastExps > 30 then
		table.remove(player.lastExps, 1)
	end
	
	changeExpSpeed(player)
	expSpeedEvent = scheduleEvent(checkExpSpeed, EXP_REFRESH_SPEED)
end

function expForLevel(level)
	return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function onLevelChange(localPlayer, value, percent)
	changeExpSpeed(localPlayer)
end

local function isNaN(v) return type(v) == "number" and v ~= v end
local function isInf(v) return v == math.huge end

function changeExpSpeed(localPlayer)
	if localPlayer.expSpeed ~= nil and localPlayer.lastExps ~= nil then
		expPerHour = math.floor(localPlayer.expSpeed * 3600)
		
		local nextLevelExp = expForLevel(localPlayer:getLevel()+1)
		local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
		local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft))*60)
		hoursLeft = math.floor(hoursLeft)
		
		if not isInf(hoursLeft) then
			if hoursLeft == 0 then
				hoursLeft = "00"
			elseif hoursLeft < 10 then
				hoursLeft = "0"..hoursLeft..""
			end
		else
			hoursLeft = "00"
		end
		
		if not isNaN(minutesLeft) then
			if minutesLeft == 0 then
				minutesLeft = "00"
			elseif minutesLeft < 10 then
				minutesLeft = "0"..minutesLeft..""
			end
		else
			minutesLeft = "00"
		end
		
		sessionAmount:setText(getSessionTime(startingTime))
		expValuePerHourAmount:setText(expPerHour)
		timetoLevelAmount:setText(hoursLeft..":"..minutesLeft)
	end
end

function onExperienceChange(protocol, opcode, buffer)
	if (buffer == nil) then return true end
	storedExp = storedExp + buffer[1]
	expValueAmount:setText(storedExp)
	nextLevelAmount:setText(buffer[2])
return true
end

function onMiniWindowClose()
	expAnalyzerWindow:close()
end