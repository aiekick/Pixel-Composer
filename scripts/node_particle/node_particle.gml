function Node_create_Particle(_x, _y) {
	var node = new Node_Particle(_x, _y);
	ds_list_add(PANEL_GRAPH.nodes_list, node);
	return node;
}

function __part() constructor {
	seed   = irandom(9999);
	active = false;
	surf   = noone;
	x   = 0;
	y   = 0;
	sx  = 0;
	sy  = 0;
	ac  = 0;
	g   = 0;
	wig = 0;
	
	fx  = 0;
	fy  = 0;
	
	gy  = 0;
	
	scx   = 1;
	scy   = 1;
	scx_s = 1;
	scy_s = 1;
	
	rot		= 0;
	follow	= false;
	rot_s	= 0;
	
	col      = -1;
	alp      = 1;
	alp_fade = 0;
	
	life       = 0;
	life_total = 0;
	
	surf_w = 1;
	surf_h = 1;
	
	anim_speed = 1;
	
	is_loop = false;
	
	function create(_surf, _x, _y, _life) {
		active	= true;
		surf	= _surf;
		x		= _x;
		y		= _y;
		gy		= 0;
		
		life = _life;
		life_total = life;
		
		if(is_array(_surf)) {
			surf_w = surface_get_width(_surf[0]);
			surf_h = surface_get_height(_surf[0]);
		}
	}
	function setPhysic(_sx, _sy, _ac, _g, _wig) {
		sx  = _sx;
		sy  = _sy;
		ac  = _ac;
		g   = _g;
		
		wig = _wig;
	}
	function setTransform(_scx, _scy, _scxs, _scys, _rot, _rots, _follow) {
		scx   = _scx;
		scy   = _scy;
		scx_s = _scxs;
		scy_s = _scys;
		rot   = _rot;
		rot_s = _rots;
		follow = _follow;
	}
	function setDraw(_col, _alp, _fade) {
		col      = _col;
		alp      = _alp;
		alp_fade = _fade;
	}
	
	function kill() {
		active = false;	
	}
	
	function step() {
		if(!active) return;
		var xp = x, yp = y;
		x  += sx;
		y  += sy;
		
		var dirr = point_direction(0, 0, sx, sy);
		var diss = point_distance(0, 0, sx, sy);
		if(diss > 0) {
			diss += ac;
			dirr += random_range(-wig, wig);
			sx = lengthdir_x(diss, dirr);
			sy = lengthdir_y(diss, dirr);
		}
		
		gy += g;
		y += gy;
		
		if(scx_s < 0)	scx = max(scx + scx_s, 0);
		else			scx = scx + scx_s;
		if(scy_s < 0)	scy = max(scy + scy_s, 0);
		else			scy = scy + scy_s;
		
		if(follow) 
			rot = point_direction(xp, yp, x, y);
		else
			rot += rot_s;
		alp = clamp(alp + alp_fade, 0, 1);
		
		if(life-- < 0) kill();
	}
	
	function draw(exact) {
		if(!active) return;
		var ss = surf;
		if(is_array(surf))
			ss = surf[safe_mod((life_total - life) * anim_speed, array_length(surf))];
		
		if(!ss) return;
		
		var cc = (col == -1)? c_white : gradient_eval(col, 1 - life / life_total);
		var s_w = surf_w * scx;
		var s_h = surf_h * scy;
		var _pp = point_rotate(-s_w / 2, -s_h / 2, 0, 0, rot);
		_pp[0] = x + _pp[0];
		_pp[1] = y + _pp[1];
			
		if(exact) {
			_pp[0] = round(_pp[0]);
			_pp[1] = round(_pp[1]);
		}
			
		draw_surface_ext_safe(ss, _pp[0], _pp[1], scx, scy, rot, cc, alp);
	}
}

enum PARTICLE_BLEND_MODE {
	normal,
	additive
}

function Node_Particle(_x, _y) : Node(_x, _y) constructor {
	name = "Particle";
	auto_update = false;
	use_cache = true;
	
	inputs[| 0] = nodeValue(0, "Particle", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	inputs[| 1] = nodeValue(1, "Output dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, def_surf_size2, VALUE_TAG.dimension_2d)
		.setDisplay(VALUE_DISPLAY.vector)
		.setVisible(false);
	
	inputs[| 2] = nodeValue(2, "Spawn delay", self,  JUNCTION_CONNECT.input, VALUE_TYPE.integer, 4)
		.setVisible(false);
	inputs[| 3] = nodeValue(3, "Spawn amount", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 2)
		.setVisible(false);
	inputs[| 4] = nodeValue(4, "Spawn area", self,   JUNCTION_CONNECT.input, VALUE_TYPE.float, [ def_surf_size / 2, def_surf_size / 2, def_surf_size / 2, def_surf_size / 2, AREA_SHAPE.rectangle ])
		.setDisplay(VALUE_DISPLAY.area, function() { return inputs[| 1].getValue(); })
		.setVisible(false);
	
	inputs[| 5] = nodeValue(5, "Spawn distribution", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Area", "Border" ])
		.setVisible(false);
	
	inputs[| 6] = nodeValue(6, "Lifespan", self,  JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 20, 30 ])
		.setDisplay(VALUE_DISPLAY.range)
		.setVisible(false);
	
	inputs[| 7] = nodeValue(7, "Spawn direction", self,  JUNCTION_CONNECT.input, VALUE_TYPE.integer, [ 45, 135 ])
		.setDisplay(VALUE_DISPLAY.rotation_range)
		.setVisible(false);
	inputs[| 8] = nodeValue(8, "Acceleration", self,  JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.range)
		.setVisible(false);
	
	inputs[| 9] = nodeValue(9, "Orientation", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, [0, 0])
		.setDisplay(VALUE_DISPLAY.rotation_range)
		.setVisible(false);
		
	inputs[| 10] = nodeValue(10, "Rotational speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0)
		.setVisible(false);
	
	inputs[| 11] = nodeValue(11, "Spawn scale", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1, 1, 1 ] )
		.setDisplay(VALUE_DISPLAY.vector_range)
		.setVisible(false);
	inputs[| 12] = nodeValue(12, "Scaling speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ] )
		.setDisplay(VALUE_DISPLAY.vector)
		.setVisible(false);
	
	inputs[| 13] = nodeValue(13, "Color over lifetime", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_white)
		.setDisplay(VALUE_DISPLAY.gradient)
		.setVisible(false);
	inputs[| 14] = nodeValue(14, "Alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ])
		.setDisplay(VALUE_DISPLAY.range)
		.setVisible(false);
	inputs[| 15] = nodeValue(15, "Alpha over time", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0)
		.setVisible(false);
	
	inputs[| 16] = nodeValue(16, "Rotate by direction", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false)
		.setVisible(false);
	
	inputs[| 17] = nodeValue(17, "Spawn type", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Stream", "Burst" ])
		.setVisible(false);
	
	inputs[| 18] = nodeValue(18, "Spawn size", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ] )
		.setDisplay(VALUE_DISPLAY.range)
		.setVisible(false);
	
	inputs[| 19] = nodeValue(19, "Draw exact", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true )
		.setVisible(false);
	
	inputs[| 20] = nodeValue(20, "Spawn velocity", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [1, 2] )
		.setDisplay(VALUE_DISPLAY.range)
		.setVisible(false);
	
	inputs[| 21] = nodeValue(21, "Gravity", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 )
		.setVisible(false);
	inputs[| 22] = nodeValue(22, "Wiggle", self, JUNCTION_CONNECT.input, VALUE_TYPE.float,  0 )
		.setVisible(false);
	
	inputs[| 23] = nodeValue(23, "Loop", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true )
		.setVisible(false);
	
	inputs[| 24] = nodeValue(24, "Blend mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Normal", "Additive" ])
		.setVisible(false);
	
	inputs[| 25] = nodeValue(25, "Surface selection", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Random", "Order", "Animation" ])
		.setVisible(false, false);
	
	inputs[| 26] = nodeValue(26, "Animation speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ] )
		.setDisplay(VALUE_DISPLAY.vector)
		.setVisible(false, false);
	
	inputs[| 27] = nodeValue(27, "Scatter", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Uniform", "Random" ])
		.setVisible(false);
	
	input_display_list = [		
		["Output",		true],	1,
		["Sprite",		true],	0, 25,
		["Spawn",		true],	17, 2, 3, 4, 5, 27, 6,
		["Movement",	true],	7, 20, 8,
		["Physics",		true],	21, 22,
		["Rotation",	true],	16, 9, 10, 
		["Scale",		true],	11, 18, 12, 
		["Color",		true],	13, 14, 15, 24,
		["Render",		true],	26, 19, 23,
	];
	
	outputs[| 0] = nodeValue(0, "Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, surface_create(1, 1));
	
	def_surface = -1;
	
	parts = ds_list_create();
	for(var i = 0; i < PREF_MAP[? "part_max_amount"]; i++)
		ds_list_add(parts, new __part());
	
	outputs[| 1] = nodeValue(1, "Particle data", self, JUNCTION_CONNECT.output, VALUE_TYPE.object, parts );
	
	function spawn() {
		var _inSurf = inputs[| 0].getValue();
		
		if(_inSurf == 0) {
			if(def_surface == -1 || !surface_exists(def_surface)) { 
				def_surface = surface_create(1, 1);
				surface_set_target(def_surface);
				draw_clear(c_white);
				surface_reset_target();
			}
			_inSurf = def_surface;	
		}
		
		var _spawn_amount	= inputs[| 3].getValue();
		var _amo = _spawn_amount;
		
		var _spawn_area		= inputs[| 4].getValue();
		var _distrib		= inputs[| 5].getValue();
		var _scatter		= inputs[| 27].getValue();
		
		var _life			= inputs[| 6].getValue();
		var _direction		= inputs[| 7].getValue();
		var _velocity		= inputs[| 20].getValue();
		
		var _accel			= inputs[| 8].getValue();
		var _grav			= inputs[| 21].getValue();
		var _wigg			= inputs[| 22].getValue();
		
		var _follow			= inputs[| 16].getValue();
		var _rotation		= inputs[| 9].getValue();
		var _rotation_speed	= inputs[| 10].getValue();
		var _scale			= inputs[| 11].getValue();
		var _size 			= inputs[| 18].getValue();
		var _scale_speed	= inputs[| 12].getValue();
		
		var _loop	= inputs[| 23].getValue();
		
		var _color	= inputs[| 13].getValue();
		var _alpha	= inputs[| 14].getValue();
		var _fade	= inputs[| 15].getValue();
		
		var _arr_type	= inputs[| 25].getValue();
		var _anim_speed	= inputs[| 26].getValue();
		
		if(_rotation[1] < _rotation[0]) _rotation[1] += 360;
		
		for(var i = 0; i < PREF_MAP[? "part_max_amount"]; i++) {
			if(!parts[| i].active) {
				var _spr = _inSurf;
				if(is_array(_inSurf)) {
					if(_arr_type == 0)
						_spr = _inSurf[irandom(array_length(_inSurf) - 1)];
					else if(_arr_type == 1)
						_spr = _inSurf[safe_mod(spawn_index, array_length(_inSurf))];
					else if(_arr_type == 2)
						_spr = _inSurf;
				}
				var xx, yy;
				
				var sp = area_get_random_point(_spawn_area, _distrib, _scatter, spawn_index, _spawn_amount);
				xx = sp[0];
				yy = sp[1];
				
				var _lif = random_range(_life[0], _life[1]);
				
				var _rot = random_range(_rotation[0], _rotation[1]);
				
				var _dirr	= random_range(_direction[0], _direction[1]);
				
				var _velo	= random_range(_velocity[0], _velocity[1]);
				var _vx		= lengthdir_x(_velo, _dirr);
				var _vy		= lengthdir_y(_velo, _dirr);
				var _acc	= random_range(_accel[0], _accel[1]);
				
				var _ss  = random_range(_size[0], _size[1]);
				var _scx = random_range(_scale[0], _scale[1]) * _ss;
				var _scy = random_range(_scale[2], _scale[3]) * _ss;
				
				var _alp = random_range(_alpha[0], _alpha[1]);
				
				parts[| i].create(_spr, xx, yy, _lif);
				parts[| i].anim_speed = random_range(_anim_speed[0], _anim_speed[1]);
				
				parts[| i].setPhysic(_vx, _vy, _acc, _grav, _wigg);
				parts[| i].setTransform(_scx, _scy, _scale_speed[0], _scale_speed[1], _rot, _rotation_speed, _follow);
				parts[| i].setDraw(_color, _alp, _fade);
				spawn_index = safe_mod(spawn_index + 1, PREF_MAP[? "part_max_amount"]);
				
				if(_loop && ANIMATOR.current_frame + _lif > ANIMATOR.frames_total)
					parts[| i].is_loop = true;
				
				if(--_amo <= 0)
					return;
			}
		}
	}
	
	function reset() {
		spawn_index = 0;
		for(var i = 0; i < PREF_MAP[? "part_max_amount"]; i++) {
			if(parts[| i].is_loop)
				parts[| i].is_loop = false;
			else
				parts[| i].kill();
		}
		render();
	}
	
	function updateParticle() {
		var jun = outputs[| 1];
		for(var j = 0; j < ds_list_size(jun.value_to); j++) {
			if(jun.value_to[| j].value_from == jun) {
				jun.value_to[| j].node.updateParticle();
			}
		}
		
		render();
	}
	
	function resetPartPool() {
		var _part_amo = PREF_MAP[? "part_max_amount"];
		if(_part_amo > ds_list_size(parts)) {
			repeat(_part_amo - ds_list_size(parts)) {
				ds_list_add(parts, new __part());
			}
		} else if(_part_amo < ds_list_size(parts)) {
			repeat(ds_list_size(parts) - _part_amo) {
				ds_list_delete(parts, 0);
			}
		}
	}
	
	function step() {
		var _inSurf = inputs[| 0].getValue();
		
		inputs[| 25].show_in_inspector = false;
		inputs[| 26].show_in_inspector = false;
		
		if(is_array(_inSurf)) {
			inputs[| 25].show_in_inspector = true;
			var _type = inputs[| 25].getValue();
			if(_type == 2) {
				inputs[| 26].show_in_inspector = true;
			}
		}
		
		resetPartPool();
		var _spawn_type = inputs[| 17].getValue();
		if(_spawn_type == 0)
			inputs[| 2].name = "Spawn delay";
		else
			inputs[| 2].name = "Spawn frame";
		
		var _spawn_delay = inputs[| 2].getValue();

		if(ANIMATOR.is_playing && ANIMATOR.frame_progress) {
			if(ANIMATOR.current_frame == 0) reset();
			
			if(_spawn_type == 0) {
				if(safe_mod(ANIMATOR.current_frame, _spawn_delay) == 0)
					spawn();
			} else if(_spawn_type == 1) {
				if(ANIMATOR.current_frame == _spawn_delay)
					spawn();
			}
			
			for(var i = 0; i < PREF_MAP[? "part_max_amount"]; i++)
				parts[| i].step();
			updateParticle();
			
			updateForward();
		}
		
		if(ANIMATOR.is_scrubing) {
			recoverCache();	
		}
	}
	
	static drawOverlay = function(_active, _x, _y, _s, _mx, _my) {
		inputs[| 4].drawOverlay(_active, _x, _y, _s, _mx, _my);
	}
	
	function render() {
		var _dim		= inputs[| 1].getValue();
		var _exact 		= inputs[| 19].getValue();
		var _blend 		= inputs[| 24].getValue();
		
		var _outSurf	= outputs[| 0].getValue();
		
		if(is_surface(_outSurf)) 
			surface_size_to(_outSurf, surface_valid(_dim[0]), surface_valid(_dim[1]));
		else {
			_outSurf = surface_create(surface_valid(_dim[0]), surface_valid(_dim[1]));
			outputs[| 0].setValue(_outSurf);
		}
		
		surface_set_target(_outSurf);
			draw_clear_alpha(0, 0);
			
			switch(_blend) {
				case PARTICLE_BLEND_MODE.normal		: 
					gpu_set_blendmode(bm_normal);	
					break;
				case PARTICLE_BLEND_MODE.additive   : 
					gpu_set_blendmode(bm_add);
					break;
			}
			
			for(var i = 0; i < PREF_MAP[? "part_max_amount"]; i++)
				parts[| i].draw(_exact);
			
			gpu_set_blendmode(bm_normal);
		surface_reset_target();
		
		cacheCurrentFrame(_outSurf);
	}
	
	function update() {
		reset();
	}
	update();
	render();
}