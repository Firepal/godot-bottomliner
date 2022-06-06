tool
extends Spatial

# Path does nothing right now
onready var p : Path = $Path
onready var m = $MeshInstance
export var ex_points : PoolVector3Array = PoolVector3Array([Vector3(),Vector3(1,0,-2)]) setget set_ex_points

func set_ex_points(val):
	ex_points = val
	_update()

func _ready():
	p.connect("curve_changed",self,"_update")
	_update()

func _gen_mesh(points : PoolVector3Array):
	if points.size() < 2:
		return ArrayMesh.new()
	
	var dir = Vector3.UP
	var last_p = null
	
	var _v = []
	var _n = []
	var _t = []
	var _c = []
	var _uv = []
	var _uv2 = []
	var _i = []
	_v.resize(points.size() * 3)
	_n.resize(_v.size())
	_t.resize(_v.size() * 4)
	_c.resize(_v.size())
	_uv.resize(_v.size())
	_uv2.resize(_v.size())
	_i.resize( (points.size() * (3*3)) + 6 )
	
	var inv_ps = 1.0/(points.size()+1)
	
	for i in range(points.size()):
		var p1 : Vector3 = points[i]
		
		if i < points.size()-1:
			dir = points[i+1] - p1
		
		printt( "CURRENT POINT: " + str(i) )
		var i_ = i
		
		i *= 3
		
		_v[i] = p1
		_v[i+1] = p1
		_v[i+2] = p1
		
		_n[i] = dir
		_n[i+1] = dir
		_n[i+2] = dir
		
		# last point
		var lp = p1
		if last_p != null:
			lp = last_p
		
		# can't store negative values in color
		# so we use plane method
		
		var lpp = Plane(lp, lp.length())
		
		var ip = i
		if ip != 0: ip += 1
		for _u in range(5):
			print("tangent ", ip)
			_t[ip] = lpp.normal.x
			_t[ip+1] = lpp.normal.y
			_t[ip+2] = lpp.normal.z
			_t[ip+3] = 1.0
			ip += 4
		
		var lpl = Color(lpp.d * 0.1,lpp.d * 0.4,lpp.d, (lpp.d - 3.0) * 0.1)
		
		_c[i] = lpl
		_c[i+1] = lpl
		_c[i+2] = lpl
		
		last_p = p1
		
		print( "yes ", inv_ps*i )
		print( _t)
		
		# Setup how the 3 vertices will be moved in vertex shader
		# Currently setup as "equilateral" triangle
		_uv[i] = Vector2(-0.5,-0.288671)
		_uv[i+1] = Vector2(0.5,-0.288671)
		_uv[i+2] = Vector2(0,0.577342)
		
		var uv_x = inv_ps*i
		
		_uv2[i  ] = Vector2(uv_x,0)
		_uv2[i+1] = Vector2(uv_x,0)
		_uv2[i+2] = Vector2(uv_x,0)
		
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
				var cn = c+3
				
				var n = c+1
				var nn = n+3
				
				print("SIDE: ", u)
				printt(c, n, points.size() * 3)
				
				_i[i] = n
				_i[i+1] = cn
				_i[i+2] = c
				
				_i[i+3] = n
				_i[i+4] = nn
				_i[i+5] = cn
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
	arrs[ArrayMesh.ARRAY_NORMAL] = PoolVector3Array(_n)
	arrs[ArrayMesh.ARRAY_TANGENT] = PoolRealArray(_t)
	arrs[ArrayMesh.ARRAY_COLOR] = PoolColorArray(_c)
	arrs[ArrayMesh.ARRAY_TEX_UV] = PoolVector2Array(_uv)
	arrs[ArrayMesh.ARRAY_TEX_UV2] = PoolVector2Array(_uv2)
	arrs[ArrayMesh.ARRAY_INDEX] = PoolIntArray(_i)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrs,[],ArrayMesh.ARRAY_COMPRESS_DEFAULT - ArrayMesh.ARRAY_COMPRESS_TANGENT)
	
	return mesh

func _update():
	m.mesh = _gen_mesh(ex_points)
