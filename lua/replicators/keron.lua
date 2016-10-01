--[[

	REPLICATORS AI segment
	
]]

AddCSLuaFile()

local m_ID = 0
local m_DebugLink = { }

hook.Add( "Initialize", "CNR_KeronInitialize", function( )

	if SERVER then
	

		util.AddNetworkString( "CNR_UpdateMetalPoint" )
		util.AddNetworkString( "CNR_UpdateMetalEntity" )

		util.AddNetworkString( "CNR_AddMetalPoint" )
		util.AddNetworkString( "CNR_AddMetalEntity" )
		
		util.AddNetworkString( "debug_rDrawPoint" )
		util.AddNetworkString( "debug_rDrawpPoint" )
		util.AddNetworkString( "debug_render_rerpl" )
		util.AddNetworkString( "debug_keron_network" )

		util.AddNetworkString( "rDark_points" )
		
		
		g_Replicator_entDissolver = ents.Create( "env_entity_dissolver" )
		if not IsValid( g_Replicator_entDissolver ) then return end
		g_Replicator_entDissolver:Spawn()

		g_Replicator_entDissolver:SetSolid( SOLID_NONE )
		g_Replicator_entDissolver:SetKeyValue( "magnitude", "0" )
		g_Replicator_entDissolver:SetKeyValue( "dissolvetype", "3" )
		
	end
end )


hook.Add( "EntityTakeDamage", "CNR_GetDamaged", function( target, dmginfo )

	if target:GetClass() == "npc_bullseye" and target.rNPCTarget then
	
		local h_Attacker = dmginfo:GetAttacker()
		
		if not g_Attackers[ "r"..h_Attacker:EntIndex() ] and ( ( h_Attacker:IsPlayer() and h_Attacker:Alive() ) or h_Attacker:IsNPC() ) then
		
			g_Attackers[ "r"..h_Attacker:EntIndex() ] = h_Attacker
			target.rParentReplicator.rResearch = true
			target.rParentReplicator:TakeDamage( dmginfo:GetDamage(), h_Attacker, h_Attacker )
			
		end

	end

end )

hook.Add( "KeyPress", "debug_render_rerpl", function( ply, key ) 

	if SERVER then
		
		if key == IN_WALK then
		
			print( table.Count( g_PathPoints ), table.Count( g_MetalPoints ), table.Count( g_DarkPoints ), table.Count( g_PointIsInvalid ), table.Count( g_Attackers ), table.Count( g_MetalPointsAsigned )  )
			//net.Start( "debug_keron_network" )
			//	net.WriteTable( g_PathPoints )
			//net.Broadcast()
			
		end
		
		//if key == IN_RUN then PrintTable( g_MetalPoints ) end
		
		//if key == IN_RELOAD then endPOS = ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 10 print( endPOS ) end
		
		/*
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
		*/
	end
	
	if CLIENT then
	
		if key == IN_RELOAD then
			g_PathPoints = { }
		end
	end
end )


hook.Add( "PostCleanupMap", "CNR_Cleanup", function( )

	g_PathPoints = { }
	g_MetalPoints = { }
	m_DebugLink = { }
	g_DarkPoints = { }
	g_MetalPointsAsigned = { }
	g_Attackers = { }
	
	g_QueenCount = { }
	g_WorkersCount = { }
	g_PointIsInvalid = { }
	
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

	
	function FindClosestPoint( pos, rad )
	
		local t_Dist = 0

		local t_Case = ""
		local t_Index = 0
		
		local t_pathPoints = {}
				
		for x = -1 * rad, 1 * rad do
		for y = -1 * rad, 1 * rad do
		for z = -1 * rad, 1 * rad do

			local coord, sCoord = REPLICATOR.ConvertToGrid( pos + Vector( x, y, z ) * 100, 100 )

			if g_PathPoints[ sCoord ] then table.Add( t_pathPoints, g_PathPoints[ sCoord ] ) end
			
		end
		end
		end
		
		local t_First = true
		
		for k, v in pairs( t_pathPoints ) do
			local tracer = REPLICATOR.TraceLine( v.pos, pos, g_ReplicatorNoCollideGroupWith )
			
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
			
			if g_PathPoints[ v.case ] and g_PathPoints[ v.case ][ v.index ] and g_PathPoints[ v.case ][ v.index ].connection then
				local pPoint = g_PathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = REPLICATOR.TraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), g_ReplicatorNoCollideGroupWith )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then g_PathPoints[ v.case ][ v.index ].ent = trace.Entity
						else g_PathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( g_PointIsInvalid[ v.case ] and g_PointIsInvalid[ v.case ][ v.index ] and g_PointIsInvalid[ v.case ][ v.index ] < 10 )
						or not g_PointIsInvalid[ v.case ] or ( g_PointIsInvalid[ v.case ] and not g_PointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then
				
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
	
	function GetPatchWayToClosestEnt( start, entTable )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if g_PathPoints[ v.case ] and g_PathPoints[ v.case ][ v.index ] and g_PathPoints[ v.case ][ v.index ].connection then
				local pPoint = g_PathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = REPLICATOR.TraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), g_ReplicatorNoCollideGroupWith )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then g_PathPoints[ v.case ][ v.index ].ent = trace.Entity
						else g_PathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( g_PointIsInvalid[ v.case ] and g_PointIsInvalid[ v.case ][ v.index ] and g_PointIsInvalid[ v.case ][ v.index ] < 10 )
						or not g_PointIsInvalid[ v.case ] or ( g_PointIsInvalid[ v.case ] and not g_PointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then
				
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
									and not REPLICATOR.TraceLine( t_v2pos, v3:GetPos(), g_ReplicatorNoCollideGroupWith ).Hit 
										and REPLICATOR.TraceHoles( t_v2pos, v3:GetPos(), 50, Vector( 0, 0, -25 ), Vector( 5, 5, 5 ) ) then
									
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
		
		MsgC( Color( 255, 255, 0 ), "Doesn't founded closest ENT\n" )
		
		return {}, Entity( 0 )
	end

	function GetPatchWayToClosestId( start )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if g_PathPoints[ v.case ] and g_PathPoints[ v.case ][ v.index ] and g_PathPoints[ v.case ][ v.index ].connection then
				local pPoint = g_PathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = REPLICATOR.TraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), g_ReplicatorNoCollideGroupWith )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then g_PathPoints[ v.case ][ v.index ].ent = trace.Entity
						else g_PathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( g_PointIsInvalid[ v.case ] and g_PointIsInvalid[ v.case ][ v.index ] and g_PointIsInvalid[ v.case ][ v.index ] < 10 )
						or not g_PointIsInvalid[ v.case ] or ( g_PointIsInvalid[ v.case ] and not g_PointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then
				
					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							local v2pos = pPoint.pos
							
							for k3, v3 in pairs( g_DarkPoints ) do
								
								if not v3.used and v2pos:Distance( v3.pos ) < 500
									and not REPLICATOR.TraceLine( v2pos, v3.pos, g_ReplicatorNoCollideGroupWith ).Hit 
										and REPLICATOR.TraceHoles( v2pos, v3.pos, 50, Vector( 0, 0, -25 ), Vector( 5, 5, 5 ) ) then
									
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

		MsgC( Color( 255, 255, 0 ), "Doesn't founded closest index\n" )
		
		return {}, 0
	end

	function GetPatchWayToClosestMetal( start )

		local t_Links = { }
		local t_LinksAvailable = { }
		local t_LinksHistory = { }
		
		t_Links = { { case = start.case, index = start.index } }
		t_LinksAvailable[ start.case.."|"..start.index ] = true
		
		t_LinksHistory[ start.case ] = {}
		t_LinksHistory[ start.case ][ start.index ] = { { case = start.case, index = start.index } }

		for k, v in pairs( t_Links ) do
			
			if g_PathPoints[ v.case ] and g_PathPoints[ v.case ][ v.index ] and g_PathPoints[ v.case ][ v.index ].connection then
				local pPoint = g_PathPoints[ v.case ][ v.index ]
				
				local t_Next = false
				
				if ( pPoint.ent and pPoint.ent:IsValid() and pPoint.ent:GetPos():Distance( pPoint.pos ) < pPoint.ent:GetModelRadius() * 1.5 ) or not pPoint.ent then t_Next = true
				elseif pPoint.ent then
				
					local trace = REPLICATOR.TraceHullQuick( 
						pPoint.pos, Vector(),
						Vector( 10, 10, 10 ), g_ReplicatorNoCollideGroupWith )
						
					if trace.Hit then
						
						if trace.Entity:IsValid() then g_PathPoints[ v.case ][ v.index ].ent = trace.Entity
						else g_PathPoints[ v.case ][ v.index ].ent = nil end
						
						t_Next = true
						
					end
					
				end
				
				if ( ( g_PointIsInvalid[ v.case ] and g_PointIsInvalid[ v.case ][ v.index ] and g_PointIsInvalid[ v.case ][ v.index ] < 10 )
						or not g_PointIsInvalid[ v.case ] or ( g_PointIsInvalid[ v.case ] and not g_PointIsInvalid[ v.case ][ v.index ] ) ) and t_Next then				

					for k2, v2 in pairs( pPoint.connection ) do

						if not t_LinksAvailable[ v2.case.."|"..v2.index ] then
						
							table.Add( t_Links, { { case = v2.case, index = v2.index } } )
							t_LinksAvailable[ v2.case.."|"..v2.index ] = true
							
							if not t_LinksHistory[ v2.case ] then t_LinksHistory[ v2.case ] = {} end
							
							t_LinksHistory[ v2.case ][ v2.index ] = { { case = v2.case, index = v2.index } }
							table.Add( t_LinksHistory[ v2.case ][ v2.index ], t_LinksHistory[ v.case ][ v.index ] )
							
							local v2pos = pPoint.pos
							
							for k3, v3 in pairs( g_MetalPoints ) do
							
								if v3.ent then
								
									if v3.ent:IsValid() then
									
										local v3pos = v3.ent:WorldSpaceCenter()
												
										if v2pos:Distance( v3pos ) < 500 
											and not REPLICATOR.TraceLine( v2pos, v3pos, g_ReplicatorNoCollideGroupWith, { v3.ent } ).Hit
												and REPLICATOR.TraceHoles( v2pos, v3pos, 50, Vector( 0, 0, -25 ), Vector( 5, 5, 5 ) ) then
											
											return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3pos } ), k3
											
										end
									else table.remove( g_MetalPoints, ""..v3.ent:EntIndex() ) end
									
								else

									local v3pos = v3.pos
									
									if not v3.used and v2pos:Distance( v3pos ) < 500
										and not REPLICATOR.TraceLine( v3pos, v2pos, g_ReplicatorNoCollideGroupWith ).Hit then
									
										return table.Add( table.Reverse( t_LinksHistory[ v2.case ][ v2.index ] ), { v3pos } ), k3
										
									end
								end
							end
						end
					end
				end
			end

			t_LinksHistory[ v.case ][ v.index ] = { }
			
		end

		MsgC( Color( 255, 255, 0 ), "Doesn't founded closest Metal\n" )
		
		return {}, 0
	end
	
	function AddMetalPoint( _stringp, _pos, _normal, _amount )
		
		g_MetalPoints[ _stringp ] = { pos = _pos, normal = _normal, amount = _amount, used = false }
		g_MetalPointsAsigned[ _stringp ] = true
		
		local t_tracer = REPLICATOR.TraceQuick( _pos, -_normal * 20, g_ReplicatorNoCollideGroupWith )
				
		net.Start( "CNR_AddMetalPoint" )
			net.WriteString( _stringp )
			net.WriteTable( { pos = t_tracer.HitPos, normal = t_tracer.HitNormal, amount = _amount, used = false } )
		net.Broadcast()
		
	end

	function UpdateMetalPoint( _stringp, _amount )
	
		g_MetalPoints[ _stringp ].amount = _amount

		net.Start( "CNR_UpdateMetalPoint" ) net.WriteString( _stringp ) net.WriteFloat( _amount ) net.Broadcast()
		
	end
		
	function AddMetalEntity( _ent )

		local _amount = ( _ent:GetModelRadius() * _ent:GetPhysicsObject():GetMass() ) / 100
		print( _amount )
		
		g_MetalPoints[ _ent ] = { ent = _ent, amount = _amount }
		g_MetalPointsAsigned[ _ent:EntIndex() ] = true

		net.Start( "CNR_AddMetalEntity" )
			net.WriteEntity( _ent )
			net.WriteTable( { ent = _ent, amount = _amount, used = false } )
		net.Broadcast()
		
	end
	
	function UpdateMetalEntity( _ent, _amount )
	
		g_MetalPoints[ _ent ].amount = _amount
		net.Start( "CNR_UpdateMetalEntity" ) net.WriteEntity( _ent ) net.WriteFloat( _amount ) net.Broadcast()
		
	end
		
	function AddPathPoint( _pos, _connection, _ent )
	
		local merge = false
		local t_Mergered = false
		local returnID
		
		local t_pathPoints = {}
		
		for x = -1, 1 do
		for y = -1, 1 do
		for z = -1, 1 do

			local coord, sCoord = REPLICATOR.ConvertToGrid( _pos + Vector( x, y, z ) * 80, 100 )
			
			if g_PathPoints[ sCoord ] then table.Add( t_pathPoints, g_PathPoints[ sCoord ] ) end
			
		end
		end
		end
		
		if table.Count( _connection ) > 0 then

			for k2, v2 in pairs( _connection ) do
			
				for k, v in pairs( t_pathPoints ) do
				
					local v2pos = g_PathPoints[ v2.case ][ v2.index ].pos
					
					//print( v.case, v.index, v2.case, v2.index, v.pos:Distance( _pos ), not ( v.case == v2.case and v.index == v2.index ), ( v.pos:Distance( _pos ) < 10 and not REPLICATOR.TraceLine( v.pos, _pos, g_ReplicatorNoCollideGroupWith ).Hit ) )
					
					if not ( v.case == v2.case and v.index == v2.index ) 
						and ( ( v.pos:Distance( _pos ) < 50 and not REPLICATOR.TraceLine( v.pos, v2pos, g_ReplicatorNoCollideGroupWith ).Hit ) 
							or ( v.pos:Distance( _pos ) < 10 and not REPLICATOR.TraceLine( v.pos, _pos, g_ReplicatorNoCollideGroupWith ).Hit ) ) then
					
						if not g_PathPoints[ v.case ][ v.index ].connection[ v2.case.."|"..v2.index ] then
						
							g_PathPoints[ v.case ][ v.index ].connection[ v2.case.."|"..v2.index ] = { case = v2.case, index = v2.index }
							g_PathPoints[ v2.case ][ v2.index ].connection[ v.case.."|"..v.index ] = { case = v.case, index = v.index }

							//table.Add( g_PathPoints[ v.case ][ v.index ].connection, {{ case = v2.case, index = v2.index }} )
							//table.Add( g_PathPoints[ v2.case ][ v2.index ].connection, {{ case = v.case, index = v.index }} )
							
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
				
				if g_PathPoints[ r_Case ][ r_Index ].pos:Distance( _pos ) < 50 and not REPLICATOR.TraceLine( _pos, g_PathPoints[ r_Case ][ r_Index ].pos, g_ReplicatorNoCollideGroupWith ).Hit then
					
					merge = true
					returnID = { case = r_Case, index = r_Index }
					
				end
			end
		end
		
		if not merge then
			
			local coord, sCoord = REPLICATOR.ConvertToGrid( _pos, 100 )

			if g_PathPoints[ sCoord ] then
			
				m_ID = table.Count( g_PathPoints[ sCoord ] ) + 1
				
			else
			
				m_ID = 1
				g_PathPoints[ sCoord ] = {}
				
			end
			
			returnID = { case = sCoord, index = m_ID }
			
			if _ent and _ent:IsValid() then table.Add( g_PathPoints[ sCoord ], {{ pos = _pos, connection = {}, case = sCoord, index = m_ID, ent = _ent }} )
			else table.Add( g_PathPoints[ sCoord ], {{ pos = _pos, connection = {}, case = sCoord, index = m_ID }} ) end
			
			for k, v in pairs( _connection ) do
			
				//local result = REPLICATOR.TraceLine( _pos, g_PathPoints[ v.case ][ v.index ].pos, g_ReplicatorNoCollideGroupWith )

				//if not result.Hit then

					g_PathPoints[ v.case ][ v.index ].connection[ sCoord.."|"..m_ID ] = { case = sCoord, index = m_ID }
					g_PathPoints[ sCoord ][ m_ID ].connection[ v.case.."|"..v.index ] = { case = v.case, index = v.index }
					
					//table.Add( g_PathPoints[ v.case ][ v.index ].connection, {{ case = sCoord, index = m_ID }} )
					//table.Add( g_PathPoints[ sCoord ][ m_ID ].connection, {{ case = v.case, index = v.index }} )

					//PrintMessage( HUD_PRINTTALK, m_ID )
					
				//end
				
			end
			
		end
		
		//PrintTable( returnID )
		return returnID, t_Mergered
	end

if SERVER then

	net.Receive( "rDark_points", function() g_DarkPoints[ net.ReadString() ] = { pos = net.ReadVector(), used = false } end )		
	
end // SERVER


hook.Add("Think", "CNR_Think", function( )
	
	if SERVER then
		
		if game.SinglePlayer() then
			
			for k, v in pairs( g_Replicators ) do
			
				local h_Phys = v:GetPhysicsObject()
				local h_Offset = v.rOffset
				local h_AngleOffset = v.rAngleOffset
				
				if h_Offset != Vector() and h_AngleOffset != Angle() then
				
					h_Phys:SetPos( h_Phys:GetPos() + h_Offset )
					h_Phys:SetAngles( v:LocalToWorldAngles( h_AngleOffset ) )
					
				end
			end
		end
	end // SERVER
	
	if CLIENT then	
	end // CLIENT
	
end )

if CLIENT then

	function AddDarkPoint( _stringp, _pos )
	
		g_DarkPoints[ _stringp ] = { pos = _pos, used = false }
		
		net.Start( "rDark_points" )
			net.WriteString( _stringp )
			net.WriteVector( _pos )
		net.SendToServer()
		
	end
	
end // CLIENT

hook.Add( "PostDrawTranslucentRenderables", "CNR_PDTRender", function()
	
	net.Receive( "CNR_UpdateMetalPoint", function() g_MetalPoints[ net.ReadString() ].amount = net.ReadFloat() end )
	net.Receive( "CNR_UpdateMetalEntity", function() g_MetalPoints[ net.ReadEntity() ].amount = net.ReadFloat() end )
	
	net.Receive( "CNR_AddMetalPoint", function() g_MetalPoints[ net.ReadString() ] = net.ReadTable() end )
	net.Receive( "CNR_AddMetalEntity", function() g_MetalPoints[ net.ReadEntity() ] = net.ReadTable() end )

	net.Receive( "debug_keron_network", function() g_PathPoints = net.ReadTable() end )
	for k, v in pairs( g_PathPoints ) do
	
		render.SetMaterial( Material( "models/wireframe" ) )
		
		for k2, v2 in pairs( v ) do

			render.SetColorMaterial()
			if v2.ent then render.DrawBox( v2.pos, Angle( ), -Vector( 2, 2, 2 ), Vector( 2, 2, 2 ), Color( 255, 0, 0, 50 ), false ) 
			else render.DrawBox( v2.pos, Angle( ), -Vector( 2, 2, 2 ), Vector( 2, 2, 2 ), Color( 255, 255, 255, 50 ), false ) end
			
			for k3, v3 in pairs( v2.connection ) do
			
				if g_PathPoints[ v3.case ] then

					local p = g_PathPoints[ v3.case ][ v3.index ]
					local vec = ( v2.pos - p.pos ):Angle()
					
					render.DrawLine( v2.pos + vec:Right() / 2, p.pos + vec:Right() / 2, Color( 255, 255, 255, 50 ), false )
					
				end				
			end
		end
	end
	
	for k, v in pairs( g_DarkPoints ) do
	
		render.SetColorMaterial()
		render.SetBlend( 1 )
		
		render.DrawBox( v.pos, Angle( ), -Vector( 5, 5, 0 ), Vector( 5, 5, 0 ), Color( 255, 255, 255, 10 ), true ) 
		
	end
	
	for k, v in pairs( g_MetalPoints ) do

		local t_Radius = ( 1 - math.exp( -( ( 1 - v.amount / 100 ) * 10 ) / 2 ) ) * 20

		if not v.ent then
		
			render.SetMaterial( Material( "rust/rusty_spot" ) )
			render.DrawQuadEasy( v.pos, v.normal, t_Radius, t_Radius, Color( 255, 255, 255 ), t_Radius * 128 ) 
			
		elseif v.ent:IsValid() and false then
			render.SetMaterial( Material( "rust/rusty_paint" ) )
		
			if not v.ent.model then
			
				local ent = ClientsideModel( v.ent:GetModel(), RENDERGROUP_OPAQUE_BRUSH )
				ent:SetNoDraw( true )
				ent:SetMaterial( Material( "models/shiny" ) )
				v.ent.model = ent
				
			end
			
			v.ent.model:SetPos( v.ent:LocalToWorld( Vector( 0, 0, 0 ) ) )
			v.ent.model:SetAngles( v.ent:LocalToWorldAngles( Angle( 0, 0, 0 ) ) )
			v.ent.model:SetupBones()
			v.ent.model:DrawModel()
			
		end
	end
	

	net.Receive( "debug_render_rerpl", function() m_DebugLink = net.ReadTable() end )
	
	for k, v in pairs( m_DebugLink ) do
	
		render.SetColorMaterial()
		render.DrawBox( g_PathPoints[ v.case ][ v.index ].pos, Angle( 45, 45 ,45 ), -Vector( 1, 1, 1 ) * ( 1 + k / 100 ), Vector( 1, 1, 1 ) * ( 1 + k / 100 ), Color( 0, 0, 255 ), false ) 
		
	end
	
end )