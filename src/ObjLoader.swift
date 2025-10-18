import Foundation

enum ObjLoaderError: Error{
  case invalidFloat
  case invalidIndex
  case invalidFaceFormat
  case invalidElementCount
}

struct ObjLoader{
  func load(from url: URL) throws -> Object{
    let contents = try String(contentsOf: url, encoding: .utf8)
    let lines = contents.components(separatedBy: .newlines)

    var positions: [SIMD3<Float>] = []
    var uvs: [SIMD2<Float>] = []
    var normals: [SIMD3<Float>] = []
    var face_indices: [(posIdx: Int, uvIdx: Int, normIdx: Int)] = []

    for line in lines{
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else {continue}

      let parts = trimmed.components(separatedBy: .whitespaces).filter{!$0.isEmpty}
      switch parts[0]{
      case "v":
        guard parts.count == 4 else {throw ObjLoaderError.invalidElementCount}
        guard let x = Float(parts[1]) else {throw ObjLoaderError.invalidFloat}
        guard let y = Float(parts[2]) else {throw ObjLoaderError.invalidFloat}
        guard let z = Float(parts[3]) else {throw ObjLoaderError.invalidFloat}
        let position = SIMD3<Float>(x, y, z)
        positions.append(position)
      case "vt":
        guard let u = Float(parts[1]) else {throw ObjLoaderError.invalidFloat}
        guard let v = Float(parts[2]) else {throw ObjLoaderError.invalidFloat}
        let uv = SIMD2<Float>(u, v)
        uvs.append(uv)
      case "vn":
        guard let x = Float(parts[1]) else {throw ObjLoaderError.invalidFloat}
        guard let y = Float(parts[2]) else {throw ObjLoaderError.invalidFloat}
        guard let z = Float(parts[3]) else {throw ObjLoaderError.invalidFloat}
        let normal = SIMD3<Float>(x, y, z)
        normals.append(normal)
      case "f":
        for i in 1..<parts.count{
          let vert_ref = parts[i]
          let indices = vert_ref.components(separatedBy: "/")
          guard indices.count == 3 else {throw ObjLoaderError.invalidFaceFormat}
          guard let posIdx = Int(indices[0]) else {throw ObjLoaderError.invalidIndex}
          guard let uvIdx = Int(indices[1]) else {throw ObjLoaderError.invalidIndex}
          guard let normIdx = Int(indices[2]) else {throw ObjLoaderError.invalidIndex}
          face_indices.append((posIdx-1, uvIdx-1, normIdx-1))
        }
      default:
        break
      }
    }

    var vertices: [Vertex] = []
    var indices: [UInt32] = []
    var vert_map: [String: UInt32] = [:]

    for faceIdx in face_indices{
      let key = "\(faceIdx.posIdx)/\(faceIdx.uvIdx)/\(faceIdx.normIdx)"

      if let exisiting_index = vert_map[key]{
        indices.append(exisiting_index)
      }else{
        let vertex = Vertex(
          position: positions[faceIdx.posIdx],
          normal: normals[faceIdx.normIdx],
          uv: uvs[faceIdx.uvIdx],
        )
        vertices.append(vertex)
        let new_index = UInt32(vertices.count - 1)
        vert_map[key] = new_index
        indices.append(new_index)
      }
    }

    let object = Object(vertices: vertices, indices: indices)
    return object
  }
}
