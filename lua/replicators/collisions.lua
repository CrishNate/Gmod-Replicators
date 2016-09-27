--[[

	REPLICATORS Collision segment
	
]]

local h_ReplicatorNoCollideGroup = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker"
}

g_ReplicatorNoCollideGroupWith = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker",
	"npc_bullseye"
}

REPLICATOR.TraceHull = function( startpos, endpos, rad, ignore, ignoreEnt )

	local tr = util.TraceHull( {
		start = startpos,
		endpos = endpos,
		maxs = rad,
		mins = -rad,
		filter = function( ent ) 
			
			if ignore then
			
				for k, v in pairs( ignore ) do
				
					if ent:GetClass() == v then
					
						return false
						
					end
				end
			end
			
			if ignoreEnt then
			
				for k, v in pairs( ignoreEnt ) do
				
					if ent == v then
					
						return false
						
					end		
				end
			end

			return true
		end
	} )
	
	return tr, tr.HitPos:Distance( startpos )
end

REPLICATOR.TraceHullQuick = function( startpos, dir, rad, ignore, ignoreEnt )

	local tr = util.TraceHull( {
		start = startpos,
		endpos = startpos + dir,
		maxs = rad,
		mins = -rad,
		filter = function( ent ) 
			
			if ignore then
			
				for k, v in pairs( ignore ) do
				
					if ent:GetClass() == v then
					
						return false
						
					end
				end
			end
			
			if ignoreEnt then
			
				for k, v in pairs( ignoreEnt ) do
				
					if ent == v then
					
						return false
						
					end		
				end
			end

			return true
		end
	} )
	
	return tr, tr.HitPos:Distance( startpos )
	
end

REPLICATOR.TraceQuick = function( startpos, dir, ignore, ignoreEnt )

	local tr = util.QuickTrace(
		startpos, dir,
		function( ent ) 
		
			if ignore then
			
				for k, v in pairs( ignore ) do
				
					if ent:GetClass() == v then
					
						return false
						
					end
				end
			end
			
			if ignoreEnt then
			
				for k, v in pairs( ignoreEnt ) do
				
					if ent == v then
					
						return false
						
					end		
				end
			end
			
			return true
		end
	)

	return tr, tr.HitPos:Distance( startpos )
end

REPLICATOR.TraceLine = function( startpos, endpos, ignore, ignoreEnt )
	local tr = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		filter = function( ent ) 
		
			if ignore then
			
				for k, v in pairs( ignore ) do
				
					if ent:GetClass() == v then
					
						return false
						
					end
				end
			end
			
			if ignoreEnt then
			
				for k, v in pairs( ignoreEnt ) do
				
					if ent == v then
					
						return false
						
					end		
				end
			end

			return true
		end
	} )

	return tr, tr.HitPos:Distance( startpos )
end

REPLICATOR.TraceHoles = function( startpos, endpos, divPerUnit, dir, hullrad )

	local count = math.Round( startpos:Distance( endpos ) / divPerUnit )
	
	local direction = endpos - startpos
	direction:Normalize()
	
	for i = 0, count do
	
		if not CNRTraceHullQuick( startpos + direction * divPerUnit * i, dir, hullrad, g_ReplicatorNoCollideGroupWith ).Hit then
		
			return false
			
		end
		
	end
	
	return true
end

hook.Add("ShouldCollide", "replicator_nocolide", function( ent1, ent2 )

	for k, v in pairs( h_ReplicatorNoCollideGroup ) do
		for k2, v2 in pairs( g_ReplicatorNoCollideGroupWith ) do
		
			if ent1:GetClass() == v and ent2:GetClass() == v2 then return false end
			
		end
	end
	
end )