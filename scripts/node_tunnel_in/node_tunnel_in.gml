function Node_Tunnel_In(_x, _y, _group = -1) : Node(_x, _y, _group) constructor {
	name = "Tunnel In";
	previewable = false;
	color = COLORS.node_blend_tunnel;
	
	w = 96;
	
	inputs[| 0] = nodeValue( 0, "Name", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "" );
		
	inputs[| 1] = nodeValue( 1, "Value in", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, noone )
		.setVisible(true, true);
	
	error_notification = noone;
	
	static onDrawNodeBehind = function(_x, _y, _mx, _my, _s) {
		var xx = _x + x * _s;
		var yy = _y + y * _s;
		
		var hover = point_in_rectangle(_mx, _my, xx, yy, xx + w * _s, yy + h * _s);
		if(!hover) return;
		
		var _key = inputs[| 0].getValue();
		var amo = ds_map_size(TUNNELS_OUT);
		var k = ds_map_find_first(TUNNELS_OUT);
		repeat(amo) {
			if(TUNNELS_OUT[? k] == _key && ds_map_exists(NODE_MAP, k)) {
				var node = NODE_MAP[? k];
				
				draw_set_color(COLORS.node_blend_tunnel);
				draw_set_alpha(0.35);
				draw_line_width(xx + w * _s / 2, yy + h * _s / 2, _x + (node.x + node.w / 2) * _s, _y + (node.y + node.h / 2) * _s, 6 * _s);
				draw_set_alpha(1);
			}
			
			k = ds_map_find_next(TUNNELS_OUT, k);
		}
	}
	
	static onClone = function() { onValueUpdate(); }
	static update = function() { onValueUpdate(); }
	
	static resetMap = function() {
		var _key = inputs[| 0].getValue();
		TUNNELS_IN_MAP[? node_id] = _key;
		TUNNELS_IN[? _key] = inputs[| 1];
	}
	
	static checkDuplicate = function() {
		var _key = inputs[| 0].getValue();
		var amo = ds_map_size(TUNNELS_IN_MAP);
		var k   = ds_map_find_first(TUNNELS_IN_MAP);
		var dup = false;
		
		repeat(amo) {
			if(k != node_id && TUNNELS_IN_MAP[? k] == _key)
				dup = true;
			
			k = ds_map_find_next(TUNNELS_IN_MAP, k);
		}
		
		if(dup && error_notification == noone) {
			error_notification = noti_error("Duplicated key: " + string(_key));
			error_notification.onClick = function() { PANEL_GRAPH.focusNode(self); };
		} else if(!dup && error_notification) {
			noti_remove(error_notification);
			error_notification = noone;
		}
	}
	
	static onValueUpdate = function(index) {
		var _key = inputs[| 0].getValue();
		resetMap();
		
		var amo = ds_map_size(TUNNELS_IN_MAP);
		var k   = ds_map_find_first(TUNNELS_IN_MAP);
		repeat(amo) {
			if(ds_map_exists(NODE_MAP, k)) 
				NODE_MAP[? k].resetMap();
			k = ds_map_find_next(TUNNELS_IN_MAP, k);	
		}
		
		var k   = ds_map_find_first(TUNNELS_IN_MAP);
		repeat(amo) {
			if(ds_map_exists(NODE_MAP, k)) 
				NODE_MAP[? k].checkDuplicate();
			k = ds_map_find_next(TUNNELS_IN_MAP, k);	
		}
	}
	
	static step = function() {
		var _key = inputs[| 0].getValue();
		
		value_validation[VALIDATION.error] = error_notification != noone;
		
		if(inputs[| 1].value_from == noone) {
			inputs[| 1].type = VALUE_TYPE.any;
			inputs[| 1].display_type = VALUE_DISPLAY._default;
		} else {
			inputs[| 1].type = inputs[| 1].value_from.type;
			inputs[| 1].display_type = inputs[| 1].value_from.display_type;
		}
	}
	
	static getNextNodes = function() {
		var _key = inputs[| 0].getValue();
		var amo = ds_map_size(TUNNELS_OUT);
		var k = ds_map_find_first(TUNNELS_OUT);
		
		repeat(amo) {
			if(TUNNELS_OUT[? k] == _key) {
				NODE_MAP[? k].triggerRender();
				ds_queue_enqueue(RENDER_QUEUE, NODE_MAP[? k]);
			}
			
			k = ds_map_find_next(TUNNELS_OUT, k);
		}
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s) {
		draw_set_text(f_h5, fa_center, fa_center, COLORS._main_text);
		var str	= string(inputs[| 0].getValue());
		
		var bbox = drawGetBbox(xx, yy, _s);
		var ss	= string_scale(str, bbox.w, bbox.h);
		draw_text_transformed(bbox.xc, bbox.yc, str, ss, ss, 0);
	}
}