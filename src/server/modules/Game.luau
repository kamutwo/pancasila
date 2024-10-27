local Player = require(script.Parent.Player)
local Game = {}
Game.__index = Game

function Game.new()
	local class = setmetatable({}, Game)
	class.players = {}
	class.alivePlayer = 0
	class.spotAmount = 0
	class.inSession = false

	return class
end

function Game:addPlayer(playerData)
	local player = Player.new(playerData.player, playerData.spot)
	table.insert(self.players, player)
	return player
end

function Game:removePlayer(player)
	for index, plr in ipairs(self.players) do
		if plr == player then
			table.remove(self.players, index)
			break
		end
	end
	self.alivePlayer -= 1
end

function Game:isSessionOver()
	return self.alivePlayer <= (self.spotAmount > 1 and 1 or 0)
end

return Game
