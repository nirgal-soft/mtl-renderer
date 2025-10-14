import simd

struct Uniforms{
  var modelMatrix: simd_float4x4
  var viewMatrix: simd_float4x4
  var projectionMatrix: simd_float4x4
}

class Camera{
  var fov: Float
  var aspect: Float
  var near: Float
  var far: Float
  var pos: SIMD3<Float>
  var orient: SIMD3<Float>
  var view_mat: simd_float4x4
  var proj_mat: simd_float4x4

  init(fov: Float, aspect: Float, near: Float, far: Float){
    self.fov = fov
    self.aspect = aspect
    self.near = near
    self.far = far
    pos = SIMD3<Float>(0, 0, 0)
    orient = SIMD3<Float>(0, 0, 0)
    view_mat = simd_float4x4()
    proj_mat = simd_float4x4()
  }

  func makePerspective() -> simd_float4x4{
    let ys = 1 / tan(fov * 0.5)
    let xs = ys / aspect
    let zs = far / (near - far)

    return simd_float4x4(
      SIMD4(xs, 0, 0, 0),
      SIMD4(0, ys, 0, 0),
      SIMD4(0, 0, zs, -1),
      SIMD4(0, 0, zs*near, 0),
    )
  }

  func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4{
    let z_axis = simd_normalize(eye - center) //forward
    let x_axis = simd_normalize(simd_cross(up, z_axis)) //right
    let y_axis = simd_cross(z_axis, x_axis) //up

    let translation = simd_float4(
      -simd_dot(x_axis, eye),
      -simd_dot(y_axis, eye),
      -simd_dot(z_axis, eye),
      1.0)

    return simd_float4x4(columns: (
      simd_float4(x_axis.x, y_axis.x, z_axis.x, 0),
      simd_float4(x_axis.y, y_axis.y, z_axis.y, 0),
      simd_float4(x_axis.z, y_axis.z, z_axis.z, 0),
      translation
    ))
  }
}
