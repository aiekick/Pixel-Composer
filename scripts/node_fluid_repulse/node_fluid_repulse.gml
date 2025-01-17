function Node_Fluid_Repulse(_x, _y, _group = noone) : Node_Fluid(_x, _y, _group) constructor {
	name  = "Repulse";
	w = 96;
	min_h = 96;
	
	inputs[| 0] = nodeValue("Domain", self, JUNCTION_CONNECT.input, VALUE_TYPE.fdomain, noone)
		.setVisible(true, true);
	
	inputs[| 1] = nodeValue("Position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [0, 0])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 2] = nodeValue("Radius", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 8);
	
	inputs[| 3] = nodeValue("Strength", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.10)
		.setDisplay(VALUE_DISPLAY.slider, { range: [-1, 1, 0.01] });
	
	inputs[| 4] = nodeValue("Mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Override", "Add" ]);
	
	input_display_list = [ 
		["Domain",	false], 0, 
		["Repulse",	false], 4, 1, 2, 3
	];
	
	outputs[| 0] = nodeValue("Domain", self, JUNCTION_CONNECT.output, VALUE_TYPE.fdomain, noone);
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		var _pos = getInputData(1);
		var _rad = getInputData(2);
		var px = _x + _pos[0] * _s;
		var py = _y + _pos[1] * _s;
		
		draw_set_color(COLORS._main_accent);
		draw_circle_prec(px, py, _rad * _s, true);
		
		inputs[| 1].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
		inputs[| 2].drawOverlay(active, px, py, _s, _mx, _my, _snx, _sny, 0, 1, THEME.anchor_scale_hori);
	}
	
	static update = function(frame = CURRENT_FRAME) {
		var _dom = inputs[| 0].getValue(frame);
		var _pos = inputs[| 1].getValue(frame);
		var _rad = inputs[| 2].getValue(frame);
		var _str = inputs[| 3].getValue(frame);
		var _mod = inputs[| 4].getValue(frame);
		
		FLUID_DOMAIN_CHECK
		outputs[| 0].setValue(_dom);
		
		_rad = max(_rad, 1);
		var vSurface = surface_create_size(_dom.sf_velocity);
		
		surface_set_target(vSurface)
			draw_clear_alpha(0., 0.);
			shader_set(sh_fd_repulse);
			BLEND_OVERRIDE;
		
			shader_set_f("strength", _str);
			draw_sprite_stretched(s_fx_pixel, 0, _pos[0] - _rad, _pos[1] - _rad, _rad * 2, _rad * 2);
			BLEND_NORMAL;
			shader_reset();
		surface_reset_target();
		
		with(_dom) {
			fd_rectangle_set_target(id, _mod? FD_TARGET_TYPE.ADD_VELOCITY : FD_TARGET_TYPE.REPLACE_VELOCITY);
			draw_surface_safe(vSurface, 0, 0);
			fd_rectangle_reset_target(id);
		}
		
		surface_free(vSurface);
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		
		draw_sprite_fit(s_node_smokeSim_repulse, 0, bbox.xc, bbox.yc, bbox.w, bbox.h);
	}
}