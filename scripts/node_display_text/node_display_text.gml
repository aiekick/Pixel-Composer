function Node_Display_Text(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Display Text";
	w = 240;
	h = 160;
	
	bg_spr		= THEME.node_frame_bg;
	
	size_dragging = false;
	size_dragging_w = w;
	size_dragging_h = h;
	size_dragging_mx = w;
	size_dragging_my = h;
	
	auto_height = false;
	name_hover  = false;
	draw_scale  = 1;
	
	ta_editor   = new textArea(TEXTBOX_INPUT.text, function(val) { inputs[| 1].setValue(val); })
	
	inputs[| 0] = nodeValue("Color", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_white )
		.rejectArray();
	
	inputs[| 1] = nodeValue("Text", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "Text")
		.rejectArray();
	
	inputs[| 2] = nodeValue("Style", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 2)
		.setDisplay(VALUE_DISPLAY.enum_scroll, ["Header", "Sub header", "Normal"])
		.rejectArray();
	
	inputs[| 3] = nodeValue("Alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.75)
		.setDisplay(VALUE_DISPLAY.slider)
		.rejectArray();
	
	inputs[| 4] = nodeValue("Line width", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, -1)
		.rejectArray();
	
	inputs[| 5]  = nodeValue("Position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ x, y ])
		.setDisplay(VALUE_DISPLAY.vector)
		.rejectArray();
	
	inputs[| 6]  = nodeValue("Smooth transform", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true)
		.rejectArray();
	
	input_display_list = [1, 
		["Styling", false], 2, 0, 3, 4,
		["Display", false], 5, 6, 
	];
	
	_prev_text = "";
	font   = f_sdf_medium;
	fsize  = 1;
	_lines = [];
	
	smooth = true;
	pos_x  = x;
	pos_y  = y;
	
	ml_press   = 0;
	ml_release = 0;
	ml_double  = 0;
	mr_press   = 0;
	mr_release = 0;
	mm_press   = 0;
	mm_release = 0;
	
	static move = function(_x, _y, _s) { #region
		if(x == _x && y == _y) return;
		if(!LOADING) PROJECT.modified = true;
		
		x = _x;
		y = _y;
		
		if(inputs[| 5].setValue([ _x, _y ]))
			UNDO_HOLDING = true;
	} #endregion
	
	static button_reactive_update = function(key) { #region
		ml_press   = lerp_float(ml_press  , 0, 10);
		ml_release = lerp_float(ml_release, 0, 10);
		ml_double  = lerp_float(ml_double,  0, 10);
		mr_press   = lerp_float(mr_press  , 0, 10);
		mr_release = lerp_float(mr_release, 0, 10);
		mm_press   = lerp_float(mm_press  , 0, 10);
		mm_release = lerp_float(mm_release, 0, 10);
		
		if(mouse_press(mb_left))     ml_press   = 2;
		if(mouse_release(mb_left))   ml_release = 2;
		if(DOUBLE_CLICK)		     ml_double  = 2;
		if(mouse_press(mb_right))    mr_press   = 2;
		if(mouse_release(mb_right))  mr_release = 2;
		if(mouse_press(mb_middle))   mm_press   = 2;
		if(mouse_release(mb_middle)) mm_release = 2;
	} #endregion
	
	static button_reactive = function(key) { #region
		switch(key) {
			case "left_mouse_click" :		 return clamp(ml_press, 0, 1);
			case "left_mouse_double_click" : return clamp(ml_double, 0, 1);
			case "left_mouse_release" :		 return clamp(ml_release, 0, 1);
			case "left_mouse_drag" :		 return mouse_click(mb_left);
			
			case "right_mouse_click" :		 return clamp(mr_press, 0, 1);
			case "right_mouse_release" :	 return clamp(mr_release, 0, 1);
			case "right_mouse_drag" :		 return mouse_click(mb_right);
			
			case "middle_mouse_click" :		 return clamp(mm_press, 0, 1);
			case "middle_mouse_release" :	 return clamp(mm_release, 0, 1);
			case "middle_mouse_drag" :		 return mouse_click(mb_middle);
			
			case "ctrl" :  return key_mod_press(CTRL);
			case "alt" :   return key_mod_press(ALT);
			case "shift" : return key_mod_press(SHIFT);
			
			case "space" : return keyboard_check(vk_space);
			case "f1" :    return keyboard_check(vk_f1);
			case "f2" :    return keyboard_check(vk_f2);
			case "f3" :    return keyboard_check(vk_f3);
			case "f4" :    return keyboard_check(vk_f4);
			case "f5" :    return keyboard_check(vk_f5);
			case "f6" :    return keyboard_check(vk_f6);
			case "f7" :    return keyboard_check(vk_f7);
			case "f8" :    return keyboard_check(vk_f8);
			case "f9" :    return keyboard_check(vk_f9);
			case "f10" :   return keyboard_check(vk_f10);
			case "f11" :   return keyboard_check(vk_f11);
			case "f12" :   return keyboard_check(vk_f12);
		}
		
		if(string_length(key) == 1) return keyboard_check(ord(string_upper(key)));
		
		return 0;
	} #endregion
	
	static draw_text_style = function(_x, _y, txt, _s, _mx, _my) { #region
		var _tx = _x;
		var index = 1;
		var _len = string_length(txt);
		var _ch = "";
		var _tw, _th;
		var _ch_h = string_height("l") * _s * fsize;
		var _mode = 0;
		var _cmd = "";
		
		var width = 0;
		
		var _ff = draw_get_font();
		var _cc = draw_get_color();
		var _aa = draw_get_alpha();
		
		while(index <= _len) {
			_ch = string_char_at(txt, index);
			index++;
			
			switch(_ch) {
				case "<" : 
					_mode = 1; 
					continue;
				case ">" : 
					var _c = string_splice(_cmd, " ");
					
					if(array_length(_c) > 1) {
						switch(_c[0]) {
							case "bt" :
								var _bch = "";
								for( var i = 1; i < array_length(_c); i++ ) {
									if(i > 1) _bch += " ";
									_bch += _c[i];
								}
								_tw = string_width(_bch)  * _s * fsize;
								_th = string_height(_bch) * _s * fsize;
								
								draw_sprite_stretched_points(THEME.ui_panel_bg, 0, _tx - 4, _y - 4, _tx + _tw + 4, _y + _th + 4, COLORS._main_icon_light);
								draw_sprite_stretched_points(THEME.ui_panel_fg, 0, _tx - 4, _y - 4, _tx + _tw + 4, _y + _th + 4);
									
								draw_set_color(_cc);
								draw_text_transformed(_tx, _y, _bch, _s * fsize, _s * fsize, 0);
								
								var _reac = button_reactive(string_to_var(_bch));
								if(_reac > 0) {
									draw_sprite_stretched_points(THEME.ui_panel_bg, 4, _tx - 4, _y - 4, _tx + _tw + 4, _y + _th + 4, COLORS._main_accent, _reac);
									
									draw_set_color(merge_color(0, COLORS.panel_bg_clear_inner, 0.5));
									draw_set_alpha(_reac);
									draw_text_transformed(_tx, _y, _bch, _s * fsize, _s * fsize, 0);
									draw_set_alpha(_aa);
									draw_set_color(_cc);
								} 
								
								_tx += _tw;
								width += string_width(_bch) * fsize;
								break;
							case "panel" :
								var _key = _c[1] + " panel";
								var _tss = 11 / 32;
								draw_set_color(_cc);
								draw_set_font(f_sdf);
								
								_tw = string_width(_key)  * _s * _tss;
								_th = string_height(_key) * _s * _tss;
								
								if(point_in_rectangle(_mx, _my, _tx - 4, _y - 4, _tx + _tw + 4, _y + _th + 4)) {
									draw_set_color(COLORS._main_accent);
									draw_set_alpha(1);
									
									switch(string_lower(_c[1])) {
										case "graph" :      FOCUSING_PANEL = PANEL_GRAPH;      break;
										case "preview" :    FOCUSING_PANEL = PANEL_PREVIEW;    break;
										case "inspector" :  FOCUSING_PANEL = PANEL_INSPECTOR;  break;
										case "animation" :  FOCUSING_PANEL = PANEL_ANIMATION;  break;
										case "collection" : FOCUSING_PANEL = findPanel("Panel_Collection"); break;
									}
								}
								draw_text_transformed(_tx, _y, _key, _s * _tss, _s * _tss, 0);
								
								_tx += _tw;
								width += string_width(_key) * _tss;
								
								draw_set_font(_ff);
								draw_set_color(_cc);
								draw_set_alpha(_aa);
								break;
							case "spr" :
								var _spr_t = _c[1];
								if(!variable_struct_exists(THEME, _spr_t)) break;
								var _spr = variable_struct_get(THEME, _spr_t);
								
								var _spr_i = array_length(_c) > 2? real(_c[2]) : 0;
								var _spr_s = array_length(_c) > 3? _s * real(_c[3]) : _s;
								
								_tw = sprite_get_width(_spr);
								_th = sprite_get_height(_spr) * _spr_s;
								var _ow = sprite_get_xoffset(_spr) * _spr_s;
								var _oh = sprite_get_yoffset(_spr) * _spr_s;
								
								draw_sprite_ext(_spr, _spr_i, _tx + _ow, _y + _ch_h / 2 - _th / 2 + _oh, _spr_s, _spr_s, 0, c_white, 1);
								
								_tx += _tw * _spr_s;
								width += _tw;
								break;
						}
					}
					
					_mode = 0; 
					_cmd = "";
					continue;
			}
			
			switch(_mode) {
				case 0 :	
					_tw = string_width(_ch);
					_th = string_height(_ch);
			
					draw_text_transformed(_tx, _y, _ch, _s * fsize, _s * fsize, 0);
					_tx += _tw * _s * fsize;
					width += _tw * fsize;
					break;
				case 1 : 
					_cmd += _ch;
					break;
			}
		}
		
		return width;
	} #endregion
	
	static string_raw = function(txt) { #region
		var index = 1;
		var _len = string_length(txt);
		var _ch = "";
		var _mode = 0;
		var ss = "";
		var ch_str = "";
		
		while(index <= _len) {
			_ch = string_char_at(txt, index);
			index++;
			
			switch(_ch) {
				case "<" : 
					_mode = 1; continue;
				case ">" : 
					var _c = string_splice(ch_str, " ");
					
					if(array_length(_c) > 1) {
						switch(_c[0]) {
							case "bt" :
								var _bch = "";
								for( var i = 1; i < array_length(_c); i++ ) {
									if(i > 1) _bch += " ";
									_bch += _c[i];
								}
								
								ss += _bch;
								break;
						}
					}
					
					ch_str = "";
					_mode = 0; 
					continue;
			}
			
			switch(_mode) {
				case 0 : ss += _ch; break;
				case 1 : ch_str += _ch; break;
			}
		}
		
		return ss;
	} #endregion
	
	static line_update = function(txt, line_width = -1) { #region
		_prev_text = txt;
		_lines = [];
		
		var ch, i = 1, ss = "", _txt = _prev_text;
		var len = string_length(_prev_text);
		
		var _line_man = string_splice(_txt, "\n");
		
		draw_set_font(font);
		
		for( var i = 0, n = array_length(_line_man); i < n; i++ ) {
			var _tx = _line_man[i];
			
			while(string_length(_tx) > 0) {
				var sp = min(string_pos(" ", _tx));
				if(sp == 0) sp = string_length(_tx);
			
				var _ps = string_copy(_tx, 1, sp);
				_tx = string_copy(_tx, sp + 1, string_length(_tx) - sp);
			
				if(line_width > 0 && string_width(string_raw(ss + _ps)) * fsize >= line_width) {
					array_push(_lines, ss);
					ss = _ps;
				} else if(string_length(_tx) <= 0) {
					array_push(_lines, ss + _ps);
					ss = "";
				} else 
					ss += _ps;	
			}
		}
		
		if(ss != "") array_push(_lines, ss);
	} #endregion
	
	static onValueUpdate = function(index = 0) { #region
		if(index == 1 || index == 4)
			line_update(getInputData(1), getInputData(4));
	} #endregion
	
	static drawNodeBase = function(xx, yy, mx, my, _s) { #region
		var color  = getInputData(0);
		var txt    = getInputData(1);
		if(txt == "") txt = "..."
		
		var sty  = getInputData(2);
		var alp  = getInputData(3);
		var wid  = getInputData(4);
		var posi = getInputData(5);
		smooth   = getInputData(6);
		
		pos_x = posi[0];
		pos_y = posi[1];
		
		font = f_p1;
		switch(sty) {
			case 0 : font = f_sdf;        fsize  = 20 / 32; break;
			case 1 : font = f_sdf;        fsize  = 0.5;     break;
			case 2 : font = f_sdf_medium; fsize  = 0.5;     break;
		}
		
		var ww = 0;
		var hh = 0;
			
		var tx = xx + 4;
		var ty = yy + 4;
			
		if(WIDGET_CURRENT == ta_editor) {
			switch(sty) {
				case 0 : ta_editor.font = f_h3; break;
				case 1 : ta_editor.font = f_h5; break;
				case 2 : ta_editor.font = f_p1; break;
			}
			
			ta_editor.draw(tx, ty, wid * _s, 0, txt, [ mx, my ] );
		} else {
			if(_prev_text != txt)
				line_update(txt, wid);
			
			draw_set_alpha(alp);
			draw_set_text(font, fa_left, fa_top, color);
			for( var i = 0, n = array_length(_lines); i < n; i++ ) {
				var _line = _lines[i];
				var _h = line_get_height(font) * fsize;
				var _w = draw_text_style(tx, ty, _line, _s, mx, my);
			
				ww = max(ww, _w);
				hh += _h;
				ty += _h * _s;
			}
			draw_set_alpha(1);
			
			if(PANEL_GRAPH.node_hovering == self && PANEL_GRAPH.getFocusingNode() == self) {
				if(point_in_rectangle(mx, my, xx, yy, xx + ww + 8, yy + hh + 8) && DOUBLE_CLICK) {
					ta_editor._current_text = txt;
					ta_editor.activate();
				}
			}
		}
		
		draw_scale = _s;
		w = ww + 8;
		h = hh + 8;
	} #endregion
	
	static drawNode = function(_x, _y, _mx, _my, _s) { #region
		x = smooth? lerp_float(x, pos_x, 4) : pos_x;
		y = smooth? lerp_float(y, pos_y, 4) : pos_y;
		
		var xx = x * _s + _x;
		var yy = y * _s + _y;
		
		if(active_draw_index > -1) {
			draw_sprite_stretched_ext(bg_sel_spr, 0, xx, yy, w * _s, h * _s, COLORS._main_accent, 1);
			active_draw_index = -1;
		}
		
		button_reactive_update();
		drawNodeBase(xx, yy, _mx, _my, _s);
		return noone;
	} #endregion
}