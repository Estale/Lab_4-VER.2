<?php
	header ('Content-type: text/html; charset=utf-8');
	echo "<br>Создание базы данных";
	// Создадим базу данных
	$db = new SQLite3("database.db");
	if (!$db) exit("<br>Не удалось создать базу данных!");
	if ($db) echo "<br>База создана успешно!";

	// пользователь-пароль

	$db->query("
		CREATE TABLE IF NOT EXISTS `USERS` (
			`ID` integer PRIMARY KEY AUTOINCREMENT,
			`USERNAME` varchar(255) NOT NULL default '',
			`PASSWORD` varchar(255) NOT NULL default ''
		)
	");

	// пользователь-счет

	$db->query("
		CREATE TABLE IF NOT EXISTS `SCORES` (
			`ID` integer PRIMARY KEY,
			`BESTSCORE` integer default 0
		)
	");

	echo "<br>Таблицы созданы";
?>