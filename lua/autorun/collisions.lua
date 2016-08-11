local replicatorNoCollideGroup = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker"
}

replicatorNoCollideGroup_Witch = {
	"replicator_segment",
	"replicator_queen",
	"replicator_worker"
}

function PlaySequence( self, seq )
	local sequence = self:LookupSequence( seq )
	
	self:SetPlaybackRate( 1.0 )
	self:SetSequence( sequence )
	self:ResetSequence( sequence )
	
	return self:SequenceDuration( sequence )
end

function traceHull( startpos, endpos, rad, ignore )
	local tr = util.TraceHull( {
		start = startpos,
		endpos = endpos,
		maxs = rad,
		mins = -rad,
		filter = function( ent ) 
			local ok = true
			for k, v in pairs( ignore ) do
				if ( ent:GetClass() == v ) then ok = false end
			end
			if( ok ) then return true end
		end
	} )
	
	return tr, tr.HitPos:Distance( startpos )
end

function traceHullQuick( startpos, dir, rad, ignore )
	local tr = util.TraceHull( {
		start = startpos,
		endpos = startpos + dir,
		maxs = rad,
		mins = -rad,
		filter = function( ent ) 
			local ok = true
			for k, v in pairs( ignore ) do
				if ( ent:GetClass() == v ) then ok = false end
			end
			if( ok ) then return true end
		end
	} )
	
	return tr, tr.HitPos:Distance( startpos )
end

function traceQuick( startpos, dir, ignore )
	local tr = util.QuickTrace(
		startpos, dir,
		function( ent ) 
			local ok = true
			for k, v in pairs( ignore ) do
				if ( ent:GetClass() == v ) then ok = false end
			end
			if( ok ) then return true end
		end
	)

	return tr, tr.HitPos:Distance( startpos )
end

function traceLine( startpos, endpos, ignore )
	local tr = util.TraceLine( {
		start = startpos,
		endpos = endpos,
		filter = function( ent ) 
			local ok = true
			for k, v in pairs( ignore ) do
				if ( ent:GetClass() == v ) then ok = false end
			end
			if( ok ) then return true end
		end
	} )

	return tr, tr.HitPos:Distance( startpos )
end

hook.Add("ShouldCollide", "replicator_nocolide", function( ent1, ent2 )
	//print( ent1, ent2 )
	
	for k, v in pairs( replicatorNoCollideGroup ) do
		for k2, v2 in pairs( replicatorNoCollideGroup_Witch ) do
			if ent1:GetClass() == v and ent2:GetClass() == v2 then
				return false
			end
		end
	end
end )