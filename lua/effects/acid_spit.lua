
function EFFECT:Init( data )

	self.Start = data:GetOrigin()
	self.Direction = data:GetNormal()
	self.Emitter = ParticleEmitter( self.Start )
		
	for i = 1, 40 do
	
		local vec = VectorRand()
		vec = Vector( vec.x, vec.y, 0 )
		vec:Rotate( self.Direction:Angle() + Angle( 90, 0, 0 ) )

		local p = self.Emitter:Add( "sprites/light_glow02_add", self.Start )

		p:SetDieTime( math.random( 1, 1.5 ) )
		p:SetStartAlpha( math.random( 200, 255 ) )
		p:SetEndAlpha( 0 )
		p:SetStartSize( math.random( 1, 2 ) )
		p:SetEndSize( 0 )
		p:SetRoll( math.Rand( -10, 10 ) )
		p:SetRollDelta( math.Rand( -10, 10 ) )
		p:SetVelocity( vec * 15 )
		p:SetGravity( -vec * 15 + VectorRand() * 7 )
		p:SetColor( 150 + math.random( 0, 50 ), 200 + math.random( 0, 55 ), 75 + math.random( 0, 25 ) )
		p:SetCollide( true )
		
	end

	for i = 1, 20 do
	
		local vec = VectorRand()
		vec = Vector( vec.x, vec.y, 0 )
		vec:Rotate( self.Direction:Angle() + Angle( 90, 0, 0 ) )
		
		local p = self.Emitter:Add("particle/smokesprites_000" .. math.random( 1, 9 ), self.Start + vec )

		p:SetDieTime( math.random( 1, 1.5 ) )
		p:SetStartAlpha( math.random( 200, 255 ) )
		p:SetEndAlpha( 0 )
		p:SetStartSize( math.random( 3, 5 ) )
		p:SetEndSize( math.random( 3, 5 ) )
		p:SetRoll( math.Rand( 0, 360 ) )
		p:SetRollDelta( math.Rand( -3, 3 ) )
		p:SetVelocity( vec * 6 )
		p:SetGravity( Vector( 0, 0, math.Rand( 1, 5 ) ) )
		p:SetColor( 150 + math.random( 0, 50 ), 200 + math.random( 0, 55 ), 75 + math.random( 0, 25 ) )
		p:SetCollide( true )
		
	end
	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

	//render.SetMaterial( Material( "sprites/light_ignorez" ) )
	//render.DrawSprite( self.Start, self.size, self.size, Color( 255, 100, 0, 50 ) )
	
end
