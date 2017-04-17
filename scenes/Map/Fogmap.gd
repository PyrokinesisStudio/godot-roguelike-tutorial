extends TileMap

onready var map = get_parent()



func get_datamap():
	var data = []
	var size = RPG.MAP_SIZE
	for x in range(size.x):
		var col = []
		for y in range(size.y):
			col.append(get_cell(x,y))
		data.append(col)
	return data


func fill():
	var size = RPG.MAP_SIZE
	for x in range(size.x):
		for y in range(size.y):
			set_cell(x,y,0)

func reveal(cells):
	map.fov_cells = cells
	for cell in cells:
		if get_cellv(cell) != -1:
			set_cellv(cell,-1)

func reveal_from_data(data):
	var cells = []
	for x in range(data.size()-1):
		for y in range(data[x].size()-1):
			if data[x][y] == -1:
				cells.append(Vector2(x,y))
	reveal(cells)

func _ready():
	fill()


func _on_player_pos_changed(player):
	# Torch (sight) radius
	var r = RPG.TORCH_RADIUS
	
	# Get FOV cells
	var cells = FOVGen.calculate_fov(DungeonGen.datamap, 1, player.get_map_pos(), r)
	# Reveal cells
	reveal(cells)
	
	# Process Object visibility
	for node in get_tree().get_nodes_in_group('objects'):
		node.seen = node.get_map_pos() in cells
		# Keep discovered stay_visible objects seen
		if node.discovered and node.stay_visible:
			node.seen = true
	map.set_cursor()

