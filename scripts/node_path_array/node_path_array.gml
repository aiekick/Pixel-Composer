function Node_Path_Array(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Path Array";
	previewable = false;
	
	w = 96;
	
	setIsDynamicInput(1);
	
	outputs[| 0] = nodeValue("Path array", self, JUNCTION_CONNECT.output, VALUE_TYPE.pathnode, self);
	
	static createNewInput = function() { #region
		var index = ds_list_size(inputs);
		
		inputs[| index] = nodeValue("Path", self, JUNCTION_CONNECT.input, VALUE_TYPE.pathnode, noone )
			.setVisible(true, true);
		
		return inputs[| index];
	} if(!LOADING && !APPENDING) createNewInput(); #endregion
	
	static refreshDynamicInput = function() { #region
		var _l = ds_list_create();
		
		for( var i = 0; i < input_fix_len; i++ ) 
			_l[| i] = inputs[| i];
		
		for( var i = input_fix_len; i < ds_list_size(inputs); i += data_length ) {
			if(inputs[| i].value_from)
				ds_list_add(_l, inputs[| i]);
			else
				delete inputs[| i];	
		}
		
		for( var i = 0; i < ds_list_size(_l); i++ )
			_l[| i].index = i;	
		
		ds_list_destroy(inputs);
		inputs = _l;
		
		createNewInput();
	} #endregion
	
	static onValueFromUpdate = function(index) { #region
		if(LOADING || APPENDING) return;
		
		refreshDynamicInput();
	} #endregion
	
	static getLineCount = function() { #region
		var l = 0;
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			l += struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
		}
		return l; 
	} #endregion
	
	static getSegmentCount = function(ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc    = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.getSegmentCount(ind);
			ind -= lc;
		}
		
		return 0;
	} #endregion
	
	static getLength = function(ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc    = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.getLength(ind);
			ind -= lc;
		}
		
		return 0;
	} #endregion
	
	static getAccuLength = function(ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc    = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.getAccuLength(ind);
			ind -= lc;
		}
		
		return 0;
	} #endregion
	
	static get__vec2Ratio = function(_rat, ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.get__vec2Ratio(_rat, ind).clone();
			ind -= lc;
		}
		
		return new __vec2();
	} #endregion
	
	static get__vec2Distance = function(_dist, ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.get__vec2Distance(_dist, ind).clone();
			ind -= lc;
		}
		
		return new __vec2();
	} #endregion
	
	static getBoundary = function(ind = 0) { #region
		for( var i = input_fix_len; i < ds_list_size(inputs) - 1; i += data_length ) {
			var _path = getInputData(i);
			var lc    = struct_has(_path, "getLineCount")? _path.getLineCount() : 1; 
			
			if(ind < lc) return _path.getBoundary(ind);
			ind -= lc;
		}
		
		return 0;
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		outputs[| 0].setValue(self);
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		
	} #endregion
}