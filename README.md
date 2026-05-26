
# For Mappers
Place `proj_volumetric_light.fgd` to `Garrysmod/bin/`. Then goto Hammer++, `Tools` -> `Options` -> `Game Data files:` -> `Add` `proj_volumetric_light.fgd`. 

<img width="904" height="504" alt="image" src="https://github.com/user-attachments/assets/14705293-38dc-4559-856f-1ab555489b7a" />

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

TODO: Emission term — self-luminous volumes

Height-Based Density ( Connect Evgeny new shader with volumes )

Scattering albedo — separate sigma_s from sigma_t

Multiple scattering — diffusion approximation

Rayleigh scattering component ( maybe for csm )

Light cone preculling ( every pixel runs a full ray march even if the pixel lies entirely outside the spot light's cone or behind the light. Skipping these early frees up your step budget for pixels that actually contribute )

Rotated Poisson disk shadow sampling
Stochastic soft shadows ( current shadow tap is a fixed grid (or single tap). Rotating a Poisson disk kernel by a per-pixel random angle breaks up the regular pattern — combined with temporal reprojection, this gives the appearance of very wide, smooth penumbra at zero additional runtime cost over standard PCF )

Light-aligned anisotropic noise ( isotropic noise produces round blob shapes. Real light shafts in dusty/foggy air have elongated structures aligned with the light direction — you can see individual streaks. Stretching the noise sampling coordinates along the light direction creates this for free )

Heterogeneous medium — properly integrated density ( medium has spatially uniform density. Real fog, smoke, and dust are wildly non-uniform. The key is that varying density must be applied inside both the transmittance and the scattering integrals — not just cosmetically multiplied on the output. Getting this wrong produces density blobs that don't attenuate light correctly )


