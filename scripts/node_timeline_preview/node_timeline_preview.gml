function Node_Timeline_Preview(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Timeline";
	use_cache = CACHE_USE.auto;
	color = COLORS.node_blend_number;
	
	w = 96;
	
	
	PANEL_ANIMATION.timeline_preview = self;
	
	inputs[| 0] = nodeValue("Surface", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	static update = function(frame = CURRENT_FRAME) {
		var _inSurf = getInputData(0);
		if(_inSurf == 0) return;
		
		if(is_array(_inSurf)) {
			if(surface_exists(_inSurf[preview_index]))
				cacheCurrentFrame(_inSurf[preview_index]);	
		} else if(surface_exists(_inSurf))
			cacheCurrentFrame(_inSurf);
	}
}