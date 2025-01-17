function Node_create_Image_Sequence(_x, _y, _group = noone) {
	var path = "";
	if(!LOADING && !APPENDING && !CLONING) {
		path = get_open_filenames_compat(".png", "");
		key_release();
		if(path == "") return noone;
	}
	
	var node = new Node_Image_Sequence(_x, _y, _group);
	var paths = string_splice(path, "\n");
	node.inputs[| 0].setValue(paths);
	node.doUpdate();
	return node;
}

function Node_create_Image_Sequence_path(_x, _y, _path) {
	var node = new Node_Image_Sequence(_x, _y, PANEL_GRAPH.getCurrentContext());
	node.inputs[| 0].setValue(_path);
	node.doUpdate();
	return node;
}

enum CANVAS_SIZE {
	individual,
	minimum,
	maximum
}

enum CANVAS_SIZING {
	padding,
	scale
}

function Node_Image_Sequence(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name  = "Image Array";
	spr   = [];
	color = COLORS.node_blend_input;
	
	inputs[| 0]  = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.path, [])
		.setDisplay(VALUE_DISPLAY.path_array, { filter: ["*.png", ""] });
	
	inputs[| 1]  = nodeValue("Padding", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [0, 0, 0, 0])
		.setDisplay(VALUE_DISPLAY.padding)
		.rejectArray();
	
	inputs[| 2] = nodeValue("Canvas size", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0) 
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Individual", "Minimum", "Maximum" ])
		.rejectArray();
	
	inputs[| 3] = nodeValue("Sizing method", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Padding / Crop", "Scale" ])
		.rejectArray();
	
	input_display_list = [
		["Array settings",	false], 0, 1, 2, 3
	];
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, []);
	outputs[| 1] = nodeValue("Paths", self, JUNCTION_CONNECT.output, VALUE_TYPE.path, [] ).
		setVisible(true, true);
	
	attribute_surface_depth();
	
	path_loaded = [];
	
	on_drop_file = function(path) {
		if(directory_exists(path)) {
			with(dialogCall(o_dialog_drag_folder, WIN_W / 2, WIN_H / 2)) {
				dir_paths = path;
				target    = other;
			}
			return true;
		}
		
		var paths = paths_to_array(path);
		
		inputs[| 0].setValue(path);
		if(updatePaths(paths)) {
			doUpdate();
			return true;
		}
		
		return false;
	}
	
	insp1UpdateTooltip  = __txt("Refresh");
	insp1UpdateIcon     = [ THEME.refresh, 1, COLORS._main_value_positive ];
	
	static onInspector1Update = function() {
		var path = getInputData(0);
		if(path == "") return;
		updatePaths(path);
		update();
	}
	
	function updatePaths(paths) {
		for(var i = 0; i < array_length(spr); i++) {
			if(spr[i] && sprite_exists(spr[i]))
				sprite_delete(spr[i]);
		}
		spr = [];
		
		path_loaded = array_create(array_length(paths));
		
		for( var i = 0, n = array_length(paths); i < n; i++ )  {
			path_loaded[i] = paths[i];
			var path = try_get_path(paths[i]);
			if(path == -1) continue;
			var ext = string_lower(filename_ext(path));
			setDisplayName(filename_name_only(path));
			
			switch(ext) {
				case ".png"	 :
				case ".jpg"	 :
				case ".jpeg" :
					array_push(spr, sprite_add(path, 1, false, false, 0, 0));
					break;
			}
		}
		
		outputs[| 1].setValue(paths);
		
		return true;
	}
	
	static update = function(frame = CURRENT_FRAME) {
		var path = getInputData(0);
		if(path == "") return;
		if(!is_array(path)) path = [ path ];
		if(!array_equals(path, path_loaded)) 
			updatePaths(path);
		
		var pad = getInputData(1);
		var can = getInputData(2);
		inputs[| 3].setVisible(can != CANVAS_SIZE.individual);
		
		var siz = getInputData(3);
		
		var ww = -1, hh = -1;
		var _ww = -1, _hh = -1;
		
		var surfs = outputs[| 0].getValue();
		var amo   = array_length(spr);
		for(var i = amo; i < array_length(surfs); i++)
			surface_free(surfs[i]);
		array_resize(surfs, amo);
		
		for(var i = 0; i < amo; i++) {
			var _spr = spr[i];
			var _w = sprite_get_width(_spr);
			var _h = sprite_get_height(_spr);
			
			switch(can) {
				case CANVAS_SIZE.minimum :
					if(ww == -1)	ww = _w;
					else			ww = min(ww, _w);
					if(hh == -1)	hh = _h;
					else			hh = min(hh, _h);
					break;
				case CANVAS_SIZE.maximum :
					if(ww == -1)	ww = _w;
					else			ww = max(ww, _w);
					if(hh == -1)	hh = _h;
					else			hh = max(hh, _h);
					break;
			}
		}
		_ww = ww;
		_hh = hh;
		ww += pad[0] + pad[2];
		hh += pad[1] + pad[3];
		
		for(var i = 0; i < array_length(spr); i++) {
			var _spr = spr[i];
			switch(can) {
				case CANVAS_SIZE.individual :
					ww = sprite_get_width(_spr) + pad[0] + pad[2];
					hh = sprite_get_height(_spr) + pad[1] + pad[3];
					
					surfs[i] = surface_verify(surfs[i], ww, hh, attrDepth());
					surface_set_target(surfs[i]);
						DRAW_CLEAR
						BLEND_OVERRIDE;
						draw_sprite(_spr, 0, pad[2], pad[1]);
						BLEND_NORMAL;
					surface_reset_target();
					break;
				case CANVAS_SIZE.maximum :
				case CANVAS_SIZE.minimum :
					surfs[i] = surface_verify(surfs[i], ww, hh, attrDepth());
					var _w = sprite_get_width(_spr);
					var _h = sprite_get_height(_spr);
						
					if(siz == CANVAS_SIZING.scale) {
						var ss = min(_ww / _w, _hh / _h);
						var sw = (ww - _w * ss) / 2;
						var sh = (hh - _h * ss) / 2;
						
						surface_set_target(surfs[i]);
							DRAW_CLEAR
							BLEND_OVERRIDE;
							draw_sprite_ext(_spr, 0, sw, sh, ss, ss, 0, c_white, 1);
							BLEND_NORMAL;
						surface_reset_target();
					} else {
						var xx = (ww - _w) / 2;
						var yy = (hh - _h) / 2;
						
						surface_set_target(surfs[i]);
							DRAW_CLEAR
							BLEND_OVERRIDE;
							draw_sprite(_spr, 0, xx, yy);
							BLEND_NORMAL;
						surface_reset_target();
					}
					break;
			}
			
		}
		
		outputs[| 0].setValue(surfs);
	}
}