package ;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.text.*;
import openfl.events.Event;
import openfl.Assets;

import openfl.display.OpenGLView;
import openfl.geom.Rectangle;
import openfl.geom.Matrix3D;
import openfl.gl.GL;
import haxe.Http;

import visual.*;
import logic.*;

class Main extends Sprite {

	/* Окно вывода GL */
	private var view:OpenGLView;

	/* Размеры экрана */
	public static var SCREEN_W = 640;
	public static var SCREEN_H = 480;
	public static var SCREEN_DEPTH = 20.0;

	/* Тексты очков */
	var playerScoreTxt:ScoreText;
	var playerLivesTxt:ScoreText;

	/* Визуальные объекты */
	var ball = new Ball();
	var playerPaddle = new Paddle();
	var enemyPaddle = new Paddle();

	/* Количество очков */
	public static var playerScore = 0;
	public static var playerLives = 5;
	public static var bestScore = 0;

	/* Объекты логики */
	var ballLogic:logic.BallLogic;
	var playerLogic:logic.PaddleControl;
	var enemyLogic:logic.PaddleAI;

	public function new () {
		super (); /* Обязательно */
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	/* Событие помещения на экран */
	private function added (event) {
		removeEventListener(Event.ADDED_TO_STAGE, added);

		/* Установим высокй фреймрейт */
		stage.frameRate = 60;

		/* Инициализация GL */
		if (OpenGLView.isSupported) {
			view = new OpenGLView ();
			visual.Walls.init();
			visual.Plane.init();
			view.render = renderView;
			addChild(view);
		}

		/* Разместим доски игроков */
		playerPaddle.x = 15;
		enemyPaddle.x = SCREEN_W - 15;

		playerPaddle.y = enemyPaddle.y = SCREEN_H / 2;

		/* Поместим шар в кадр */
		ball.x = SCREEN_W / 2;
		ball.y = SCREEN_H / 2;

		/* Создадим объекы логики */
		ballLogic = new BallLogic(enemyPaddle, ball, playerPaddle);
		playerLogic = new PaddleControl(playerPaddle, stage);
		enemyLogic = new PaddleAI(enemyPaddle, ball);

		/* Создадим тексты */
		playerScoreTxt = new ScoreText(ScoreText.ALIGN_LEFT);
		playerLivesTxt = new ScoreText(ScoreText.ALIGN_RIGHT);

		playerScoreTxt.x = 0;
		playerScoreTxt.y = 0;

		playerLivesTxt.x = SCREEN_W - playerLivesTxt.width;
		playerLivesTxt.y = 0;

		playerLivesTxt.text = "";
		playerScoreTxt.text = "";

		// загрузим лучший результат с сервера

		var req = new haxe.Http("http://localhost/pong/scoreload.php");
		req.setParameter("USERNAME", Login.USERNAME);
		req.onData = function (data:String)
			if(data == "false")
				bestScore = 0;
			else
				bestScore = Std.parseInt(""+ haxe.Json.parse(data).BESTSCORE);
		req.onError = function (error:String) bestScore = 0;
		req.request(false);

		/* Запустим обновление */
		addEventListener(Event.ENTER_FRAME, frame);
	}

	/* Действие на каждый кадр */
	private function frame (event) {
		if(playerLives < 1) {
			bestScore = Std.int(Math.max(bestScore, playerScore));

			// загрузим лучший результат на сервер
			var req = new haxe.Http("http://localhost/pong/scoresave.php");
			req.setParameter("USERNAME", Login.USERNAME);
			req.setParameter("PASSWORD", Login.PASSWORD);
			req.setParameter("BESTSCORE", "" + bestScore);
			req.onError = function (error:String) trace(error);
			req.request(false);

			playerLives = 5;
			playerScore = 0;

			leaderboard();
		}

		playerLogic.move();
		enemyLogic.move();
		ballLogic.move();
		updateTextFields();
	}

	/* Таблица рекордов */
	function leaderboard() {
		var req = new haxe.Http("http://localhost/pong/results.php");
		req.onError = function (error:String) trace(error);
		req.onData = function (data:String) {
			var scores:Array<Dynamic> = haxe.Json.parse(data);
			var text = "";

			for(i in 0...scores.length) {
				text += " №" + (i + 1) +
				" [ " + scores[i].USERNAME + " " +
				scores[i].BESTSCORE + " ]\n";
			};

			var format = new TextFormat();
			format.font = "Arial";
			format.size = 15;

			var textField = new TextField();
			textField.textColor = 0xFFFFFFFF;
			textField.selectable = textField.border = textField.embedFonts = textField.wordWrap = false;
			textField.multiline = true;
			textField.width = 150;
			textField.height = 400;
			textField.x = 20;
			textField.y = 60;
			textField.cacheAsBitmap = true;
			textField.text = text;
			textField.defaultTextFormat = format;
			stage.addChild(textField);

			stage.addEventListener(flash.events.MouseEvent.CLICK, function(event)
			stage.removeChild(textField));
		}
		req.request(false);
	}

	/* Обновление текста очков */
	function updateTextFields ()
	{
		playerScoreTxt.text = " Player Score: " + playerScore
							+ " Best Score: " + bestScore;
		playerLivesTxt.text = " Player Lives: " + playerLives + " ";
	}

	/* Функция создания матрицы перспективного преобразования */
	public static function perspectiveFieldOfViewLH(fieldOfViewY:Float, // угол обзора
													aspectRatio:Float, // формат экрана
													zNear:Float, // ближняя граница
													zFar:Float) { // дальняя граница
		var yScale = 1.0/Math.tan(fieldOfViewY/2.0);
		var xScale = yScale / aspectRatio;
		var m = new Matrix3D();
		m.copyRawDataFrom(([
						  xScale, 0.0, 0.0, 0.0,
						  0.0, yScale, 0.0, 0.0,
						  0.0, 0.0, zFar/(zFar-zNear), 1.0,
						  0.0, 0.0, (zNear*zFar)/(zNear-zFar), 0.0
						  ]));
		return m;
	}

	/* Матрица, созданная для текущего варианта игры */
	public static function perspectiveMatrix() {
		return perspectiveFieldOfViewLH(75, SCREEN_W/SCREEN_H, 0.1, SCREEN_DEPTH);
	}

	/* Рендеринг GL */
	private function renderView (rect:Rectangle):Void {
		// зона вывода
		GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height));
		GL.enable(GL.DEPTH_TEST); // буфер глубины
		GL.depthFunc(GL.LESS); // отсечение дальних плоскостей, перекрытых ближними
		GL.clearColor (0.0, 0.5, 0.0, 1.0); // очистка экрана (зеленый цвет)
		GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT); // очистка буфера цвета
		// и глубины

		GL.enable(GL.DEPTH_TEST); // активируем тест глубины
		Walls.draw(ball);
		enemyPaddle.draw();
		ball.draw();
		playerPaddle.draw();

		GL.disable(GL.DEPTH_TEST); // деактивируем тест глубины
		// это позволит отобразить тексты поверх всей геометрии
		playerScoreTxt.draw();
		playerLivesTxt.draw();
	}
}