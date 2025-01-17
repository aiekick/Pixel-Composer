function Node_Repeat(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Repeat";
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, noone );
	
	inputs[| 1] = nodeValue("Dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, DEF_SURF)
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 2] = nodeValue("Amount", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 2);
	
	inputs[| 3] = nodeValue("Pattern", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Linear", "Grid", "Circular" ]);
	
	inputs[| 4] = nodeValue("Repeat position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [DEF_SURF_W / 2, 0])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function() { return getDimension(); });
	
	inputs[| 5] = nodeValue("Repeat rotation", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [0, 0])
		.setDisplay(VALUE_DISPLAY.rotation_range);
	
	inputs[| 6] = nodeValue("Scale multiply", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1);
	
	inputs[| 7] = nodeValue("Angle range", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [0, 360])
		.setDisplay(VALUE_DISPLAY.rotation_range);
	
	inputs[| 8] = nodeValue("Radius", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1);
		
	inputs[| 9] = nodeValue("Start position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 0])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getInputData(1); });
		
	inputs[| 10] = nodeValue("Scale over copy", self, JUNCTION_CONNECT.input, VALUE_TYPE.curve, CURVE_DEF_11 );
	
	inputs[| 11] = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.pathnode, noone, "Make each copy follow along path." )
		.setVisible(true, true);
	
	inputs[| 12] = nodeValue("Path range", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 1], "Range of the path to follow.")
		.setDisplay(VALUE_DISPLAY.slider_range);
	
	inputs[| 13] = nodeValue("Path shift", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0);
	
	inputs[| 14] = nodeValue("Color over copy", self, JUNCTION_CONNECT.input, VALUE_TYPE.gradient, new gradientObject(c_white) );
		
	inputs[| 15] = nodeValue("Alpha over copy", self, JUNCTION_CONNECT.input, VALUE_TYPE.curve, CURVE_DEF_11 );
	
	inputs[| 16] = nodeValue("Array select", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0, "Whether to select image from an array in order, at random, pr spread or each image to one output." )
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Order", "Random", "Spread" ]);
	
	inputs[| 17] = nodeValue("Seed", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, irandom(99999) );
	
	inputs[| 18] = nodeValue("Column", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 4);
	
	inputs[| 19] = nodeValue("Column shift", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, DEF_SURF_H / 2])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function() { return getDimension(); });
	
	inputs[| 20] = nodeValue("Animator midpoint", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.5)
		.setDisplay(VALUE_DISPLAY.slider, { range: [-1, 2, 0.01] });
	
	inputs[| 21] = nodeValue("Animator range", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 22] = nodeValue("Animator position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 23] = nodeValue("Animator rotation", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.rotation);
		
	inputs[| 24] = nodeValue("Animator scale", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector);
		
	inputs[| 25] = nodeValue("Animator falloff", self, JUNCTION_CONNECT.input, VALUE_TYPE.curve, CURVE_DEF_10);
	 
	inputs[| 26] = nodeValue("Stack", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0, "Place each copy next to each other, taking surface dimension into account.")
		.setDisplay(VALUE_DISPLAY.enum_button, [ "None", "X", "Y" ]);
	
	inputs[| 27] = nodeValue("Animator blend", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_white);
	
	inputs[| 28] = nodeValue("Animator alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
		
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	input_display_list = [
		["Surfaces",	 true],	0, 1, 16, 17,
		["Pattern",		false],	3, 9, 2, 18, 7, 8, 
		["Path",		 true],	11, 12, 13, 
		["Transform",	false],	4, 26, 19, 5, 6, 10, 
		["Render",		false],	14, 15,
		["Animator",	 true],	20, 21, 25, 22, 23, 24, 27, 28, 
	];
	
	attribute_surface_depth();
	
	static getDimension = function() {
		var _surf = getInputData(0);
		if(is_array(_surf)) {
			if(array_length(_surf) == 0) return [1, 1];
			if(!is_surface(_surf[0])) return [1, 1];
			return [ surface_get_width_safe(_surf[0]), surface_get_height_safe(_surf[0]) ];
		}
			
		if(!is_surface(_surf)) return [1, 1];
		return [ surface_get_width_safe(_surf), surface_get_height_safe(_surf) ];
	}
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		if(inputs[| 9].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny, THEME.anchor))
			active = false;
		
		var _pat  = getInputData(3);
		var _spos = getInputData(9);
		
		var px = _x + _spos[0] * _s;
		var py = _y + _spos[1] * _s;
		
		if(_pat == 0 || _pat == 1) {
			if(inputs[| 4].drawOverlay(active, px, py, _s, _mx, _my, _snx, _sny))
				active = false;
		} else if(_pat == 2) {
			if(inputs[| 8].drawOverlay(active, px, py, _s, _mx, _my, _snx, _sny))
				active = false;
		}
	}
	
	function doRepeat(_outSurf, _inSurf) {
		var _dim    = getInputData( 1);
		var _amo    = getInputData( 2);
		var _pat    = getInputData( 3);
							  
		var _spos = getInputData( 9);
		
		var _rpos = getInputData( 4);
		var _rsta = getInputData(26);
		var _rrot = getInputData( 5);
		var _rsca = getInputData( 6);
		var _msca = getInputData(10);
		
		var _aran = getInputData( 7);
		var _arad = getInputData( 8);
		
		var _path = getInputData(11);
		var _prng = getInputData(12);
		var _prsh = getInputData(13);
		
		var _grad = getInputData(14);
		var _alph = getInputData(15);
		
		var _arr = getInputData(16);
		var _sed = getInputData(17);
		
		var _col = getInputData(18);
		var _cls = getInputData(19);
		
		var _an_mid = getInputData(20);
		var _an_ran = getInputData(21);
		var _an_fal = getInputData(25);
		var _an_pos = getInputData(22);
		var _an_rot = getInputData(23);
		var _an_sca = getInputData(24);
		
		var _an_bld = getInputData(27);
		var _an_alp = getInputData(28);
		
		var _surf, runx, runy, posx, posy, scax, scay, rot;
				   
		random_set_seed(_sed);
		
		surface_set_target(_outSurf);
		DRAW_CLEAR
			runx = 0;
			runy = 0;
			
			for( var i = 0; i < _amo; i++ ) {
				posx = runx;
				posy = runy;
				
				if(_pat == 0) {
					if(_path == noone || !variable_struct_exists(_path, "getPointRatio")) {
						posx += _spos[0] + _rpos[0] * i;
						posy += _spos[1] + _rpos[1] * i;
					} else {
						var rat = _prsh + _prng[0] + (_prng[1] - _prng[0]) * i / _amo;
						if(_prng[1] - _prng[0] == 0) break;
						rat = abs(frac(rat));
						
						var _p = _path.getPointRatio(rat);
						posx = _p.x;
						posy = _p.y;
					}
				} else if(_pat == 1) {
					var row = floor(i / _col);
					var col = safe_mod(i, _col);
					
					posx = _spos[0] + _rpos[0] * col + _cls[0] * row;
					posy = _spos[1] + _rpos[1] * col + _cls[1] * row;
				} else if(_pat == 2) {
					var aa = _aran[0] + (_aran[1] - _aran[0]) * i / _amo;
					posx = _spos[0] + lengthdir_x(_arad, aa);
					posy = _spos[1] + lengthdir_y(_arad, aa);
				}
				
				scax = eval_curve_x(_msca, i / (_amo - 1)) * _rsca;
				scay = scax;
				rot = _rrot[0] + (_rrot[1] - _rrot[0]) * i / (_amo - 1);
				
				var _an_dist = abs(i - _an_mid * (_amo - 1));
				var _inf = 0;
				if(_an_dist < _an_ran * _amo) {
					_inf = eval_curve_x(_an_fal, _an_dist / (_an_ran * _amo));
					posx += _an_pos[0] * _inf;
					posy += _an_pos[1] * _inf;
					rot  += _an_rot    * _inf;
					scax += _an_sca[0] * _inf;
					scay += _an_sca[1] * _inf;
				}
				
				var _surf = _inSurf;
				
				if(is_array(_inSurf)) 
					_surf = array_safe_get(_inSurf, _arr? irandom(array_length(_inSurf) - 1) : safe_mod(i, array_length(_inSurf)));
				
				var _sw = surface_get_width_safe(_surf);
				var _sh = surface_get_height_safe(_surf);
				var sw = _sw * scax;
				var sh = _sh * scay;
				
				if(i) {
					if(_rsta == 1) { 
						runx += _sw / 2;
						posx += _sw / 2;
					}
					if(_rsta == 2) { 
						runy += _sh / 2;
						posy += _sh / 2;
					}
				}
				
				var pos = point_rotate(-sw / 2, -sh / 2, 0, 0, rot);
				var cc  = _grad.eval(i / (_amo - 1));
				var aa  = eval_curve_x(_alph, i / (_amo - 1));
				
				cc = merge_color(cc, colorMultiply(cc, _an_bld), _inf);
				aa += _an_alp * _inf;
				
				draw_surface_ext_safe(_surf, posx + pos[0], posy + pos[1], scax, scay, rot, cc, aa);
				
				if(_rsta == 1)	runx += _sw / 2;
				if(_rsta == 2)	runy += _sh / 2;
			}
		surface_reset_target();
	}
	
	static update = function(frame = CURRENT_FRAME) {
		var _inSurf = getInputData(0);
		if(is_array(_inSurf) && array_length(_inSurf) == 0) return;
		if(!is_array(_inSurf) && !is_surface(_inSurf)) return;
					
		var _dim = getInputData(1);
		var _pat = getInputData(3);
		var cDep = attrDepth();
		
		var _arr = getInputData(16);
		
		inputs[|  4].setVisible( _pat == 0 || _pat == 1);
		inputs[|  7].setVisible( _pat == 2);
		inputs[|  8].setVisible( _pat == 2);
		inputs[| 18].setVisible( _pat == 1);
		inputs[| 19].setVisible( _pat == 1);
		inputs[| 26].setVisible( _pat == 0);
		
		var runx, runy, posx, posy, scax, scay, rot;
		var _outSurf = outputs[| 0].getValue();
		
		if(is_array(_inSurf) && _arr == 2) {
			if(!is_array(_outSurf)) surface_free(_outSurf);
			else {
				for( var i = 0, n = array_length(_outSurf); i < n; i++ )
					surface_free(_outSurf[i]);
			}
			
			for( var i = 0, n = array_length(_inSurf); i < n; i++ ) {
				var _out = surface_create(_dim[0], _dim[1], cDep);
				_outSurf[i] = _out;
				doRepeat(_out, _inSurf[i]);
			}
		} else {
			_outSurf = surface_verify(_outSurf, _dim[0], _dim[1], cDep);
			doRepeat(_outSurf, _inSurf);
		}
		
		outputs[| 0].setValue(_outSurf);
	}
}