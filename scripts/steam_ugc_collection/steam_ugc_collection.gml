function steam_ugc_create_collection(file) { #region
	if(STEAM_UGC_ITEM_UPLOADING) return;
	
	STEAM_UGC_UPDATE = false;
	STEAM_UGC_ITEM_UPLOADING = true;
	STEAM_UGC_ITEM_FILE = file;
	STEAM_UGC_TYPE = STEAM_UGC_FILE_TYPE.collection;
	
	directory_destroy(DIRECTORY + "steamUGC");
	directory_create(DIRECTORY + "steamUGC");
	file_copy(file.path, DIRECTORY + "steamUGC/" + filename_name(file.path));
	file_copy(file.meta_path, DIRECTORY + "steamUGC/" + filename_name(file.meta_path));
	
	if(array_safe_get(file.spr_path, 0, 0) != 0)
		file_copy(file.spr_path[0], DIRECTORY + "steamUGC/" + filename_name(file.spr_path[0]));
	steam_ugc_collection_generate(file);
	
	STEAM_UGC_ITEM_ID = steam_ugc_create_item(STEAM_APP_ID, ugc_filetype_community);
} #endregion

function steam_ugc_update_collection(file, update_preview = false, update_note = "Updated") { #region
	if(STEAM_UGC_ITEM_UPLOADING) return;
	
	STEAM_UGC_UPDATE = true;
	STEAM_UGC_ITEM_UPLOADING = true;
	STEAM_UGC_ITEM_FILE = file;
	STEAM_UGC_TYPE = STEAM_UGC_FILE_TYPE.collection;
	
	directory_destroy(DIRECTORY + "steamUGC");
	directory_create(DIRECTORY + "steamUGC");
	file_copy(file.path, DIRECTORY + "steamUGC/" + filename_name(file.path));
	file_copy(file.meta_path, DIRECTORY + "steamUGC/" + filename_name(file.meta_path));
	if(array_safe_get(file.spr_path, 0, 0) != 0)
		file_copy(file.spr_path[0], DIRECTORY + "steamUGC/" + filename_name(file.spr_path[0]));
	
	STEAM_UGC_PUBLISH_ID = file.meta.file_id;
	STEAM_UGC_UPDATE_HANDLE = steam_ugc_start_item_update(STEAM_APP_ID, STEAM_UGC_PUBLISH_ID);
	
	steam_ugc_set_item_title(STEAM_UGC_UPDATE_HANDLE, STEAM_UGC_ITEM_FILE.meta.name);
	steam_ugc_set_item_description(STEAM_UGC_UPDATE_HANDLE, STEAM_UGC_ITEM_FILE.meta.description);
	
	var tgs = STEAM_UGC_ITEM_FILE.meta.tags;
	
	array_insert(tgs, 0, "Collection");
	array_push(tgs, VERSION_STRING);
	
	steam_ugc_set_item_tags(STEAM_UGC_UPDATE_HANDLE, tgs);
	steam_ugc_set_item_content(STEAM_UGC_UPDATE_HANDLE, DIRECTORY + "steamUGC");
	
	STEAM_UGC_SUBMIT_ID = steam_ugc_submit_item_update(STEAM_UGC_UPDATE_HANDLE, update_note);
} #endregion

function steam_ugc_collection_generate(file, dest_path = TEMPDIR + "steamUGCthumbnail.png") { #region
	file_delete(dest_path);
	var spr       = STEAM_UGC_ITEM_FILE.getSpr();
	var prev_size = 512;
	var _s = surface_create(prev_size, prev_size);
	surface_set_target(_s);
		draw_clear(COLORS._main_icon_dark);
		draw_sprite_tiled(s_workshop_bg, 0, -64, -64);
		draw_sprite_stretched(s_workshop_frame, 0, 0, 0, prev_size, prev_size);
		
		if(spr == -1) spr = THEME.workshop_collection;
		var ss = (prev_size - 160) / max(sprite_get_width(spr), sprite_get_height(spr));
		var ox = (sprite_get_xoffset(spr) - sprite_get_width(spr) / 2) * ss;
		var oy = (sprite_get_yoffset(spr) - sprite_get_height(spr) / 2) * ss;
		draw_sprite_ext(spr, 0, prev_size / 2 + ox, prev_size / 2 + oy, ss, ss, 0, c_white, 1);
		
		draw_sprite_stretched(s_workshop_badge, 0, 8, 8, 88, 88);
		draw_sprite_ext(THEME.workshop_collection, 0, 40, 40, 1, 1, 0, COLORS._main_icon_dark, 1);
		
		draw_set_text(f_h2, fa_right, fa_bottom, COLORS._main_icon_dark);
		var _bw = 48 + string_width(VERSION_STRING);
		var _bh = 88;
		draw_sprite_stretched(s_workshop_badge_version, 0, prev_size - 8 - _bw, prev_size - 8 - _bh, _bw, _bh);
		draw_text(prev_size - 16, prev_size - 12, VERSION_STRING);
	surface_reset_target();
	surface_save_safe(_s, dest_path);
	surface_free(_s);
} #endregion