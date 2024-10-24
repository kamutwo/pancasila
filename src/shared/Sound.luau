local module = {}

function module.play(soundName: string, parent: Instance, volume: number?, looped: boolean?, destroy: boolean?)
	local soundFile = game:GetService("ReplicatedStorage").Sounds:FindFirstChild(soundName, true)
	if not soundFile then return end

	local sound: Sound = soundFile:Clone()
	sound.Parent = parent
	sound.Volume = volume or sound.Volume
	sound.Looped = looped or sound.Looped
	sound:Play()

	sound.Ended:Once(function()
		if destroy then sound:Destroy() end
	end)
	return sound
end

return module
