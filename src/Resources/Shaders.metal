#include <metal_stdlib>
using namespace metal;

//vertex structure
struct Vertex{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

//uniforms
struct Uniforms{
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
    float3 lightDirection;
    float3 lightColor;
    float3 spotLightDirection;
    float3 spotLightPosition;
    float3 spotLightColor;
    float spotLightCutoff;
    float spotLightOuterCutoff;
};

//output from vertex to frag Shaders
struct RasterizerData{
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float3 worldPos;
};

//vertex shader
vertex RasterizerData vertexShader(Vertex in [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]]) {
                                    
    RasterizerData out;

    float4 worldPos = uniforms.modelMatrix * float4(in.position, 1.0);
    out.worldPos = worldPos.xyz;

    float4 viewPos = uniforms.viewMatrix * worldPos;

    out.position = uniforms.projectionMatrix * viewPos;
    out.normal = uniforms.normalMatrix * in.normal;
    out.uv = in.uv;

    return out;
}

//frag shader
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                                texture2d<float> colorTexture [[texture(0)]],
                                sampler textureSampler [[sampler(0)]],
                                constant Uniforms& uniforms [[buffer(1)]]){
  float4 textureColor = colorTexture.sample(textureSampler, in.uv);
  float3 normal = normalize(in.normal);

  //directional direction
  float diffuse = max(dot(normal, -uniforms.lightDirection), 0.0);
  float ambient = 0.2;
  float3 directionalLight = uniforms.lightColor * (ambient + diffuse * 0.5);

  //spot light
  float3 lightDir = uniforms.spotLightPosition - in.worldPos;
  float distance = length(lightDir);
  lightDir = normalize(lightDir);

  //check if frag is inside spotlight cone
  float theta = dot(lightDir, normalize(-uniforms.spotLightDirection));
  float epsilon = uniforms.spotLightCutoff - uniforms.spotLightOuterCutoff;
  float intensity = clamp((theta - uniforms.spotLightOuterCutoff) / epsilon, 0.0, 1.0);

  //attenuate
  float attenuation = 1.0 /  (1.0 + 0.09 * distance + 0.032 * distance * distance);

  //spotlight diffuse
  float spotDiffuse = max(dot(normal, uniforms.spotLightDirection), 0.0);
  float3 spotLight = uniforms.spotLightColor * spotDiffuse * intensity * attenuation;

  float3 bulbLightDir = uniforms.spotLightPosition - in.worldPos;
  float bulbDistance = length(bulbLightDir);
  bulbLightDir = normalize(bulbLightDir);

  float bulbAttenuation = 1.0 /  (1.0 + 0.03 * bulbDistance + 0.1 * bulbDistance * bulbDistance);
  float bulbDiffuse = max(dot(normal, bulbLightDir), 0.0);
  float3 bulbLight = uniforms.spotLightColor * bulbDiffuse * bulbAttenuation * 0.3;

  //combine
  float3 finalLight = directionalLight + spotLight + bulbLight;
  float3 finalColor = textureColor.rgb * finalLight;

  return float4(finalColor, textureColor.a);
}
