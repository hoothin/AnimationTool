package com.tool.vo;
import openfl.display.BitmapData;
import openfl.geom.Point;

/**
 * @time 2015/4/13 20:11:28
 * @author Hoothin
 */
class ImgStoreData {
	
	public var storeBitmapData(get_storeBitmapData, null):BitmapData;
	public var storename(get_storename, null):String;
	public var offsetPoint(get_offsetPoint, null):Point;
	public var imgUrl(get_imgUrl, null):String;
	
	private var _storeBitmapData:BitmapData;
	private var _offsetPoint:Point;
	private var _imgUrl:String;
	
	public function new(storeBitmapData:BitmapData, offsetX:Float, offsetY:Float, imgUrl:String) {
		this._storeBitmapData = storeBitmapData;
		this._offsetPoint = new Point(offsetX, offsetY);
		this._imgUrl = imgUrl;
	}
	
	public function getClassName():String {
		var value = this._imgUrl.substr(this._imgUrl.lastIndexOf("\\") + 1);
		var valueSplit = value.split("_");
		if (valueSplit.length > 1) {
			return valueSplit[0];
		}
		var resultStr:String = "";
		for (i in 0...value.length) {
			var chatCode:Int = value.charCodeAt(i);
			if (chatCode >= 48 && chatCode <= 57) {
				break;
			}
			resultStr += value.charAt(i);
		}
		return resultStr;
	}
	
	function get_storeBitmapData():BitmapData {
		return _storeBitmapData;
	}
	
	function get_storename():String {
		var splitIndex:Int = this._imgUrl.lastIndexOf("\\");
		return this._imgUrl.substr(splitIndex + 1);
	}
	
	function get_imgUrl():String {
		return _imgUrl;
	}
	
	function get_offsetPoint():Point {
		return _offsetPoint;
	}
}