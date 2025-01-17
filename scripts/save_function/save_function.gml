globalvar SAVING;
SAVING = false;

function NEW() { #region
	PROJECT = new Project();
	array_push(PROJECTS, PROJECT);
	
	var graph = new Panel_Graph(PROJECT);
	PANEL_GRAPH.panel.setContent(graph, true);
	PANEL_GRAPH = graph;
} #endregion

function save_serialize(project = PROJECT, _outMap = false) { #region
	var _map  = {};
	_map.version = SAVE_VERSION;
	
	var _node_list = [];
	var _key = ds_map_find_first(project.nodeMap);
	
	repeat(ds_map_size(project.nodeMap)) {
		var _node = project.nodeMap[? _key];
		
		if(_node.active)
			array_push(_node_list, _node.serialize());
		
		_key = ds_map_find_next(project.nodeMap, _key);	
	}
	_map.nodes = _node_list;
	
	var _anim_map = {};
	_anim_map.frames_total = project.animator.frames_total;
	_anim_map.framerate    = project.animator.framerate;
	_map.animator		   = _anim_map;
	
	_map.metadata    = METADATA.serialize();
	_map.global_node = project.globalNode.serialize();
	_map.onion_skin  = project.onion_skin;
	
	_map.previewGrid = project.previewGrid;
	_map.graphGrid   = project.graphGrid;
	_map.attributes  = project.attributes;
	
	_map.timelines   = project.timelines.serialize();
	_map.notes       = array_map(project.notes, function(note) { return node.serialize(); } );
	
	var prev = PANEL_PREVIEW.getNodePreviewSurface();
	if(!is_surface(prev)) _map.preview = "";
	else				  _map.preview = surface_encode(surface_size_lim(prev, 128, 128));
	
	var _addon = {};
	with(_addon_custom) {
		var _ser = lua_call(thread, "serialize");
		_addon[$ name] = PREFERENCES.save_file_minify? json_stringify_minify(_ser) : json_stringify(_ser);
	}
	_map.addon = _addon;
	
	if(_outMap) return _map;
	
	return PREFERENCES.save_file_minify? json_stringify_minify(_map) : json_stringify(_map, true);
} #endregion

function SET_PATH(project, path) { #region
	if(path == "") {
		project.readonly = false;
	} else if(!project.readonly) {
		ds_list_remove(RECENT_FILES, path);
		ds_list_insert(RECENT_FILES, 0, path);
		while(ds_list_size(RECENT_FILES) > 64)
			ds_list_delete(RECENT_FILES, ds_list_size(RECENT_FILES) - 1);
		RECENT_SAVE();
		RECENT_REFRESH();
		//project.path = filename_name(path);
	}
	
	project.path = path;
} #endregion

function SAVE_ALL() { #region
	for( var i = 0, n = array_length(PROJECTS); i < n; i++ )
		SAVE(PROJECTS[i]);
} #endregion

function SAVE(project = PROJECT) { #region
	if(DEMO) return false;
	
	if(project.path == "" || project.readonly)
		return SAVE_AS(project);
	return SAVE_AT(project, project.path);
} #endregion

function SAVE_AS(project = PROJECT) { #region
	if(DEMO) return false;
	
	var path = get_save_filename("Pixel Composer project (.pxc)|*.pxc", ""); 
	key_release();
	if(path == "") return false;
	
	if(filename_ext(path) != ".pxc")
		path += ".pxc";
	
	if(file_exists(path))
		log_warning("SAVE", "Overrided file : " + path);
	SAVE_AT(project, path);
	SET_PATH(project, path);
	
	return true;
} #endregion

function SAVE_AT(project = PROJECT, path = "", log = "save at ") { #region
	if(DEMO) return false;
	
	SAVING = true;
	
	if(file_exists(path))
		file_delete(path);
	var file = file_text_open_write(path);
	file_text_write_string(file, save_serialize(project));
	file_text_close(file);
	
	SAVING    = false;
	project.readonly  = false;
	project.modified  = false;
	
	log_message("FILE", log + path, THEME.noti_icon_file_save);
	PANEL_MENU.setNotiIcon(THEME.noti_icon_file_save);
	
	return true;
} #endregion

/////////////////////////////////////////////////////// COLLECTION ///////////////////////////////////////////////////////

function SAVE_COLLECTIONS(_list, _path, save_surface = true, metadata = noone, context = PANEL_GRAPH.getCurrentContext()) { #region
	var _content = {};
	_content.version = SAVE_VERSION;
	
	var _nodes = [];
	var cx = 0;
	var cy = 0;
	for(var i = 0; i < ds_list_size(_list); i++) {
		cx += _list[| i].x;
		cy += _list[| i].y;
	}
	cx = round((cx / ds_list_size(_list)) / 32) * 32;
	cy = round((cy / ds_list_size(_list)) / 32) * 32;
	
	if(save_surface) {
		var preview_surface = PANEL_PREVIEW.getNodePreviewSurface();
		if(is_surface(preview_surface)) {
			var icon_path = string_copy(_path, 1, string_length(_path) - 5) + ".png";
			surface_save_safe(preview_surface, icon_path);
		}
	}
	
	for(var i = 0; i < ds_list_size(_list); i++)
		SAVE_NODE(_nodes, _list[| i], cx, cy, true, context);
	_content.nodes = _nodes;
	
	json_save_struct(_path, _content, !PREFERENCES.save_file_minify);
	
	if(metadata != noone) {
		var _meta  = metadata.serialize();
		var _dir   = filename_dir(_path);
		var _name  = filename_name_only(_path);
		var _mpath = $"{_dir}/{_name}.meta";
		
		json_save_struct(_mpath, _meta, true);
	}
	
	var pane = findPanel("Panel_Collection");
	if(pane) pane.refreshContext();
	
	log_message("COLLECTION", "save collection at " + _path, THEME.noti_icon_file_save);
	PANEL_MENU.setNotiIcon(THEME.noti_icon_file_save);
} #endregion

function SAVE_COLLECTION(_node, _path, save_surface = true, metadata = noone, context = PANEL_GRAPH.getCurrentContext()) { #region
	if(save_surface) {
		var preview_surface = PANEL_PREVIEW.getNodePreviewSurface();
		if(is_surface(preview_surface)) {
			var icon_path = string_replace(_path, filename_ext(_path), "") + ".png";
			surface_save_safe(preview_surface, icon_path);
		}
	}
	
	var _content = {};
	_content.version = SAVE_VERSION;
	
	var _nodes = [];
	SAVE_NODE(_nodes, _node, _node.x, _node.y, true, context);
	_content.nodes = _nodes;
	
	json_save_struct(_path, _content, !PREFERENCES.save_file_minify);
	
	if(metadata != noone) {
		var _meta  = metadata.serialize();
		var _dir   = filename_dir(_path);
		var _name  = filename_name_only(_path);
		var _mpath = $"{_dir}/{_name}.meta";
		
		_meta.version = SAVE_VERSION;
		json_save_struct(_mpath, _meta, true);
	}
	
	var pane = findPanel("Panel_Collection");
	if(pane) pane.refreshContext();
	
	log_message("COLLECTION", "save collection at " + _path, THEME.noti_icon_file_save);
	PANEL_MENU.setNotiIcon(THEME.noti_icon_file_save);
} #endregion

function SAVE_NODE(_arr, _node, dx = 0, dy = 0, scale = false, context = PANEL_GRAPH.getCurrentContext()) { #region
	if(struct_has(_node, "nodes")) {
		for(var i = 0; i < ds_list_size(_node.nodes); i++)
			SAVE_NODE(_arr, _node.nodes[| i], dx, dy, scale, context);
	}
	
	var m = _node.serialize(scale);
	m.x -= dx;
	m.y -= dy;
	
	var c = context == noone? noone : context.node_id;
	if(m.group == c) m.group = noone;
	
	array_push(_arr, m);
} #endregion