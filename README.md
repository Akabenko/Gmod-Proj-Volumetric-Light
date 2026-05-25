
# For Mappers
Place `proj_volumetric_light.fgd` to `Garrysmod/bin/`. Then goto Hammer++, `Tools` -> `Options` -> `Game Data files:` -> `Add` `proj_volumetric_light.fgd`. 

New params of `env_projectedtexture`:
- Enable Volumetrics (`volumetric`) — Enables/disables volumetrics from this projected texture.
- Volumetric Intensity (`volumetricintensity`) — Sets the intensity of the volumetric lighting.

New Inputs:
- EnableVolumetrics — Set if the volumetrics are enabled.
- SetVolumetricIntensity — Sets the volumetric lighting\'s intensity.

***
Workshop addon: https://steamcommunity.com/sharedfiles/filedetails/?id=3712613623
<br>Half upsamplig code by [LVutner](https://github.com/LVutner).
<br>Matrix calculations by Jaymun.
<br>Volumetric params of `proj_volumetric_light.fgd` from [Strata Source](https://developer.valvesoftware.com/wiki/Ru/Strata_Source) from Valve Wiki page: https://developer.valvesoftware.com/wiki/Env_projectedtexture

Reference:
- [Volumetric lights by Alexandre Pestana](https://www.alexandre-pestana.com/volumetric-lights/)
