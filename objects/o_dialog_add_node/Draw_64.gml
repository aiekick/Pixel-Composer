/// @description init
if !ready exit;

#region base UI
	DIALOG_DRAW_BG
	if(sFOCUS) DIALOG_DRAW_FOCUS
#endregion

#region search
	WIDGET_CURRENT = tb_search;
	
	if(search_string == "") {
		tb_search.setFocusHover(false, false);
		tb_search.sprite_index = 1;
		
		catagory_pane.setFocusHover(sFOCUS, sHOVER);
		catagory_pane.draw(dialog_x + ui(14), dialog_y + ui(52));
		
		var _x = dialog_x + category_width - ui(12);
		draw_sprite_stretched(THEME.ui_panel_bg, 1, _x, dialog_y + ui(52), dialog_w - category_width - ui(2), dialog_h - ui(66));
		content_pane.setFocusHover(sFOCUS, sHOVER);
		content_pane.draw(_x, dialog_y + ui(52));
		
		node_selecting = 0;
	} else {
		tb_search.setFocusHover(true, true);
		draw_sprite_stretched(THEME.ui_panel_bg, 1, dialog_x + ui(14), dialog_y + ui(52), dialog_w - ui(28), dialog_h - ui(66));
		search_pane.setFocusHover(sFOCUS, sHOVER);
		search_pane.draw(dialog_x + ui(16), dialog_y + ui(52));
	}
	
	var tw = dialog_w - ui(96);
	if(node_called != noone || junction_hovering != noone)
		tw -= ui(32);
	tb_search.draw(dialog_x + ui(14), dialog_y + ui(14), tw, ui(32), search_string, mouse_ui);
	
	var bx = dialog_x + dialog_w - ui(44);
	var by = dialog_y + ui(16);
	var b = buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, 
		PREFERENCES.dialog_add_node_view? __txtx("view_list", "List view") : __txtx("view_grid", "Grid view"), 
		THEME.view_mode, PREFERENCES.dialog_add_node_view, COLORS._main_icon);
	if(b == 2) 
		PREFERENCES.dialog_add_node_view = !PREFERENCES.dialog_add_node_view;
	
	bx -= ui(32);
	var b = buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, 
		PREFERENCES.dialog_add_node_grouping? __txtx("add_node_group_enabled", "Group enabled") : __txtx("add_node_group_disabled", "Group disabled"), 
		THEME.view_group, PREFERENCES.dialog_add_node_grouping, COLORS._main_icon);
	if(b == 2)
		PREFERENCES.dialog_add_node_grouping = !PREFERENCES.dialog_add_node_grouping;
	
	if(node_called != noone || junction_hovering != noone) {
		var txt = node_show_connectable? __txtx("add_node_show_connect", "Showing connectable") : __txtx("add_node_show_all", "Showing all");
		var cc  = node_show_connectable? COLORS._main_accent : COLORS._main_icon;
		bx -= ui(32);
		var b = buttonInstant(THEME.button_hide, bx, by, ui(28), ui(28), mouse_ui, sFOCUS, sHOVER, txt, THEME.filter_type, node_show_connectable, cc);
		if(b == 2)
			node_show_connectable = !node_show_connectable;
	}
#endregion

#region tooltip
	if(node_tooltip != noone) {
		var ww = ui(300 + 8);
		var hh = ui(16);
		
		var txt = node_tooltip.getTooltip();
		var spr = node_tooltip.tooltip_spr;
		
		draw_set_font(f_p1);
		
		if(spr) {
			ww = ui(8) + sprite_get_width(spr);
			hh = ui(8) + sprite_get_height(spr);
		} else 
			hh = ui(16) + string_height_ext(txt, -1, ww - ui(16));
		
		var x0 = min(node_tooltip_x, WIN_W - ww - ui(8));
		var x1 = node_tooltip_x + ww;
		var y1 = node_tooltip_y - ui(8);
		var y0 = y1 - hh;
		
		draw_sprite_stretched(THEME.textbox, 3, x0, y0, ww, hh);
		draw_sprite_stretched(THEME.textbox, 0, x0, y0, ww, hh);
		
		if(spr) draw_sprite(spr, 0, x0 + ui(4), y0 + ui(4));
		
		draw_set_text(f_p1, fa_left, fa_bottom, COLORS._main_text)
		draw_text_line(x0 + ui(8), y1 - ui(8), txt, -1, ww - ui(16));
	}
	
	node_tooltip = noone;
#endregion

//#region dec
//	if(node_called) {
//		var jx = 0;
//		var jy = dialog_y + ui(26);
		
//		if(node_called.connect_type == JUNCTION_CONNECT.input) 
//			jx = dialog_x;
//		else 
//			jx = dialog_x + dialog_w;
//	}
//#endregion