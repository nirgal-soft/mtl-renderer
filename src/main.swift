//  main.swift
//  hello_triangle
//
//  Created by Zach Murray on 10/5/25.
//

import Foundation
import Cocoa
import Metal
import MetalKit
import simd

//MARK: - Shaders (metal shading language)
let shaderSource = """
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
};

//output from vertex to frag Shaders
struct RasterizerData{
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

//vertex shader
vertex RasterizerData vertexShader(Vertex in [[stage_in]],
                                   constant Uniforms& uniforms [[buffer(1)]]) {
                                    
    RasterizerData out;
    float4 worldPos = uniforms.modelMatrix * float4(in.position, 1.0);
    float4 viewPos = uniforms.viewMatrix * worldPos;
    out.position = uniforms.projectionMatrix * viewPos;
    out.normal = in.normal;
    out.uv = in.uv;
    return out;
}

//frag shader
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                                texture2d<float> colorTexture [[texture(0)]],
                                sampler textureSampler [[sampler(0)]]){
    float4 textureColor = colorTexture.sample(textureSampler, in.uv);
    return textureColor;
}
"""

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

func translationMatrix(pos: SIMD3<Float>) -> simd_float4x4{
  var mat = matrix_identity_float4x4
  mat.columns.3 = SIMD4<Float>(pos.x, pos.y, pos.z, 1.0)
  return mat
}

// MARK: - Renderer
class Renderer: NSObject, MTKViewDelegate{
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  var depthStencilState: MTLDepthStencilState!
  var camera: Camera!
  var pipelineState: MTLRenderPipelineState!
  var samplerState: MTLSamplerState!
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  var texture: MTLTexture!
  var triangle: Triangle!
  var cube: Object!
  var lastFrameTime = CACurrentMediaTime()
  var angle: Float = 0.0

  init(device: MTLDevice){
    self.device = device
    self.commandQueue = device.makeCommandQueue()!
    super.init()

    setupDepthStencil()
    setupPipeline()
    setupSamplerState()
    setupTexture()
    setupVertexBuffer()
    setupIndexBuffer()
    setupUniformBuffer()

    print("cube verts count: \(cube.vertexData().count)")
  }

  func setupDepthStencil(){
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .less
    depthDescriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
  }

  func setupPipeline(){
    //compile shaders
    let library = try! device.makeLibrary(source: shaderSource, options: nil)
    let vertexFunction = library.makeFunction(name: "vertexShader")
    let fragmentFunction = library.makeFunction(name: "fragmentShader")

    //create
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

    //set up vert descriptor (tesll metal the layout of the vert data)
    let vertexDescriptor = MTLVertexDescriptor()
    //position attr (3 floats at offset 0)
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    //normal attrs (3 floats at offset 12 bytes)
    vertexDescriptor.attributes[1].format = .float3
    vertexDescriptor.attributes[1].offset = 12
    vertexDescriptor.attributes[1].bufferIndex = 0
    //uv attr (2 floats at offset 24 bytes)
    vertexDescriptor.attributes[2].format = .float2
    vertexDescriptor.attributes[2].offset = 24
    vertexDescriptor.attributes[2].bufferIndex = 0
    //layout (stride = 32 bytes per vertex: 3 position + 3 normal + 2 texture)
    vertexDescriptor.layouts[0].stride = 32

    pipelineDescriptor.vertexDescriptor = vertexDescriptor

    //create pipeline pipelineState
    do{
      pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
      print("pipeline created successfully")
    }catch{
      print("pipeline error: \(error)")
    }
  }

  func setupSamplerState(){
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    samplerDescriptor.sAddressMode = .repeat
    samplerDescriptor.tAddressMode = .repeat
    samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
  }

  func setupTexture(){
    let loader = TextureLoader(device: device)
    guard let url = Bundle.module.url(forResource: "texture", withExtension: "jpg", subdirectory: "Resources") else {
      fatalError("Could not find texture.jpg in bundle")
    }
    texture = try! loader.loadTexture(from: url)
  }

  func setupVertexBuffer(){
    let loader = ObjLoader()
    guard let url = Bundle.module.url(forResource: "cube", withExtension: "obj", subdirectory: "Resources") else {
      fatalError("Could not find cube.obj in bundle")
    }
    // cube = Cube()
    cube = try! loader.load(from: url)

    //create vertex buffer (count * size)
    let dataSize = cube.vertexData().count * MemoryLayout<Float>.stride
    vertexBuffer = device.makeBuffer(bytes: cube.vertexData(), length: dataSize, options: [])
  }

  func setupIndexBuffer(){
    let dataSize = cube.indexData().count * MemoryLayout<UInt32>.stride
    indexBuffer = device.makeBuffer(bytes: cube.indexData(), length: dataSize, options: [])
  }

  func setupUniformBuffer(){
    uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])
  }

  //called every frame
  func draw(in view: MTKView){
    let now = CACurrentMediaTime()
    let deltaTime = now - lastFrameTime
    lastFrameTime = now 
    angle += Float(deltaTime) * 2.0

    let mat = rotationMatrixY(angle: angle)

    let proj = camera.makePerspective()
    let eye = SIMD3<Float>(2, 2, 2)
    let center = SIMD3<Float>(0, 0, 0)
    let up = SIMD3<Float>(0, 1, 0)
    let view_mat = camera.lookAt(eye: eye, center: center, up: up)
    
    let uniforms = Uniforms(modelMatrix: mat, viewMatrix: view_mat, projectionMatrix: proj)

    let pointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
    pointer.pointee = uniforms

    guard let drawable = view.currentDrawable,
      let renderPassDescriptor = view.currentRenderPassDescriptor else {return}

    //set clear color
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

    //create comand buffer
    let commandBuffer = commandQueue.makeCommandBuffer()!

    //create render encoder
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

    //set pipeline and vertex buffer
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
    renderEncoder.setFragmentTexture(texture, index: 0)
    renderEncoder.setFragmentSamplerState(samplerState, index: 0)

    //draw the object
    // renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 36)
    renderEncoder.drawIndexedPrimitives(
      type: .triangle,
      indexCount: cube.indexData().count,
      indexType: .uint32,
      indexBuffer: indexBuffer,
      indexBufferOffset: 0
    )

    //finish encoding
    renderEncoder.endEncoding()

    //presnet drawable and commit
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize){

  }
}

//MAKR: - app setup
class AppDelegate: NSObject, NSApplicationDelegate{
  var window: NSWindow!
  var renderer: Renderer!

  func applicationDidFinishLaunching(_ notification: Notification){
    //get metal device (gpu)
    guard let device = MTLCreateSystemDefaultDevice() else{
      fatalError("metal is not supported on this device")
    }

    //create metal view
    let metalView = MTKView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    metalView.device = device
    metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.clearDepth = 1.0

    //create renderer
    renderer = Renderer(device: device)
    let aspect = Float(metalView.drawableSize.width/metalView.drawableSize.height)
    renderer.camera = Camera(fov: 1.13, aspect: aspect, near: 0.1, far: 100.0)
    metalView.delegate = renderer

    //create window
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "METAL"
    window.contentView = metalView
    window.center()
    window.makeKeyAndOrderFront(nil)
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
