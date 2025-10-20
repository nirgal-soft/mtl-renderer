import simd

struct Particle{
  var position: SIMD3<Float>
  var velocity: SIMD3<Float>
  var lifetime: Float
}

class ParticleSystem{
  var particles: [Particle] = []
  let maxParticles: Int
  let spawnArea: SIMD3<Float>

  init(maxParticles: Int, spawnArea: SIMD3<Float>){
    self.maxParticles = maxParticles
    self.spawnArea = spawnArea

    for _ in 0..<maxParticles{
      particles.append(createParticle())
    }
  }

  func createParticle() -> Particle{
    return Particle(
      position: SIMD3<Float>(
        Float.random(in: -spawnArea.x...spawnArea.x),
        Float.random(in: 0...spawnArea.y),
        Float.random(in: -spawnArea.z...spawnArea.z)
      ),
      velocity: SIMD3<Float>(
        Float.random(in: -0.2...0.2),
        -1.0,
        Float.random(in: -0.2...0.2)
      ),
      lifetime: Float.random(in: 5.0...10.0)
    )
  }

  func update(deltaTime: Float){
    for i in 0..<particles.count{
      particles[i].position += particles[i].velocity * deltaTime
      particles[i].lifetime -= deltaTime

      if particles[i].position.y < 0 || particles[i].lifetime <= 0{
        particles[i] = createParticle()
      }
    }
  }

  func vertexData(cameraRight: SIMD3<Float>, cameraUp: SIMD3<Float>) -> [Float]{
    var data: [Float] = []
    let size: Float = 0.05

    let normal = normalize(cross(cameraRight, cameraUp))

    for particle in particles{
      let pos = particle.position
      let right_offset = cameraRight * size
      let up_offset = cameraUp * size

      let bottom_left = pos - right_offset - up_offset
      let bottom_right = pos + right_offset - up_offset
      let top_right = pos + right_offset + up_offset
      let top_left = pos - right_offset + up_offset
      
      let vertices = [bottom_left, bottom_right, top_right, top_left]

      data.append(contentsOf: [vertices[0].x, vertices[0].y, vertices[0].z, normal.x, normal.y, normal.z, 0, 0])
      data.append(contentsOf: [vertices[1].x, vertices[1].y, vertices[1].z, normal.x, normal.y, normal.z, 1, 0])
      data.append(contentsOf: [vertices[2].x, vertices[2].y, vertices[2].z, normal.x, normal.y, normal.z, 1, 1])

      data.append(contentsOf: [vertices[0].x, vertices[0].y, vertices[0].z, normal.x, normal.y, normal.z, 0, 0])
      data.append(contentsOf: [vertices[2].x, vertices[2].y, vertices[2].z, normal.x, normal.y, normal.z, 1, 1])
      data.append(contentsOf: [vertices[3].x, vertices[3].y, vertices[3].z, normal.x, normal.y, normal.z, 0, 1])
    }

    return data
  }
}
