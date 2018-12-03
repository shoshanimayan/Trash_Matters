extends KinematicBody2D

var t = 30
var speed = 40 
var moveDir = Vector2()
export(int) var moveTick = 30
var moveTickMax = moveTick
var motion
var freeWalk = true 
var playerDist 
export (int) var health = 1
export (int) var dmg = 1

var d
var distance

var heartDrop = preload("res://Nodes/pickups/Health.tscn")
var ammoDrop = preload("res://Nodes/pickups/Ammo.tscn")
var trashSmallDrop = preload("res://Nodes/pickups/Trash_small.tscn")

var newItem

var meleeDamage = 1

var Ray1
var Ray2
var Ray3
var Ray4

var player

func _ready():
	player = get_parent().get_node("Player")
	moveDir = direction.random()
	Ray1 = get_node("RayCast2D")
	Ray2 = get_node("RayCast2D2")
	Ray3 = get_node("RayCast2D3")
	Ray4 = get_node("RayCast2D4")

#loop for random movement
func movementLoop():
	motion = moveDir.normalized() * speed
	move_and_slide(motion, Vector2(0,0))

#todo, no wall crashing, add raycast so no run into wall or others
func runTowards(a):
	speed = 80
	a = a.normalized() 
	if 1-abs(a.x) < 1-abs(a.y):
		moveDir.x= direction.orientation(a.x)
		moveDir.y = 0
	else:
		moveDir.y = direction.orientation(a.y)
		moveDir.x = 0
	if is_on_wall():
		if moveDir.x == 0:
			moveDir.y=0
			match direction.orientation(a.x):
				1:
					moveDir.x = 1
				-1: 
					moveDir.x = -1
		else:
			moveDir.x = 0
			match direction.orientation(a.y):
				1:
					moveDir.y = 1
				-1: 
					moveDir.y = -1

func runLine(a):
	var other
	if Ray1.is_colliding():
		other = Ray1.get_collider()
		if other != null and other.has_method("get_hurt"):
			speed = 250
	#		runTowards(a)

			match $AnimatedSprite.animation:
				"left":
					moveDir = direction.left
					return true
				"right":
					moveDir = direction.right
					return true
				"up":
					moveDir = direction.up
					return true 
				"down":
					moveDir = direction.down
					return true

func attack():
	var other
	#print("attacking")
	if distance <= 26:
		player.get_hurt(dmg)
		player.push(moveDir,30)
	#print(distance)

func _physics_process(delta):
	if freeWalk:
		# Get distance between player and bunny
		playerDist =  player.position
		d = Vector2(playerDist-position)#.normalized()
		distance = sqrt((d.x*d.x)+(d.y*d.y))
		movementLoop()
		
		# If player is close, chase!
		if distance <= 100:
			speed = 80
			moveDir = Vector2(0,0)
			moveTick= moveTickMax
			runTowards(d)
		elif distance <= 125 && distance >=100:
			speed = 80
			d = d.normalized() 
			if 1-abs(d.x) < 1-abs(d.y):
				match direction.orientation(d.x):
					1: 
						$AnimatedSprite.animation = "right"
						Ray1.cast_to = Vector2(200,0)
					0:
						$AnimatedSprite.animation = "left"
						Ray1.cast_to = Vector2(-200,0)
			else:
				match direction.orientation(d.y):
					1: 
						$AnimatedSprite.animation = "down"
						Ray1.cast_to = Vector2(0,200)
					0:
						$AnimatedSprite.animation = "up"
						Ray1.cast_to = Vector2(0,-200)
			
		elif runLine(d):
			speed = 250
		else:
			speed = 40
			if moveTick > 0:
				moveTick -= 1
			if moveTick == 0 || is_on_wall():
				moveDir = direction.random()
				moveTick = moveTickMax
	
	else:
		speed = 40
		if moveTick > 0:
			moveTick -= 1
		if moveTick == 0 || is_on_wall():
			moveDir = direction.random()
			moveTick = moveTickMax
			freeWalk = true

func _process(delta):
	$AnimatedSprite.play()
	if moveDir == direction.right:
		$AnimatedSprite.animation = "right"
		Ray1.cast_to = Vector2(200,0)
		Ray2.cast_to = Vector2(50,0)
		Ray3.cast_to = Vector2(50,-15)
		Ray4.cast_to = Vector2(50,15)
	if moveDir == direction.left:
		$AnimatedSprite.animation = "left"
		Ray1.cast_to = Vector2(-200,0)
		Ray2.cast_to = Vector2(-50,0)
		Ray3.cast_to = Vector2(-50,-15)
		Ray4.cast_to = Vector2(-50,15)
	if moveDir == direction.up:
		$AnimatedSprite.animation = "up"
		Ray1.cast_to = Vector2(0,-200)
		Ray2.cast_to = Vector2(0,-50)
		Ray3.cast_to = Vector2(-15,-50)
		Ray4.cast_to = Vector2(15,-50)
	if moveDir == direction.down:
		$AnimatedSprite.animation = "down"
		Ray1.cast_to = Vector2(0,200)
		Ray2.cast_to = Vector2(0,50)
		Ray3.cast_to = Vector2(-15,50)
		Ray4.cast_to = Vector2(15,50)
	attack()

func hit(damage):
	health -= damage
	dieCheck()

func get_damage():
	return meleeDamage

func dropItems():
	match randi() % 3 + 1:
		2: 
			newItem = heartDrop.instance()
			newItem.position = position
			get_tree().get_root().add_child(newItem)
		1:
			newItem = ammoDrop.instance()
			newItem.position = position
			get_tree().get_root().add_child(newItem)
		3:
			newItem = trashSmallDrop.instance()
			newItem.position = position
			get_tree().get_root().add_child(newItem)

func dieCheck():
	if health <= 0:
		dropItems()
		$CollisionShape2D.disabled = true
		self.hide()
		#print(self.name, " has died")
		$AudioStreamPlayer.play()


func _on_AudioStreamPlayer_finished():
	self.queue_free()
