function Node_Image_Sheet(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name  = "Splice Spritesheet";
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1]  = nodeValue("Sprite size", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 32, 32 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 2]  = nodeValue("Row", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1); //unused
	inputs[| 3]  = nodeValue("Amount", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 1, 1 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 4]  = nodeValue("Offset", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 5]  = nodeValue("Spacing", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 6]  = nodeValue("Padding", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [0, 0, 0, 0])
		.setDisplay(VALUE_DISPLAY.padding);
	
	inputs[| 7]  = nodeValue("Output", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Animation", "Array"]);
	
	inputs[| 8]  = nodeValue("Animation speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1);
	
	inputs[| 9]  = nodeValue("Orientation", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Horizontal", "Vertical"]);
	
	inputs[| 10] = nodeValue("Auto fill", self, JUNCTION_CONNECT.input, VALUE_TYPE.trigger, 0, "Automatically set amount based on sprite size.")
		.setDisplay(VALUE_DISPLAY.button, { name: "Auto fill", onClick: function() { #region
			var _sur = getInputData(0);
			if(!is_surface(_sur) || _sur == DEF_SURFACE) return;
			var ww = surface_get_width_safe(_sur);
			var hh = surface_get_height_safe(_sur);
		
			var _size = getInputData(1);
			var _offs = getInputData(4);
			var _spac = getInputData(5);
			var _orie = getInputData(9);
		
			var sh_w = _size[0] + _spac[0];
			var sh_h = _size[1] + _spac[1];
		
			var fill_w = floor((ww - _offs[0]) / sh_w);
			var fill_h = floor((hh - _offs[1]) / sh_h);
			
			if(_orie == 0)	inputs[| 3].setValue([ fill_w, fill_h ]);
			else			inputs[| 3].setValue([ fill_h, fill_w ]);
		
			doUpdate();
		} }); #endregion
		
	inputs[| 11] = nodeValue("Sync animation", self, JUNCTION_CONNECT.input, VALUE_TYPE.trigger, 0)
		.setDisplay(VALUE_DISPLAY.button, { name: "Sync frames", onClick: function() { 
			var _atl = outputs[| 1].getValue();
			var _spd = getInputData(8);
			TOTAL_FRAMES = max(1, _spd == 0? 1 : ceil(array_length(_atl) / _spd));
		} });
		
	inputs[| 12] = nodeValue("Filter empty output", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
		
	inputs[| 13] = nodeValue("Filtered Pixel", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Transparent", "Color" ]);
	
	inputs[| 14] = nodeValue("Filtered Color", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_black)
	
	input_display_list = [
		["Sprite", false],	0, 1, 6, 
		["Sheet",  false],	3, 10, 9, 4, 5, 
		["Output", false],	7, 8, 12, 13, 14, 11
	];
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	outputs[| 1] = nodeValue("Atlas Data", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, [])
		.setArrayDepth(1);
	
	attribute_surface_depth();
	
	drag_type = 0;	
	drag_sx   = 0;
	drag_sy   = 0;
	drag_mx   = 0;
	drag_my   = 0;
	curr_off  = [0, 0];
	curr_dim  = [0, 0];
	curr_amo  = [0, 0];
	
	surf_array = [];
	atls_array = [];
	
	surf_size_w = 1;
	surf_size_h = 1;
	
	surf_space  = 0;
	surf_origin = 0;
	
	sprite_pos   = [];
	sprite_valid = [];
	spliceSurf   = noone;
	
	static getPreviewValues = function() { return getInputData(0); }
	
	static onValueFromUpdate = function() { _inSurf = noone; }
	static onValueUpdate     = function() { _inSurf = noone; }
	
	function getSpritePosition(index) { #region
		var _dim = curr_dim;
		var _col = curr_amo[0];
		var _off = curr_off;
		var _spa = surf_space;
		var _ori = surf_origin;
		
		var _irow = floor(index / _col);
		var _icol = safe_mod(index, _col);
		
		var _x, _y;
		
		var _x = _off[0] + _icol * (_dim[0] + _spa[0]);
		var _y = _off[1] + _irow * (_dim[1] + _spa[1]);
		
		if(_ori == 0) return [ _x, _y ];
		else		  return [ _y, _x ];
	} #endregion 
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) { #region
		var _inSurf  = getInputData(0);
		if(!is_surface(_inSurf)) return;
		
		var _out = getInputData(7);
		var _spc = getInputData(5);
		
		if(drag_type == 0) {
			curr_dim = getInputData(1);
			curr_amo = getInputData(3);
			curr_off = getInputData(4);
		}
		
		var _amo = array_safe_get(curr_amo, 0) * array_safe_get(curr_amo, 1);
		
		if(_amo < 256) {
			for(var i = _amo - 1; i >= 0; i--) {
				if(!array_safe_get(sprite_valid, i, true))
					continue;
				
				var _f = sprite_pos[i];
				var _fx0 = _x + _f[0] * _s;
				var _fy0 = _y + _f[1] * _s;
				var _fx1 = _fx0 + curr_dim[0] * _s;
				var _fy1 = _fy0 + curr_dim[1] * _s;
			
				draw_set_color(COLORS._main_accent);
				draw_set_alpha(i == 0? 1 : 0.75);
				draw_rectangle(_fx0, _fy0, _fx1 - 1, _fy1 - 1, true);
				draw_set_alpha(1);
			}
		} else {
			var _f = sprite_pos[0];
			var _fx0 = _x + _f[0] * _s;
			var _fy0 = _y + _f[1] * _s;
			var _fx1 = _fx0 + curr_dim[0] * _s;
			var _fy1 = _fy0 + curr_dim[1] * _s;
			
			draw_set_color(COLORS._main_accent);
			draw_rectangle(_fx0, _fy0, _fx1 - 1, _fy1 - 1, true);
		}
		
		var __ax = curr_off[0];
		var __ay = curr_off[1];
		var __aw = curr_dim[0];
		var __ah = curr_dim[1];
						
		var _ax = __ax * _s + _x;
		var _ay = __ay * _s + _y;
		var _aw = __aw * _s;
		var _ah = __ah * _s;
		
		var _bw = curr_amo[0] * (curr_dim[0] + _spc[0]) - _spc[0]; _bw *= _s;
		var _bh = curr_amo[1] * (curr_dim[1] + _spc[1]) - _spc[1]; _bh *= _s;
		
		draw_sprite_colored(THEME.anchor, 0, _ax, _ay);
		draw_sprite_colored(THEME.anchor_selector, 0, _ax + _aw, _ay + _ah);
		draw_sprite_colored(THEME.anchor_arrow, 0, _ax + _bw + _s * 4, _ay + _bh / 2);
		draw_sprite_colored(THEME.anchor_arrow, 0, _ax + _bw / 2, _ay + _bh + _s * 4,, -90);
		
		if(active) {
			if(point_in_circle(_mx, _my, _ax + _aw, _ay + _ah, 8))
				draw_sprite_colored(THEME.anchor_selector, 1, _ax + _aw, _ay + _ah);
			else if(point_in_rectangle(_mx, _my, _ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah))
				draw_sprite_colored(THEME.anchor, 0, _ax, _ay, 1.25, c_white);
			else if(point_in_circle(_mx, _my, _ax + _bw + _s * 4, _ay + _bh / 2, 8))
				draw_sprite_colored(THEME.anchor_arrow, 1, _ax + _bw + _s * 4, _ay + _bh / 2);
			else if(point_in_circle(_mx, _my, _ax + _bw / 2, _ay + _bh + _s * 4, 8))
				draw_sprite_colored(THEME.anchor_arrow, 1, _ax + _bw / 2, _ay + _bh + _s * 4,, -90);
		}
		
		#region area
			var __dim = getInputData(1);
			var __amo = getInputData(3);
			var __off = getInputData(4);
						
			var _ax = __off[0] * _s + _x;
			var _ay = __off[1] * _s + _y;
			var _aw = __dim[0] * _s;
			var _ah = __dim[1] * _s;
			
			if(drag_type == 1) {
				var _xx = value_snap(round(drag_sx + (_mx - drag_mx) / _s), _snx);
				var _yy = value_snap(round(drag_sy + (_my - drag_my) / _s), _sny);
							
				var off = [_xx, _yy];
				curr_off = off;
			
				if(mouse_release(mb_left)) {
					drag_type = 0;
					inputs[| 4].setValue(off);
				}
			} else if(drag_type == 2) {
				var _dx = value_snap(round(abs((_mx - drag_mx) / _s)), _snx);
				var _dy = value_snap(round(abs((_my - drag_my) / _s)), _sny);
				
				var dim = [_dx, _dy];
				curr_dim = dim;
							
				if(key_mod_press(SHIFT)) {
					dim[0] = max(_dx, _dy);
					dim[1] = max(_dx, _dy);
				}
				
				if(mouse_release(mb_left)) {
					drag_type = 0;
					inputs[| 1].setValue(dim);
				}
			} else if(drag_type == 3) {
				var _col = floor((abs(_mx - drag_mx) / _s - _spc[0]) / (__dim[0] + _spc[0]));
				curr_amo[0] = _col;
				
				if(mouse_release(mb_left)) {
					drag_type = 0;
					inputs[| 3].setValue(curr_amo);
				}
			} else if(drag_type == 4) {
				var _row = floor((abs(_my - drag_my) / _s - _spc[1]) / (__dim[1] + _spc[1]));
				curr_amo[1] = _row;
				
				if(mouse_release(mb_left)) {
					drag_type = 0;
					inputs[| 3].setValue(curr_amo);
				}
			}
						
			if(mouse_press(mb_left, active)) {
				if(point_in_circle(_mx, _my, _ax + _aw, _ay + _ah, 8)) { // drag size
					drag_type = 2;
					drag_mx   = _ax;
					drag_my   = _ay;
				} else if(point_in_rectangle(_mx, _my, _ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah)) { // drag position
					drag_type = 1;	
					drag_sx   = __off[0];
					drag_sy   = __off[1];
					drag_mx   = _mx;
					drag_my   = _my;
				} else if(point_in_circle(_mx, _my, _ax + _bw + _s * 4, _ay + _bh / 2, 8)) { // drag col
					drag_type = 3;
					drag_mx   = _ax;
					drag_my   = _ay;
				} else if(point_in_circle(_mx, _my, _ax + _bw / 2, _ay + _bh + _s * 4, 8)) { // drag row
					drag_type = 4;
					drag_mx   = _ax;
					drag_my   = _ay;
				}
			}
		#endregion
	} #endregion
	
	static step = function() { #region
		var _out  = getInputData(7);
		var _filt = getInputData(12);
		var _flty = getInputData(13);
		
		inputs[| 11].setVisible(!_out);
		inputs[|  8].setVisible(!_out);
		inputs[| 13].setVisible(_filt);
		inputs[| 14].setVisible(_filt && _flty);
	} #endregion
	
	static spliceSprite = function() { #region
		var _inSurf = getInputData(0);
		if(!is_surface(_inSurf)) return;
		
		spliceSurf  = _inSurf;
		
		var _outSurf = outputs[| 0].getValue();
		var _out	 = getInputData(7);
		
		var _dim	= getInputData(1);
		var _amo	= getInputData(3);
		var _off	= getInputData(4);
		var _total  = _amo[0] * _amo[1];
		var _pad	= getInputData(6);
		
		var ww   = _dim[0] + _pad[0] + _pad[2];
		var hh   = _dim[1] + _pad[1] + _pad[3];
		
		var _resizeSurf = surf_size_w != ww || surf_size_h != hh;
		
		surf_size_w = ww;
		surf_size_h = hh;
		
		var _filt = getInputData(12);
		var _fltp = getInputData(13);
		var _flcl = getInputData(14);
		
		var cDep  = attrDepth();
		curr_dim = _dim;
		curr_amo = is_array(_amo)? _amo : [1, 1];
		curr_off = _off;
		
		if(ww <= 1 || hh <= 1) return;
		
		if(_filt) {
			var filSize = 4;
			var _empS = surface_create_valid(filSize, filSize, cDep);
			var _buff = buffer_create(filSize * filSize * surface_format_get_bytes(cDep), buffer_fixed, 2);
		}
		
		var _atl = array_create(_total);
		var _sar = array_create(_total);
		var _arrAmo = 0;
		
		surf_space  = getInputData(5);
		surf_origin = getInputData(9);
	
		for(var i = 0; i < _total; i++) 
			sprite_pos[i] = getSpritePosition(i);
		
		for(var i = 0; i < _total; i++) {
			var _s = array_safe_get(surf_array, i);
			
			if(!surface_exists(_s)) _s = surface_create(ww, hh, cDep);
			else if(surface_get_format(_s) != cDep) {
				surface_free(_s);
				_s = surface_create(ww, hh, cDep);
			} else if(_resizeSurf) _s = surface_resize(_s, ww, hh);
			
			var _a = array_safe_get(atls_array, i, 0);
			if(_a == 0) _a = new SurfaceAtlas(_s, 0, 0);
			else        _a.setSurface(_s);
			
			var _spr_pos = sprite_pos[i];
			
			surface_set_target(_s);
				DRAW_CLEAR
				draw_surface_part(_inSurf, _spr_pos[0], _spr_pos[1], _dim[0], _dim[1], _pad[2], _pad[1]);
			surface_reset_target();
			
			_a.x = _spr_pos[0];
			_a.y = _spr_pos[1];
				
			if(!_filt) {
				_atl[_arrAmo] = _a;
				_sar[_arrAmo] = _s;
				_arrAmo++;
				
				sprite_valid[i] = true;
				continue;
			}
			
			gpu_set_tex_filter(true);
			surface_set_target(_empS);
			DRAW_CLEAR
			draw_surface_stretched_safe(_s, 0, 0, filSize, filSize);
			surface_reset_target();
			gpu_set_tex_filter(false);
				
			buffer_get_surface(_buff, _empS, 0);
			buffer_seek(_buff, buffer_seek_start, 0);
			var empty = true;
				
			repeat(filSize * filSize - 1) {
				var c = buffer_read(_buff, buffer_u32);
				if(_fltp == 0 && ((c & 0xFF000000) >> 24) != 0) {
					empty = false;
					break;
				} else if(_fltp == 1 && (c & 0x00FFFFFF) != _flcl) {
					empty = false;
					break;
				}
			}
					
			if(!empty) {
				_atl[_arrAmo] = _a;
				_sar[_arrAmo] = _s;
				_arrAmo++;
			}
			sprite_valid[i] = !empty;
		}
		
		for( var i = _arrAmo, n = array_length(surf_array); i < n; i++ )
			if(is_surface(surf_array[i])) surface_free(surf_array[i]);
			
		surf_array = array_create(_arrAmo);
		array_copy(surf_array, 0, _sar, 0, _arrAmo);
		
		atls_array = array_create(_arrAmo);
		array_copy(atls_array, 0, _atl, 0, _arrAmo);
		
		if(_out == 1) outputs[| 0].setValue(surf_array);
		outputs[| 1].setValue(atls_array);
		
		if(_filt) {
			buffer_delete(_buff);
			surface_free(_empS);
		}
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		spliceSprite();
		
		var _out = getInputData(7);
		if(_out == 1) {
			outputs[| 0].setValue(surf_array);
			update_on_frame = false;
			return;
		}
		
		var _spd = getInputData(8);
		update_on_frame = true;
		
		if(array_length(surf_array)) {
			var ind = safe_mod(CURRENT_FRAME * _spd, array_length(surf_array));
			outputs[| 0].setValue(array_safe_get(surf_array, ind));
		}
	} #endregion
}