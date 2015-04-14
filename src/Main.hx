package;

import com.tool.BitmapProcess;
import motion.Actuate;
import openfl.Assets;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import sys.FileSystem;
import systools.Clipboard;
import systools.Dialogs;

/**
 * @time 2015/4/13 19:20:51
 * @author Hoothin
 */

class Main extends Sprite {

	public static var texturePackerPath:String;
	public static var exportPath:String;
	private static var output:TextField;
	public function new() {
		super();
		var pathStr:String = Assets.getText("assets/PathConfig.txt");
		if (pathStr == null) {
			trace("PathConfig.txt is not valid!");
			return;
		}
		var pathArr:Array<String> = pathStr.split("\n");
		for (path in pathArr) {
			var singlePath:Array<String> = path.split(">");
			if (singlePath.length != 2) {
				trace("Path content is error!");
				return;
			}
			switch(singlePath[0]) {
				case "tpbin":
					texturePackerPath = singlePath[1];
				case "output":
					exportPath = singlePath[1];
					if (!FileSystem.exists(exportPath)) {
						FileSystem.createDirectory(exportPath);
					}
			}
		}
		this.initUI();
	}
	
	static public function log(value:String):Void {
		output.appendText(value+"\n");
	}
	
	private function initUI():Void {
		var inputText:TextField = new TextField();
		inputText.background = true;
		inputText.backgroundColor = 0x989898;
		inputText.defaultTextFormat = new TextFormat("assets/font.ttf", 20, 0xffffff, false, false, false);
		inputText.type = TextFieldType.INPUT;
		inputText.multiline = false;
		inputText.width = 540;
		inputText.height = 30;
		inputText.x = 50;
		inputText.y = 5;
		inputText.text = "paste the directory url for analyze here...";
		var clickHandler:MouseEvent->Void = null;
		clickHandler = function(e) { 
			inputText.text = Clipboard.getText();
			inputText.removeEventListener(MouseEvent.CLICK, clickHandler); 			
		};
		inputText.addEventListener(MouseEvent.CLICK, clickHandler);
		this.addChild(inputText);
		
		var browserBtn:Sprite = this.generateBtn("Browser");
		browserBtn.x = 600;
		browserBtn.y = 5;
		this.addChild(browserBtn);
		
		var runBtn:Sprite = this.generateBtn("Run");
		runBtn.x = 700;
		runBtn.y = 5;
		this.addChild(runBtn);
		
		browserBtn.addEventListener(MouseEvent.CLICK, function(e){
			var result = Dialogs.folder
			( "Select a folder contains animation images"
			, ""			
			);
			if (result != null) {
				inputText.text = result;
				startProcess(result);
			}
		});
		
		runBtn.addEventListener(MouseEvent.CLICK, function(e){
			startProcess(inputText.text);
		});
		
		output = new TextField();
		output.background = true;
		output.backgroundColor = 0x989898;
		output.defaultTextFormat = new TextFormat("assets/font.ttf", 20, 0xffffff, false, false, false);
		output.width = 700;
		output.height = 500;
		output.x = 50;
		output.y = 50;
		this.addChild(output);
	}
	
	private function startProcess(path:String):Void {
		log("Your app storage dir: " + path + ", start load image...");
		Actuate.timer(0.1).onComplete(function() { BitmapProcess.getInstance().startProcess(path); });
	}
	
	private function generateBtn(text:String):Sprite {
		var content:TextField = new TextField();
		content.defaultTextFormat = new TextFormat("assets/font.ttf", 20, 0x000000, false, false, false);
		content.autoSize = TextFieldAutoSize.LEFT;
		content.text = text;
		content.x = 10;
		var resultBtn:Sprite = new Sprite();
		var btnBg:Shape = new Shape();
		btnBg.graphics.beginFill(0xffffff);
		btnBg.graphics.drawRoundRect(0, 0, content.width + 20, 30, 10, 10);
		btnBg.graphics.endFill();
		resultBtn.addChild(btnBg);
		resultBtn.addChild(content);
		resultBtn.mouseChildren = false;
		resultBtn.addEventListener(MouseEvent.ROLL_OVER, function(e) {
			btnBg.graphics.beginFill(0x6D6A6A);
			btnBg.graphics.drawRoundRect(0, 0, content.width + 20, 30, 10, 10);
			btnBg.graphics.endFill();
		});
		resultBtn.addEventListener(MouseEvent.ROLL_OUT, function(e) {
			btnBg.graphics.beginFill(0xffffff);
			btnBg.graphics.drawRoundRect(0, 0, content.width + 20, 30, 10, 10);
			btnBg.graphics.endFill();
		});
		return resultBtn;
	}
}
