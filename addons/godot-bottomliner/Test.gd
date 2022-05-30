tool
extends Spatial

# Path does nothing right now
onready var p : Path = $Path
onready var m = $MeshInstance


func _ready():
	p.connect("curve_changed",self,"_update")
	_update()

func _gen_mesh(points : PoolVector3Array):
	if points.size() < 2:
		return ArrayMesh.new()
	
	var last = Vector3.UP
	
	var _v = []
	var _uv = []
	var _i = []
	_v.resize(points.size() * 3)
	_uv.resize(_v.size())
	_i.resize( (points.size() * (3*3)) + 6 )
	
	
	for i in range(points.size()):
		var p1 = points[i]
		
		printt( "CURRENT POINT: " + str(i) )
		var i_ = i
		
		i *= 3
		
		_v[i] = p1
		_v[i+1] = p1
		_v[i+2] = p1
		
		_uv[i] = Vector2(-1,-1)
		_uv[i+1] = Vector2(1,-1)
		_uv[i+2] = Vector2(0,1)
		
		if i_ < points.size()-1:
			print( i )
			var e = i
			
			# Start cap
			if i == 0:
				_i[i] = e+2
				_i[i+1] = e+1
				_i[i+2] = e
			else:
				i += i_ * 3
			
			# Offset for start cap
			i += 3
			
			# TODO: Second and third iterations create bad indices
			# Only bottom side correctly renders with more than two points
			# Help ¨n
			
			for u in range(3):
				var c = e+u
				var cn = c+1
				
				var n = c+2
				var nn = n+1
				
				print("SIDE: ", u)
				printt(c, n, points.size() * (3))
				
				_i[i] = c
				_i[i+1] = cn
				_i[i+2] = n
				
				_i[i+3] = cn
				_i[i+4] = nn
				_i[i+5] = n
				i += 6
			print( _i )
			
			
#			var c = e+1
#			var n = c+3
#			printt(c, n, points.size() * (3))
#			_i[i] = c
#			_i[i+1] = c + 1
#			_i[i+2] = n
#
#			_i[i+3] = c + 1
#			_i[i+4] = n + 1
#			_i[i+5] = n
#			i += 6
#
			# End cap
			if i_ == points.size()-2:
				_i[i] = e+3
				_i[i+1] = e+4
				_i[i+2] = e+5
		
	var mesh = ArrayMesh.new()
	
	var arrs = []
	arrs.resize(ArrayMesh.ARRAY_MAX)
	arrs[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(_v)
	arrs[ArrayMesh.ARRAY_INDEX] = PoolIntArray(_i)
	arrs[ArrayMesh.ARRAY_TEX_UV] = PoolVector2Array(_uv)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrs)
	
	return mesh

func _update():
	var points = p.curve.get_baked_points()
	points = [Vector3(),
		Vector3.FORWARD
#		Vector3(1,0,-2)
#		Vector3.FORWARD*3
	]
	
	m.mesh = _gen_mesh(points)
