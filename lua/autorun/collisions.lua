local replicatorNoCollideGroup = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker"
}

replicatorNoCollideGroup_With = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker",
	"npc_bullseye"
}

function CNRTraceHull( startpos, endpos, rad, ignore, ignoreEnt )

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

function CNRTraceHullQuick( startpos, dir, rad, ignore, ignoreEnt )

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

function CNRTraceQuick( startpos, dir, ignore, ignoreEnt )

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

function CNRTraceLine( startpos, endpos, ignore, ignoreEnt )
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

hook.Add("ShouldCollide", "replicator_nocolide", function( ent1, ent2 )
	//print( ent1, ent2 )
	
	for k, v in pairs( replicatorNoCollideGroup ) do
		for k2, v2 in pairs( replicatorNoCollideGroup_With ) do
			if ent1:GetClass() == v and ent2:GetClass() == v2 then
				return false
			end
		end
	end
	
end )