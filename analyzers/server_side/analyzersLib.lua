EXP_ANALYZER_OPCODE = 121

function Player.addAnalyzerExp(self, value, expH)
	if expH < 0 then expH = 0 end
	self:sendOpcode(EXP_ANALYZER_OPCODE, {value, expH})
return true
end