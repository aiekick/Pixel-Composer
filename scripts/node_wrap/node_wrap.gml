function Node_Warp(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Warp";
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Top left", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ] )
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
	
	inputs[| 2] = nodeValue("Top right", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ DEF_SURF_W, 0 ] )
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
	
	inputs[| 3] = nodeValue("Bottom left", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, DEF_SURF_H ] )
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
	
	inputs[| 4] = nodeValue("Bottom right", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, DEF_SURF )
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
	
	inputs[| 5] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 5;
		
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	input_display_list = [ 5,
		["Surfaces", false], 0,
		["Wrap",	 false], 1, 2, 3, 4
	]
	
	attribute_surface_depth();
	attribute_interpolation();

	drag_side = -1;
	drag_mx = 0;
	drag_my = 0;
	drag_s = [[0, 0], [0, 0]];
	
	attributes[? "initalset"] = LOADING || APPENDING;
	
	static onValueFromUpdate = function(index) { #region
		if(index == 0 && attributes[? "initalset"] == false) {
			var _surf = getInputData(0);
			if(!is_surface(_surf)) return;
			
			var _sw = surface_get_width_safe(_surf);
			var _sh = surface_get_height_safe(_surf);
			
			inputs[| 1].setValue([   0,   0 ]);
			inputs[| 2].setValue([ _sw,   0 ]);
			inputs[| 3].setValue([   0, _sh ]);
			inputs[| 4].setValue([ _sw, _sh ]);
			
			attributes[? "initalset"] = true;
		}
	} if(!LOADING && !APPENDING) run_in(1, function() { onValueFromUpdate(0); }) #endregion
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) { #region
		PROCESSOR_OVERLAY_CHECK
		
		var _surf = outputs[| 0].getValue();
		if(is_array(_surf)) {
			if(array_length(_surf) == 0) return;
			_surf = _surf[preview_index];
		}
		
		var tl = array_clone(getInputData(1));
		var tr = array_clone(getInputData(2));
		var bl = array_clone(getInputData(3));
		var br = array_clone(getInputData(4));
		
		tl[0] = _x + tl[0] * _s;
		tr[0] = _x + tr[0] * _s;
		bl[0] = _x + bl[0] * _s;
		br[0] = _x + br[0] * _s;
		
		tl[1] = _y + tl[1] * _s;
		tr[1] = _y + tr[1] * _s;
		bl[1] = _y + bl[1] * _s;
		br[1] = _y + br[1] * _s;
		
		draw_set_color(COLORS._main_accent);
		draw_line(tl[0], tl[1], tr[0], tr[1]);
		draw_line(tl[0], tl[1], bl[0], bl[1]);
		draw_line(br[0], br[1], tr[0], tr[1]);
		draw_line(br[0], br[1], bl[0], bl[1]);
		
		if(inputs[| 1].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny)) active = false;
		if(inputs[| 2].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny)) active = false;
		if(inputs[| 3].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny)) active = false;
		if(inputs[| 4].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny)) active = false;
		
		var dx = 0;
		var dy = 0;
		
		if(drag_side > -1) {
			dx = (_mx - drag_mx) / _s;
			dy = (_my - drag_my) / _s;
			
			if(mouse_release(mb_left)) {
				drag_side = -1;	
				UNDO_HOLDING = false;
			}
		}
		
		draw_set_color(COLORS.node_overlay_gizmo_inactive);
		if(drag_side == 0) {
			draw_line_width(tl[0], tl[1], tr[0], tr[1], 3);
			
			var _tlx = value_snap(drag_s[0][0] + dx, _snx);
			var _tly = value_snap(drag_s[0][1] + dy, _sny);
			
			var _trx = value_snap(drag_s[1][0] + dx, _snx);
			var _try = value_snap(drag_s[1][1] + dy, _sny);
			
			var _up1 = inputs[| 1].setValue([ _tlx, _tly ]);
			var _up2 = inputs[| 2].setValue([ _trx, _try ]);
			
			if(_up1 || _up2) UNDO_HOLDING = true;
		} else if(drag_side == 1) {
			draw_line_width(tl[0], tl[1], bl[0], bl[1], 3);
			
			var _tlx = value_snap(drag_s[0][0] + dx, _snx);
			var _tly = value_snap(drag_s[0][1] + dy, _sny);
								  
			var _blx = value_snap(drag_s[1][0] + dx, _snx);
			var _bly = value_snap(drag_s[1][1] + dy, _sny);
			
			var _up1 = inputs[| 1].setValue([ _tlx, _tly ]);
			var _up3 = inputs[| 3].setValue([ _blx, _bly ]);
			
			if(_up1 || _up3) UNDO_HOLDING = true;
		} else if(drag_side == 2) {
			draw_line_width(br[0], br[1], tr[0], tr[1], 3);
			
			var _brx = value_snap(drag_s[0][0] + dx, _snx);
			var _bry = value_snap(drag_s[0][1] + dy, _sny);
								  
			var _trx = value_snap(drag_s[1][0] + dx, _snx);
			var _try = value_snap(drag_s[1][1] + dy, _sny);
			
			var _up4 = inputs[| 4].setValue([ _brx, _bry ]);
			var _up2 = inputs[| 2].setValue([ _trx, _try ]);
			
			if(_up4 || _up2) UNDO_HOLDING = true;
		} else if(drag_side == 3) {
			draw_line_width(br[0], br[1], bl[0], bl[1], 3);
			
			var _brx = value_snap(drag_s[0][0] + dx, _snx);
			var _bry = value_snap(drag_s[0][1] + dy, _sny);
								  
			var _blx = value_snap(drag_s[1][0] + dx, _snx);
			var _bly = value_snap(drag_s[1][1] + dy, _sny);
			
			var _up4 = inputs[| 4].setValue([ _brx, _bry ]);
			var _up3 = inputs[| 3].setValue([ _blx, _bly ]);
			
			if(_up4 || _up3) UNDO_HOLDING = true;
		} else if(active) {
			draw_set_color(COLORS._main_accent);
			if(distance_to_line_infinite(_mx, _my, tl[0], tl[1], tr[0], tr[1]) < 12) {
				draw_line_width(tl[0], tl[1], tr[0], tr[1], 3);
				if(mouse_press(mb_left, active)) {
					drag_side = 0;
					drag_mx = _mx;
					drag_my = _my;
					drag_s = [ current_data[1], current_data[2] ];
				}
			} else if(distance_to_line_infinite(_mx, _my, tl[0], tl[1], bl[0], bl[1]) < 12) {
				draw_line_width(tl[0], tl[1], bl[0], bl[1], 3);
				if(mouse_press(mb_left, active)) {
					drag_side = 1;
					drag_mx = _mx;
					drag_my = _my;
					drag_s = [ current_data[1], current_data[3] ];
				}
			} else if(distance_to_line_infinite(_mx, _my, br[0], br[1], tr[0], tr[1]) < 12) {
				draw_line_width(br[0], br[1], tr[0], tr[1], 3);
				if(mouse_press(mb_left, active)) {
					drag_side = 2;
					drag_mx = _mx;
					drag_my = _my;
					drag_s = [ current_data[4], current_data[2] ];
				}
			} else if(distance_to_line_infinite(_mx, _my, br[0], br[1], bl[0], bl[1]) < 12) {
				draw_line_width(br[0], br[1], bl[0], bl[1], 3);
				if(mouse_press(mb_left, active)) {
					drag_side = 3;
					drag_mx = _mx;
					drag_my = _my;
					drag_s = [ current_data[4], current_data[3] ];
				}
			}
		}
		
		inputs[| 1].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
		inputs[| 2].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
		inputs[| 3].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
		inputs[| 4].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region
		var tl = _data[1];
		var tr = _data[2];
		var bl = _data[3];
		var br = _data[4];
		
		var sw = surface_get_width_safe(_data[0]);
		var sh = surface_get_height_safe(_data[0]);
		
		var teq = round(tl[1]) == round(tr[1]);
		var beq = round(bl[1]) == round(br[1]);
		var leq = round(tl[0]) == round(bl[0]);
		var req = round(tr[0]) == round(br[0]);
		
		if(teq && beq && leq && req) {
			surface_set_shader(_outSurf)
			shader_set_interpolation(_data[0]);
			draw_surface_stretched_safe(_data[0], tl[0], tl[1], tr[0] - tl[0], bl[1] - tl[1]);
			surface_reset_shader();
		} else {
			surface_set_shader(_outSurf, sh_warp_4points);
			shader_set_interpolation(_data[0]);
				shader_set_dim("dimension", _data[0]);
				shader_set_f("p0", br[0] / sw, br[1] / sh);
				shader_set_f("p1", tr[0] / sw, tr[1] / sh);
				shader_set_f("p2", tl[0] / sw, tl[1] / sh);
				shader_set_f("p3", bl[0] / sw, bl[1] / sh);
			
				draw_surface_safe(_data[0], 0, 0);
			surface_reset_shader();
		}
		
		return _outSurf;
	} #endregion
}