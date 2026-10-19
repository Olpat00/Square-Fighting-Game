extends SceneTree
var world: MatchWorld
var rows: Array[Dictionary] = []
func _initialize(): run.call_deferred()
func run():
 world = MatchWorld.new()
 root.add_child(world)
 await process_frame
 world.start([{"fighter":"f05_fine_print","device":"CPU"},{"fighter":"f01_clutch","device":"CPU"}], "Fair Fight")
 world.countdown = 0
 var a: RiotFighter = world.fighters[0]
 var b: RiotFighter = world.fighters[1]
 a.position = Vector3(-0.4, 0, 0)
 b.position = Vector3(0.2, 0, 0)
 a.provider = ScriptedInputProvider.new([{"from":0,"to":0,"move":Vector2(0, 1),"actions":["special"]}])
 b.provider = ScriptedInputProvider.new([{"from":0,"to":200,"actions":["defend"]}])
 world.presentation_event.connect(func(event: String, actor: int, at: Vector3, details: Dictionary):
  if event in ["shield", "hit", "parry"]:
   rows.append({"event":event,"world_tick":world.tick,"move_tick":a.move_tick,"hitstop":a.hitstop,"source_position":str(a.position),"shield":b.shield})
 )
 for i in 90:
  world.step()
  if i < 15: print(i, " ", a.state, " ", a.move_tick, " ", a.position, " ", b.state, " ", b.position)
 print("REHIT_PROBE ", JSON.stringify(rows))
 world.queue_free()
 await process_frame
 quit()



