struct Scene{
  var game_objects: [GameObject] = []

  mutating func addObject(_ object: GameObject){
    game_objects.append(object)
  }
}
