local m_ID = 0
local m_DebugLink = { }

hook.Add( "Initialize", "replicator_keron_initialize", function( )

	if SERVER then
	
		util.AddNetworkString( "draw_keron_network" )
		util.AddNetworkString( "add_metal_points" )
		util.AddNetworkString( "update_metal_points" )
		
		util.AddNetworkString( "debug_rDrawPoint" )
		util.AddNetworkString( "debug_rDrawpPoint" )
		util.AddNetworkString( "debug_render_rerpl" )

		util.AddNetworkString( "rDark_points" )
		
		
		g_Replicator_entDissolver = ents.Create( "env_entity_dissolver" )
		if not IsValid( g_Replicator_entDissolver ) then return end
		g_Replicator_entDissolver:Spawn()

		g_Replicator_entDissolver:SetSolid( SOLID_NONE )
		g_Replicator_entDissolver:SetKeyValue( "magnitude", "0" )
		g_Replicator_entDissolver:SetKeyValue( "dissolvetype", "3" )
		
	end
	
	
end )

/*
concommand.Add( "tr_replicator_", function( ply )
	local swep = ply:GetActiveWeapon()
	if( ply:GetVar( "bad_time" ) != NULL && ply:GetVar( "bad_time_mode" ) != NULL && swep:IsValid() ) then
		
		if( ply:GetVar( "bad_time" ) == 100 && swep:GetClass() == "weapon_undertale_sans" ) then
			if( ply:GetVar( "bad_time_mode" ) == 0 ) then
				ply:SetVar( "bad_time_mode", CurTime() )
			end
		end
	end
end )
*/

//local endPOS

hook.Add( "EntityTakeDamage", "ReplicatorGetDamaged", function( target, dmginfo )

	if target:GetClass() == "npc_bullseye" and target.rReplicatorsNPCTarget then
	
		local attacker = dmginfo:GetAttacker()
		
		if not m_attackers[ "r"..attacker:EntIndex() ] and ( ( attacker:IsPlayer() and attacker:Alive() ) or attacker:IsNPC() ) then
		
			m_attackers[ "r"..attacker:EntIndex() ] = attacker
			target.rParentReplicator.rResearch = true
			
		end

	end

end )

hook.Add( "KeyPress", "debug_render_rerpl", function( ply, key ) 

	if SERVER then
		
		if key == IN_WALK then
		
			net.Start( "draw_keron_network" )
				net.WriteTable( m_pathPoints )
			net.Broadcast()
			
		end
		
		if key == IN_RUN then PrintTable( m_metalPoints ) end
		
		if key == IN_RELOAD then endPOS = ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10 print( endPOS ) end

		if key == IN_ZOOM then
		
			local case, index = FindClosestPoint( ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10, 1 )
			print( id )
		end
		
		if key == IN_USE then
			local case, index = FindClosestPoint( ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10, 1 )

			print( case, index )
			
			local result = GetPatchWay( { case = case, index = index }, endPOS )

			PrintTable( result )
			
			net.Start( "debug_render_rerpl" ) net.WriteTable( result ) net.Broadcast()
		end
	end
end )


hook.Add( "PostCleanupMap", "replicator_keron_clear", function( )

	m_pathPoints = { }
	m_metalPoints = { }
	m_DebugLink = { }
	m_darkPoints = { }
	m_metalPointsAsigned = { }
	m_attackers = { }
	
	m_queenCount = { }
	m_workersCount = { }
	m_pointIsInvalid = { }
	
	m_ID = 0
	
	if SERVER then
	
		g_Replicator_entDissolver = ents.Create( "env_entity_dissolver" )
		if not IsValid( g_Replicator_entDissolver ) then return end
		g_Replicator_entDissolver:Spawn()
		
		g_Replicator_entDissolver:SetSolid( SOLID_NONE )
		g_Replicator_entDissolver:SetKeyValue( "magnitude", "0" )
		g_Replicator_entDissolver:SetKeyValue( "dissolvetype", "3" )

		PrintTable( g_Replicator_entDissolver:GetTable() )
		
	end

end )

//
// Converting coordinate to grid
//
function convertToGrid( pos, size )

	local t_Pos = pos / size
	t_Pos = Vector( math.Round( t_Pos.x, 0 ), math.Round( t_Pos.y, 0 ), math.Round( t_Pos.z, 0 ) ) * size
	
	local t_StringPos = ( t_Pos.x ).."_"..( t_Pos.y ).."_"..( t_Pos.z )
	
	return t_Pos, t_StringPos
end

if SERVER then

	function CNRDissolveEntity( ent )
	
		 ent:SetKeyValue( "targetname", "ANIHILATION" )
		 g_Replicator_entDissolver:Fire( "Dissolve", "ANIHILATION", 0 )
		 
	end

	function CNRPlaySequence( self, seq )
	
		local sequence = self:LookupSequence( seq )
		self:ResetSequence( sequence )

		self:SetPlaybackRate( 1.0 )
		self:SetSequence( sequence )
		
		return self:SequenceDuration( sequence )
	end

	
	function CNRTestForFloor( startpos, endpos, divPerUnit, dir, hullrad )
	
		local count = math.Round( startpos:Distance( endpos ) / divPerUnit )
		
		local direction = endpos - startpos
		direction:Normalize()
		
		for i = 0, count do
		
			if not CNRTraceHullQuick( startpos + direction * divPerUnit * i, dir, hullrad, replicatorNoCollideGroup_With ).Hit then
			
				return false
				
			end
			
		end
		
		return true
	end
	
	//
	// Returning closest point from Replicators Net Work to pos
	//
	function FindClosestPoint( pos, rad )
	
		local t_Dist = 0

		local t_Case = ""
		local t_Index = 0
		
		local t_pathPoints = {}
				
		for x = -1 * rad, 1 * rad do
		for y = -1 * rad, 1 * rad do
		for z = -1 * rad, 1 * rad do

			local coord, sCoord = convertToGrid( pos + Vector( x, y, z ) * 100, 100 )

			if m_pathPoints[ sCoord ] then table.Add( t_pathPoints, m_pathPoints[ sCoord ] ) end
			
		end
		end
		end
		
		local t_First = true
		for k, v in pairs( t_pathPoints ) do
			local tracer = CNRTraceLine( v.pos, pos, replicatorNoCollideGroup_With )
			
			if not tracer.Hit then
			
				if t_First then
				
					t_First = false
					t_Dist = v.pos:Distance( pos )

					t_Case = v.case
					t_Index = v.index
					
				else
				
					local d = v.pos:Distance( pos )
					
					if d < t_Dist then
					
						t_Dist = d

						t_Case = v.case
						t_Index = v.index
						
					end
				end
			end
		end
		
		return t_Case, t_Index
	end
	
	//
	// Getting Path in Replicators Net Work to endpos
	//
	function GetPatchWay( start, endpos )

		local t_Case, t_Index = FindClosestPoint( endpos, 1 )
		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if m_pathPoints[ v.case ] and m_pathPoints[ v.case ][ v.index ] and m_pathPoints[ v.case ][ v.index ].connection then
				local pPoint = m_pathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = CNRTraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), replicatorNoCollideGroup_With )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then m_pathPoints[ v.case ][ v.index ].ent = trace.Entity
						else m_pathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( m_pointIsInvalid[ v.case ] and m_pointIsInvalid[ v.case ][ v.index ] and m_pointIsInvalid[ v.case ][ v.index ] < 10 )
						or not m_pointIsInvalid[ v.case ] or ( m_pointIsInvalid[ v.case ] and not m_pointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then
				
					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							if v2.case == t_Case and v2.index == t_Index then return table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ) end
							
						end
					end
				end
			end

			t_LinksHistory[ v.case ][ v.index ] = { }

			if k > 10000 then MsgC( Color( 255, 0, 0 ), "BREAK ERROR 1", "\n" ) PrintTable( t_Links ) break end
		end
		
		return {}
	end
	
	//
	// Getting Path in Replicators Net Work to closest entTable element
	//
	function GetPatchWayToClosestEnt( start, entTable )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if m_pathPoints[ v.case ] and m_pathPoints[ v.case ][ v.index ] and m_pathPoints[ v.case ][ v.index ].connection then
				local pPoint = m_pathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = CNRTraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), replicatorNoCollideGroup_With )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then m_pathPoints[ v.case ][ v.index ].ent = trace.Entity
						else m_pathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( m_pointIsInvalid[ v.case ] and m_pointIsInvalid[ v.case ][ v.index ] and m_pointIsInvalid[ v.case ][ v.index ] < 10 )
						or not m_pointIsInvalid[ v.case ] or ( m_pointIsInvalid[ v.case ] and not m_pointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then
				
					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							local t_v2pos = pPoint.pos

							for k3, v3 in pairs( entTable ) do
							
								if v3:IsValid() and t_v2pos:Distance( v3:GetPos() ) < 500
									and not CNRTraceLine( t_v2pos, v3:GetPos(), replicatorNoCollideGroup_With ).Hit 
										and CNRTestForFloor( t_v2pos, v3:GetPos(), 50, Vector( 0, 0, -25 ), Vector( 5, 5, 5 ) ) then
									
									return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3:GetPos() } ), v3, k3

								end
							end
						end
					end
				end
			end
			

			t_LinksHistory[ v.case ][ v.index ] = { }

			if k > 10000 then MsgC( Color( 255, 0, 0 ), "BREAK ERROR 1", "\n" ) break end
			
		end
		
		print( "DOES FOUNDED" )
		return {}, Entity( 0 )
	end

	//
	// Getting Path in Replicators Net Work to closest Id
	//
	function GetPatchWayToClosestId( start )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if m_pathPoints[ v.case ] and m_pathPoints[ v.case ][ v.index ] and m_pathPoints[ v.case ][ v.index ].connection then
				local pPoint = m_pathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = CNRTraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), replicatorNoCollideGroup_With )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then m_pathPoints[ v.case ][ v.index ].ent = trace.Entity
						else m_pathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( m_pointIsInvalid[ v.case ] and m_pointIsInvalid[ v.case ][ v.index ] and m_pointIsInvalid[ v.case ][ v.index ] < 10 )
						or not m_pointIsInvalid[ v.case ] or ( m_pointIsInvalid[ v.case ] and not m_pointIsInvalid[ v.case ][ v.index ] ) ) then
				
					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							local v2pos = pPoint.pos
							
							for k3, v3 in pairs( m_darkPoints ) do
								
								if not v3.used and v2pos:Distance( v3.pos ) < 500
									and not CNRTraceLine( v2pos, v3.pos, replicatorNoCollideGroup_With ).Hit 
										and CNRTestForFloor( v2pos, v3.pos, 50, Vector( 0, 0, -25 ), Vector( 5, 5, 5 ) ) then
									
									return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3.pos } ), k3

								end
							end
						end
					end
				else end
			end

			t_LinksHistory[ v.case ][ v.index ] = { }

			if k > 10000 then MsgC( Color( 255, 0, 0 ), "BREAK ERROR 1", "\n" ) break end
		end
		
		return {}, 0
	end

	//
	// Getting Path in Replicators Net Work to metal
	//
	function GetPatchWayToClosestMetal( start )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if m_pathPoints[ v.case ] and m_pathPoints[ v.case ][ v.index ] and m_pathPoints[ v.case ][ v.index ].connection then
				local pPoint = m_pathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = CNRTraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), replicatorNoCollideGroup_With )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then m_pathPoints[ v.case ][ v.index ].ent = trace.Entity
						else m_pathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( m_pointIsInvalid[ v.case ] and m_pointIsInvalid[ v.case ][ v.index ] and m_pointIsInvalid[ v.case ][ v.index ] < 10 )
						or not m_pointIsInvalid[ v.case ] or ( m_pointIsInvalid[ v.case ] and not m_pointIsInvalid[ v.case ][ v.index ] ) ) then				

					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							local v2pos = pPoint.pos
							
							for k3, v3 in pairs( m_metalPoints ) do
							
								if v3.ent then
								
									if v3.ent:IsValid() then
									
										local v3pos = v3.ent:WorldSpaceCenter()
												
										if v2pos:Distance( v3pos ) < 500 
											and not CNRTraceLine( v2pos, v3pos, replicatorNoCollideGroup_With, { v3.ent } ).Hit then
											
											return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3pos } ), k3
											
										end
									else table.remove( m_metalPoints, ""..v3.ent:EntIndex() ) end
									
								else

									local v3pos = v3.pos
									
									if not v3.used and v2pos:Distance( v3pos ) < 500
										and not CNRTraceLine( v3pos, v2pos, replicatorNoCollideGroup_With ).Hit then
									
										return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3.pos } ), k3
										
									end

								end
							end
							
						end
					end
				else end
				
			else MsgC( Color( 255, 0, 0 ), "ERROR LNK", "\n" ) end

			t_LinksHistory[ v.case ][ v.index ] = { }

			//if k > 100 then print( "BREAK" ) break end
		end
		
		//print( "DOESNT FOUNDED METAL")
		return {}, 0
	end
	
	//
	// Adding metal spot
	//
	
	function UpdateMetalPoint( _stringp, _amount )
	
		m_metalPoints[ _stringp ].amount = _amount

		net.Start( "update_metal_points" ) net.WriteString( _stringp ) net.WriteFloat( _amount ) net.Broadcast()
		
	end
	
	//
	// Adding metal entity
	//
	function AddMetalEntity( _ent )

		local _stringp = "_".._ent:EntIndex()
		
		m_metalPoints[ _stringp ] = { ent = _ent, amount = _ent:GetModelRadius() * 4 }
		m_metalPointsAsigned[ _stringp ] = true
		
	end
	
	
	function AddMetalPoint( _stringp, _pos, _normal, _amount )
		
		m_metalPoints[ _stringp ] = { pos = _pos, normal = _normal, amount = _amount, used = false }
		m_metalPointsAsigned[ _stringp ] = true
		
		local t_tracer = CNRTraceQuick( _pos, -_normal * 20, replicatorNoCollideGroup_With )
				
		net.Start( "add_metal_points" )
		
			net.WriteString( _stringp )
			net.WriteTable( { pos = t_tracer.HitPos, normal = t_tracer.HitNormal, amount = _amount, used = false } )
			
		net.Broadcast()
		
	end
	
	//
	// Adding path point
	//
	function AddPathPoint( _pos, _connection, _ent )
	
		local merge = false
		local t_Mergered = false
		local returnID
		
		local t_pathPoints = {}
		
		for x = -1, 1 do
		for y = -1, 1 do
		for z = -1, 1 do

			local coord, sCoord = convertToGrid( _pos + Vector( x, y, z ) * 80, 100 )
			
			if m_pathPoints[ sCoord ] then table.Add( t_pathPoints, m_pathPoints[ sCoord ] ) end
			
		end
		end
		end
		
		if table.Count( _connection ) > 0 then

			for k2, v2 in pairs( _connection ) do
			
				for k, v in pairs( t_pathPoints ) do
				
					local v2pos = m_pathPoints[ v2.case ][ v2.index ].pos
					
					//print( v.case, v.index, v2.case, v2.index, v.pos:Distance( _pos ), not ( v.case == v2.case and v.index == v2.index ), ( v.pos:Distance( _pos ) < 10 and not CNRTraceLine( v.pos, _pos, replicatorNoCollideGroup_With ).Hit ) )
					
					if not ( v.case == v2.case and v.index == v2.index ) 
						and ( ( v.pos:Distance( _pos ) < 50 and not CNRTraceLine( v.pos, v2pos, replicatorNoCollideGroup_With ).Hit ) 
							or ( v.pos:Distance( _pos ) < 10 and not CNRTraceLine( v.pos, _pos, replicatorNoCollideGroup_With ).Hit ) ) then
					
						if not m_pathPoints[ v.case ][ v.index ].connection[ v2.case.."|"..v2.index ] then
						
							m_pathPoints[ v.case ][ v.index ].connection[ v2.case.."|"..v2.index ] = { case = v2.case, index = v2.index }
							m_pathPoints[ v2.case ][ v2.index ].connection[ v.case.."|"..v.index ] = { case = v.case, index = v.index }

							//table.Add( m_pathPoints[ v.case ][ v.index ].connection, {{ case = v2.case, index = v2.index }} )
							//table.Add( m_pathPoints[ v2.case ][ v2.index ].connection, {{ case = v.case, index = v.index }} )
							
							t_Mergered = true
						end
						
						returnID = { case = v.case, index = v.index }
						merge = true
					end
				end
			end
		end
		
		
		if ( table.Count( _connection ) == 0 or not t_Mergered ) and table.Count( t_pathPoints ) > 0 then
		
			local t_Next = false
			local r_Case, r_Index = FindClosestPoint( _pos, 1 )
			
			if r_Case != "" and r_Index > 0 then
				
				if m_pathPoints[ r_Case ][ r_Index ].pos:Distance( _pos ) < 50 and not CNRTraceLine( _pos, m_pathPoints[ r_Case ][ r_Index ].pos, replicatorNoCollideGroup_With ).Hit then
					
					merge = true
					returnID = { case = r_Case, index = r_Index }
					
				end
			end
		end
		
		if not merge then
			
			local coord, sCoord = convertToGrid( _pos, 100 )

			if m_pathPoints[ sCoord ] then
			
				m_ID = table.Count( m_pathPoints[ sCoord ] ) + 1
				
			else
			
				m_ID = 1
				m_pathPoints[ sCoord ] = {}
				
			end
			
			returnID = { case = sCoord, index = m_ID }
			
			if _ent and _ent:IsValid() then table.Add( m_pathPoints[ sCoord ], {{ pos = _pos, connection = {}, case = sCoord, index = m_ID, ent = _ent }} )
			else table.Add( m_pathPoints[ sCoord ], {{ pos = _pos, connection = {}, case = sCoord, index = m_ID }} ) end
			
			for k, v in pairs( _connection ) do
			
				//local result = CNRTraceLine( _pos, m_pathPoints[ v.case ][ v.index ].pos, replicatorNoCollideGroup_With )

				//if not result.Hit then

					m_pathPoints[ v.case ][ v.index ].connection[ sCoord.."|"..m_ID ] = { case = sCoord, index = m_ID }
					m_pathPoints[ sCoord ][ m_ID ].connection[ v.case.."|"..v.index ] = { case = v.case, index = v.index }
					
					//table.Add( m_pathPoints[ v.case ][ v.index ].connection, {{ case = sCoord, index = m_ID }} )
					//table.Add( m_pathPoints[ sCoord ][ m_ID ].connection, {{ case = v.case, index = v.index }} )

					//PrintMessage( HUD_PRINTTALK, m_ID )
					
				//end
				
			end
			
		end
		
		//PrintTable( returnID )
		return returnID, t_Mergered
	end

	net.Receive( "rDark_points", function() m_darkPoints[ net.ReadString() ] = { pos = net.ReadVector(), used = false } end )		
	
end // SERVER


hook.Add("Think", "replicator_keron", function( )
	
	if SERVER then
	end // SERVER
	
	if CLIENT then	
	end // CLIENT
	
end )

if CLIENT then

	function AddDarkPoint( _stringp, _pos )
	
		m_darkPoints[ _stringp ] = { pos = _pos, used = false }
		
		net.Start( "rDark_points" )
			net.WriteString( _stringp )
			net.WriteVector( _pos )
		net.SendToServer()
		
	end
	
end // CLIENT

hook.Add( "PostDrawTranslucentRenderables", "DrawQuadEasyExample", function()

	net.Receive( "draw_keron_network", function() m_pathPoints = net.ReadTable() end )
	
	net.Receive( "update_metal_points", function() m_metalPoints[ net.ReadString() ].amount = net.ReadFloat() end )
	net.Receive( "add_metal_points", function() m_metalPoints[ net.ReadString() ] = net.ReadTable() end )

	for k, v in pairs( m_pathPoints ) do
		local words = string.Explode( "_", k )
	
		render.SetMaterial( Material( "models/wireframe" ) )
		
		//render.DrawBox( Vector( tonumber( words[ 1 ], 10 ), tonumber( words[ 2 ], 10 ), tonumber( words[ 3 ], 10 ) ), Angle( ), -Vector( 1, 1, 1 ) * 50, Vector( 1, 1, 1 ) * 50, Color( 255, 255, 255 ), false ) 

		for k2, v2 in pairs( v ) do

			render.SetColorMaterial()
			if v2.ent then render.DrawBox( v2.pos, Angle( ), -Vector( 2, 2, 2 ), Vector( 2, 2, 2 ), Color( 255, 0, 0, 50 ), false ) 
			else render.DrawBox( v2.pos, Angle( ), -Vector( 2, 2, 2 ), Vector( 2, 2, 2 ), Color( 255, 255, 255, 50 ), false ) end
			
			for k3, v3 in pairs( v2.connection ) do
			
				if m_pathPoints[ v3.case ] then

					local p = m_pathPoints[ v3.case ][ v3.index ]
					local vec = ( v2.pos - p.pos ):Angle()
					
					render.DrawLine( v2.pos + vec:Right() / 2, p.pos + vec:Right() / 2, Color( 255, 255, 255, 50 ), false )
					
				end
				//else table.remove( m_pathPoints[ v2.case ].connection, k2 ) end
				
			end
		end
	end
	
	for k, v in pairs( m_darkPoints ) do
	
		render.SetColorMaterial()
		render.SetBlend( 1 )
		
		render.DrawBox( v.pos, Angle( ), -Vector( 10, 10, 0 ), Vector( 10, 10, 0 ), Color( 255, 255, 255, 10 ), true ) 
		
	end


	for k, v in pairs( m_metalPoints ) do
	
		render.SetMaterial( Material( "decals/antlion/shot5" ) )

		local t_Radius = ( 1 - math.exp( -( ( 1 - v.amount / 100 ) * 10 ) / 2 ) ) * 50
		
		render.DrawQuadEasy( v.pos, v.normal, t_Radius, t_Radius, Color( 255, 255, 255 ), t_Radius * 100 ) 
		//render.DrawBox( v.pos, v.angle, -Vector( 1, 1, 1 ), Vector( 1, 1, 1 ), Color( 0, 0, 255 ), false ) 
		
	end

	net.Receive( "debug_render_rerpl", function() m_DebugLink = net.ReadTable() end )
	
	for k, v in pairs( m_DebugLink ) do
	
		render.SetColorMaterial()
		render.DrawBox( m_pathPoints[ v.case ][ v.index ].pos, Angle( 45, 45 ,45 ), -Vector( 1, 1, 1 ) * ( 1 + k / 100 ), Vector( 1, 1, 1 ) * ( 1 + k / 100 ), Color( 0, 0, 255 ), false ) 
		
	end
	
end )