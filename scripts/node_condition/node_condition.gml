function Node_Condition(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Condition";
	previewable = false;
	
	w = 96;
	
	inputs[| 0] = nodeValue("Check value", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 )
		.setVisible(true, true);
		
	inputs[| 1] = nodeValue("Condition", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, ["Equal", "Not equal", "Less", "Less or equal", "Greater", "Greater or equal"])
		.rejectArray();
		
	inputs[| 2] = nodeValue("Compare to", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0 )
		.rejectArray();
	
	inputs[| 3] = nodeValue("True", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, -1 )
		.setVisible(true, true);
		
	inputs[| 4] = nodeValue("False", self, JUNCTION_CONNECT.input, VALUE_TYPE.any, -1 )
		.setVisible(true, true);
	
	inputs[| 5] = nodeValue("Eval mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0 )
		.setDisplay(VALUE_DISPLAY.enum_scroll, ["Boolean", "Number compare", "Text compare" ])
		.rejectArray();
	
	inputs[| 6] = nodeValue("Boolean", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false )
		.setVisible(true, true)
		.rejectArray();
	
	inputs[| 7] = nodeValue("Text 1", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "" );
	
	inputs[| 8] = nodeValue("Text 2", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "" );
		
	input_display_list = [ 5,
		["Condition", false], 0, 1, 2, 6, 7, 8, 
		["Result",	  true], 3, 4
	]
	
	outputs[| 0] = nodeValue("Result", self, JUNCTION_CONNECT.output, VALUE_TYPE.any, []);
	outputs[| 1] = nodeValue("Bool", self, JUNCTION_CONNECT.output, VALUE_TYPE.boolean, false);
	
	static step = function() { #region
		var _mode = getInputData(5);
		
		inputs[| 0].setVisible(_mode == 1, _mode == 1);
		inputs[| 1].setVisible(_mode == 1);
		inputs[| 2].setVisible(_mode == 1, _mode == 1);
		inputs[| 6].setVisible(_mode == 0, _mode == 0);
		inputs[| 7].setVisible(_mode == 2, _mode == 2);
		inputs[| 8].setVisible(_mode == 2, _mode == 2);
		
		inputs[| 3].setType(inputs[| 3].isLeaf()? VALUE_TYPE.any : inputs[| 3].value_from.type);
		inputs[| 4].setType(inputs[| 4].isLeaf()? VALUE_TYPE.any : inputs[| 4].value_from.type);
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		var _true = getInputData(3);
		var _fals = getInputData(4);
		
		var _mode = getInputData(5);
		
		var _chck = getInputData(0);
		var _cond = getInputData(1);
		var _valu = getInputData(2);
		var _bool = getInputData(6);
		var _txt1 = getInputData(7);
		var _txt2 = getInputData(8);
		
		var res = false;
		
		switch(_mode) {
			case 0 : res = _bool; break;
			case 1 :
				switch(_cond) {
					case 0 : res = _chck == _valu; break;
					case 1 : res = _chck != _valu; break;
					case 2 : res = _chck <  _valu; break;
					case 3 : res = _chck <= _valu; break;
					case 4 : res = _chck >  _valu; break;
					case 5 : res = _chck >= _valu; break;
				}
				break;
			case 2 : res = _txt1 == _txt2; break;
		}
		
		if(res) {
			outputs[| 0].setValue(_true);
			outputs[| 0].setType(inputs[| 3].type);
			outputs[| 0].display_type = inputs[| 3].display_type;
		} else {
			outputs[| 0].setValue(_fals);
			outputs[| 0].setType(inputs[| 4].type);	
			outputs[| 0].display_type = inputs[| 4].display_type;
		}
		
		outputs[| 1].setValue(res);
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		var val = outputs[| 1].getValue();
		var frm = val? inputs[| 3] : inputs[| 4];
		var to  = outputs[| 0];
		var c0 = value_color(frm.type);
		
		draw_set_color(c0);
		draw_set_alpha(0.5);
		draw_line_width(frm.x, frm.y, to.x, to.y, _s * 4);
		draw_set_alpha(1);
	} #endregion
}