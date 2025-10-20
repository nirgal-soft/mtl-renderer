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

extension simd_float4{
  var xyz: simd_float3{
    return simd_float3(x, y, z)
  }
}

// MARK: - Renderer
class Renderer: NSObject, MTKViewDelegate{
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  var depthStencilState: MTLDepthStencilState!
  var camera: Camera!
  var pipelineState: MTLRenderPipelineState!
  var samplerState: MTLSamplerState!
  // var vertexBuffer: MTLBuffer!
  // var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  var globalVertexBuffer: MTLBuffer!
  var globalIndexBuffer: MTLBuffer!
  var texture: MTLTexture!
  var scene: Scene!
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
    setupUniformBuffer()
    setupScene()
    buildGlobalBuffers()
  }

  func setupDepthStencil(){
    let depthDescriptor = MTLDepthStencilDescriptor()
    depthDescriptor.depthCompareFunction = .less
    depthDescriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
  }

  func setupPipeline(){
    //compile shaders
    // let library = try! device.makeLibrary(source: shaderSource, options: nil)
    guard let url = Bundle.module.url(
      forResource: "Shaders",
      withExtension: "metal",
      subdirectory: "Resources")
    else{
      fatalError("Could not find Shaders.metal in bundle")
    }
    let source = try! String(contentsOf: url, encoding: .utf8)
    let library = try! device.makeLibrary(source: source, options: nil)
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
    guard let url = Bundle.module.url(forResource: "car_blue", withExtension: "png", subdirectory: "Resources") else {
      fatalError("Could not find car_blue.png in bundle")
    }
    texture = try! loader.loadTexture(from: url)
  }

  func setupUniformBuffer(){
    uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride * 100, options: [])
  }

  func setupScene(){
    scene = Scene()

    let loader = ObjLoader()
    guard let url = Bundle.module.url(
      forResource: "car",
      withExtension: "obj",
      subdirectory: "Resources") else {
        fatalError("Could not find car.obj in bundle")
    }
    let car_mesh = try! loader.load(from: url)

    let car_object = GameObject(
      mesh: car_mesh,
      transform: Transform(
        position: SIMD3<Float>(0, 0, 0),
        rotation: SIMD3<Float>(0, 45, 0),
      )
    )
    scene.addObject(car_object)

    guard let url = Bundle.module.url(
      forResource: "lamp",
      withExtension: "obj",
      subdirectory: "Resources") else {
        fatalError("Could not find light.obj in bundle")
    }
    let lamp_mesh = try! loader.load(from: url)

    let lamp_object = GameObject(
      mesh: lamp_mesh,
      transform: Transform(
        position: SIMD3<Float>(0, 0.5, 3.5),
        rotation: SIMD3<Float>(0, 45, 0),
        scale: SIMD3<Float>(0.003, 0.003, 0.003),
      ),
    )
    scene.addObject(lamp_object)

    guard let url = Bundle.module.url(
      forResource: "cube",
      withExtension: "obj",
      subdirectory: "Resources") else {
        fatalError("Could not find cube.obj in bundle")
    }
    let cube_mesh = try! loader.load(from: url)

    let cube_object = GameObject(
      mesh: cube_mesh,
      transform: Transform(
        position: SIMD3<Float>(0.5, 5.3, 2.5),
        rotation: SIMD3<Float>(0, 0, 0),
        scale: SIMD3<Float>(0.5, 0.5, 0.5),
      )
    )

    scene.addObject(cube_object)
  }

  func buildGlobalBuffers(){
    var global_vertex_data: [Float] = []
    var global_index_data: [UInt32] = []
    var current_vertex_offset: Int = 0
    var current_index_offset: Int = 0
    var current_vertex_count: UInt32 = 0

    for i in 0..<scene.game_objects.count{
      let mesh = scene.game_objects[i].mesh

      scene.game_objects[i].mesh.vertex_offset = current_vertex_offset
      scene.game_objects[i].mesh.index_offset = current_index_offset

      global_vertex_data.append(contentsOf: mesh.vertexData())
      global_index_data.append(contentsOf: mesh.indices)

      current_vertex_offset += mesh.vertexData().count
      current_index_offset += mesh.indices.count
      current_vertex_count += UInt32(mesh.vertices.count)
    }

    globalVertexBuffer = device.makeBuffer(
      bytes: global_vertex_data,
      length: global_vertex_data.count * MemoryLayout<Float>.stride,
      options: []
    )
    globalIndexBuffer = device.makeBuffer(
      bytes: global_index_data,
      length: global_index_data.count * MemoryLayout<UInt32>.stride,
      options: []
    )
  }

  //called every frame
  func draw(in view: MTKView){
    let now = CACurrentMediaTime()
    let deltaTime = now - lastFrameTime
    lastFrameTime = now 
    angle += Float(deltaTime) * 2.0

    let proj_mat = camera.makePerspective()
    let eye = SIMD3<Float>(10, 5, 0)
    let center = SIMD3<Float>(0, 0, 0)
    let up = SIMD3<Float>(0, 1, 0)
    let view_mat = camera.lookAt(eye: eye, center: center, up: up)
    
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
    renderEncoder.setFragmentTexture(texture, index: 0)
    renderEncoder.setFragmentSamplerState(samplerState, index: 0)

    let bulbOffset = SIMD3<Float>(0, 1.5, 5)
    let bulbWorldPos = scene.game_objects[0].transform.position + bulbOffset

    // scene.game_objects[0].transform.rotation.y = angle
    //draw the object
    for (index, game_object) in scene.game_objects.enumerated(){
      let model_mat = game_object.transform.modelMatrix()

      let normalMatrix = simd_float3x3(
        model_mat.columns.0.xyz,
        model_mat.columns.1.xyz,
        model_mat.columns.2.xyz,
      ).inverse.transpose

      let uniforms = Uniforms(
        modelMatrix: model_mat,
        viewMatrix: view_mat,
        projectionMatrix: proj_mat,
        normalMatrix: normalMatrix,
        lightDirection: normalize(SIMD3<Float>(1, -1, -1)),
        lightColor: SIMD3<Float>(1, 1, 1),
        spotLightPosition: SIMD3<Float>(0.7, 3.0, 2.5),
        spotLightDirection: normalize(SIMD3<Float>(0, -1, 3)),
        spotLightColor: SIMD3<Float>(1.0, 0.9, 0.7),
        spotLightCutoff: cos(Float.pi / 4),
        spotLightOuterCutoff: cos(Float.pi / 2)
      )

      let offset = index * MemoryLayout<Uniforms>.stride
      let pointer = uniformBuffer
        .contents()
        .advanced(by: offset)
        .bindMemory(to: Uniforms.self, capacity: 1)
      pointer.pointee = uniforms
      
      renderEncoder.setVertexBuffer(
        globalVertexBuffer,
        offset: game_object.mesh.vertex_offset * MemoryLayout<Float>.stride,
        index: 0
      )
      renderEncoder.setVertexBuffer(uniformBuffer, offset: offset, index: 1)
      renderEncoder.setFragmentBuffer(uniformBuffer, offset: offset, index: 1)
      renderEncoder.drawIndexedPrimitives(
        type: .triangle,
        indexCount: game_object.mesh.indices.count,
        indexType: .uint32,
        indexBuffer: globalIndexBuffer,
        indexBufferOffset: game_object.mesh.index_offset * MemoryLayout<UInt32>.stride
      )
    }

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
