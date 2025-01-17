function Node_Path_Reverse(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name		= "Reverse Path";
	previewable = false;
	
	w = 96;
	
	inputs[| 0] = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.pathnode, noone)
		.setVisible(true, true);
	
	outputs[| 0] = nodeValue("Path", self, JUNCTION_CONNECT.output, VALUE_TYPE.pathnode, self);
	
	static getLineCount = function() { 
		var _path = getInputData(0);
		return struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
	}
	
	static getSegmentCount = function(ind = 0) { 
		var _path = getInputData(0);
		return struct_has(_path, "getSegmentCount")? _path.getSegmentCount(ind) : 0; 
	}
	
	static getLength = function(ind = 0) { 
		var _path = getInputData(0);
		return struct_has(_path, "getLength")? _path.getLength(ind) : 0; 
	}
		
	static getAccuLength = function(ind = 0) { 
		var _path = getInputData(0);
		return struct_has(_path, "getAccuLength")? array_reverse(_path.getAccuLength(ind)) : []; 
	}
	
	static getBoundary = function(ind = 0) { 
		var _path = getInputData(0);
		return struct_has(_path, "getBoundary")? _path.getBoundary(ind) : new BoundingBox(0, 0, 1, 1); 
	}
		
	static getPointRatio = function(_rat, ind = 0, out = undefined) {
		if(out == undefined) out = new __vec2(); else { out.x = 0; out.y = 0; }
		var _path = getInputData(0);
		
		if(!is_struct(_path) || !struct_has(_path, "getPointRatio"))
			return out;
		return _path.getPointRatio(1 - _rat, ind, out);
	}
	
	static getPointDistance = function(_dist, ind = 0, out = undefined) { return getPointRatio(_dist / getLength(), ind, out); }
	
	static update = function() { 
		outputs[| 0].setValue(self);
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		draw_sprite_fit(s_node_path_trim, 0, bbox.xc, bbox.yc, bbox.w, bbox.h);
	}
}