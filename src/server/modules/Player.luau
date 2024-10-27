local Player = {}
Player.__index = Player

function Player.new(playerInstance, spot)
	local self = setmetatable({}, Player)
	self.player = playerInstance
	self.spot = spot
	self.health = 100
	self.score = 0
	self.questionHistory = {}
	return self
end

function Player:isAlive()
	return self.health > 0
		and self.player.Character
		and self.player.Character:FindFirstChild("Humanoid")
		and self.player.Character.Humanoid.Health > 0
end

function Player:adjustHealth(amount)
	self.health = math.clamp(self.health + amount, 0, 100)
end

function Player:updateScore(points)
	self.score += points
end

return Player
