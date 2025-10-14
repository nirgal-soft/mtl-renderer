import simd

struct Cube{
  var vertices: [Vertex]

  init(){
    self.vertices = createCube()
  }

  func vertexData() -> [Float]{
    vertices.flatMap{vertex in
      [vertex.position.x, vertex.position.y, vertex.position.z,
        vertex.color.x, vertex.color.y, vertex.color.z,
        vertex.uv.x, vertex.uv.y]
    }
  }
}

func createCube() -> [Vertex] {
  let vertices: [Vertex] = [
    // Front face (red)
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD3(1, 0, 0), uv: SIMD2(0, 0)),

    // Back face (green)
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(0, 1, 0), uv: SIMD2(1, 0)),

    // Left face (blue)
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(0, 0, 1), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD3(0, 0, 1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD3(0, 0, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD3(0, 0, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD3(0, 0, 1), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(0, 0, 1), uv: SIMD2(0, 0)),

    // Right face (yellow)
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD3(1, 1, 0), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD3(1, 1, 0), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(1, 1, 0), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(1, 1, 0), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD3(1, 1, 0), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD3(1, 1, 0), uv: SIMD2(1, 0)),

    // Top face (cyan)
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD3(0, 1, 1), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3(-0.5,  0.5,  0.5), color: SIMD3(0, 1, 1), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(0, 1, 1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5,  0.5), color: SIMD3(0, 1, 1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5,  0.5, -0.5), color: SIMD3(0, 1, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5,  0.5, -0.5), color: SIMD3(0, 1, 1), uv: SIMD2(0, 1)),

    // Bottom face (magenta)
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(1, 0, 1), uv: SIMD2(0, 0)),
    Vertex(position: SIMD3( 0.5, -0.5, -0.5), color: SIMD3(1, 0, 1), uv: SIMD2(1, 0)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD3(1, 0, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3( 0.5, -0.5,  0.5), color: SIMD3(1, 0, 1), uv: SIMD2(1, 1)),
    Vertex(position: SIMD3(-0.5, -0.5,  0.5), color: SIMD3(1, 0, 1), uv: SIMD2(0, 1)),
    Vertex(position: SIMD3(-0.5, -0.5, -0.5), color: SIMD3(1, 0, 1), uv: SIMD2(0, 0)),
  ]
  return vertices
}
