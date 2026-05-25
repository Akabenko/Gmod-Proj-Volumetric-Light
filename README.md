
# For Mappers
Place `proj_volumetric_light.fgd` to `Garrysmod/bin/`. Then goto Hammer++, `Tools` -> `Options` -> `Game Data files:` -> `Add` `proj_volumetric_light.fgd`. 

New params of `env_projectedtexture`:
- **Enable Volumetrics** (`volumetric`) — Enables/disables volumetrics from this projected texture.
- **Volumetric Intensity** (`volumetricintensity`) — Sets the intensity of the volumetric lighting.

New Inputs:
- **EnableVolumetrics** — Set if the volumetrics are enabled.
- **SetVolumetricIntensity** — Sets the volumetric lighting\'s intensity.

***
Workshop addon: [Proj Volumetric Light (Shader)](https://steamcommunity.com/sharedfiles/filedetails/?id=3712613623), based on [GShader library](https://github.com/Akabenko/GShader-library/tree/main).
<br>Half upsamplig code by [LVutner](https://github.com/LVutner).
<br>Matrix calculations by Jaymun.
<br>Volumetric params of `proj_volumetric_light.fgd` from [Strata Source](https://developer.valvesoftware.com/wiki/Ru/Strata_Source) from Valve Wiki page: [Env_projectedtexture](https://developer.valvesoftware.com/wiki/Env_projectedtexture).

Reference:
- [Volumetric lights by Alexandre Pestana](https://www.alexandre-pestana.com/volumetric-lights/)

<img width="512" height="512" alt="r_proj_volumetric" src="https://github.com/user-attachments/assets/a66277a1-fefb-439c-b1d1-494db6e8a043" />

