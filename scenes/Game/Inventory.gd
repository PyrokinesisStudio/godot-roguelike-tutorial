extends GridContainer

onready var objects = get_node('../InventoryObjects')
onready var name_label = get_node('../ItemName')

# Restore inventory objects from data
#func restore_item(data):
#	var ob = load(data.filename).instance()
#	if ob:
#		ob.restore(data,false)
#		print(ob.item != null)
#		add_to_inventory(ob)

# Get an array of all inventory Objects
func get_objects():
	return self.objects.get_children()

# Get the first free inventoryslot
func get_free_slot():
	for node in get_children():
		if node.contents.empty():
			return node

# find an inventoryslot which contains an item
func get_matching_slot(item):
	for node in get_children():
		if not node.contents.empty():
			if node.contents[0].name == item.name:
				return node

# add an item to an inventoryslot
func add_to_inventory(obj):
	print(obj.get_display_name())
	var slot = null

	if obj.item && obj.item.stackable:
		# find a matching slot
		slot = get_matching_slot(obj)
	# find free slot if no matches found
	if !slot: slot = get_free_slot()
	# break if no slots free
	if !slot: return
	
	# remove from world objects group
	if obj.is_in_group('world'):
		obj.remove_from_group('world')
	# add to inventory group
	if !obj.is_in_group('inventory'):
		obj.add_to_group('inventory')
	
	# shift item parent from Map to InventoryObjects
	if obj.get_parent() == RPG.map:
		obj.get_parent().remove_child(obj)
	objects.add_child(obj)
	
	# assign the obj to the slot
	slot.add_contents(obj)
	print(obj.get_groups())
	return OK


func remove_from_inventory(slot, item):
	slot.remove_contents(item)
	
	item.remove_from_group('inventory')
	item.add_to_group('world')

	item.get_parent().remove_child(item)
	RPG.map.add_child(item)
	item.set_map_pos(RPG.player.get_map_pos())
	

func call_drop_menu():
	var header = "Choose item(s) to Drop..."
	var footer = "ENTER to confirm, ESC or RMB to cancel"
	RPG.inventory_menu.start(true, header, footer)
	
func call_throw_menu():
	var header = "Choose an item to Throw..."
	var footer = "ENTER to confirm, ESC or RMB to cancel"
	RPG.inventory_menu.start(false, header, footer)




func _ready():
	RPG.inventory = self


func _on_slot_mouse_enter(slot):
	var name = '' if slot.contents.empty() else slot.contents[0].get_display_name()
	var count = slot.contents.size()
	var nt = '' if count < 2 else str(count)+'x '
	name_label.set_text(nt + name)

func _on_slot_mouse_exit():
	name_label.set_text('')


func _on_slot_button_pressed(slot):
	assert not slot.contents.empty()
	var obj = slot.contents[0]
	var result = yield(obj.item, 'used')
	
	if result == "OK":
		if not obj.item.indestructible:
			slot.remove_contents(obj)
			obj.kill()
		RPG.player.emit_signal('object_acted')
	else:
		RPG.broadcast(result, RPG.COLOR_BROWN)


func _on_slot_item_used(slot):
	assert not slot.contents.empty()
	slot.contents[0].item.use()


func _on_Drop_pressed():
	var cont = RPG.player.find_node('Controller')
	cont.Drop()


func _on_Throw_pressed():
	var cont = RPG.player.find_node('Controller')
	cont.Throw()


func _on_Grab_pressed():
	var cont = RPG.player.find_node('Controller')
	cont.Grab()
