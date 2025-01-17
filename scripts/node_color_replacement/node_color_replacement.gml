function Node_Colors_Replace(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Replace Colors";
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	inputs[| 1] = nodeValue("Palette from", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, [])
		.setDisplay(VALUE_DISPLAY.palette);
	
	inputs[| 2] = nodeValue("Palette to", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, [])
		.setDisplay(VALUE_DISPLAY.palette)
		.setVisible(false, false);
	
	inputs[| 3] = nodeValue("Threshold", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 4] = nodeValue("Mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 5] = nodeValue("Mix", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 6] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 6;
		
	__init_mask_modifier(4); // inputs 7, 8, 
	
	selecting_index = 0;
	
	function setColor(colr) { #region
		var _to   = array_clone(getInputData(2));
		_to[selecting_index] = colr;
		
		inputs[| 2].setValue(_to);			// Not necessary due to array reference
	} #endregion
		
	render_palette = new Inspector_Custom_Renderer(function(_x, _y, _w, _m, _hover, _focus) { #region
		var bx = _x;
		var by = _y;
		
		var bs = ui(24);
		if(buttonInstant(THEME.button_hide, bx, by, bs, bs, _m, _focus, _hover,, THEME.refresh_s) == 2) 
			refreshPalette();
			
		bx += bs + ui(4);
		var jun   = inputs[| 2];
		var index = jun.isLeaf()? jun.is_anim : 2;
		if(buttonInstant(THEME.button_hide, bx, by, bs, bs, _m, _focus, _hover,, THEME.animate_clock, index, index == 2? COLORS._main_accent : COLORS._main_icon) == 2) 
			jun.setAnim(!jun.is_anim);
		
		bx += bs + ui(4);
		var vis = jun.visible;
		if(buttonInstant(THEME.button_hide, bx, by, bs, bs, _m, _focus, _hover,, THEME.junc_visible, vis) == 2)
			jun.visible = !vis;
			
		var _from = getInputData(1);
		var _to   = getInputData(2);
		
		var ss  = TEXTBOX_HEIGHT;
		var amo = array_length(_from);
		var top = bs + ui(8);
		var hh  = top + (amo * (ss + ui(8)) + ui(8));
		var _yy = _y + top;
		
		draw_sprite_stretched_ext(THEME.ui_panel_bg, 1, _x, _yy, _w, hh - top, COLORS.node_composite_bg_blend, 1);
		
		for( var i = 0; i < amo; i++ ) {
			var fr = array_safe_get(_from, i);
			var to = array_safe_get(_to,   i);
			
			var _x0 = _x  + ui(8);
			var _y0 = _yy + ui(8) + i * (ss + ui(8));
			
			draw_sprite_stretched_ext(THEME.color_picker_box, 0, _x0, _y0, ss, ss, COLORS._main_icon, 0.5);
			draw_sprite_stretched_ext(THEME.color_picker_box, 1, _x0, _y0, ss, ss, fr, 1);
			
			var _x1 = _x0 + ss + ui(32);
			var _x2 = _x + _w - ui(8);
			
			bx   = _x2 - ui(32);
			_x2 -= ui(32 + 4);
			by   = _y0 + ss / 2 - ui(32) / 2;
			if(buttonInstant(THEME.button_hide, bx, by, ui(32), ui(32), _m, _focus, _hover,, THEME.color_picker_dropper,, c_white) == 2) {
				var dialog = dialogCall(o_dialog_color_selector, WIN_W / 2, WIN_H / 2);
				dialog.selector.dropper_active = true;
				dialog.selector.dropper_close  = true;
		
				dialog.selector.onApply = setColor;
				dialog.onApply = setColor;
			}
			
			bx   = _x2 - ui(32);
			_x2 -= ui(32 + 4);
			if(buttonInstant(THEME.button_hide, bx, by, ui(32), ui(32), _m, _focus, _hover,, THEME.color_wheel,, c_white) == 2) {
				var pick = instance_create(mouse_mx, mouse_my, o_dialog_color_quick_pick);
				pick.onApply = setColor;
				selecting_index = i;
			}
			
			_x2 -= ui(4);
			
			var _xw = _x2 - _x1;
			
			draw_sprite_ext(THEME.arrow, 0, (_x0 + ss + _x1) / 2, _y0 + ss / 2, 1, 1, 0, c_white, 0.5);
			
			draw_sprite_stretched_ext(THEME.color_picker_box, 1, _x1, _y0, _xw, ss, to, 1);
			
			if(_hover && point_in_rectangle(_m[0], _m[1], _x1, _y0, _x1 + _xw, _y0 + ss)) {
				draw_sprite_stretched_ext(THEME.color_picker_box, 0, _x1, _y0, _xw, ss, COLORS._main_icon, 1);
				
				if(mouse_press(mb_left, _focus)) {
					var dialog = dialogCall(o_dialog_color_selector, WIN_W / 2, WIN_H / 2);
					dialog.setDefault(to);
					dialog.selector.onApply = setColor;
					dialog.onApply = setColor;
					selecting_index = i;
				}
			} else 
				draw_sprite_stretched_ext(THEME.color_picker_box, 0, _x1, _y0, _xw, ss, COLORS._main_icon, 0.5);
		}
		
		return hh;
	}); #endregion
	
	input_display_list = [ 6, 
		["Surfaces",	 true], 0, 4, 5, 7, 8, 
		["Replace",		false], render_palette, 2, 
		["Comparison",	false], 3, 
	];
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	attribute_surface_depth();
	
	static refreshPalette = function() { #region
		var _surf = array_safe_get(current_data, 0);
		
		inputs[| 1].setValue([]);
		inputs[| 2].setValue([]);
		
		if(!is_array(_surf))
			_surf = [ _surf ];
		
		var _pall = ds_map_create();
		
		for( var i = 0, n = array_length(_surf); i < n; i++ ) {
			var ww = surface_get_width_safe(_surf[i]);
			var hh = surface_get_height_safe(_surf[i]);
		
			var c_buffer = buffer_create(ww * hh * 4, buffer_fixed, 2);
		
			buffer_get_surface(c_buffer, _surf[i], 0);
			buffer_seek(c_buffer, buffer_seek_start, 0);
		
			for( var i = 0; i < ww * hh; i++ ) {
				var b = buffer_read(c_buffer, buffer_u32);
				var c = b & ~(0b11111111 << 24);
				var a = b & (0b11111111 << 24);
				if(a == 0) continue;
				c = make_color_rgb(color_get_red(c), color_get_green(c), color_get_blue(c));
				_pall[? c] = 1;
			}
		
			buffer_delete(c_buffer);
		}
		
		var palette = ds_map_keys_to_array(_pall);
		ds_map_destroy(_pall);
		
		inputs[| 1].setValue(palette);
		inputs[| 2].setValue(palette);
	} #endregion
	
	static step = function() { #region
		__step_mask_modifier();
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) { #region		
		var fr  = _data[1];
		var to  = _data[2];
		var tr  = _data[3];
		var msk = _data[4];
		
		surface_set_shader(_outSurf, sh_colours_replace);
			shader_set_palette(fr, "colorFrom", "colorFromAmount");
			shader_set_palette(to, "colorTo",   "colorToAmount");
			
			shader_set_i("useMask", is_surface(msk));
			shader_set_surface("mask", msk);
			
			draw_surface_safe(_data[0], 0, 0);
		
		surface_reset_shader();
		
		__process_mask_modifier(_data);
		_outSurf = mask_apply(_data[0], _outSurf, _data[4], _data[5]);
		
		return _outSurf;
	} #endregion
}