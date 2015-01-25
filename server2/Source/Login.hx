package ;

import openfl.display.*;
import openfl.events.*;
import haxe.Http;
import openfl.text.*;
import openfl.utils.*;

class Login extends Sprite {

	public static var USERNAME = "";
	public static var PASSWORD = "";

	var username:TextField;
	var password:TextField;
	var login:TextField;
	var register:TextField;

	var format = new TextFormat();

	public function new () {
		super (); /* Обязательно */
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	/* Событие помещения на экран */
	private function added (event) {
		removeEventListener(Event.ADDED_TO_STAGE, added);

		var req = new haxe.Http("http://localhost/pong/install.php");
		req.request(false);

		/* Шрифт */
		format.font = "Arial";
		format.size = 25;

		username = createInput("имя");
		password = createInput("пароль", true);
		login = createButton("вход");
		register = createButton("регистрация");

		login.addEventListener(MouseEvent.CLICK, dologin);
		register.addEventListener(MouseEvent.CLICK, doregister);
	}

	var createY:Int = 100;

	function createInput(text, pass = false) {
		var textField:TextField;
		textField = new TextField();
		textField.textColor = 0x00000000;
		textField.selectable = true;
		textField.border = textField.embedFonts = textField.wordWrap = false;
		textField.width = 300;
		textField.height = 30;
		textField.text = text;
		textField.displayAsPassword = pass;
		textField.y = createY;
		textField.x = 200;
		createY = createY + 50;
		textField.type = openfl.text.TextFieldType.INPUT;
		textField.defaultTextFormat = format;
		addChild(textField);
		return textField;
	}

	function createButton(text) {
		var textField:TextField;
		textField = new TextField();
		textField.textColor = 0x00000000;
		textField.selectable = textField.border = textField.embedFonts = textField.wordWrap = false;
		textField.width = 300;
		textField.border = true;
		textField.height = 30;
		textField.text = text;
		textField.y = createY;
		createY = createY + 50;
		textField.x = 200;
		textField.defaultTextFormat = format;
		addChild(textField);
		return textField;
	}

	function dologin(event) {
		var req = new haxe.Http("http://localhost/pong/login.php");

		req.setParameter("USERNAME", username.text);
		req.setParameter("PASSWORD", password.text);

		req.onData = function (data:String) if(data == "true") success();
		req.onError = function (error:String) trace(error);
		req.request(false);
	}

	function doregister(event) {
		var req = new haxe.Http("http://localhost/pong/register.php");

		req.setParameter("USERNAME", username.text);
		req.setParameter("PASSWORD", password.text);

		req.onData = function (data:String) if(data == "true") success();
		req.onError = function (error:String) trace(error);
		req.request(false);
	}

	function success() {
		USERNAME = username.text;
		PASSWORD = password.text;

		parent.addChild(new Main());
		parent.removeChild(this);
	}
}