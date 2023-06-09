# Shader Collection

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/your-username/your-repo-name/blob/main/LICENSE)

## Introduction

This is a collection of shaders written in HLSL using Evergine. The library provides a variety of shader effects to enhance the visual quality of your graphics applications. It includes implementations of popular effects such as Blinn-Phong, BRDF Microfacet, BRDF + IBL, IBL, etc.

![Big-Picture](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/BigPicture.png)

## Shaders

- **Blinn-Phong**: Implements the classic Blinn-Phong lighting model for realistic shading and highlights.
- **BRDF Microfacet**: Offers a microfacet-based BRDF (Bidirectional Reflectance Distribution Function) for accurate material rendering.
- **IBL**: Implements Image-Based Lighting (IBL) to achieve realistic reflections and lighting effects.
- **BRDF + IBL**: Combines BRDF with Image-Based Lighting (IBL) techniques for realistic and dynamic lighting.
- **Equirectangular Reflections**: Provides reflections based on equirectangular environment maps.
- **TextureCube Reflections**: Offers reflections using cube maps as environment maps.
- **Fur Shells**: Simulates fur or hair effects using shell rendering techniques.
- **Explode Effect**: Creates an explosion effect by manipulating vertex positions.
- **Extrude Pyramid**: Extrudes a pyramid shape from a base geometry.
- **Extrude Triangles**: Extrudes triangles along their normals to create a 3D effect.
- **Flat Shading**: Applies flat shading to achieve a low-polygon aesthetic.
- **Fresnel**: Implements Fresnel effects for reflective materials.
- **Interior Mapping**: Simulates the appearance of interiors behind windows or other surfaces.
- **Parallax Corrected Cube Mapping**: Provides improved cube map reflections with parallax correction.
- **Normal Mapping**: Enhances surface lighting and detail using normal maps.
- **Parallax Mapping**: Simulates depth on textured surfaces by offsetting texture coordinates.
- **Parallax Occlusion Mapping**: Enhances the depth simulation of Parallax Mapping with occlusion handling.
- **Toon Shading**: Applies a toon or cel-shading effect to achieve a cartoon-like rendering style.
- **Translucency Shading**: Simulates light passing through translucent materials for realistic rendering.
- **Vertex Normals GS**: Calculates vertex normals in the Geometry Shader stage for improved shading accuracy.
- **Wireframe GS**: Renders objects as wireframes using the Geometry Shader stage.
- **WrapShading**: Fast subsurface scattering by modulating the shading based on their orientation relative to the incident light.

## Screenshots

Here are some screenshots showcasing the shader effects in action:

![Blinn-Phong](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/BlinnPhong.png)
![BRDF Microfacet](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/BRDF.png)
![BRDF + IBL](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/BRDF_IBL.png)
![Equirectangular Reflections](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/EquirectangularReflections.png)
![Explode Effect](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ExplodeEffectGS.png)
![Extrude Pyramid](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ExtrudePyramidGS.png)
![Extrude Triangles](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ExtrudeTriangleGS.png)
![Flat Shading](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/FlatShadingDD.png)
![Flat Shading](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/FlatShadingGS.png)
![Fresnel](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/Fresnel.png)
![Fur Shells](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/FurGS.png)
![IBL](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/IBL.png)
![Interior Mapping](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/InteriorMapping.png)
![Normal Mapping](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/NormalMapping.png)
![Parallax Corrected Cube Mapping](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ParallaxCorrectedCubeMap.png)
![Parallax Mapping](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ParallaxMapping.png)
![Parallax Occlusion Mapping](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ParallaxOcclusionMapping.png)
![TextureCube Reflections](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/TextureCube%20Reflections.png)
![Toon Shading](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/ToonShading.png)
![Translucency Shading](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/Traslucency.png)
![Vertex Normals GS](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/VertexNormals.png)
![Wireframe GS](https://github.com/jcant0n/ShaderLibrary/raw/main/Screenshots/WireFrameGS.png)
![WrapShading](https://github.com/jcant0n/ShaderLibrary/blob/main/Screenshots/WrapShading.png)

## Requirements

- Evergine: [Download Evergine](https://www.evergine.com) (Version 2023.3.1 or higher)
- Graphics API: DirectX 11/12, OpenGL or Vulkan

## Take a look

Follow the steps below to get started with using the shader library:

1. Clone the repository: `git clone https://github.com/your-username/your-repo-name.git`
2. Install the necessary Evergine version using the Evergine Launcher.
3. Build and run your project to see the shader effects in action.

## Contributing

Contributions to the shader library collection are welcome! If you would like to contribute, please follow these guidelines:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and ensure they are well-tested.
4. Commit your changes with a clear and descriptive message.
5. Push your changes to your forked repository.
6. Submit a pull request to the main repository, explaining the changes you made.

## Screenshots


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments

  List any resources, libraries, or tutorials that you found helpful while creating this shader library collection:
  
  - https://colinbarrebrisebois.com/2011/03/07/gdc-2011-approximating-translucency-for-a-fast-cheap-and-convincing-subsurface-scattering-look/
  - https://www.gdcvault.com/play/1018270/Next-Generation-Character
  - https://learnopengl.com/Advanced-Lighting/Parallax-Mapping
  - http://www.shaderslab.com/shaders.html
  - https://roystan.net/articles/
  - https://catlikecoding.com/unity/tutorials/
  - https://www.clicktorelease.com/blog/making-of-cruciform/
  - https://github.com/csdjk/LearnUnityShader
  - https://www.gsn-lib.org/index.html#projectName=public3dshader&graphName=ImageBasedLighting
  - 

## Contact

If you have any questions, suggestions, or feedback, feel free to open and issue and share your ideas.

