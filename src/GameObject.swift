struct GameObject{
  var transform: Transform
  var mesh: Object

  init(mesh: Object, transform: Transform = Transform()){
    self.mesh = mesh
    self.transform = transform
  }
}
