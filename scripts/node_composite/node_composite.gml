enum NODE_COMPOSE_DRAG {
	move,
	rotate,
	scale
}

enum COMPOSE_OUTPUT_SCALING {
	first,
	largest,
	constant
}

function Node_Composite(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name		= "Composite";
	
	inputs[| 0] = nodeValue("Padding", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 0, 0, 0, 0 ])
		.setDisplay(VALUE_DISPLAY.padding);
	
	inputs[| 1] = nodeValue("Output dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, COMPOSE_OUTPUT_SCALING.first)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "First surface", "Largest surface", "Constant" ]);
	
	inputs[| 2] = nodeValue("Dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, DEF_SURF)
		.setDisplay(VALUE_DISPLAY.vector)
		.setVisible(false);
	
	attribute_surface_depth();
	attribute_interpolation();
	
	setIsDynamicInput(4);
	
	attributes.layer_visible    = [];
	attributes.layer_selectable = [];
	
	hold_visibility = true;
	hold_select		= true;
	layer_dragging	= noone;
	layer_remove	= -1;
	layer_renderer	= new Inspector_Custom_Renderer(function(_x, _y, _w, _m, _hover, _focus) { #region
		var amo = (ds_list_size(inputs) - input_fix_len) / data_length - 1;
		if(array_length(current_data) != ds_list_size(inputs)) return 0;
		
		var lh = 32;
		var _h = 8 + max(1, amo) * (lh + 4) + 8;
		layer_renderer.h = _h;
		draw_sprite_stretched_ext(THEME.ui_panel_bg, 1, _x, _y, _w, _h, COLORS.node_composite_bg_blend, 1);
		
		var _vis = attributes.layer_visible;
		var _sel = attributes.layer_selectable;
		var ly   = _y + 8;
		var ssh  = lh - 6;
		var hoverIndex = noone;
		draw_set_color(COLORS.node_composite_separator);
		draw_line(_x + 16, ly, _x + _w - 16, ly);
		
		layer_remove = -1;
		for(var i = 0; i < amo; i++) {
			var ind   = amo - i - 1;
			var index = input_fix_len + ind * data_length;
			var _surf = current_data[index + 0];
			var _pos  = current_data[index + 1];
			
			var _bx = _x + _w - 24;
			var _cy = ly + i * (lh + 4);
			
			if(point_in_circle(_m[0], _m[1], _bx, _cy + lh / 2, 16)) {
				draw_sprite_ui_uniform(THEME.icon_delete, 3, _bx, _cy + lh / 2, 1, COLORS._main_value_negative);
				
				if(mouse_press(mb_left, _focus))
					layer_remove = ind;
			} else 
				draw_sprite_ui_uniform(THEME.icon_delete, 3, _bx, _cy + lh / 2, 1, COLORS._main_icon);
			
			if(!is_surface(_surf)) continue;
			
			var aa = (ind != layer_dragging || layer_dragging == noone)? 1 : 0.5;
			var vis = _vis[ind];
			var sel = _sel[ind];
			var hover = point_in_rectangle(_m[0], _m[1], _x, _cy, _x + _w, _cy + lh);
			
			draw_set_color(COLORS.node_composite_separator);
			draw_line(_x + 16, _cy + lh + 2, _x + _w - 16, _cy + lh + 2);
			
			var _bx = _x + 24 * 2 + 8;
			if(point_in_circle(_m[0], _m[1], _bx, _cy + lh / 2, 12)) {
				draw_sprite_ui_uniform(THEME.junc_visible, vis, _bx, _cy + lh / 2, 1, c_white);
				
				if(mouse_press(mb_left, _focus))
					hold_visibility = !_vis[ind];
					
				if(mouse_click(mb_left, _focus) && _vis[ind] != hold_visibility) {
					_vis[ind] = hold_visibility;
					doUpdate();
				}
			} else 
				draw_sprite_ui_uniform(THEME.junc_visible, vis, _bx, _cy + lh / 2, 1, COLORS._main_icon, 0.5 + 0.5 * vis);
			
			_bx += 24 + 8;
			if(point_in_circle(_m[0], _m[1], _bx, _cy + lh / 2, 12)) {
				draw_sprite_ui_uniform(THEME.cursor_select, sel, _bx, _cy + lh / 2, 1, c_white);
				
				if(mouse_press(mb_left, _focus))
					hold_select = !_sel[ind];
					
				if(mouse_click(mb_left, _focus) && _sel[ind] != hold_select)
					_sel[ind] = hold_select;
			} else 
				draw_sprite_ui_uniform(THEME.cursor_select, sel, _bx, _cy + lh / 2, 1, COLORS._main_icon, 0.5 + 0.5 * sel);
			
			draw_set_color(COLORS.node_composite_bg);
			var _sx0 = _bx + 24;
			var _sx1 = _sx0 + ssh;
			var _sy0 = _cy + 3;
			var _sy1 = _sy0 + ssh;
			draw_rectangle(_sx0, _sy0, _sx1, _sy1, true);
			
			var _ssw = surface_get_width_safe(_surf);
			var _ssh = surface_get_height_safe(_surf);
			var _sss = min(ssh / _ssw, ssh / _ssh);
			draw_surface_ext_safe(_surf, _sx0, _sy0, _sss, _sss, 0, c_white, 1);
			
			draw_set_text(f_p1, fa_left, fa_center, hover? COLORS._main_text : COLORS._main_text);
			draw_set_alpha(aa);
			draw_text(_sx1 + 12, _cy + lh / 2, inputs[| index].name);
			draw_set_alpha(1);
			
			if(_hover && point_in_rectangle(_m[0], _m[1], _x, _cy, _x + _w, _cy + lh)) {
				hoverIndex = ind;
				if(layer_dragging != noone) {
					draw_set_color(COLORS._main_accent);
					if(layer_dragging > ind)
						draw_line_width(_x + 16, _cy + lh + 2, _x + _w - 16, _cy + lh + 2, 2);
					else if(layer_dragging < ind)
						draw_line_width(_x + 16, _cy - 2, _x + _w - 16, _cy - 2, 2);
				}
			}
			
			if(layer_dragging == noone || layer_dragging == ind) {
				var _bx = _x + 24;
				if(point_in_circle(_m[0], _m[1], _bx, _cy + lh / 2, 16)) {
					draw_sprite_ui_uniform(THEME.hamburger_s, 3, _bx, _cy + lh / 2, 1, c_white);
				
					if(mouse_press(mb_left, _focus))
						layer_dragging = ind;
				} else 
					draw_sprite_ui_uniform(THEME.hamburger_s, 3, _bx, _cy + lh / 2, 1, COLORS._main_icon);
			}
		}
		
		if(layer_dragging != noone && mouse_release(mb_left)) {
			if(layer_dragging != hoverIndex && hoverIndex != noone) {
				var index = input_fix_len + layer_dragging * data_length;
				var targt = input_fix_len + hoverIndex * data_length;
				var _vis = attributes.layer_visible;
				var _sel = attributes.layer_selectable;
				
				var ext = [];
				var vis = _vis[layer_dragging];
				array_delete(_vis, layer_dragging, 1);
				array_insert(_vis, hoverIndex, vis);
				
				var sel = _sel[layer_dragging];
				array_delete(_sel, layer_dragging, 1);
				array_insert(_sel, hoverIndex, sel);
				
				for( var i = 0; i < data_length; i++ ) {
					ext[i] = inputs[| index];
					ds_list_delete(inputs, index);
				}
				
				for( var i = 0; i < data_length; i++ )
					ds_list_insert(inputs, targt + i, ext[i]);
				
				doUpdate();
			}
			
			layer_dragging = noone;
		}
		
		return _h;
	}); #endregion
	
	input_display_list = [
		["Output",	 true],	0, 1, 2,
		["Layers",	false],	layer_renderer,
		["Surfaces", true],	
	];
	input_display_list_len = array_length(input_display_list);
	
	function deleteLayer(index) { #region
		var idx = input_fix_len + index * data_length;
		for( var i = 0; i < data_length; i++ ) {
			ds_list_delete(inputs, idx);
			array_remove(input_display_list, idx + i);
		}
		
		for( var i = input_display_list_len; i < array_length(input_display_list); i++ ) {
			if(input_display_list[i] > idx)
				input_display_list[i] = input_display_list[i] - data_length;
		}
		
		if(ds_list_size(inputs) == input_fix_len)
			createNewInput();
		doUpdate();
	} #endregion
	
	static createNewInput = function() { #region
		var index = ds_list_size(inputs);
		var _s    = floor((index - input_fix_len) / data_length);
		
		inputs[| index + 0] = nodeValue(_s? ("Surface " + string(_s)) : "Background", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
		inputs[| index + 0].surface_index = index;
		inputs[| index + 0].hover_effect  = 0;
		
		inputs[| index + 1] = nodeValue("Position " + string(_s), self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ] )
			.setDisplay(VALUE_DISPLAY.vector)
			.setUnitRef(function(index) { return [ overlay_w, overlay_h ]; });
		inputs[| index + 1].surface_index = index;
		
		inputs[| index + 2] = nodeValue("Rotation " + string(_s), self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 )
			.setDisplay(VALUE_DISPLAY.rotation);
		inputs[| index + 2].surface_index = index;
		
		inputs[| index + 3] = nodeValue("Scale " + string(_s), self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ] )
			.setDisplay(VALUE_DISPLAY.vector);
		inputs[| index + 3].surface_index = index;
		
		array_push(input_display_list, index + 0);
		array_push(input_display_list, index + 1);
		array_push(input_display_list, index + 2);
		array_push(input_display_list, index + 3);
		
		while(_s >= array_length(attributes.layer_visible))
			array_push(attributes.layer_visible, true);
		while(_s >= array_length(attributes.layer_selectable))
			array_push(attributes.layer_selectable, true);
	} #endregion
	if(!LOADING && !APPENDING) createNewInput();
	
	//function getInput() { return inputs[| ds_list_size(inputs) - data_length]; }
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	outputs[| 1] = nodeValue("Atlas data", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, [])
		.rejectArrayProcess();
	
	temp_surface = [ surface_create(1, 1), surface_create(1, 1), surface_create(1, 1) ];
	blend_temp_surface = temp_surface[2];
	
	surf_dragging  = -1;
	input_dragging = -1;
	drag_type   = 0;
	dragging_sx = 0;
	dragging_sy = 0;
	dragging_mx = 0;
	dragging_my = 0;
	
	rot_anc_x = 0;
	rot_anc_y = 0;
	
	overlay_w = 0;
	overlay_h = 0;
	
	atlas_data = [];
	
	surface_selecting = noone;
	
	static getInputAmount = function() { #region
		return input_fix_len + (ds_list_size(inputs) - input_fix_len) / data_length;
	} #endregion
	
	static getInputIndex = function(index) { #region
		if(index < input_fix_len) return index;
		return input_fix_len + (index - input_fix_len) * data_length;
	} #endregion
	
	static setHeight = function() { #region
		var _hi = ui(32);
		var _ho = ui(32);
		
		for( var i = 0; i < getInputAmount(); i++ ) 
			if(inputs[| getInputIndex(i)].isVisible())	
				_hi += 24;
			
		for( var i = 0; i < ds_list_size(outputs); i++ ) 
			if(outputs[| i].isVisible()) 
				_ho += 24;
		
		h = max(min_h, (preview_surface && previewable)? 128 : 0, _hi, _ho);
	} #endregion
	
	static drawJunctions = function(_x, _y, _mx, _my, _s) { #region
		if(!active) return;
		var hover = noone;
		var amo = array_length(input_display_list);
		
		var hov = PANEL_GRAPH.value_focus;
		var ind = -1;
		if(hov != noone && struct_has(hov, "surface_index"))
			ind = hov.surface_index;
		
		for( var i = 0; i < getInputAmount(); i++ ) {
			var idx = getInputIndex(i);
			if(!inputs[| idx].isVisible()) continue;
			
			if(inputs[| idx].drawJunction(_s, _mx, _my, 1.5))	
				hover = inputs[| idx];
			
			if(idx >= input_fix_len && inputs[| idx].hover_effect > 0) {
				var _px0 =  999999;
				var _py0 =  999999;
				var _px1 = -999999;
				var _py1 = -999999;
				var _drw = false;
				var _hov = inputs[| idx].hover_effect;
				
				for( var j = 1; j < data_length; j++ ) {
					if(!inputs[| idx + j].isVisible()) continue;
					_px0 = min( _px0, inputs[| idx + j].x );
					_py0 = min( _py0, inputs[| idx + j].y );
					_px1 = max( _px1, inputs[| idx + j].x );
					_py1 = max( _py1, inputs[| idx + j].y );
					_drw = true;
				}
				
				if(!_drw) continue;
				
				//if(_hov > 0.5) {
				//	var pilx = _px0 - 16 * _s;
				//	var pily = _py0 - 16 * _s;
				//	var pilw = _px1 - _px0 + 32 * _s;
				//	var pilh = _py1 - _py0 + 32 * _s;
					
				//	draw_sprite_stretched_ext(THEME.node_bg_pill, 0, pilx, pily, pilw, pilh, COLORS._main_icon_dark, (_hov - 0.5) * 2);
				//}
				
				for( var j = 1; j < data_length; j++ ) {
					if(inputs[| idx + j].drawJunction(_s, _mx, _my, 1.5))	
						hover = inputs[| idx + j];
				}
			}
		}
		
		for(var i = 0; i < ds_list_size(outputs); i++)
			if(outputs[| i].drawJunction(_s, _mx, _my))
				hover = outputs[| i];
		
		return hover;
	} #endregion
	
	static drawJunctionNames = function(_x, _y, _mx, _my, _s) { #region
		if(!active) return;
		var amo = input_display_list == -1? ds_list_size(inputs) : array_length(input_display_list);
		var jun;
		
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		
		show_input_name  = PANEL_GRAPH.pHOVER && point_in_rectangle(_mx, _my, xx - 8 * _s, yy + 20 * _s, xx + 8 * _s, yy + h * _s);
		show_output_name = PANEL_GRAPH.pHOVER && point_in_rectangle(_mx, _my, xx + (w - 8) * _s, yy + 20 * _s, xx + (w + 8) * _s, yy + h * _s);
		
		var hov = PANEL_GRAPH.value_focus;
		var ind = -1;
		if(hov != noone && struct_has(hov, "surface_index"))
			ind = hov.surface_index;
		
		if(ind != -1) {
			for( var j = 1; j < data_length; j++ ) {
				if(ind + j >= ds_list_size(inputs)) break;
				inputs[| ind + j].drawNameBG(_s);
			}
				
			for( var j = 1; j < data_length; j++ ) {
				if(ind + j >= ds_list_size(inputs)) break;
				inputs[| ind + j].drawName(_s, _mx, _my);
			}
			
		} else if(show_input_name) {
			for( var i = 0; i < getInputAmount(); i++ ) {
				var idx = getInputIndex(i);
				
				if(idx == ind) continue;
				inputs[| idx].drawNameBG(_s);
			}
				
			for( var i = 0; i < getInputAmount(); i++ ) {
				var idx = getInputIndex(i);
				
				if(idx == ind) continue;
				inputs[| idx].drawName(_s, _mx, _my);
			}
		}
		
		if(show_output_name) {
			for(var i = 0; i < ds_list_size(outputs); i++)
				outputs[| i].drawNameBG(_s);
			
			for(var i = 0; i < ds_list_size(outputs); i++)
				outputs[| i].drawName(_s, _mx, _my);
		}
	} #endregion
	
	static preDraw = function(_x, _y, _s) { #region
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		var jun;
		
		var inamo = input_display_list == -1? ds_list_size(inputs) : array_length(input_display_list);
		var _in = yy + ui(32) * _s;
		
		var hov = PANEL_GRAPH.value_focus;
		var ind = -1;
		if(hov != noone && struct_has(hov, "surface_index"))
			ind = hov.surface_index;
		
		for( var i = 0; i < getInputAmount(); i++ ) {
			var idx = getInputIndex(i);
			jun = ds_list_get(inputs, idx, noone);
			if(jun == noone || is_undefined(jun)) continue;
			jun.x = xx;
			jun.y = _in;
			
			if(i >= input_fix_len) {
				jun.hover_effect = lerp_float(jun.hover_effect, ind == idx, 3);
				var sp = jun.hover_effect * 24;
				var sx = xx - sp * _s;
				var sy = _in;
				
				for( var j = 1; j < data_length; j++ ) {
					var _jun = ds_list_get(inputs, idx + j, noone);
					_jun.x = sx;
					_jun.y = sy;
					
					sy += sp * _s * _jun.isVisible();
				}
			}
			
			_in += 24 * _s * jun.isVisible();
		}
		
		var outamo = output_display_list == -1? ds_list_size(outputs) : array_length(output_display_list);
		
		xx = xx + w * _s;
		_in = yy + ui(32) * _s;
		for(var i = 0; i < outamo; i++) {
			var idx = getOutputJunctionIndex(i);
			jun = outputs[| idx];
			
			jun.x = xx;
			jun.y = _in;
			_in += 24 * _s * jun.isVisible();
		}
	} #endregion
	
	static onValueFromUpdate = function(index) { #region
		if(LOADING || APPENDING) return;
		
		if(index + data_length >= ds_list_size(inputs))
			createNewInput();
	} #endregion
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) { #region
		var pad = getInputData(0);
		var ww  = overlay_w;
		var hh  = overlay_h;
		
		var x0  = _x + pad[2] * _s;
		var x1  = _x + (ww - pad[0]) * _s;
		var y0  = _y + pad[1] * _s;
		var y1  = _y + (hh - pad[3]) * _s;
		
		if(input_dragging > -1) {
			if(drag_type == NODE_COMPOSE_DRAG.move) {
				var _dx = (_mx - dragging_mx) / _s;
				var _dy = (_my - dragging_my) / _s;
				
				if(key_mod_press(SHIFT)) {
					if(abs(_dx) > abs(_dy) + ui(16))
						_dy = 0;
					else if(abs(_dy) > abs(_dx) + ui(16))
						_dx = 0;
					else {
						_dx = max(_dx, _dy);
						_dy = _dx;
					}
				}
				
				var pos_x = value_snap(dragging_sx + _dx, _snx);
				var pos_y = value_snap(dragging_sy + _dy, _sny);
				
				if(key_mod_press(ALT)) {
					var _surf = current_data[input_dragging - 1];
					var _sw = surface_get_width_safe(_surf);
					var _sh = surface_get_height_safe(_surf);
					
					var x0 = pos_x, x1 = pos_x + _sw;
					var y0 = pos_y, y1 = pos_y + _sh;
					var xc = (x0 + x1) / 2;
					var yc = (y0 + y1) / 2;
					var snap = 4;
					
					draw_set_color(COLORS._main_accent);
					if(abs(x0 -  0) < snap) {
						pos_x = 0;
						draw_line_width(_x + _s * 0, 0, _x + _s * 0, WIN_H, 2);
					}
					
					if(abs(y0 -  0) < snap) {
						pos_y = 0;
						draw_line_width(0, _y + _s * 0, WIN_W, _y + _s * 0, 2);
					}
					
					if(abs(x1 - ww) < snap) {
						pos_x = ww - _sw;
						draw_line_width(_x + _s * ww, 0, _x + _s * ww, WIN_H, 2);
					}
					
					if(abs(y1 - hh) < snap) {
						pos_y = hh - _sh;
						draw_line_width(0, _y + _s * hh, WIN_W, _y + _s * hh, 2);
					}
					
					if(abs(xc - ww / 2) < snap) {
						pos_x = ww / 2 - _sw / 2;
						draw_line_width(_x + _s * ww / 2, 0, _x + _s * ww / 2, WIN_H, 2);
					}
					
					if(abs(yc - hh / 2) < snap) {
						pos_y = hh / 2 - _sh / 2;
						draw_line_width(0, _y + _s * hh / 2, WIN_W, _y + _s * hh / 2, 2);
					}
				}
				
				if(inputs[| input_dragging].setValue([ pos_x, pos_y ]))
					UNDO_HOLDING = true;
			} else if(drag_type == NODE_COMPOSE_DRAG.rotate) {
				var aa = point_direction(rot_anc_x, rot_anc_y, _mx, _my);
				var da = angle_difference(dragging_mx, aa);
				var sa;
				
				if(key_mod_press(CTRL)) 
					sa = round((dragging_sx - da) / 15) * 15;
				else 
					sa = dragging_sx - da;
			
				if(inputs[| input_dragging].setValue(sa))
					UNDO_HOLDING = true;	
			} else if(drag_type == NODE_COMPOSE_DRAG.scale) {
				var _surf = getInputData(surf_dragging + 0);
				var _rot  = getInputData(surf_dragging + 2);
				var _sw = surface_get_width_safe(_surf);
				var _sh = surface_get_height_safe(_surf);
				
				var _p = point_rotate(_mx - dragging_mx, _my - dragging_my, 0, 0, -_rot);
				var sca_x = _p[0] / _s / _sw * 2;
				var sca_y = _p[1] / _s / _sh * 2;
				
				if(key_mod_press(SHIFT)) {
					sca_x = min(sca_x, sca_y);
					sca_y = min(sca_x, sca_y);
				}
				
				if(inputs[| input_dragging].setValue([ sca_x, sca_y ]))
					UNDO_HOLDING = true;	
			}
			
			if(mouse_release(mb_left)) {
				input_dragging = -1;
				UNDO_HOLDING = false;
			}
		}
		
		var hovering      = noone;
		var hovering_type = noone;
		var _vis = attributes.layer_visible;
		var _sel = attributes.layer_selectable;
		
		var amo = (ds_list_size(inputs) - input_fix_len) / data_length;
		if(array_length(current_data) < input_fix_len + amo * data_length)
			return;
		
		var anchors = array_create(ds_list_size(inputs));
		
		for(var i = 0; i < amo; i++) {
			var vis = _vis[i];
			var sel = _sel[i];
			
			var index = input_fix_len + i * data_length;
			var _surf = current_data[index + 0];
			var _pos  = current_data[index + 1];
			var _rot  = current_data[index + 2];
			var _sca  = current_data[index + 3];
			
			if(!_surf || is_array(_surf)) continue;
			
			var _ww = surface_get_width_safe(_surf);
			var _hh = surface_get_height_safe(_surf);
			var _sw = _ww * _sca[0];
			var _sh = _hh * _sca[1];
			
			var _cx = _pos[0] + _ww / 2;
			var _cy = _pos[1] + _hh / 2;
			
			var _d0 = point_rotate(_cx - _sw / 2, _cy - _sh / 2, _cx, _cy, _rot);
			var _d1 = point_rotate(_cx - _sw / 2, _cy + _sh / 2, _cx, _cy, _rot);
			var _d2 = point_rotate(_cx + _sw / 2, _cy - _sh / 2, _cx, _cy, _rot);
			var _d3 = point_rotate(_cx + _sw / 2, _cy + _sh / 2, _cx, _cy, _rot);
			var _rr = point_rotate(_cx,  _cy - _sh / 2 - 1,      _cx, _cy, _rot);
			
			_d0[0] = overlay_x(_d0[0], _x, _s); _d0[1] = overlay_y(_d0[1], _y, _s);
			_d1[0] = overlay_x(_d1[0], _x, _s); _d1[1] = overlay_y(_d1[1], _y, _s);
			_d2[0] = overlay_x(_d2[0], _x, _s); _d2[1] = overlay_y(_d2[1], _y, _s);
			_d3[0] = overlay_x(_d3[0], _x, _s); _d3[1] = overlay_y(_d3[1], _y, _s);
			_rr[0] = overlay_x(_rr[0], _x, _s); _rr[1] = overlay_y(_rr[1], _y, _s);
			
			anchors[index] = {
				cx: _cx,
				cy: _cy,
				d0: _d0,
				d1: _d1,
				d2: _d2,
				d3: _d3,
				rr: _rr,
				
				rot: _rot,
			}
		}
		
		for(var i = 0; i < amo; i++) {
			var vis = _vis[i];
			var sel = _sel[i];
			if(!vis) continue;
			
			var index = input_fix_len + i * data_length;
			var _surf = current_data[index + 0];
			var _pos  = current_data[index + 1];
			var _rot  = current_data[index + 2];
			var _sca  = current_data[index + 3];
			
			if(!_surf || is_array(_surf)) continue;
			
			var a = anchors[index];
			
			if(surface_selecting == index) {
				var _ri = 0;
				var _si = 0;
			
				if(point_in_circle(_mx, _my, a.d3[0], a.d3[1], 12)) {
					hovering = index;
					hovering_type = NODE_COMPOSE_DRAG.scale;
					_si = 1;
				} else if(point_in_rectangle_points(_mx, _my, a.d0[0], a.d0[1], a.d1[0], a.d1[1], a.d2[0], a.d2[1], a.d3[0], a.d3[1])) {
					hovering = index;
					hovering_type = NODE_COMPOSE_DRAG.move;
				} else if(point_in_circle(_mx, _my, a.rr[0], a.rr[1], 12)) {
					hovering = index;
					hovering_type = NODE_COMPOSE_DRAG.rotate;
					_ri = 1;
				}
				
				draw_sprite_colored(THEME.anchor_rotate, _ri, a.rr[0], a.rr[1],, a.rot);
				draw_sprite_colored(THEME.anchor_scale,  _si, a.d3[0], a.d3[1],, a.rot);
			} else if(point_in_rectangle_points(_mx, _my, a.d0[0], a.d0[1], a.d1[0], a.d1[1], a.d2[0], a.d2[1], a.d3[0], a.d3[1]) && 
				(hovering != surface_selecting || surface_selecting == noone)) {
					
				hovering = index;
				hovering_type = NODE_COMPOSE_DRAG.move;
			}
		}
		
		if(mouse_press(mb_left, active))
			surface_selecting = hovering;
		if(surface_selecting != noone) {
			var a = array_safe_get(anchors, surface_selecting, noone);
			if(!is_struct(a)) surface_selecting = noone;
		}
		
		if(hovering != noone) {
			var a = anchors[hovering];
			
			draw_set_color(COLORS.node_composite_overlay_border);
			draw_line(a.d0[0], a.d0[1], a.d1[0], a.d1[1]);
			draw_line(a.d0[0], a.d0[1], a.d2[0], a.d2[1]);
			draw_line(a.d3[0], a.d3[1], a.d1[0], a.d1[1]);
			draw_line(a.d3[0], a.d3[1], a.d2[0], a.d2[1]);
		}
				
		if(surface_selecting != noone) {
			var a = anchors[surface_selecting];
			
			draw_set_color(COLORS._main_accent);
			draw_line(a.d0[0], a.d0[1], a.d1[0], a.d1[1]);
			draw_line(a.d0[0], a.d0[1], a.d2[0], a.d2[1]);
			draw_line(a.d3[0], a.d3[1], a.d1[0], a.d1[1]);
			draw_line(a.d3[0], a.d3[1], a.d2[0], a.d2[1]);
		}
		
		if(hovering != noone && mouse_press(mb_left, active)) {
			var a = anchors[hovering];
			
			if(hovering_type == NODE_COMPOSE_DRAG.move) {
				surf_dragging	= hovering;
				input_dragging	= hovering + 1;
				drag_type		= hovering_type;
				dragging_sx		= current_data[hovering + 1][0];
				dragging_sy		= current_data[hovering + 1][1];
				dragging_mx		= _mx;
				dragging_my		= _my;
			} else if(hovering_type == NODE_COMPOSE_DRAG.rotate) { //rot
				surf_dragging	= hovering;
				input_dragging	= hovering + 2;
				drag_type		= hovering_type;
				dragging_sx		= current_data[hovering + 2];
				rot_anc_x		= overlay_x(a.cx, _x, _s);
				rot_anc_y		= overlay_y(a.cy, _y, _s);
				dragging_mx		= point_direction(rot_anc_x, rot_anc_y, _mx, _my);
			} else if(hovering_type == NODE_COMPOSE_DRAG.scale) { //sca
				surf_dragging	= hovering;
				input_dragging	= hovering + 3;
				drag_type		= hovering_type;
				dragging_sx		= _sca[0];
				dragging_sy		= _sca[1];
				dragging_mx		= (a.d0[0] + a.d3[0]) / 2;
				dragging_my		= (a.d0[1] + a.d3[1]) / 2;
			}
		}
		
		if(layer_remove > -1) {
			deleteLayer(layer_remove);
			layer_remove = -1;
		}
	} #endregion
	
	static step = function() { #region
		var _dim_type = getSingleValue(1);
		
		inputs[| 2].setVisible(_dim_type == COMPOSE_OUTPUT_SCALING.constant);
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region
		if(_output_index == 1) return atlas_data;
		if(_output_index == 0 && _array_index == 0) atlas_data = [];
		
		if(array_length(_data) < 4) return _outSurf;
		var _pad	  = _data[0];
		var _dim_type = _data[1];
		var _dim	  = _data[2];
		var base	  = _data[3];
		var cDep	  = attrDepth();
		var ww = 0, hh = 0;
		
		switch(_dim_type) {
			case COMPOSE_OUTPUT_SCALING.first :
				ww = surface_get_width_safe(base);
				hh = surface_get_height_safe(base);
				break;
			case COMPOSE_OUTPUT_SCALING.largest :
				for(var i = input_fix_len; i < array_length(_data) - data_length; i += data_length) {
					var _s = _data[i];
					ww = max(ww, surface_get_width_safe(_s));
					hh = max(hh, surface_get_height_safe(_s));
				}
				break;
			case COMPOSE_OUTPUT_SCALING.constant :	
				ww = _dim[0];
				hh = _dim[1];
				break;
		}
		ww += _pad[0] + _pad[2];
		hh += _pad[1] + _pad[3];
		
		overlay_w = ww;
		overlay_h = hh;
		
		for(var i = 0; i < 3; i++) {
			temp_surface[i] = surface_verify(temp_surface[i], ww, hh, cDep);
			surface_clear(temp_surface[i]);
		}
		
		var res_index = 0, bg = 0;
		var imageAmo = (ds_list_size(inputs) - input_fix_len) / data_length;
		var _vis = attributes.layer_visible;
		var _bg  = 0;
		
		for(var i = 0; i < imageAmo; i++) {
			var vis  = _vis[i];
			if(!vis) continue;
			
			var startDataIndex = input_fix_len + i * data_length;
			var _s   = _data[startDataIndex + 0];
			var _pos = _data[startDataIndex + 1];
			var _rot = _data[startDataIndex + 2];
			var _sca = _data[startDataIndex + 3];
			
			if(!_s || is_array(_s)) continue;
			
			var _ww = surface_get_width_safe(_s);
			var _hh = surface_get_height_safe(_s);
			var _sw = _ww * _sca[0];
			var _sh = _hh * _sca[1];
			
			var cx = _pos[0] + _ww / 2;
			var cy = _pos[1] + _hh / 2;
			
			var _d0 = point_rotate(cx - _sw / 2, cy - _sh / 2, cx, cy, _rot);
			
			array_push(atlas_data, new SurfaceAtlas(_s, _d0[0], _d0[1], _rot, _sca[0], _sca[1]));
			
			surface_set_shader(temp_surface[_bg], sh_sample, true, BLEND.over);
				blend_temp_surface = temp_surface[2];
				draw_surface_blend_ext(temp_surface[!_bg], _s, _d0[0], _d0[1], _sca[0], _sca[1], _rot);
			surface_reset_shader();
			
			_bg = !_bg;
		}
		
		_outSurf = surface_verify(_outSurf, ww, hh, cDep);
		
		surface_set_shader(_outSurf);
			draw_surface_safe(temp_surface[!_bg]);
		surface_reset_shader();
		
		return _outSurf;
	} #endregion
	
	static attributeSerialize = function() { #region
		var att = {};
		att.layer_visible    = attributes.layer_visible;
		att.layer_selectable = attributes.layer_selectable;
		
		return att;
	} #endregion
	
	static attributeDeserialize = function(attr) { #region
		if(struct_has(attributes, "use_project_dimension") && !struct_has(attr, "use_project_dimension"))
			attributes.use_project_dimension = false;
			
		if(struct_has(attr, "layer_visible"))
			attributes.layer_visible = attr.layer_visible;
			
		if(struct_has(attr, "layer_selectable"))
			attributes.layer_selectable = attr.layer_selectable;
	} #endregion
}

