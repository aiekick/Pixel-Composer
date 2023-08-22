function __vec3Sub(_x = 0, _y = _x, _z = _x) : __vec3(_x, _y, _z) constructor {
	old       = false;
	connected = [];
	
	static smooth = function() {
		if(array_empty(connected)) return;
		
		var _k = array_length(connected) / 2;
		var beta = 3 / (5 * _k);
		var _s = self.multiply(1 - _k * beta);
		var _c = new __vec3();
		
		for( var i = 0; i < array_length(connected); i++ ) 
			_c._add(connected[i]);
		_c._multiply(0.5 * beta)._add(_s);
		set(_c);
	}
	
	static connectTo = function(point) { array_push(connected, point); }
	
	static clearConnect = function() { connected = []; }
}

function __3dICOSphere(radius = 0.5, level = 2, smt = false) : __3dObject() constructor {
	VF = global.VF_POS_NORM_TEX_COL;
	render_type = pr_trianglelist;
	
	self.radius = radius;
	self.level  = level;
	self.smooth = smt;
	
	_vhash = ds_map_create();
	
	static getVertex = function(vertex) {
		var _hash = string(vertex);
		if(ds_map_exists(_vhash, _hash))
			return _vhash[? _hash];
		_vhash[? _hash] = vertex;
		return vertex;
	}
	
	static initModel = function() { // swap H, V because fuck me
		var _vertices = ds_list_create();
		var _normals  = ds_list_create();
		var _uvs      = ds_list_create();
		
		var phi = (1 + sqrt(5)) * 0.5; // golden ratio
		var a = 1.0;
		var b = 1.0 / phi;
	
		icoverts = [
			new __vec3Sub( 1,  1,  1)._normalize(),
			new __vec3Sub( 0,  b, -a)._normalize(),
			new __vec3Sub( b,  a,  0)._normalize(),
			new __vec3Sub(-b,  a,  0)._normalize(),
			new __vec3Sub( 0,  b,  a)._normalize(),
			new __vec3Sub( 0, -b,  a)._normalize(),
			new __vec3Sub(-a,  0,  b)._normalize(),
			new __vec3Sub( 0, -b, -a)._normalize(),
			new __vec3Sub( a,  0, -b)._normalize(),
			new __vec3Sub( a,  0,  b)._normalize(),
			new __vec3Sub(-a,  0, -b)._normalize(),
			new __vec3Sub( b, -a,  0)._normalize(),
			new __vec3Sub(-b, -a,  0)._normalize(),
		]
		
		array_foreach(icoverts, function(vert) { vert.old = true; })
		
		// Generate icosphere vertices
		ds_list_add(_vertices, icoverts[ 3], icoverts[ 2], icoverts[ 1]);
		ds_list_add(_vertices, icoverts[ 2], icoverts[ 3], icoverts[ 4]);
		ds_list_add(_vertices, icoverts[ 6], icoverts[ 5], icoverts[ 4]);
		ds_list_add(_vertices, icoverts[ 5], icoverts[ 9], icoverts[ 4]);
		ds_list_add(_vertices, icoverts[ 8], icoverts[ 7], icoverts[ 1]);
		ds_list_add(_vertices, icoverts[ 7], icoverts[10], icoverts[ 1]);
		ds_list_add(_vertices, icoverts[12], icoverts[11], icoverts[ 5]);
		ds_list_add(_vertices, icoverts[11], icoverts[12], icoverts[ 7]);
		ds_list_add(_vertices, icoverts[10], icoverts[ 6], icoverts[ 3]);
		ds_list_add(_vertices, icoverts[ 6], icoverts[10], icoverts[12]);
		ds_list_add(_vertices, icoverts[ 9], icoverts[ 8], icoverts[ 2]);
		ds_list_add(_vertices, icoverts[ 8], icoverts[ 9], icoverts[11]);
		ds_list_add(_vertices, icoverts[ 3], icoverts[ 6], icoverts[ 4]);
		ds_list_add(_vertices, icoverts[ 9], icoverts[ 2], icoverts[ 4]);
		ds_list_add(_vertices, icoverts[10], icoverts[ 3], icoverts[ 1]);
		ds_list_add(_vertices, icoverts[ 2], icoverts[ 8], icoverts[ 1]);
		ds_list_add(_vertices, icoverts[12], icoverts[10], icoverts[ 7]);
		ds_list_add(_vertices, icoverts[ 8], icoverts[11], icoverts[ 7]);
		ds_list_add(_vertices, icoverts[ 6], icoverts[12], icoverts[ 5]);
		ds_list_add(_vertices, icoverts[11], icoverts[ 9], icoverts[ 5]);
		
		for( var w = 1; w <= level; w++ ) { #region subdivide
		    ds_map_clear(_vhash);
			var newVertices = ds_list_create();
		    
		    for (var i = 0, n = ds_list_size(_vertices) / 3; i < n; i++) {
		        var v1 = _vertices[| i * 3 + 0];
		        var v2 = _vertices[| i * 3 + 1];
		        var v3 = _vertices[| i * 3 + 2];
				
		        var mid12Pos = getVertex(new __vec3Sub(v1.add(v2).divide(2)));
		        var mid23Pos = getVertex(new __vec3Sub(v2.add(v3).divide(2)));
		        var mid31Pos = getVertex(new __vec3Sub(v3.add(v1).divide(2)));
				
				v1.connectTo(mid12Pos); v1.connectTo(mid31Pos);
				v2.connectTo(mid12Pos); v2.connectTo(mid23Pos);
				v3.connectTo(mid23Pos); v3.connectTo(mid31Pos);
				
		        ds_list_add(newVertices, v1, mid12Pos, mid31Pos);
		        ds_list_add(newVertices, mid12Pos, v2, mid23Pos);
		        ds_list_add(newVertices, mid31Pos, mid23Pos, v3);
				ds_list_add(newVertices, mid12Pos, mid23Pos, mid31Pos);
		    }
			
			for (var i = 0, n = ds_list_size(newVertices); i < n; i++) {
				var _v = newVertices[| i];
				if(_v.old) _v.smooth();
				
				_v.old = true;
				_v.clearConnect();
			}
			
			ds_list_destroy(_vertices);
		    _vertices = newVertices;
		} #endregion

		for( var i = 0, n = ds_list_size(_vertices) / 3; i < n; i++ ) { #region normal, uv generation
			var _v0 = _vertices[| i * 3 + 0];
			var _v1 = _vertices[| i * 3 + 1];
			var _v2 = _vertices[| i * 3 + 2];
			var _n  = _v1.subtract(_v0).cross(_v2.subtract(_v0));
			var _u = [ 0, 0 ];
			
			ds_list_add(_normals, _n, _n, _n);
			ds_list_add(_uvs, _u, _u, _u);
		} #endregion
		
		vertex   = array_create(ds_list_size(_vertices));
		normals  = array_create(ds_list_size(_normals));
		uv       = ds_list_to_array(_uvs);
		
		for( var i = 0, n = ds_list_size(_vertices); i < n; i++ ) 
			vertex[i] = _vertices[| i].toArray();
		
		for( var i = 0, n = ds_list_size(_normals); i < n; i++ ) 
			normals[i] = _normals[| i].toArray();
		
		ds_list_destroy(_vertices);
		ds_list_destroy(_normals);
		ds_list_destroy(_uvs);
		
		VB = build();
	} initModel();
	
	static onParameterUpdate = initModel;
}