extends Node


###
# Swipe Detector implementation
# Captures a gesture and stores a history of all
# captured gestures.


## Signals

# Signal triggered when swipe captured
signal swiped(gesture)
signal swipe_ended(gesture) # alias for `swiped`

# Signal triggered when swipe started
signal swipe_started(point)

# Signal triggered when gesture is updated
signal swipe_updated(point)
signal swipe_updated_with_delta(point, delta)

# Signal triggered when swipe failed
# This means the swipe didn't pass thresholds and requirements
# to be detected as swipe.
signal swipe_failed()


## Exported Variables

# Minimum distance between points
export var distance_threshold = 25.0

# Indicate minimum swipe duration
# "A swipe will be a swipe if it the duration 
# is at least {{duration_threshold}} seconds"
export var duration_threshold = 0.05

# Minimum swipe points
# "A swipe will be captured if it has at least {{minimum_points}} points
export var minimum_points = 2

# Enable or disable gesture detection
export var detect_gesture = true setget detect


## Implementation

var capturing_gesture = false
var gesture_history
var gesture
var last_update_delta


func _ready():
	gesture_history = []


func detect(detect=true):
	set_process(detect)
	if not detect:
		clean_state()
	return self


func _process(delta):
	if not capturing_gesture and swiping():
		swipe_start()
	elif capturing_gesture and swiping():
		swipe_update(delta)
	elif capturing_gesture and not swiping():
		swipe_stop()

	
func clean_state():
	gesture = null
	last_update_delta = null
	capturing_gesture = false


func swiping():
	return Input.is_mouse_button_pressed(BUTTON_LEFT)


func swipePoint():
	return get_viewport().get_mouse_pos()


func swipe_start():
	var point = swipePoint()
	capturing_gesture = true
	last_update_delta = 0
	gesture = SwipeGesture.new()
	add_gesture_data(point)
	emit_signal('swipe_started', point)
	return self


func swipe_stop():
	#print('Ended gesture')
	print(gesture.to_string())
	if gesture.point_count() > minimum_points and gesture.get_duration() > duration_threshold:
		print('Captured gesture!')
		emit_signal('swiped', gesture)
		emit_signal('swipe_ended', gesture)
		gesture_history.append(gesture)
	else:
		emit_signal('swipe_failed')
	clean_state()
	return self


func swipe_update(delta):
	var point = swipePoint()
	last_update_delta += delta
	if gesture.last_point().distance_to(point) > distance_threshold:
		add_gesture_data(point, last_update_delta)
		emit_signal('swipe_updated', point)
		emit_signal('swipe_updated_with_delta', point, last_update_delta) 
		last_update_delta = 0


func add_gesture_data(point, delta=0):
	gesture.add_point(point)
	gesture.add_duration(delta)
	return self


func history():
	return gesture_history


func set_duration_threshold(value):
	duration_threshold = value
	return self


func set_distance_threshold(value):
	distance_threshold = value
	return self



## SwipeGesture class

class SwipeGesture:
	# Stores swipe data
	
	var points # list of points
	var duration # in seconds
	
	func _init():
		points = []
		duration = 0
		
	func get_duration():
		return duration
	
	func add_duration(delta):
		duration += delta
		return self
	
	func add_point(point):
		points.append(point)
		return self

	func first_point():
		return points[0]

	func last_point():
		return points[points.size() - 1]

	func to_string():
		return ('Swipe ' + str(first_point()) + ':' + str(last_point()) + 
			   ' ' + str(points.size()) + ', length: ' + str(duration))
	

	func get_curve():
		# Get a Curve2D from swipe points		
		var curve = Curve2D.new()
		for point in points:
			curve.add_point(point)
		return curve

	func get_points():
		return points
		
	func point_count():
		return points.size()