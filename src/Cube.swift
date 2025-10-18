import simd

struct Cube{
  var vertices: [Vertex]
  var indices: [UInt32]

  init(){
    self.vertices = createCube()
    self.indices = createIndices()
  }

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

func createCube() -> [Vertex] {
  let vertices: [Vertex] = [
    // Front face (z = 0.5) - indices 0-3
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(0, 0, 1), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3(0, 0, 1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3(0, 0, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(0, 0, 1), uv: SIMD2(0, 1)),

    // Back face (z = -0.5) - indices 4-7
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3(0, 0, -1), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(0, 0, -1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(0, 0, -1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3(0, 0, -1), uv: SIMD2(0, 1)),

    // Left face (x = -0.5) - indices 8-11
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(-1, 0, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(-1, 0, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(-1, 0, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(-1, 0, 0), uv: SIMD2(0, 1)),

    // Right face (x = 0.5) - indices 12-15
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3(1, 0, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3(1, 0, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3(1, 0, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3(1, 0, 0), uv: SIMD2(0, 1)),

    // Top face (y = 0.5) - indices 16-19
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), normal: SIMD3(0, 1, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), normal: SIMD3(0, 1, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), normal: SIMD3(0, 1, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), normal: SIMD3(0, 1, 0), uv: SIMD2(0, 1)),

    // Bottom face (y = -0.5) - indices 20-23
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), normal: SIMD3(0, -1, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), normal: SIMD3(0, -1, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), normal: SIMD3(0, -1, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), normal: SIMD3(0, -1, 0), uv: SIMD2(0, 1)),
  ]
  return vertices
}

func createIndices() -> [UInt32] {
  let indices: [UInt32] = [
    // Front face
    0, 1, 2,  2, 3, 0,
    // Back face
    4, 5, 6,  6, 7, 4,
    // Left face
    8, 9, 10,  10, 11, 8,
    // Right face
    12, 13, 14,  14, 15, 12,
    // Top face
    16, 17, 18,  18, 19, 16,
    // Bottom face
    20, 21, 22,  22, 23, 20,
  ]
  return indices
}
