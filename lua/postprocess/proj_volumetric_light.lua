-- Akabenko&Jaymun
-- https://developer.valvesoftware.com/wiki/Env_projectedtexture

local shaderName = "ProjVolumetricLight"

local r_proj_volumetric = CreateClientConVar( "r_proj_volumetric", "0", true, false, "Enable/Disable Volimetric light for Projected Textures.", 0, 1 )
local r_proj_volumetric_debug = CreateClientConVar( "r_proj_volumetric_debug", "0", false, false, "Enable/Disable debug mode for volumetric light.", 0, 2 )
local r_proj_volumetric_noshadows = CreateClientConVar( "r_proj_volumetric_noshadows", "0", true, false, "Draw volumetric light from lamps with no shadows.", 0, 1 )
local r_proj_volumetric_mul = CreateClientConVar( "r_proj_volumetric_mul", "0.0", true, false, "Enable/Disable upsampling for volumetric light.", 0, 10 )
local r_proj_volumetric_add = CreateClientConVar( "r_proj_volumetric_add", "0.1", true, false, "Enable/Disable upsampling for volumetric light.", 0, 10 )
local r_proj_volumetric_add_proj = CreateClientConVar( "r_proj_volumetric_add_proj", "0.3", true, false, "Enable/Disable upsampling for volumetric light.", 0, 10 )
local r_scattering = CreateClientConVar( "r_scattering", "0.2",  true, false, "Mie scaterring approximated with Henyey-Greenstein phase function.", 0, 0.99 )
local r_proj_volumetric_dist = CreateClientConVar( "r_proj_volumetric_dist", "192", true, false, "Near fade factor for Projected Volumetric light.", 1, 512 )
local r_proj_volumetric_quad = CreateClientConVar( "r_proj_volumetric_quad", "0", true, false, "Ultra downsampling for Proj Volumetric light.", 0, 1 )

list.Set( "PostProcess", "#r_proj_volumetric.name", {
	icon = "gui/postprocess/r_proj_volumetric.jpg"; convar = r_proj_volumetric:GetName(); category = "#shaders_pp";
	["cpanel"] = function( panel )

		panel:AddControl( "ComboBox", {
			["MenuButton"] = 1,
			["Folder"] = "proj_volumetric",
			["Options"] = {
				[ "#preset.default" ] = {
					[ r_proj_volumetric:GetName() ]				= r_proj_volumetric:GetDefault(),
					[ r_proj_volumetric_debug:GetName() ]		= r_proj_volumetric_debug:GetDefault(),
					[ r_proj_volumetric_mul:GetName() ] 		= r_proj_volumetric_mul:GetDefault(),
					[ r_proj_volumetric_add:GetName() ] 		= r_proj_volumetric_add:GetDefault(),
                    [ r_proj_volumetric_add_proj:GetName() ]    = r_proj_volumetric_add_proj:GetDefault(),
                    [ r_scattering:GetName() ]                  = r_scattering:GetDefault(),
                    [ r_proj_volumetric_dist:GetName() ]        = r_proj_volumetric_dist:GetDefault(),
                    [ r_proj_volumetric_noshadows:GetName() ]   = r_proj_volumetric_noshadows:GetDefault(),
                    [ r_proj_volumetric_quad:GetName() ]        = r_proj_volumetric_quad:GetDefault(),
				}
			},
			["CVars"] = {
				r_proj_volumetric:GetName(),
				r_proj_volumetric_debug:GetName(),
				r_proj_volumetric_mul:GetName(),
				r_proj_volumetric_add:GetName(),
                r_proj_volumetric_add_proj:GetName(),
                r_scattering:GetName(),
                r_proj_volumetric_dist:GetName(),
                r_proj_volumetric_noshadows:GetName(),
                r_proj_volumetric_quad:GetName(),
			}
		} )

		panel:AddControl( "CheckBox", { Label = "#r_proj_volumetric.enable", Command = r_proj_volumetric:GetName() } )
        panel:AddControl( "CheckBox", { Label = "#r_proj_volumetric.noshadows", Command = r_proj_volumetric_noshadows:GetName(), Help = true } )

        panel:AddControl( "CheckBox", { Label = "#r_proj_volumetric.quad", Command = r_proj_volumetric_quad:GetName(), Help = true } )

        panel:AddControl( "Slider", {
            ["Label"] = "#r_proj_volumetric.dist",
            ["Command"] = r_proj_volumetric_dist:GetName(),
            ["Min"] = tostring( r_proj_volumetric_dist:GetMin() ),
            ["Max"] = tostring( r_proj_volumetric_dist:GetMax() ),
            ["Type"] = "Float",
        } )

        panel:Help( "#r_proj_volumetric.perspective" )
        
        panel:AddControl( "Slider", {
            ["Label"] = "#r_proj_volumetric.add",
            ["Command"] = r_proj_volumetric_add_proj:GetName(),
            ["Min"] = tostring( r_proj_volumetric_add_proj:GetMin() ),
            ["Max"] = tostring( r_proj_volumetric_add_proj:GetMax() ),
            ["Type"] = "Float",
        } )
        
        panel:Help( "#r_proj_volumetric.ortho_csm" )
        
		panel:AddControl( "Slider", {
			["Label"] = "#r_proj_volumetric.mul",
			["Command"] = r_proj_volumetric_mul:GetName(),
			["Min"] = tostring( r_proj_volumetric_mul:GetMin() ),
			["Max"] = tostring( r_proj_volumetric_mul:GetMax() ),
			["Type"] = "Float",
		} )

		panel:AddControl( "Slider", {
			["Label"] = "#r_proj_volumetric.add",
			["Command"] = r_proj_volumetric_add:GetName(),
			["Min"] = tostring( r_proj_volumetric_add:GetMin() ),
			["Max"] = tostring( r_proj_volumetric_add:GetMax() ),
			["Type"] = "Float",
		} )

        panel:AddControl( "Slider", {
            ["Label"] = "#r_proj_volumetric.scattering",
            ["Command"] = r_scattering:GetName(),
            ["Min"] = tostring( r_scattering:GetMin() ),
            ["Max"] = tostring( r_scattering:GetMax() ),
            ["Type"] = "Float",
        } )
        
        panel:AddControl( "combobox", {
            ["Label"] = "#r_proj_volumetric.debug",
            ["Command"] = r_proj_volumetric_debug:GetName(),
            ["Options"] = {
                [ "#r_proj_volumetric.view_disabled" ] = {
                    [ r_proj_volumetric_debug:GetName() ] = "0",
                },

                [ "#r_proj_volumetric.view_colors" ] = {
                    [ r_proj_volumetric_debug:GetName() ] = "1",
                },

                [ "#r_proj_volumetric.view_frustrum" ] = {
                    [ r_proj_volumetric_debug:GetName() ] = "2",
                },
            },
            ["CVars"] = {
                r_proj_volumetric_debug:GetName(),
            },
            ["Help"] = false,
        } )
	end
} )

local ultra_downsampling = r_proj_volumetric_quad:GetBool()
local downsample = true
local scale = downsample and 0.5 or 1

local rt_size = ultra_downsampling and RT_SIZE_HDR or RT_SIZE_LITERAL
local rt_flags = bit.bor(1,4,8,256,512) -- не факт, что POINTSAMPLE флаг нужен
local rt_hdr = render.GetHDREnabled() and CREATERENDERTARGETFLAGS_HDR or 0
local rt_w, rt_h = ScrW() * scale, ScrH() * scale

local rt = GetRenderTargetEx("_rt_VolumetricProj", rt_w, rt_h,
    rt_size,MATERIAL_RT_DEPTH_NONE, rt_flags,
    rt_hdr,
    IMAGE_FORMAT_RGBA16161616F
)

local rt2 = GetRenderTargetEx("_rt_VolumetricProj_filter", rt_w, rt_h,
    rt_size,MATERIAL_RT_DEPTH_NONE, rt_flags,
    rt_hdr,
    IMAGE_FORMAT_RGBA16161616F
)


local mat = Material("pp/proj_volumetric")
local mat_shadowmap = Material("pp/proj_volumetric_shadowmap")
local mat_csm = Material("pp/proj_volumetric_csm")
local mat_blur_h = Material("pp/proj_volumetric_blurx")
local mat_blur_v = Material("pp/proj_volumetric_blury")
-- TODO: Calc Volumetric in BOX

local mat_up = ultra_downsampling and Material("pp/proj_volumetric_upsampling_quad") or Material("pp/proj_volumetric_upsampling")
local mat_up_csm = ultra_downsampling and Material("pp/proj_volumetric_csm_upsampling_quad") or Material("pp/proj_volumetric_csm_upsampling")

local screeneffects = render.GetScreenEffectTexture()

local function setFloat(k,v)
    mat_csm:SetFloat( k,v )
    mat:SetFloat( k,v )
    mat_shadowmap:SetFloat( k,v )
    mat_up:SetFloat( k,v )
    mat_up_csm:SetFloat( k,v )
end

local m_nMaxDepthTextureShadows = 8 -- 0 .. 7

local shadow_i = 0
while true do  -- detect using -numshadowtextures
    local t = "_rt_shadowdepthtexture_" .. shadow_i
    local mat = CreateMaterial(t, "UnlitGeneric") 
    mat:SetTexture("$basetexture", t)
    if !mat or mat:IsError() then break end
    local tex = mat:GetTexture("$basetexture")
    if !tex or tex:IsError() or tex:IsErrorTexture() then break end
    shadow_i = shadow_i + 1
end

m_nMaxDepthTextureShadows = shadow_i
-- print(m_nMaxDepthTextureShadows)
ENV_PROJTEXS = ENV_PROJTEXS or {}
ENV_PROJTEXS_I = ENV_PROJTEXS_I or {}

local target_class = "_EnvProjectedTexture"

hook.Add("OnEntityCreated", shaderName, function(ent)
	local class = ent:GetClass()

    if !class:find(target_class) then return end
	local index = ent:EntIndex()

	local i = #ENV_PROJTEXS + 1
	ENV_PROJTEXS[i] = ent
	ENV_PROJTEXS_I[index] = i
end)

hook.Add("EntityRemoved", shaderName, function(ent)
	local class = ent:GetClass()

    if !class:find(target_class) then return end
	local index = ent:EntIndex()

	local i = ENV_PROJTEXS_I[index]
	table.remove(ENV_PROJTEXS, i)
	ENV_PROJTEXS_I[index] = nil
end)

local viewSetup = {
	aspect = 1;
	x = 0; y = 0;
	origin = vector_origin;
	angles = angle_zero;
	fov = 60;
}

local hookname = "RenderScreenspaceEffects"

local function Vector3DMultiplyPositionProjective(matrix, src) 
    if !matrix then return vector_origin end -- attempt to index local 'matrix' (à nil value) (NPC ARCCW weapons)
    local x = matrix:GetField(1, 1) * src.x + matrix:GetField(1, 2) * src.y + matrix:GetField(1, 3) * src.z + matrix:GetField(1, 4)
    local y = matrix:GetField(2, 1) * src.x + matrix:GetField(2, 2) * src.y + matrix:GetField(2, 3) * src.z + matrix:GetField(2, 4)
    local z = matrix:GetField(3, 1) * src.x + matrix:GetField(3, 2) * src.y + matrix:GetField(3, 3) * src.z + matrix:GetField(3, 4)
    local w = matrix:GetField(4, 1) * src.x + matrix:GetField(4, 2) * src.y + matrix:GetField(4, 3) * src.z + matrix:GetField(4, 4)
    
    if w ~= 0.0 then
        w = 1.0 / w
    end
    
    return Vector(x * w, y * w, z * w)
end

local corners_aabb = {
    Vector(-1, -1, -1), Vector(-1, -1, 1),
    Vector(-1,  1, -1), Vector(-1,  1, 1),
    Vector( 1, -1, -1), Vector( 1, -1, 1),
    Vector( 1,  1, -1), Vector( 1,  1, 1)
}

local function CalculateAABBFromProjectionMatrixInverse(volumeToWorld)
    local mins = Vector(99999, 99999, 99999)
    local maxs = Vector(-99999, -99999, -99999)

    for _, corner in ipairs(corners_aabb) do
        local worldPos = Vector3DMultiplyPositionProjective(volumeToWorld, corner)
        mins.x = math.min(mins.x, worldPos.x)
        mins.y = math.min(mins.y, worldPos.y)
        mins.z = math.min(mins.z, worldPos.z)
        maxs.x = math.max(maxs.x, worldPos.x)
        maxs.y = math.max(maxs.y, worldPos.y)
        maxs.z = math.max(maxs.z, worldPos.z)
    end
    
    return mins, maxs
end

local t0 = {0,0,-1,0}

local function GetProjMatrix(fov, aspect, znear, zfar)
    local f = math.cot(math.rad(fov) * 0.5)
    local range = znear - zfar

    return Matrix({
        --{f / aspect, 0, 0, 0},
        {f, 0, 0, 0},
        {0, f, 0, 0},
        {0, 0, (zfar + znear) / range, (2 * znear * zfar) / range},
        t0
    })
end

local function GetFrustumAABB(pos, ang, fov, aspect, znear, zfar)
    local matView = shaderlib.GetViewMatrix(pos,ang)
    local matProj = GetProjMatrix(fov, aspect, znear, zfar)
    local matViewProj = matProj * matView
    local volumeToWorld = matViewProj:GetInverse()
    return CalculateAABBFromProjectionMatrixInverse(volumeToWorld)
end

local function IsAABBIntersectingFrustum(mins, maxs, viewSetup)
    local camOrigin = viewSetup.origin
    local camForward = viewSetup.angles:Forward()
    local camRight = viewSetup.angles:Right()
    local camUp = viewSetup.angles:Up()
    
    local fovRad = math.rad(viewSetup.fov)
    local fovYRad = 2 * math.atan(math.tan(fovRad * 0.5) / viewSetup.aspect)
    
    local farDist = viewSetup.zfar
    local farCenter = camOrigin + camForward * farDist
    local farHalfWidth = math.tan(fovRad * 0.5) * farDist
    local farHalfHeight = math.tan(fovYRad * 0.5) * farDist
    
    local ftl = farCenter + camUp * farHalfHeight - camRight * farHalfWidth
    local ftr = farCenter + camUp * farHalfHeight + camRight * farHalfWidth
    local fbl = farCenter - camUp * farHalfHeight - camRight * farHalfWidth
    local fbr = farCenter - camUp * farHalfHeight + camRight * farHalfWidth
    
    local planes = {}
    
    local dir1 = (ftr - camOrigin):GetNormalized()
    local dir2 = (fbr - camOrigin):GetNormalized()
    planes[BOX_RIGHT] = {
        normal = dir1:Cross(dir2):GetNormalized();
        dist = -dir1:Cross(dir2):GetNormalized():Dot(camOrigin)
    }
    
    dir1 = (fbl - camOrigin):GetNormalized()
    dir2 = (ftl - camOrigin):GetNormalized()
    planes[BOX_LEFT] = {
        normal = dir1:Cross(dir2):GetNormalized();
        dist = -dir1:Cross(dir2):GetNormalized():Dot(camOrigin)
    }
    
    dir1 = (ftl - camOrigin):GetNormalized()
    dir2 = (ftr - camOrigin):GetNormalized()
    planes[BOX_TOP] = {
        normal = dir1:Cross(dir2):GetNormalized();
        dist = -dir1:Cross(dir2):GetNormalized():Dot(camOrigin)
    }
    
    dir1 = (fbr - camOrigin):GetNormalized()
    dir2 = (fbl - camOrigin):GetNormalized()
    planes[BOX_BOTTOM] = {
        normal = dir1:Cross(dir2):GetNormalized();
        dist = -dir1:Cross(dir2):GetNormalized():Dot(camOrigin)
    }
    
    planes[BOX_FRONT] = {
        normal = camForward;
        dist = -camForward:Dot(camOrigin) - viewSetup.znear
    }

    planes[BOX_BACK] = {
        normal = -camForward;
        dist = camForward:Dot(camOrigin) + farDist
    }

    for i = BOX_FRONT, BOX_BOTTOM do
        local plane = planes[i]
        local pVertex = Vector(
            plane.normal.x >= 0 and maxs.x or mins.x,
            plane.normal.y >= 0 and maxs.y or mins.y,
            plane.normal.z >= 0 and maxs.z or mins.z
        )
        
        if plane.normal:Dot(pVertex) + plane.dist < 0 then
            return false
        end
    end
    
    return true
end

local n = 0
local shadowmap_textures = {}

local function EnableDebugMode()
    RunConsoleCommand("r_flashlightdrawfrustum", 1)
    --RunConsoleCommand("r_flashlightdrawfrustumbbox", 1)

	hook.Add("HUDPaint", shaderName, function()
		local cur_count = #ENV_PROJTEXS

		local count = 0
		render.RenderFlashlights(function()
		    count = count + 1
		end)

		local text1 = "Visible ProjectedTextures: " .. n .. "\nTotal ProjectedTextures: ".. cur_count .. "\nReal engine count: " .. count

		if DUMMY_FLASH then
			text1 = text1 .. "\nFlashlight skipped"
		end

		draw.DrawText(text1, "BudgetLabel", ScrW()*0.5, ScrH()*0.2, color_white, TEXT_ALIGN_CENTER)
		
		for i = 1, cur_count do
			local env_proj = ENV_PROJTEXS[i]
			if !IsValid(env_proj) then continue end
			local pos = env_proj:GetPos()
			local screen = pos:ToScreen()
			local x = screen.x
			local y = screen.y

			local text = "#" .. i .. " Shadowmap texture: ".. (shadowmap_textures[i] or "error")

			text = text .. "\n" .. "Texture Name: " .. (env_proj.tex or "error") .. "\n".. "Light Strength: " ..
			(env_proj.VolumetricIntensity or "error") .. "\nZNear: " .. (env_proj.znear or "error") .. " ZFar: " .. (env_proj.zfar or "error") .. " Fov: ".. (env_proj.hFov or "error") ..
            "\nEnabled: " .. (env_proj.state or "error")

			draw.DrawText(text, "BudgetLabel", screen.x, screen.y - i * ScrH()*0.015, color_white, TEXT_ALIGN_CENTER)

			surface.SetDrawColor(255,255,255)
    		surface.DrawRect( x - 18, y - 18, 16, 16 )
    		surface.SetDrawColor(0,0,0)
    		surface.DrawOutlinedRect( x - 20, y - 20, 20, 20 )
    		surface.DrawOutlinedRect( x - 18, y - 18, 16, 16 )
		end
	end)
end

DUMMY_FLASH = DUMMY_FLASH or false

local t_0001 = {0,   0,   0,   1}
local t_0000 = {0,0,0,0}

local function EnableProjVolumetric()
	
	if r_proj_volumetric_debug:GetInt() == 2 then
		EnableDebugMode()
	end

	hook.Add(hookname, shaderName, function()
        if !shaderlib.CanDrawEffects() then return end
        if !GetConVar("r_shadows"):GetBool() then return end
        if !GetConVar("r_flashlightdepthtexture"):GetBool() then return end

		local client = LocalPlayer()
		local flashlight_active = client:FlashlightIsOn()

		-- works bad
		if DUMMY_FLASH != false and !flashlight_active then -- баг
			table.remove(ENV_PROJTEXS, DUMMY_FLASH)
			DUMMY_FLASH = false
		end

		if DUMMY_FLASH == false and flashlight_active then
			local index_dummy = #ENV_PROJTEXS + 1
			DUMMY_FLASH = index_dummy
			ENV_PROJTEXS[index_dummy] = "dummy"
		end


		if !flashlight_active then -- TODO: FIX
			for i = 1,#ENV_PROJTEXS do
				if ENV_PROJTEXS[i] == "dummy" then
					table.remove(ENV_PROJTEXS, i)
				end
			end
		end

		local num = #ENV_PROJTEXS

		n = 0

		if num <= 0 then return end 

		local ply_viewsetup = render.GetViewSetup()

		local eyepos = EyePos()
		local eyeang = EyeAngles()
		local fov = ply_viewsetup.fov
		local ply_znear = ply_viewsetup.znear
		local ply_zfar = ply_viewsetup.zfar
		local aspect = ply_viewsetup.aspect

        local mdata = Matrix({
            {eyepos.x,eyepos.y,eyepos.z,0};
            {eyepos.y,0,0,0};
            {eyepos.z,0,0,0};
            t_0000;
        })

        mat_shadowmap:SetMatrix( "$INVVIEWPROJMAT", mdata)
        mat:SetMatrix("$INVVIEWPROJMAT", mdata)
        mat_csm:SetMatrix("$INVVIEWPROJMAT", mdata)

		--local cur_count = math.min( m_nMaxDepthTextureShadows, num )
        local cur_count = num

		local vector255 = Vector(255,255,255)

		local max_density = render.GetFogMaxDensity()
        setFloat("$c3_z", max_density)

        render.PushRenderTarget(rt)
        render.Clear(0,0,0,0)
        render.PopRenderTarget()

        render.UpdateScreenEffectTexture()
        render.CopyRenderTargetToTexture(screeneffects)

        local config_enable_shadows = r_proj_volumetric_noshadows:GetBool()

        local csm_dir, csm_color

		for i = 1, cur_count do
			local env_proj = ENV_PROJTEXS[i]
            if env_proj == "dummy" then n = n + 1 continue end -- TODO: Calc pos of flashlight
            if !IsEntity(env_proj) and !env_proj:IsValid() then table.remove(ENV_PROJTEXS, i) return end -- TODO: Confirm
			if IsEntity(env_proj) and !IsValid(env_proj) then table.remove(ENV_PROJTEXS, i) return end -- TODO: Remove
			if !env_proj then table.remove(ENV_PROJTEXS, i) continue end
			
			local client_lamp = !env_proj.EntIndex

            local enable_shadows = false

            if env_proj.GetEnableShadows then
                enable_shadows = env_proj:GetEnableShadows()
            else
                enable_shadows = env_proj:GetNWBool("enableshadows", false)
                env_proj.state = enable_shadows and 1 or 0

                local enabled = env_proj:GetNWBool("enabled", true)
                if !enabled then continue end
            end

			if !config_enable_shadows and !enable_shadows then continue end

            local is_client = env_proj.GetVerticalFOV
			
			local pos = env_proj:GetPos()
			local ang = env_proj:GetAngles()
			local hFov = env_proj.GetVerticalFOV and env_proj:GetVerticalFOV() or env_proj:GetNWFloat("FOV", 96.379997253418 )
			
			local znear = env_proj.GetNearZ and env_proj:GetNearZ() or env_proj:GetNWFloat("NEARZ", 12 )

			local zfar = env_proj.GetFarZ and env_proj:GetFarZ() or env_proj:GetNWFloat("FARZ", 2048 )
			if !client_lamp then
				env_proj.znear = znear
				env_proj.zfar = zfar
				env_proj.hFov = hFov
			end

            local ortho = false
            local csm = false

            local visible = true

            if client_lamp then
                local left, top, right, bottom
                ortho, left, top, right, bottom = env_proj:GetOrthographic()

                if ortho then
                    if RealCSM then
                        if RealCSM.Lamps and istable(RealCSM.Lamps) then -- Was Lua errors
                            for i2 = 1,#RealCSM.Lamps do
                                local lamp_csm = RealCSM.Lamps[i2]
                                if env_proj == lamp_csm then
                                    csm = true
                                end
                            end
                        end

                        viewSetup.ortho = {
                            left = left;
                            top = top;
                            right = right;
                            bottom = bottom;
                        }
                    end
                end
            end

            local lightColor = client_lamp and env_proj:GetColor() or env_proj:GetNWVector("COLOR", vector255) 
            
            if !csm then
                local mins, maxs = GetFrustumAABB(pos, ang, hFov, 1, znear, zfar)

                if r_proj_volumetric_debug:GetInt() == 2 then
                    --debugoverlay.Box(vector_origin, mins, maxs, 0.2, ColorAlpha(lightColor,5))
                    cam.Start3D()
                    render.SetColorMaterial()
                    cam.IgnoreZ( true )
                    render.CullMode( MATERIAL_CULLMODE_CW )
                    render.DrawBox( vector_origin, angle_zero, mins, maxs, ColorAlpha(lightColor,55) )
                    local col_line = ColorAlpha(lightColor,255)
                    render.DrawWireframeBox( vector_origin, angle_zero, mins, maxs, col_line )
                    cam.IgnoreZ( false )
                    render.CullMode( MATERIAL_CULLMODE_CCW )
                    cam.End3D()
                end

                visible = IsAABBIntersectingFrustum(mins, maxs, ply_viewsetup)
                viewSetup.fov = hFov
            end

			if !visible then continue end

			-- Skip Lamp by PVS check (costly). TODO: Optimize
			local pvs = NikNaks.CurrentMap:PVSCheck( pos, eyepos )

            if enable_shadows then
                n = n + 1
            end

            local enable_volumetric = is_client or env_proj:GetNWBool("volumetric", true)
            if !enable_volumetric then continue end

            if n > m_nMaxDepthTextureShadows then continue end -- max or shadowmap textures

			if !pvs and !csm then continue end -- remove PVS optimization for CSM

			viewSetup.origin = pos
            
            local cur_mat = csm and mat_csm or mat_shadowmap
            if !enable_shadows then
                cur_mat = mat
            end

            local lightpos = pos

            if csm then
                csm_color = lightColor
                csm_dir = -lightpos:GetNormalized()
                lightpos = csm_dir
            end

			cur_mat:SetFloat("$c2_x", lightpos.x)
			cur_mat:SetFloat("$c2_y", lightpos.y)
			cur_mat:SetFloat("$c2_z", lightpos.z)

			local shadowmap_tex = "_rt_shadowdepthtexture_" .. (n - 1)

			shadowmap_textures[i] = shadowmap_tex

			if !client_lamp then
				env_proj.shadowmap = shadowmap_tex
			end

            if enable_shadows then
                cur_mat:SetTexture("$texture1", shadowmap_tex )
            end

			local tex

			if client_lamp then
                tex = env_proj:GetTexture() or "effects/flashlight/logo"
            else
                tex = env_proj:GetNWString("SpotlightTexture")
                if tex == "" then continue end -- no texture info on client from server
				env_proj.tex = tex
			end

			cur_mat:SetTexture("$texture2", tex )

			viewSetup.angles = ang
			
            viewSetup.znear = znear
			viewSetup.zfar = zfar

            local ViewProj
            local range = znear - zfar

            if ortho then
                local pos, ang = viewSetup.origin, viewSetup.angles
                local mView = shaderlib.GetViewMatrix(pos, ang)

                local left = viewSetup.ortho.left
                local right = viewSetup.ortho.right
                local bottom = viewSetup.ortho.bottom
                local top = viewSetup.ortho.top
                local znear = viewSetup.znear
                local zfar = viewSetup.zfar

                local mProj = Matrix({
                    { 2/(right+left), 0, 0, 0};
                    {0, 2/(top+bottom) , 0, 0};
                    {0, 0, 2/range, (znear+zfar)/range};
                    t_0001
                })

                mProj:Mul(mView)
                ViewProj = mProj
            else
                local View = shaderlib.GetViewMatrix(viewSetup.origin, viewSetup.angles)
                
                local f = math.cot(math.rad(viewSetup.fov * 0.5 ))
                
                local Proj = Matrix({
                    { f, 0, 0, 0};
                    {0, f , 0, 0};
                    {0, 0, (zfar+znear)/range, 2*znear*zfar/range};
                    t0
                })

                Proj:Mul(View)
                ViewProj = Proj
            end

			cur_mat:SetMatrix("$VIEWPROJMAT", ViewProj)

			cur_mat:SetFloat("$c0_x", lightColor.r / 255)
			cur_mat:SetFloat("$c0_y", lightColor.g / 255)
			cur_mat:SetFloat("$c0_z", lightColor.b / 255)

			--local VolumetricIntensity = client_lamp and env_proj:GetBrightness() or env_proj:GetNWFloat("volumetricintensity", 1)
            local config_add = r_proj_volumetric_add_proj:GetFloat()
            local VolumetricIntensity = client_lamp and config_add or ( env_proj:GetNWFloat("volumetricintensity") !=0 and env_proj:GetNWFloat("volumetricintensity") or config_add )
			if !client_lamp then
				env_proj.VolumetricIntensity = VolumetricIntensity
			end
			local lightAdd
			lightAdd = r_proj_volumetric_add:GetFloat()

			mat:SetFloat("$c1_w", VolumetricIntensity )
            mat_shadowmap:SetFloat("$c1_w", VolumetricIntensity )
            mat_csm:SetFloat("$c1_w", lightAdd)
            mat_up:SetFloat("$c1_w", lightAdd)

			cur_mat:SetFloat("$c1_x", 1 / zfar)

            render.PushRenderTarget(rt)

            render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_MAX)
            render.SetMaterial(cur_mat)
            render.DrawScreenQuad()
            render.OverrideBlend(false)
			render.PopRenderTarget()
		end

        mat_blur_v:SetFloat("$c3_x", eyepos.x)
        mat_blur_v:SetFloat("$c3_y", eyepos.y)
        mat_blur_v:SetFloat("$c3_z", eyepos.z)

        mat_blur_h:SetFloat("$c3_x", eyepos.x)
        mat_blur_h:SetFloat("$c3_y", eyepos.y)
        mat_blur_h:SetFloat("$c3_z", eyepos.z)

        local F = -eyeang:Forward()
        local R =  eyeang:Right()
        local U = -eyeang:Up() 

        local mViewAng = Matrix({
            {R.x, R.y, R.z, 0},
            {U.x, U.y, U.z, 0},
            {F.x, F.y, F.z, 0},
            t_0001,
        })
        local mProj = shaderlib.GetProjMatrix(viewSetup)
        mProj:Mul(mViewAng)
        local invViewProj = mProj:GetInverse()
    
        mat_blur_v:SetMatrix("$INVVIEWPROJMAT", invViewProj)
        mat_blur_h:SetMatrix("$INVVIEWPROJMAT", invViewProj)

        local cur_mat_up = csm_dir and mat_up_csm or mat_up

        cur_mat_up:SetMatrix("$INVVIEWPROJMAT", mdata)

        if csm_dir then
            cur_mat_up:SetFloat("$c2_x", csm_dir.x)
            cur_mat_up:SetFloat("$c2_y", csm_dir.y)
            cur_mat_up:SetFloat("$c2_z", csm_dir.z)

            cur_mat_up:SetFloat("$c0_x", csm_color.r / 255)
            cur_mat_up:SetFloat("$c0_y", csm_color.g / 255)
            cur_mat_up:SetFloat("$c0_z", csm_color.b / 255)
        end

        render.PushRenderTarget(rt2)
        --render.Clear(0,0,0,0)
        render.SetMaterial(mat_blur_v)
        render.DrawScreenQuad()
        render.PopRenderTarget()

        render.PushRenderTarget(rt)
        --render.Clear(0,0,0,0)
        render.SetMaterial(mat_blur_h)
        render.DrawScreenQuad()
        render.PopRenderTarget()

        if r_proj_volumetric_debug:GetInt() != 1 then
            render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
        end
        render.SetMaterial(cur_mat_up)
        render.DrawScreenQuad()
        render.OverrideBlend(false)
	end)
end

if r_proj_volumetric:GetBool() then EnableProjVolumetric() end

cvars.AddChangeCallback( r_proj_volumetric:GetName(), function( convar_name, _, identifier )
	local enabled = identifier == "1"

	if enabled then
		EnableProjVolumetric()
	else
		hook.Remove("HUDPaint", shaderName)
		hook.Remove(hookname, shaderName)
	end
end, shaderName )

cvars.AddChangeCallback( r_proj_volumetric_debug:GetName(), function( convar_name, _, identifier )
	if identifier == "2" then
		EnableDebugMode()
	else
		hook.Remove("HUDPaint", shaderName)
		RunConsoleCommand("r_flashlightdrawfrustum", 0)
	end
end, shaderName )

local function InitVolumetricLightParams(scattering)
    scattering = scattering or r_scattering:GetFloat()
    --local scattering2 = scattering * scattering -- TODO: Pre calculate
    mat_csm:SetFloat("$c2_w", scattering)
    mat_up:SetFloat("$c2_w", scattering)

    -- sigma and distance power
    --local s = 555.0
    --local p = 555.0
	local s = 7055.0
    local p = 2555.0
    mat_blur_h:SetFloat("$c1_x",s)
    mat_blur_h:SetFloat("$c2_x",p)
    mat_blur_h:SetFloat("$c2_y",0)
    mat_blur_v:SetFloat("$c1_x",s)
    mat_blur_v:SetFloat("$c2_x",p)
    mat_blur_v:SetFloat("$c2_y",0)
end

cvars.AddChangeCallback( r_scattering:GetName(), function( convar_name, _, identifier )
    InitVolumetricLightParams(tonumber(identifier))
end, shaderName )

cvars.AddChangeCallback( r_proj_volumetric_dist:GetName(), function( convar_name, _, identifier )
    local dist = tonumber(identifier)
    setFloat( "$c3_x", dist )
end, shaderName )

local function InitParams()
    mat_up:SetFloat("$c0_w", r_proj_volumetric_mul:GetFloat())
    mat_csm:SetFloat( "$c0_w", r_proj_volumetric_mul:GetFloat() )
	mat:SetFloat( "$c0_w", r_proj_volumetric_mul:GetFloat() )
    mat_shadowmap:SetFloat( "$c0_w", r_proj_volumetric_mul:GetFloat() )
    InitVolumetricLightParams(r_scattering:GetFloat())

    local dist = r_proj_volumetric_dist:GetFloat()
    setFloat( "$c3_x", dist )
end
InitParams()

hook.Add("InitPostEntity", shaderName, function()
    timer.Simple(1, function()
        InitParams()
    end)
end)

cvars.AddChangeCallback( r_proj_volumetric_mul:GetName(), InitParams, shaderName )

