<?php
	header ('Content-type: text/html; charset=utf-8');
	// Создадим базу данных
	$db = new SQLite3("database.db");
	if (!$db) {
		die;
	}

	// добавим поле для очков по ID (если его нет)

	$db->query("
		REPLACE INTO `SCORES` (ID)
		SELECT ID
		FROM `USERS`
		WHERE USERNAME = '".$_GET["USERNAME"]."' AND PASSWORD = '".$_GET["PASSWORD"]."'
	");

	// сохраним результат

	$db->query("
			UPDATE `SCORES`
			SET BESTSCORE = '".$_GET["BESTSCORE"]."'
			WHERE ID IN (
				SELECT ID
				FROM `USERS`
				WHERE USERNAME = '".$_GET["USERNAME"]."' AND PASSWORD = '".$_GET["PASSWORD"]."'
			)
	");
?>