function Node(_x, _y) constructor {
	active  = true;
	node_id = NODE_ID++;
	group   = -1;
	color   = c_white;
	icon    = noone;
	bg_spr  = s_node_bg;
	bg_sel_spr = s_node_active;
	force_preview_channel = -1;
	
	if(!LOADING && !APPENDING) {
		recordAction(ACTION_TYPE.node_added, self);
		NODE_MAP[? node_id] = self;
		group = PANEL_GRAPH.getCurrentContext();
	}
	
	name = "";
	x = _x;
	y = _y;
	
	w = 128;
	h = 128;
	min_h = 128;
	auto_height = true;
	junction_shift_y = 32;
	
	input_display_list = -1;
	is_dynamic_output = false;
	inputs  = ds_list_create();
	outputs = ds_list_create();
	attributes = ds_map_create();
	
	show_input_name = false;
	show_output_name = false;
	
	always_output = false;
	inspecting = false;
	previewing = false;
	
	previewable   = true;
	preview_speed = 0;
	preview_index = 0;
	preview_frame = 0;
	preview_x     = 0;
	preview_y     = 0;
	
	output_preview_index = 0;
	
	rendered        = false;
	auto_update     = true;
	update_on_frame = false;
	
	use_cache		= false;
	cached_output	= [];
	
	tools			= -1;
	
	on_dragdrop_file = -1;
	
	anim_show = true;
	
	static setHeight = function() {
		var _hi = 32, _ho = 32;
		for( var i = 0; i < ds_list_size(inputs); i++ )  {
			if(inputs[| i].isVisible()) _hi += 24;
		}
		for( var i = 0; i < ds_list_size(outputs); i++ )  {
			if(outputs[| i].isVisible()) _ho += 24;
		}
		
		h = max(_hi, _ho, min_h);
	}
	
	static move = function(_x, _y) {
		x = _x;
		y = _y;
	}
	
	static stepBegin = function() {
		if(use_cache) {
			if(array_length(cached_output) != ANIMATOR.frames_total + 1)
				array_resize(cached_output, ANIMATOR.frames_total + 1);
		}
		
		if(always_output) {
			for(var i = 0; i < ds_list_size(outputs); i++) {
				if(outputs[| i].type == VALUE_TYPE.surface) {
					var val = outputs[| i].getValue();
					
					if(is_array(val)) {
						for(var j = 0; j < array_length(val); j++) {
							var _surf = val[j];
							if(!is_surface(_surf) || _surf == DEF_SURFACE) {
								rendered = false;
								UPDATE = true;	
							}
						}
					} else {
						if(!is_surface(val) || val == DEF_SURFACE) {
							rendered = false;
							UPDATE = true;	
						}
					}
				}
			}
		}
		
		if(ANIMATOR.is_playing || ANIMATOR.is_scrubing) {
			if(update_on_frame)
				doUpdate();
			for(var i = 0; i < ds_list_size(inputs); i++) {
				if(inputs[| i].isAnim()) {
					rendered = false;
					UPDATE = true;
				}
			}
		}
		
		if(auto_height)
			setHeight();
	}
	static step = function() {}
	static focusStep = function() {}
	
	static doUpdate = function() {
		update();
		rendered = true;
	}
	
	static onValueUpdate = function(index) {}
	
	static update = function() {}
	
	static updateValueFrom = function(index) {}
	
	static updateForward = function() {
		if(auto_update) doUpdate();
		
		for(var i = 0; i < ds_list_size(outputs); i++) {
			var jun = outputs[| i];
			for(var j = 0; j < ds_list_size(jun.value_to); j++) {
				var _to = jun.value_to[| j];
				if(_to.value_from == jun && _to.node.auto_update) {
					_to.node.updateForward();
				}
			}
		}
		doUpdateForward();
	}
	
	static doUpdateForward = function() {}
	
	static pointIn = function(_mx, _my) {
		var xx    = x;
		var yy    = y;
		
		return point_in_rectangle(_mx, _my, xx, yy, xx + w, yy + h);
	}
	
	static drawNodeBase = function(xx, yy, _s) {
		draw_sprite_stretched_ext(bg_spr, 0, xx, yy, w * _s, h * _s, color, 0.75);
	}
	
	static drawNodeName = function(xx, yy, _s) {
		if(name == "") return;
		
		if(_s * w > 48) {
			draw_sprite_stretched_ext(s_node_name, 0, xx, yy, w * _s, 20, color, 0.75);
			draw_set_text(f_p1, fa_left, fa_center, c_white);
			if(!auto_update) icon = s_refresh_16;
			if(icon) {
				draw_sprite_ext(icon, 0, xx + 12, yy + 10, 1, 1, 0, c_white, 1);	
				draw_text_cut(xx + 24, yy + 10, name, w * _s - 24);
			} else {
				draw_text_cut(xx + 8, yy + 10, name, w * _s - 8);
			}
		}
	}
	
	static drawJunctions = function(_x, _y, _mx, _my, _s) {
		var ss    = max(0.5, _s);
		var xx    = x * _s + _x;
		var yy    = y * _s + _y;
		var hover = noone;
		
		var _in = yy + junction_shift_y * _s;
		var amo = input_display_list == -1? ds_list_size(inputs) : max(ds_list_size(inputs), array_length(input_display_list));
		
		var _show_in = show_input_name;
		var _show_ot = show_output_name;
		var _draw_cc = c_white;
		
		show_input_name = false;
		show_output_name = false;
		
		for(var i = 0; i < amo; i++) {
			var jx  = xx;
			var jy  = _in;
			
			if(input_display_list == -1)
				jun = inputs[| i];
			else {
				var jun_list_arr = input_display_list[i];
				if(is_array(jun_list_arr)) continue;
				jun = inputs[| input_display_list[i]];
			}
			
			if(jun.isVisible()) {
				jun.y = jy;
				
				if(point_in_rectangle(_mx, _my, jx - 12 * _s, jy - 12 * _s, jx + 12 * _s, jy + 12 * _s) || DEBUG) {
					_draw_cc = c_white;
					hover = jun;
					show_input_name = true;
					draw_sprite_ext(jun.isArray()? s_node_junctions_array_hover : s_node_junctions_hover, jun.type, jx, jy, ss, ss, 0, c_white, 1);
				} else {
					_draw_cc = c_ui_blue_grey;
					draw_sprite_ext(jun.isArray()? s_node_junctions_array : s_node_junctions, jun.type, jx, jy, ss, ss, 0, c_white, 1);
				}
				
				if(_show_in) {
					draw_set_text(f_p1, fa_right, fa_center, _draw_cc);
					draw_text(jx - 12 * _s, jy, jun.name);
				}
				
				_in += 24 * _s;
			}
		}
		
		var _in = yy + junction_shift_y * _s;
		for(var i = 0; i < ds_list_size(outputs); i++) {
			var jx = xx + w * _s;
			var jy = _in;
			var jun = outputs[| i];
			
			if(jun.isVisible()) {
				jun.y = jy;
				
				if(point_in_rectangle(_mx, _my, jx - 12 * _s, jy - 12 * _s, jx + 12 * _s, jy + 12 * _s) || DEBUG) {
					_draw_cc = c_white;
					hover = jun;
					show_output_name = true;
					draw_sprite_ext(jun.isArray()? s_node_junctions_array_hover : s_node_junctions_hover, jun.type, jx, jy, ss, ss, 0, c_white, 1);
					
					if(jun.type == VALUE_TYPE.surface) {
						output_preview_index = i;
					}
				} else {
					_draw_cc = c_ui_blue_grey;
					draw_sprite_ext(jun.isArray()? s_node_junctions_array : s_node_junctions, jun.type, jx, jy, ss, ss, 0, c_white, 1);
				}
				
				if(_show_ot) {
					draw_set_text(f_p1, fa_left, fa_center, _draw_cc);
					draw_text(jx + 12 * _s, jy, jun.name);
				}
				
				_in += 24 * _s;
			}
		}
		
		return hover;
	}
	
	static drawConnections = function(_x, _y, mx, my, _s) {
		var xx = x * _s + _x;
		for(var i = 0; i < ds_list_size(inputs); i++) {
			var jun = inputs[| i];
			var jx = xx;
			var jy = jun.y;	
			
			if(jun.value_from && jun.isVisible()) {
				var frx = _x + jun.value_from.node.x * _s + jun.value_from.node.w * _s;
				var fry = jun.value_from.y;
					
				var c0 = value_color(jun.value_from.type);
				var c1 = value_color(jun.type);
				
				if(PREF_MAP[? "curve_connection_line"])
					draw_line_curve_color(jx, jy, frx, fry, max(1, 2 * _s), c0, c1);
				else
					draw_line_width_color(jx, jy, frx, fry, max(1, 2 * _s), c0, c1);
			}
		}
	}
	
	static drawPreview = function(_node, xx, yy, _s) {
		var surf = _node.getValue();
		if(is_array(surf)) {
			if(array_length(surf) == 0) return;
			
			if(preview_speed != 0) {
				preview_index += preview_speed;
				if(preview_index <= 0)
					preview_index = array_length(surf) - 1;
			}
			
			if(floor(preview_index) > array_length(surf) - 1) preview_index = 0;
			preview_frame = clamp(floor(preview_index), 0, array_length(surf) - 1);
			surf = surf[preview_frame];
		}
		
		if(is_surface(surf)) {
			var pw = surface_get_width(surf);
			var ph = surface_get_height(surf);
			var ps = min((w * _s - 8) / pw, (h * _s - 8) / ph);
			var px = xx + w * _s / 2 - pw * ps / 2;
			var py = yy + h * _s / 2 - ph * ps / 2;
			
			draw_surface_ext_safe(surf, px, py, ps, ps, 0, c_white, 1);
			//draw_set_color(c_ui_blue_grey);
			//draw_rectangle(px, py, px + pw * ps - 1, py + ph * ps - 1, true);
			
			draw_set_text(_s >= 1? f_p1 : f_p2, fa_center, fa_top, c_ui_blue_grey);
			draw_text(xx + w * _s / 2, yy + h * _s + 4 * _s, string(pw) + " x " + string(ph) + "px");
		}
	}
	
	static drawNode = function(_x, _y, _mx, _my, _s) {
		if(group != PANEL_GRAPH.getCurrentContext()) return;
		
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		drawNodeBase(xx, yy, _s);
		if(previewable && ds_list_size(outputs) > 0) 
			drawPreview(outputs[| output_preview_index], xx, yy, _s);
		drawNodeName(xx, yy, _s);
		onDrawNode(xx, yy, _mx, _my, _s);
		
		if(active_draw_index > -1) {
			draw_sprite_stretched(bg_sel_spr, active_draw_index, x * _s + _x, y * _s + _y, w * _s, h * _s);
			active_draw_index = -1;
		}
		
		return drawJunctions(_x, _y, _mx, _my, _s);
	}
	static onDrawNode = function(xx, yy, _mx, _my, _s) {}
	
	static drawBadge = function(_x, _y, _s) {
		var xx = x * _s + _x + w * _s;
		var yy = y * _s + _y;
		
		if(previewing) {
			draw_sprite(s_node_state, 0, xx, yy);
			xx -= max(32 * _s, 16);
		}
		if(inspecting) {
			draw_sprite(s_node_state, 1, xx, yy);
		}
		
		inspecting = false;
		previewing = false;
	}
	
	active_draw_index = -1;
	static drawActive = function(_x, _y, _s, ind = 0) {
		active_draw_index = ind;
	}
	
	static drawOverlay = function(_active, _x, _y, _s, _mx, _my) {}
	
	static destroy = function() {
		active = false;
		if(PANEL_GRAPH.node_hover      == self) PANEL_GRAPH.node_hover = noone;
		if(PANEL_GRAPH.node_focus      == self) PANEL_GRAPH.node_focus = noone;
		if(PANEL_GRAPH.node_previewing == self) PANEL_GRAPH.node_previewing = noone;
		if(PANEL_INSPECTOR.inspecting  == self) PANEL_INSPECTOR.inspecting  = noone;
		PANEL_ANIMATION.updatePropertyList();
		
		for(var i = 0; i < ds_list_size(outputs); i++) {
			var jun = outputs[| i];
			for(var j = 0; j < ds_list_size(jun.value_to); j++) {
				jun.value_to[| j].checkConnection();
			}
		}
		
		onDestroy();
	}
	static onDestroy = function() {}
	
	static cacheCurrentFrame = function(_frame) {
		if(array_length(cached_output) != ANIMATOR.frames_total + 1)
			array_resize(cached_output, ANIMATOR.frames_total + 1);
		if(ANIMATOR.current_frame > ANIMATOR.frames_total) return;
		
		var _os = cached_output[ANIMATOR.current_frame];
		if(is_surface(_os))
			surface_copy_size(_os, _frame);
		else {
			_os = surface_clone(_frame);
			cached_output[ANIMATOR.current_frame] = _os;
		}
	}
	static recoverCache = function() {
		if(ANIMATOR.current_frame >= array_length(cached_output)) return false;
		var _s = cached_output[ANIMATOR.current_frame];
		if(is_surface(_s)) {
			var _outSurf	= outputs[| 0].getValue();
			if(is_surface(_outSurf)) 
				surface_copy_size(_outSurf, _s);
			else {
				_outSurf = surface_clone(_s);
				outputs[| 0].setValue(_outSurf);
			}
			
			return true;
		}
		return false;
	}
	static clearCache = function() {
		if(array_length(cached_output) != ANIMATOR.frames_total + 1)
			array_resize(cached_output, ANIMATOR.frames_total + 1);
		for(var i = 0; i < array_length(cached_output); i++) {
			var _s = cached_output[i];
			if(is_surface(_s)) {
				surface_free(_s);
			}
			cached_output[i] = 0;
		}
	}
	
	static checkConnectGroup = function() {
		for(var i = 0; i < ds_list_size(inputs); i++) {
			var _in = inputs[| i];
			if(_in.value_from && _in.value_from.node.group != group) {
				var input_node = new Node_Group_Input(x - w - 64, y, group);
				input_node.inputs[| 2].setValue(_in.type);
				input_node.inputs[| 0].setValue(_in.display_type);
				
				ds_list_add(group.nodes, input_node);
				
				input_node._inParent.setFrom(_in.value_from);
				input_node.onValueUpdate(0);
				_in.setFrom(input_node.outputs[| 0]);
			}
		}	
		for(var i = 0; i < ds_list_size(outputs); i++) {
			var _ou = outputs[| i];
			for(var j = 0; j < ds_list_size(_ou.value_to); j++) {
				var _to = _ou.value_to[| j];
				if(_to.node.active && _to.node.group != group) {
					var output_node = new Node_Group_Output(x + w + 64, y, group);
					ds_list_add(group.nodes, output_node);
					
					_to.setFrom(output_node._outParent);
					output_node.inputs[| 0].setFrom(_ou);
				}
			}
		}
	}
	
	static serialize = function(scale = false) {
		var _map = ds_map_create();
		
		_map[? "id"]	= node_id;
		_map[? "name"]	= name;
		_map[? "x"]		= x;
		_map[? "y"]		= y;
		_map[? "type"]  = instanceof(self);
		_map[? "group"] = group == -1? -1 : group.node_id;
		
		var att = ds_map_create();
		ds_map_override(att, attributes);
		ds_map_add_map(_map, "attri", att);
		
		var _inputs = ds_list_create();
		for(var i = 0; i < ds_list_size(inputs); i++) {
			ds_list_add(_inputs, inputs[| i].serialize(scale));
			ds_list_mark_as_map(_inputs, i);
		}
		ds_map_add_list(_map, "inputs", _inputs);
		
		doSerialize(_map);
		return _map;
	}
	
	static doSerialize = function(_map) {}
	
	keyframe_scale = false;
	static deserialize = function(_map, scale = false) {
		keyframe_scale = scale;
		node_id = _map[? "id"] + APPEND_ID;
		NODE_MAP[? node_id] = self;
		NODE_ID = max(NODE_ID, node_id + 1);
		
		name  = _map[? "name"];
		_group = _map[? "group"];
		
		x = _map[? "x"];
		y = _map[? "y"];
		
		if(ds_map_exists(_map, "attri"))
			ds_map_override(attributes, _map[? "attri"]);
		
		var _inputs = _map[? "inputs"];
		
		if(!ds_list_empty(_inputs) && !ds_list_empty(inputs)) {
			var _siz = min(ds_list_size(_inputs), ds_list_size(inputs));
			for(var i = 0; i < _siz; i++) {
				inputs[| i].deserialize(_inputs[| i], scale);
			}
		}
		
		doDeserialize(_map);
	}
	
	static doDeserialize = function(_map) {}
	
	static postDeserialize = function() {}
	
	static connect = function() {
		if(_group == -1) {
			var c = PANEL_GRAPH.getCurrentContext();
			if(c != -1) c.add(self);
		} else {
			if(ds_map_exists(NODE_MAP, _group + APPEND_ID))
				NODE_MAP[? _group + APPEND_ID].add(self);
		}
		
		preConnect();
		
		var connected = true;
		for(var i = 0; i < ds_list_size(inputs); i++) {
			connected &= inputs[| i].connect();
		}
		if(!connected) ds_queue_enqueue(CONNECTION_CONFLICT, self);
		
		doConnect();
	}
	
	static preConnect = function() {}
	static doConnect = function() {}
}