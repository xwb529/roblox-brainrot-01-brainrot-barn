-- Shared display formulas; only the server changes balances and ownership.
local Economy = {}
Economy.StartCash = 350
Economy.MaxCarry = 6
Economy.MaxSpeedLevel = 6
function Economy.Multiplier(rebirths) return 1 + rebirths * 0.5 end
function Economy.RebirthPrice(rebirths) return math.floor(20000 * 2.5 ^ rebirths) end
function Economy.SpeedPrice(level) return math.floor(350 * 1.9 ^ level) end
function Economy.CarryPrice(capacity) return math.floor(650 * 2.2 ^ (capacity - 1)) end
function Economy.Income(entry, mutationMultiplier, rebirths)
	return math.floor(entry.income * mutationMultiplier * Economy.Multiplier(rebirths))
end
function Economy.Format(number)
	if number >= 1e12 then return string.format("%.1fT", number / 1e12) end
	if number >= 1e9 then return string.format("%.1fB", number / 1e9) end
	if number >= 1e6 then return string.format("%.1fM", number / 1e6) end
	if number >= 10000 then return string.format("%.1fK", number / 1000) end
	return tostring(math.floor(number))
end
return Economy
