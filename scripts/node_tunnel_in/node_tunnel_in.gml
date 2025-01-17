function Node_Tunnel_In(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Tunnel In";
	previewable = false;
	color = COLORS.node_blend_tunnel;
	
	w = 96;
	
	inputs[| 0] = nodeValue("Name", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "" )
		.rejectArray();
		
	inputs[| 1] = nodeValue("Value in", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, noone )
		.setVisible(true, true);
	
	error_notification = noone;
	
	insp2UpdateTooltip = "Create tunnel out";
	insp2UpdateIcon    = [ THEME.tunnel, 0, c_white ];
	
	static onInspector2Update = function() { #region
		var _node = nodeBuild("Node_Tunnel_Out", x + 128, y);
		_node.inputs[| 0].setValue(getInputData(0));
	} #endregion
	
	static onDrawNodeBehind = function(_x, _y, _mx, _my, _s) { #region
		var xx = _x + x * _s;
		var yy = _y + y * _s;
		
		var hover = PANEL_GRAPH.pHOVER && point_in_rectangle(_mx, _my, xx, yy, xx + w * _s, yy + h * _s);
		var tun   = findPanel("Panel_Tunnels");
		hover |= tun && tun.tunnel_hover == self;
		if(!hover) return;
		
		var _key = getInputData(0);
		var amo  = ds_map_size(TUNNELS_OUT);
		var k    = ds_map_find_first(TUNNELS_OUT);
		repeat(amo) {
			if(TUNNELS_OUT[? k] == _key && ds_map_exists(PROJECT.nodeMap, k)) {
				var node = PROJECT.nodeMap[? k];
				if(node.group != group) continue;
				
				draw_set_color(COLORS.node_blend_tunnel);
				draw_set_alpha(0.35);
				var frx = xx + w * _s / 2;
				var fry = yy + h * _s / 2;
				var tox = _x + (node.x + node.w / 2) * _s;
				var toy = _y + (node.y + node.h / 2) * _s;
				draw_line_dashed(frx, fry, tox, toy, 8 * _s, 16 * _s, current_time / 10);
				draw_set_alpha(1);
			}
			
			k = ds_map_find_next(TUNNELS_OUT, k);
		}
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { onValueUpdate(); }
	
	static resetMap = function() { #region
		var _key = getInputData(0);
		TUNNELS_IN_MAP[? node_id] = _key;
		TUNNELS_IN[? _key] = inputs[| 1];
	} #endregion
	
	static checkDuplicate = function() { #region
		var _key = getInputData(0);
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
	} #endregion
	
	static onValueUpdate = function(index = -1) { #region
		var _key = getInputData(0);
		resetMap();
		
		var amo = ds_map_size(TUNNELS_IN_MAP);
		var k   = ds_map_find_first(TUNNELS_IN_MAP);
		repeat(amo) {
			if(ds_map_exists(PROJECT.nodeMap, k) && struct_has(PROJECT.nodeMap[? k], "resetMap")) 
				PROJECT.nodeMap[? k].resetMap();
			k = ds_map_find_next(TUNNELS_IN_MAP, k);	
		}
		
		var k   = ds_map_find_first(TUNNELS_IN_MAP);
		repeat(amo) {
			if(ds_map_exists(PROJECT.nodeMap, k) && struct_has(PROJECT.nodeMap[? k], "checkDuplicate")) 
				PROJECT.nodeMap[? k].checkDuplicate();
			k = ds_map_find_next(TUNNELS_IN_MAP, k);	
		}
		
		if(index == 0) { RENDER_ALL_REORDER }
	} #endregion
	
	static step = function() { #region
		var _key = getInputData(0);
		
		value_validation[VALIDATION.error] = error_notification != noone;
		
		if(inputs[| 1].isLeaf()) {
			inputs[| 1].setType(VALUE_TYPE.any);
			inputs[| 1].display_type = VALUE_DISPLAY._default;
		} else {
			inputs[| 1].setType(inputs[| 1].value_from.type);
			inputs[| 1].display_type = inputs[| 1].value_from.display_type;
		}
	} #endregion
	
	static getNextNodes = function() { #region
		var nodes = [];
		var nodeNames = [];
		var _key = getInputData(0);
		var amo = ds_map_size(TUNNELS_OUT);
		var k = ds_map_find_first(TUNNELS_OUT);
		
		LOG_BLOCK_START();
		LOG_IF(global.FLAG.render == 1, $"→→→→→ Call get next node from: {INAME}");
		LOG_BLOCK_START();
		
		repeat(amo) {
			if(TUNNELS_OUT[? k] == _key) {
				array_push(nodes, PROJECT.nodeMap[? k]);
				array_push(nodeNames, PROJECT.nodeMap[? k].internalName);
			}
			
			k = ds_map_find_next(TUNNELS_OUT, k);
		}
		
		LOG_IF(global.FLAG.render == 1, $"→→ Push {nodeNames} to queue.");
		
		LOG_BLOCK_END();
		LOG_BLOCK_END();
		return nodes;
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		draw_set_text(f_sdf, fa_center, fa_center, COLORS._main_text);
		var str	= string(getInputData(0));
		
		var bbox = drawGetBbox(xx, yy, _s);
		var ss	= string_scale(str, bbox.w, bbox.h);
		draw_text_transformed(bbox.xc, bbox.yc, str, ss, ss, 0);
	} #endregion
	
	static onClone = function() { onValueUpdate(0); }
	
	static postConnect = function() { onValueUpdate(0); }
	
	static onDestroy = function() { #region
		if(error_notification != noone)
			noti_remove(error_notification);
	} #endregion
}