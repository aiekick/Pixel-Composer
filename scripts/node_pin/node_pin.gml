function Node_Pin(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Pin";
	w = 32;
	h = 32;
	
	auto_height      = false;
	junction_shift_y = 16;
	previewable      = false;
	
	isHovering     = false;
	hover_scale    = 0;
	hover_scale_to = 0;
	hover_alpha    = 0;
	
	bg_spr     = THEME.node_pin_bg;
	bg_sel_spr = THEME.node_pin_bg_active;
	
	inputs[| 0] = nodeValue("In", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, 0 )
		.setVisible(true, true);
	
	outputs[| 0] = nodeValue("Out", self, JUNCTION_CONNECT.output, VALUE_TYPE.any, 0);
	
	static step = function() { #region
		if(inputs[| 0].isLeaf()) return;
		
		inputs[| 0].setType(inputs[| 0].value_from.type);
		outputs[| 0].setType(inputs[| 0].value_from.type);
		
		inputs[| 0].color_display  = inputs[| 0].value_from.color_display;
		outputs[| 0].color_display = inputs[| 0].color_display;
	} #endregion
	
	static update = function() { #region
		var _val = getInputData(0);
		outputs[| 0].setValue(_val);
	} #endregion
	
	static pointIn = function(_x, _y, _mx, _my, _s) { #region
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		
		return point_in_circle(_mx, _my, xx, yy, _s * 24);
	} #endregion
	
	static preDraw = function(_x, _y, _s) { #region
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		
		inputs[| 0].x = xx;
		inputs[| 0].y = yy;
		
		outputs[| 0].x = xx;
		outputs[| 0].y = yy;
	} #endregion
	
	static drawJunctionNames = function(_x, _y, _mx, _my, _s) {}
	
	static drawJunctions = function(_x, _y, _mx, _my, _s) { #region
		isHovering = false;
		var hover = noone;
		var xx	  = x * _s + _x;
		var yy	  = y * _s + _y;
		var hov   = PANEL_GRAPH.value_dragging; 
		
		if(hov == noone && point_in_circle(_mx, _my, xx, yy, _s * 24)) { 
			isHovering = true;
			hover_scale_to = 1;
		}
		
		if(outputs[| 0].drawJunction(_s, _mx, _my))
			hover = outputs[| 0];
		
		return hover;
	} #endregion
	
	static drawNode = function(_x, _y, _mx, _my, _s) { #region
		if(group != PANEL_GRAPH.getCurrentContext()) return;
		
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		
		hover_alpha = 0.5;
		if(active_draw_index > -1) {
			hover_alpha			= 1;
			hover_scale_to		= 1;
			active_draw_index	= -1;
		}
		
		if(hover_scale > 0) {
			draw_set_color(COLORS._main_accent);
			draw_set_alpha(hover_alpha);
			draw_circle_border(xx, yy, _s * hover_scale * 20, 2);
			draw_set_alpha(1);
		}
		
		hover_scale    = lerp_float(hover_scale, hover_scale_to, 3);
		hover_scale_to = 0;
		
		if(renamed && display_name != "" && display_name != "Pin") {
			draw_set_text(f_p0, fa_center, fa_bottom, COLORS._main_text);
			draw_text_transformed(xx, yy - 12, display_name, _s, _s, 0);
		}
		
		return drawJunctions(_x, _y, _mx, _my, _s);
	} #endregion
}