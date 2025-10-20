import simd

struct Transform{
  var position: SIMD3<Float>
  var rotation: SIMD3<Float>
  var scale: SIMD3<Float>

  init(
    position: SIMD3<Float> = SIMD3(0,0,0),
    rotation: SIMD3<Float> = SIMD3(0,0,0),
    scale: SIMD3<Float> = SIMD3(1,1,1)
  ){
    self.position = position
    self.rotation = rotation
    self.scale = scale
  }

  func modelMatrix() -> simd_float4x4{
    let T = translationMatrix(pos: position)
    let Rx = rotationMatrixX(angle: rotation.x)
    let Ry = rotationMatrixY(angle: rotation.y)
    let Rz = rotationMatrixZ(angle: rotation.z)
    let S = scaleMatrix(scale: scale)

    return T * Rx * Ry * Rz * S
  }
}

func translationMatrix(pos: SIMD3<Float>) -> simd_float4x4{
  var mat = matrix_identity_float4x4
  mat.columns.3 = SIMD4<Float>(pos.x, pos.y, pos.z, 1.0)
  return mat
}

func scaleMatrix(scale: SIMD3<Float>) -> simd_float4x4{
  return simd_float4x4(
    SIMD4(scale.x, 0, 0, 0),
    SIMD4(0, scale.y, 0, 0),
    SIMD4(0, 0, scale.z, 0),
    SIMD4(0, 0, 0, 1)
  )
}

func rotationMatrixX(angle: Float) -> float4x4{
  let c = cos(angle)
  let s = sin(angle)
  return simd_float4x4([
    SIMD4<Float>(1, 0, 0, 0),
    SIMD4<Float>(0, c, s, 0),
    SIMD4<Float>(0, -s, c, 0),
    SIMD4<Float>(0, 0, 0, 1),
  ])
}

func rotationMatrixY(angle: Float) -> float4x4{
  let c = cos(angle)
  let s = sin(angle)

  return float4x4([
    SIMD4<Float>(c, 0, -s, 0),
    SIMD4<Float>(0, 1, 0, 0),
    SIMD4<Float>(s, 0, c, 0),
    SIMD4<Float>(0, 0, 0, 1),
  ])
}

func rotationMatrixZ(angle: Float) -> float4x4{
  let c = cos(angle)
  let s = sin(angle)

  return float4x4([
    SIMD4<Float>(c, s, 0, 0),
    SIMD4<Float>(-s, c, 0, 0),
    SIMD4<Float>(0, 0, 1, 0),
    SIMD4<Float>(0, 0, 0, 1),
  ])
}
