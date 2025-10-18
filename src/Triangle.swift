import simd

struct Triangle{
  var vertices: [Vertex]

  init(){
    let h = Float(sqrt(3.0)/2.0)
    vertices = [
      Vertex(
        position: SIMD3<Float>(0.0, h*2.0/3.0, 0.0), 
        normal: SIMD3<Float>(1.0, 0.0, 0.0),
        uv: SIMD2<Float>(0.0, 0.0)
      ),
      Vertex(
        position: SIMD3<Float>(-0.5, -h/3.0, 0.0), 
        normal: SIMD3<Float>(0.0, 1.0, 0.0),
        uv: SIMD2<Float>(0.0, 0.0)
      ),
      Vertex(
        position: SIMD3<Float>(0.5, -h/3.0, 0.0), 
        normal: SIMD3<Float>(0.0, 0.0, 1.0),
        uv: SIMD2<Float>(0.0, 0.0)
      ),
    ]
  }

  var centroid: SIMD3<Float>{
    //average position of all verts
    let sum = vertices.reduce(SIMD3<Float>(0,0,0)){ result, vertex in
      result + vertex.position
    }

    return sum/Float(vertices.count)
  }

  func vertexData() -> [Float]{
    vertices.flatMap{vertex in
      [vertex.position.x, vertex.position.y, vertex.position.y,
        vertex.normal.x, vertex.normal.y, vertex.normal.z]
    }
  }
}
