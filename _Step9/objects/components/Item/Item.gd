extends Node

signal used(result)
signal landed(pos)

onready var owner = get_parent()

export(String,\
	'heal_player', 'damage_nearest',\
	'confuse_target', 'blast_cell'\
	) var use_function = ''

export(String, MULTILINE) var effect_name
export(int) var param1 = 0

export(bool) var stackable = false
export(bool) var indestructible = false

export(int,0,8) var throw_range = 0
export(int) var throw_damage = 0

var inventory_slot

var throw_path = [] setget _set_throw_path


func use():
	if use_function.empty():
		RPG.broadcast(owner.get_display_name() + " cannot be used", RPG.COLOR_DARK_GREY)
		return
	if has_method(use_function):
		call(use_function)


func pickup():
	var result = RPG.inventory.add_to_inventory(owner)
	return result

func drop():
	assert inventory_slot != null
	RPG.inventory.remove_from_inventory(inventory_slot,owner)

func throw():
	if self.throw_range <= 0:
		RPG.broadcast("You cannot throw that!")
		return
	else:
		RPG.broadcast("Which direction? Click the map to confirm, RMB to cancel")
	var cell = yield(RPG.game, 'map_clicked')
	
	if cell == null:
		RPG.broadcast("action cancelled")
		return
	else:
		RPG.broadcast("You throw " + owner.get_display_name())
		drop()
		
		var path = FOVGen.get_line(RPG.player.get_map_pos(), cell)
		if not path.empty():
			var tpath = []
			for cell in path:
				var actor = RPG.map.get_actor_in_cell(cell)
				if actor and actor != RPG.player:
					tpath.append(cell)
					break
				elif RPG.map.is_wall(cell):
					break
				else:
					tpath.append(cell)
			
			if tpath.size() > self.throw_range+1:
				tpath.resize(self.throw_range+1)
			self.throw_path = tpath
			var done = yield(self, 'landed')
			
			var target_cell = owner.get_map_pos()
			var target = RPG.map.get_actor_in_cell(target_cell)
			if target and target != RPG.player:
				if self.throw_damage > 0:
					target.fighter.take_damage(owner.get_display_name(), self.throw_damage)
		RPG.player.emit_signal('object_acted')

func _ready():
	owner.item = self



# USE FUNCTIONS
func heal_player():
	var amount = self.param1
	if RPG.player.fighter.is_hp_full():
		emit_signal('used', "You're already at full health")
		return
	RPG.player.fighter.heal_damage(owner.get_display_name(), amount)
	emit_signal('used', "OK")

func damage_nearest():
	var amount = self.param1
	var target = RPG.map.get_nearest_visible_actor()
	if not target:
		emit_signal('used', "No targets in sight")
		return
	target.fighter.take_damage(self.effect_name, amount)
	var fx_tex = preload('res://graphics/effects/bolt01.png')
	RPG.map.spawn_fx(fx_tex, target.get_map_pos())
	emit_signal('used', "OK")

func confuse_target():
	var target = null
	# instruct the player to choose a target or cancel
	RPG.broadcast("Use your mouse to target an enemy.  LMB to select a target, RMB to cancel")
	# yield for map clicking feedback
	var callback = yield(RPG.game, 'map_clicked')
	
	# callback==null = RMB to cancel
	if callback==null:
		emit_signal('used', "action cancelled")
		return
	# cell clicked
	else:
		# assign potential target
		target = RPG.map.get_actor_in_cell(callback)
	# if no actor in cell
	if not target:
		emit_signal('used', "no target there")
		return
	# if clicking yourself
	elif target == RPG.player:
		emit_signal('used', "you cannot target yourself!")
		return
	
	# found valid target
	RPG.broadcast(target.get_display_name() + " looks very confused!", RPG.COLOR_BROWN)
	target.fighter.apply_status_effect('confused',param1)
	emit_signal('used', "OK")
	
func blast_cell():
	var amount = param1
	var target_cell = null
	# instruct the player to choose a target or cancel
	RPG.broadcast("Use your mouse to target a visible space.  LMB to select a target, RMB to cancel")
	# yield for map clicking feedback
	var callback = yield(RPG.game, 'map_clicked')
	
	# callback==null = RMB to cancel
	if callback == null:
		emit_signal('used', "action cancelled")
		return
	if not callback in RPG.map.fov_cells:
		emit_signal('used', "can't cast there!")
		return
	target_cell = callback
	
	# list of actors in blast area
	var actors = []
	
	var rect = []
	for x in range(-1,2):
		for y in range(-1,2):
			var cell = Vector2(x,y) + target_cell
			if not RPG.map.is_wall(cell):
				rect.append(cell)
				var fx_tex = preload('res://graphics/effects/bolt04.png')
				RPG.map.spawn_fx(fx_tex, cell)
	
	for node in get_tree().get_nodes_in_group('actors'):
		if node.get_map_pos() in rect:
			actors.append(node)
	for obj in actors:
		obj.fighter.take_damage(effect_name, amount)
	emit_signal('used', "OK")

func _process(delta):
	if throw_path.empty():
		emit_signal('landed', owner.get_map_pos())
		set_process(false)
	else:
		var i = min(throw_path.size()-1, 1)
		owner.set_map_pos(throw_path[i], true)
		throw_path.remove(0)



func _set_throw_path(what):
	throw_path = what
	if !throw_path.empty():
		set_process(true)
	