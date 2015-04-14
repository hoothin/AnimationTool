package com.tool;
import com.tool.vo.ImgStoreData;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.errors.Error;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

/**
 * @time 2015/4/13 19:27:04
 * @author Hoothin
 */
class BitmapProcess {

	static var bitmapProcess:BitmapProcess;
	private var imageList:Array<String>;
	private var resultStore:Array<ImgStoreData>;
	private var rawStore:Map<String, BitmapData>;
	
	private var configStore:Map<String, Int>;
	private var xmlStore:Map<String, String>;
	public function new() {
		
	}

	/*-----------------------------------------------------------------------------------------
	Public methods
	-------------------------------------------------------------------------------------------*/
	public static function getInstance():BitmapProcess {
		if (bitmapProcess == null)
			bitmapProcess = new BitmapProcess();
		return bitmapProcess;
	}
	
	public function startProcess(path:String):Void {
		this.imageList = [];
		this.resultStore = [];
		this.rawStore = new Map();
		this.configStore = new Map();
		this.xmlStore = new Map();
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			this.processDir(path);
		}else {
			Main.log("path is not valid!");
			return;
		}
		for (imgPath in imageList.copy()) {
			trace("read " + imgPath);
			this.rawStore.set(imgPath, BitmapData.loadFromHaxeBytes(File.getBytes(imgPath)));
			imageList.remove(imgPath);
			if (imageList.length <= 0) {
				this.cutAlpha();
			}
		}
	}
	/*-----------------------------------------------------------------------------------------
	Private methods
	-------------------------------------------------------------------------------------------*/
	private function processDir(path:String):Void {
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
			var childList:Array<String> = FileSystem.readDirectory(path);
			for (child in childList) {
				processDir(path + "\\" + child);
			}
		}else {
			var filterType:String = path.substr(path.lastIndexOf(".") + 1);
			if (filterType == "png") {
				trace(path);
				this.imageList.push(path);
			}
		}
	}
	
	private function cutAlpha():Void {
		for (path in rawStore.keys()) {
			var cutBitmapdata:BitmapData = rawStore.get(path);
			var leftOffset:Int = 0;
			var rightOffset:Int = 0;
			var topOffset:Int = 0;
			var bottomOffset:Int = 0;
			for (h in 0...cutBitmapdata.width) {
				for (v in 0...cutBitmapdata.height) {
					if (cutBitmapdata.getPixel32(h, v) > 0) {
						if (leftOffset == 0) {
							leftOffset = h;
						}
						rightOffset = h;
						break;
					}
				}
			}
			for (v in 0...cutBitmapdata.height) {
				for (h in 0...cutBitmapdata.width) {
					if (cutBitmapdata.getPixel32(h, v) > 0) {
						if (topOffset == 0) {
							topOffset = v;
						}
						bottomOffset = v;
						break;
					}
				}
			}
			var bitmapW:Int = rightOffset - leftOffset;
			var bitmapH:Int = bottomOffset - topOffset;
			var finalBitmapData:BitmapData = new BitmapData(bitmapW > 0?bitmapW:1, bitmapH > 0?bitmapH:1);
			finalBitmapData.copyPixels(cutBitmapdata, new Rectangle(leftOffset, topOffset, rightOffset - leftOffset, bottomOffset - topOffset), new Point(0, 0));
			cutBitmapdata.dispose();
			resultStore.push(new ImgStoreData(finalBitmapData, leftOffset, topOffset, path));
		}
		this.exportToFile();
	}
	
	private function exportToFile():Void {
		this.generatePng();
		this.generateXml();
		this.packTexture();
	}
	
	private function generatePng():Void {
		for (imgStoreData in resultStore) {
			var b:ByteArray = imgStoreData.storeBitmapData.encode(
				new Rectangle(0, 0, imgStoreData.storeBitmapData.width, imgStoreData.storeBitmapData.height),
				new PNGEncoderOptions()
			);
			var dataName:String = imgStoreData.getClassName();
			if (dataName == "") {
				dataName = "temp";
			}
			
			if (configStore.exists(dataName)) {
				configStore.set(dataName, configStore.get(dataName) + 1);
			}
			else {
				configStore.set(dataName, 1);
			}
			
			if (xmlStore.exists(dataName)) {
				var xmlString:String = xmlStore.get(dataName);
				xmlString += "\t<bitmapConfig id='" + 
					StringTools.urlDecode(imgStoreData.storename).split(" ").join("+") +
					"' offsetX='" + imgStoreData.offsetPoint.x +
					"' offsetY='" + imgStoreData.offsetPoint.y +
					"'/>\n";
				xmlStore.set(dataName, xmlString);
			}else {
				xmlStore.set(dataName, "<root>\n");
			}
			
			dataName += "/";
			var exportPath = Main.exportPath + "processPath/" + dataName;
			if (!FileSystem.exists(exportPath)) {
				FileSystem.createDirectory(exportPath);
			}
			var fo:FileOutput = sys.io.File.write(exportPath + imgStoreData.storename, true);
			fo.write(b);
			fo.flush();
			fo.close();
		}
		Main.log("bitmap cut complete,start generate xml...");
	}
	
	private function generateXml():Void {
		var configStr:String = "";
		for (configName in configStore.keys()) {
			configStr += "<effectConfig id='" + StringTools.urlDecode(configName).split(" ").join("+") + "' effectType='top' totalFrame='" + configStore.get(configName) + "' frameRate='2'/>\n";
		}
		var exportPath = Main.exportPath + "effectConfig.xml";
		var fo:FileOutput = sys.io.File.append(exportPath, true);
		fo.writeString(configStr);
		fo.flush();
		fo.close();
		
		for (xmlName in xmlStore.keys()) {
			exportPath = Main.exportPath + "effect";
			if (!FileSystem.exists(exportPath)) {
				FileSystem.createDirectory(exportPath);
			}
			exportPath += ("/" + xmlName + ".xml");
			var xmlData:String = xmlStore.get(xmlName) + "</root>";
			fo = sys.io.File.write(exportPath, true);
			fo.writeString(xmlData);
			fo.flush();
			fo.close();
		}
	}
	
	private function packTexture():Void {
		Main.log("xml generate complete,start pack texture...");
		var pngOutPut:String;
		var xmlOutPut:String;
		for (configName in configStore.keys()) {
			var args : Array<String> = [];
			pngOutPut = Main.exportPath + "effect/" + configName;
			xmlOutPut = Main.exportPath + "xml/texture/" + configName;
			args.push('--sheet');
			args.push(pngOutPut + '.png');
			args.push('--data');
			args.push(xmlOutPut + '.xml');
			args.push('--no-trim');
			args.push('--allow-free-size');
			args.push('--max-size');
			args.push('8192');
			args.push('--disable-rotation');
			args.push('--format');
			args.push('xml');
			args.push(Main.exportPath + "processPath/" + configName);
			try{
				Sys.command(Main.texturePackerPath, args);
				Main.log("pack " + pngOutPut + " complete");
			}catch(error:Error){
				Main.log(error.toString());
			}
		}
	}
	/*-----------------------------------------------------------------------------------------
	Event Handlers
	-------------------------------------------------------------------------------------------*/
	
	/*-----------------------------------------------------------------------------------------
	Get/Set
	-------------------------------------------------------------------------------------------*/
	
}