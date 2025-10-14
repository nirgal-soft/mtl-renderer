import Metal
import MetalKit
import CoreGraphics

enum TextureLoaderError: Error{
  case deviceNotAvailable
  case imageNotFound
  case invalidImageData
  case textureCreationFailed
  case cgImageCreationFailed
}

class TextureLoader{
  private let device: MTLDevice
  private let textureLoader: MTKTextureLoader

  init(device: MTLDevice){
    self.device = device
    self.textureLoader = MTKTextureLoader(device: device)
  }

  func loadTexture(named name: String, bundle: Bundle = .main) throws -> MTLTexture{
    guard let url = bundle.url(forResource: name, withExtension: nil) else{
      throw TextureLoaderError.imageNotFound
    }
    return try loadTexture(from: url)
  }

  func loadTexture(from url: URL) throws -> MTLTexture{
    let options: [MTKTextureLoader.Option: Any] = [
      .textureUsage: MTLTextureUsage.shaderRead.rawValue,
      .textureStorageMode: MTLStorageMode.private.rawValue,
      .SRGB: false
    ]

    return try textureLoader.newTexture(URL: url, options: options)
  }
}
