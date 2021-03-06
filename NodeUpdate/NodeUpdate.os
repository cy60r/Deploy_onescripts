#Использовать ReadParams
#Использовать monitoring
#Использовать Ext_v8rac
#Использовать Ext_v8runner

// Подключение к кластеру
Перем УправлениеКластером;
// Подключение к конфигуратору
Перем Конфигуратор;
// Параметры из конфигурационного файла json
Перем Параметры;
// Мониторинг Zabbix
Перем Мониторинг;
// Параметры для авторизации на кластере
Перем ПараметрыАвторизацииИБ;

Процедура ПрочитатьПараметрыИзФайла()
	
	УстановитьТекущийКаталог("C:\scripts\NodeUpdate");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "NodeUpdate.json"));
	
КонецПроцедуры

Процедура ИнициализироватьМониторинг()
	
	Мониторинг = Новый УправлениеМониторингом();
	Мониторинг.УстановитьПараметрыМониторинга(Параметры["АдресZabbix"], Параметры["ZabbixSender"]);
	Мониторинг.УстановитьПараметрыЭлементаДанных(Параметры["УзелZabbix"], Параметры["КлючZabbix"]);
	Мониторинг.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Мониторинг.Информация("Начало обновления узла " + Параметры["ИмяБазы"]);
	Мониторинг.УвеличитьУровень();
	
КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()
	
	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"],
		Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Мониторинг.Отладка("Информационная база подключена");
	
КонецПроцедуры

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"], Параметры["ПортКластера"]);
	УправлениеКластером.ИспользоватьВерсию(Параметры["ВерсияПлатформы"]);
	УправлениеКластером.УстановитьАвторизациюКластера(Параметры["ПользовательКластера"], Параметры["ПарольКластера"]);
	УправлениеКластером.Подключить();
	УправлениеКластером.УстановитьАвторизациюИнформационнойБазы(Параметры["ИмяБазы"],
		Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	ПараметрыАвторизацииИБ = ПараметрыАвторизацииИБ();
	Мониторинг.Отладка("Управление кластером подключено");
	
КонецПроцедуры

Процедура УстановитьБлокировкуИБ()
	
	СообщениеОБлокировке = СообщениеОБлокировкеПоШаблону();
	УправлениеКластером.БлокировкаИнформационнойБазы(Параметры["ИмяБазы"], СообщениеОБлокировке,
		Параметры["КлючРазрешенияЗапуска"], , , Ложь, ПараметрыАвторизацииИБ);
	Мониторинг.Отладка("Блокировка ИБ установлена");
	
КонецПроцедуры

Функция СообщениеОБлокировкеПоШаблону()
	
	ТекстовыйФайл = Новый ЧтениеТекста(ОбъединитьПути(ТекущийКаталог(), "BlockMessage.txt"));
	СообщениеОБлокировке = ТекстовыйФайл.Прочитать();
	ТекстовыйФайл.Закрыть();
	
	Возврат СообщениеОБлокировке;
	
КонецФункции

Функция ПараметрыАвторизацииИБ()
	
	ПараметрыАвторизации = Новый Структура();
	ПараметрыАвторизации.Вставить("Пользователь", Параметры["ПользовательИБ"]);
	ПараметрыАвторизации.Вставить("Пароль", Параметры["ПарольИБ"]);
	
	Возврат ПараметрыАвторизации;
	
КонецФункции

Процедура ОтключитьПользователейИБ()
	
	УправлениеКластером.ОтключитьСеансыИнформационнойБазы(Параметры["ИмяБазы"]);
	Мониторинг.Отладка("Сеансы отключены");
	
КонецПроцедуры

Процедура ОтключитьСоединенияИнформационнойБазы()
	
	УправлениеКластером.ОтключитьСоединенияИнформационнойБазы(Параметры["ИмяБазы"]);
	Мониторинг.Отладка("Соединения отключены");
	
КонецПроцедуры

Процедура ЗавершитьОбновление()
	
	Мониторинг.УстановитьНулевойУровень();
	Мониторинг.Информация("Окончание обновления базы");
	
КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)
	
	СнятьБлокировкуИБ();
	Мониторинг.Внимание(ТекстОшибки);
	Мониторинг.УстановитьНулевойУровень();
	Мониторинг.КритическаяОшибка("Во время обновления произошла ошибка!");
	Мониторинг.Информация("Обновления базы не было выполнено");
	
КонецПроцедуры

Процедура ПодождатьФоновоеЗадание()
	
	Мониторинг.Отладка("Ожидание завершения фоновых заданий");
	Приостановить(30000);
	
КонецПроцедуры

Процедура ОбновитьКонфигурацию()
	
	Конфигуратор.УстановитьКлючРазрешенияЗапуска(Параметры["КлючРазрешенияЗапуска"]);
	Конфигуратор.ОбновитьКонфигурациюБазыДанных();
	Мониторинг.Отладка("Конфигурация обновлена");
	
КонецПроцедуры

Процедура СнятьБлокировкуИБ()
	
	УправлениеКластером.СнятьБлокировкуИнформационнойБазы(Параметры["ИмяБазы"], Ложь);
	Мониторинг.Отладка("Блокировка ИБ снята");
	
КонецПроцедуры

Попытка
		
	ПрочитатьПараметрыИзФайла();
	ИнициализироватьМониторинг();
	ПодключитьУправлениеКластером();
	
	УстановитьКонтекстКонфигурации();

	УстановитьБлокировкуИБ();
	
	ПодождатьФоновоеЗадание();
	
	ОтключитьПользователейИБ();
	ОтключитьСоединенияИнформационнойБазы();
	
	ОбновитьКонфигурацию();
	СнятьБлокировкуИБ();
		
	ЗавершитьОбновление();
	
Исключение
	
	ОбработатьИсключение(ОписаниеОшибки());
	
КонецПопытки;