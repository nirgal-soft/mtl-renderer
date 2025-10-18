import simd

struct Object{
  var vertices: [Vertex]
  var indices: [UInt32]

  func indexData() -> [UInt32]{
    indices
  }

  func vertexData() -> [Float]{
    vertices.flatMap{vertex in
      [vertex.position.x, vertex.position.y, vertex.position.z,
        vertex.normal.x, vertex.normal.y, vertex.normal.z,
        vertex.uv.x, vertex.uv.y]
    }
  }
}
