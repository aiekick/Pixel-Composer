/// @description init
if !ready exit;

#region dropper
	selector.interactable = interactable;
	if(selector.dropper_active) {
		selector.drawDropper(self);
		exit;
	}
#endregion

#region base UI
	var presets_x  = dialog_x;
	var presets_w  = ui(240);
	
	var content_x = dialog_x + presets_w + ui(16);
	var content_w = dialog_w - presets_w - ui(16);
	
	var p  = DIALOG_PAD;
	var p2 = DIALOG_PAD * 2;
	
	draw_sprite_stretched(THEME.dialog_bg, 0, presets_x - p, dialog_y - p, presets_w + p2, dialog_h + p2);
	if(sFOCUS) 
		draw_sprite_stretched_ext(THEME.dialog_active, 0, presets_x - p, dialog_y - p, presets_w + p2, dialog_h + p2, COLORS._main_accent, 1);
	
	draw_sprite_stretched(THEME.dialog_bg, 0, content_x - p, dialog_y - p, content_w + p2, dialog_h + p2);
	if(sFOCUS)
		draw_sprite_stretched_ext(THEME.dialog_active, 0, content_x - p, dialog_y - p, content_w + p2, dialog_h + p2, COLORS._main_accent, 1);
	
	draw_set_text(f_p0, fa_left, fa_top, COLORS._main_text);
	draw_text(presets_x + ui(24), dialog_y + ui(16), __txt("Palettes"));
	draw_text(content_x + (!interactable * ui(32)) + ui(24), dialog_y + ui(16), name);
	if(!interactable)
		draw_sprite_ui(THEME.lock, 0, content_x + ui(24 + 12), dialog_y + ui(16 + 12),,,, COLORS._main_icon);
#endregion

#region palette
	draw_sprite_stretched(THEME.ui_panel_bg, 1, presets_x + ui(16), dialog_y + ui(44), ui(240 - 32), dialog_h - ui(60));
	
	sp_presets.setFocusHover(sFOCUS, sHOVER);
	sp_presets.draw(presets_x + ui(24), dialog_y + ui(44));
	
	var bx = presets_x + presets_w - ui(44);
	var by = dialog_y + ui(12);
	
	if(buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, __txt("Refresh"), THEME.refresh) == 2)
		__initPalette();
	bx -= ui(32);
	
	if(buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, __txtx("color_selector_open_palette", "Open palette folder"), THEME.folder) == 2) {
		var _realpath = environment_get_variable("LOCALAPPDATA") + "/Pixels_Composer/Palettes";
		var _windir   = environment_get_variable("WINDIR") + "/explorer.exe";
		shell_execute_async(_windir, _realpath);
	}
	bx -= ui(32);
	
	if(buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, __txt("Show on Selector"), THEME.display_palette, NODE_COLOR_SHOW_PALETTE, c_white) == 2)
		NODE_COLOR_SHOW_PALETTE = !NODE_COLOR_SHOW_PALETTE;
	bx -= ui(32);
#endregion

#region selector
	var col_x = content_x + ui(20);
	var col_y = dialog_y + ui(52);
	
	if(preset_selecting > -1)
		selector.palette = PALETTES[preset_selecting].palette;
	selector.draw(col_x, col_y, sFOCUS, sHOVER);
#endregion

#region controls
	var bx = content_x + content_w - ui(36);
	var by = dialog_y + dialog_h - ui(36);
	
	b_apply.register();
	b_apply.setFocusHover(sFOCUS, sHOVER);
	b_apply.draw(bx - ui(18), by - ui(18), ui(36), ui(36), mouse_ui, THEME.button_lime);
	
	bx -= ui(48);
	b_cancel.register();
	b_cancel.setFocusHover(sFOCUS, sHOVER);
	b_cancel.draw(bx - ui(18), by - ui(18), ui(36), ui(36), mouse_ui, THEME.button_hide);
#endregion