globalvar BLEND_TYPES;
BLEND_TYPES = [ 
	"Normal",  "Add",     "Subtract",   "Multiply",   "Screen", 
	"Overlay", "Hue",     "Saturation", "Luminosity", "Maximum", 
	"Minimum", "Replace", "Difference" 
];

function draw_surface_blend(background, foreground, blend = 0, alpha = 1, _pre_alp = true, _mask = 0, tile = 0) {
	if(!is_surface(background)) return;
	
	var sh = sh_blend_normal
	switch(array_safe_get(BLEND_TYPES, blend)) {
		case "Normal" :		sh = sh_blend_normal		break;
		case "Add" :		sh = sh_blend_add;			break;
		case "Subtract" :	sh = sh_blend_subtract;		break;
		case "Multiply" :	sh = sh_blend_multiply;		break;
		case "Screen" :		sh = sh_blend_screen;		break;
		
		case "Overlay" :	sh = sh_blend_overlay;		break;
		case "Hue" :		sh = sh_blend_hue;			break;
		case "Saturation" :	sh = sh_blend_sat;			break;
		case "Luminosity" :	sh = sh_blend_luma;			break;
		case "Maximum" :	sh = sh_blend_max;			break;
		
		case "Minimum" :	sh = sh_blend_min;			break;
		case "Replace" :	sh = sh_blend_replace;		break;
		case "Difference" :	sh = sh_blend_difference;	break;
		default: return;
	}
	
	var surf	= surface_get_target();
	var surf_w  = surface_get_width_safe(surf);
	var surf_h  = surface_get_height_safe(surf);
	
	if(is_surface(foreground)) {
		shader_set(sh);
		shader_set_surface("fore",		foreground);
		shader_set_surface("mask",		_mask);
		shader_set_i("useMask",			is_surface(_mask));
		shader_set_f("dimension",		surface_get_width_safe(background) / surface_get_width_safe(foreground), surface_get_height_safe(background) / surface_get_height_safe(foreground));
		shader_set_f("opacity",			alpha);
		shader_set_i("preserveAlpha",	_pre_alp);
		shader_set_i("tile_type",		tile);
	}
	
	BLEND_OVERRIDE
	draw_surface_stretched_safe(background, 0, 0, surf_w, surf_h);
	BLEND_NORMAL
	shader_reset();
}

function draw_surface_blend_ext(bg, fg, _x, _y, _sx = 1, _sy = 1, _rot = 0, _col = c_white, _alpha = 1, _blend = 0) {
	surface_set_shader(blend_temp_surface);
		shader_set_interpolation(fg);
		draw_surface_ext_safe(fg, _x, _y, _sx, _sy, _rot, _col, 1);
	surface_reset_shader();
	
	draw_surface_blend(bg, blend_temp_surface, _blend, _alpha, false);
}