function draw_tooltip_text(txt) {
	draw_set_text(f_p0, fa_left, fa_top, COLORS._main_text);
	
	var tw = string_width(txt);
	var th = string_height(txt);
		
	var mx = min(mouse_mx + ui(16), WIN_W - (tw + ui(16)));
	var my = min(mouse_my + ui(16), WIN_H - (th + ui(16)));
		
	draw_sprite_stretched(THEME.textbox, 3, mx, my, tw + ui(16), th + ui(16));
	draw_sprite_stretched(THEME.textbox, 0, mx, my, tw + ui(16), th + ui(16));
	draw_text(mx + ui(8), my + ui(8), txt);
}

function draw_tooltip_color(clr) {
	if(is_array(clr)) {
		draw_tooltip_palette(clr);
		return;
	}
	
	var ww = ui(32);
	var hh = ui(32);
		
	var mx = min(mouse_mx + ui(16), WIN_W - (ww + ui(16)));
	var my = min(mouse_my + ui(16), WIN_H - (hh + ui(16)));
		
	draw_sprite_stretched(THEME.textbox, 3, mx, my, ww + ui(16), hh + ui(16));
	draw_sprite_stretched(THEME.textbox, 0, mx, my, ww + ui(16), hh + ui(16));
	
	draw_set_color(clr);
	draw_rectangle(mx + ui(8), my + ui(8), mx + ui(ww + 8), my + ui(hh + 8), false);
}

function draw_tooltip_palette(clr) {
	var ww = min(ui(160), ui(32) * array_length(clr));
	var hh = ui(32);
		
	var mx = min(mouse_mx + ui(16), WIN_W - (ww + ui(16)));
	var my = min(mouse_my + ui(16), WIN_H - (hh + ui(16)));
		
	draw_sprite_stretched(THEME.textbox, 3, mx, my, ww + ui(16), hh + ui(16));
	draw_sprite_stretched(THEME.textbox, 0, mx, my, ww + ui(16), hh + ui(16));
	
	drawPalette(clr, mx + ui(8), my + ui(8), ui(ww), ui(hh));
}

function draw_tooltip_surface(surf) {
	if(!is_surface(surf)) return;
	
	var sw = surface_get_width(surf);
	var sh = surface_get_height(surf);
	
	var ss = min(ui(128) / sw, ui(128) / sh);
	
	var ww = sw * ss;
	var hh = sh * ss;
	
	var mx = min(mouse_mx + ui(16), WIN_W - (ww + ui(16)));
	var my = min(mouse_my + ui(16), WIN_H - (hh + ui(16)));
		
	draw_sprite_stretched(THEME.textbox, 3, mx, my, ww + ui(16), hh + ui(16));
	draw_sprite_stretched(THEME.textbox, 0, mx, my, ww + ui(16), hh + ui(16));
	
	draw_surface_ext_safe(surf, mx + ui(8), my + ui(8), ss, ss);
}