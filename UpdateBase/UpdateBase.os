#Использовать ReadParams
#Использовать monitoring
#Использовать cmdline
#Использовать Ext_1commands
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
// Дата начала блокировки сеансов
Перем ДатаНачалаБлокировки;

Процедура ПрочитатьПараметрыИзФайла()

	УстановитьТекущийКаталог("C:\scripts\UpdateBase");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "UpdateBase.json"));

КонецПроцедуры

Процедура ПолучитьАргументы()

	Парсер = Новый ПарсерАргументовКоманднойСтроки();

	Парсер.ДобавитьИменованныйПараметр("--denied-from");
	
	ПараметрыКоманднойСтроки 	= Парсер.Разобрать(АргументыКоманднойСтроки);
	ДатаНачалаБлокировки 		= ПараметрыКоманднойСтроки["--denied-from"];

	// Стандартное время обновления 13:00
	Если Не ЗначениеЗаполнено(ДатаНачалаБлокировки) Тогда
	
		ДатаНачалаБлокировки 		= "13:00";		

	КонецЕсли;

КонецПроцедуры

Процедура ИнициализироватьМониторинг()
	
	Мониторинг = Новый УправлениеМониторингом();
	Мониторинг.УстановитьПараметрыМониторинга(Параметры["АдресZabbix"], Параметры["ZabbixSender"]);
	Мониторинг.УстановитьПараметрыЭлементаДанных(Параметры["УзелZabbix"], Параметры["КлючZabbix"]);
	Мониторинг.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Мониторинг.Информация("Начало обновления базы " + Параметры["ИмяБазы"]);
	Мониторинг.УвеличитьУровень();

КонецПроцедуры

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"]);
	УправлениеКластером.ИспользоватьВерсию(Параметры["ВерсияПлатформы"]);
	УправлениеКластером.УстановитьАвторизациюКластера(Параметры["ПользовательКластера"], Параметры["ПарольКластера"]);
	УправлениеКластером.Подключить();
	УправлениеКластером.УстановитьАвторизациюИнформационнойБазы(Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	ПараметрыАвторизацииИБ = ПараметрыАвторизацииИБ();
	Мониторинг.Отладка("Управление кластером подключено");

КонецПроцедуры

Функция БлокировкаУстановлена()
	
	ОписаниеИБ = УправлениеКластером.ПолучитьПодробноеОписаниеИнформационнойБазы(Параметры["ИмяБазы"]);
	Результат = ОписаниеИБ.ЗапретПодключенияСессий;
	Мониторинг.Отладка("ИБ " + ?(Результат, "", "не ") + "требует обновления");

	Возврат Результат; 

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

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Мониторинг.Отладка("Информационная база подключена");

КонецПроцедуры

Процедура ПолучитьКонфигурациюХранилища()

	Конфигуратор.УстановитьКлючРазрешенияЗапуска(Параметры["КлючРазрешенияЗапуска"]);
	Конфигуратор.ОбновитьКонфигурациюБазыДанныхИзХранилища(Параметры["ПутьКХранилищу"], 
	Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"]);
	Мониторинг.Отладка("Информационная база обновлена");

КонецПроцедуры

Процедура ОтправитьПисьмоЗавершении()
	
	ТемаПисьма = СтрШаблон(Параметры["ТемаПисьма"], ДатаНачалаБлокировки);
	ТекстСообщения = ТекстСообщенияОбУспешномОбновлении();

	ТекстКомандногоФайла = СтрШаблон("Send-MailMessage -From %1 -To %2 -Subject “%3” -Body “%4” -SMTPServer %5 %6",
	Параметры["АдресОтправителя"],
	Параметры["АдресПолучателя"],
	ТемаПисьма,
	ТекстСообщения,
	Параметры["АдресSMTP"],
	"-Encoding ([System.Text.Encoding]::UTF8)");

	КомандныйФайл = Новый КомандныйФайл;
	КомандныйФайл.УстановитьПриложение("C:\Windows\syswow64\Windowspowershell\v1.0\powershell.exe");
	КомандныйФайл.Создать("", ".ps1");
	КомандныйФайл.ПоказыватьВыводНемедленно(Ложь);
	КомандныйФайл.ДобавитьКоманду(ТекстКомандногоФайла);
	КодВозврата = КомандныйФайл.Исполнить();
	Если КодВозврата = 0 Тогда
	
		Мониторинг.Отладка("Письмо о завершении обновления отправлено");	

	Иначе

		Мониторинг.УвеличитьУровень();
		Мониторинг.Внимание(КомандныйФайл.ПолучитьВывод());
		Мониторинг.Ошибка("Ошибка при отправке письма о завершении обновления!");
		Мониторинг.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

Функция ТекстСообщенияОбУспешномОбновлении()

	ТекстовыйФайл = Новый ЧтениеТекста(ОбъединитьПути(ТекущийКаталог(), "UpdateBaseMessage.txt"));
	Сообщение = ТекстовыйФайл.Прочитать();
	ТекстовыйФайл.Закрыть();
	
	Возврат Сообщение;

КонецФункции

Процедура СнятьБлокировкуИБ()

	УправлениеКластером.СнятьБлокировкуИнформационнойБазы(Параметры["ИмяБазы"], Ложь);
	Мониторинг.Отладка("Блокировка ИБ снята");	

КонецПроцедуры

Процедура ЗавершитьОбновление()

	Мониторинг.УменьшитьУровень();
	Мониторинг.Информация("Окончание обновления базы");	

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	СнятьБлокировкуИБ();
	Мониторинг.Внимание(ТекстОшибки);
	ОтправитьПисьмоОбОшибке(ТекстОшибки);
	Мониторинг.УменьшитьУровень();
	Мониторинг.КритическаяОшибка("Во время обновления произошла ошибка!");
	Мониторинг.Информация("Обновления базы не было выполнено");

КонецПроцедуры

Процедура ОтправитьПисьмоОбОшибке(ТекстОшибки)
	
	ТемаПисьма = "ОШИБКА " + СтрШаблон(Параметры["ТемаПисьма"], ДатаНачалаБлокировки);
	ТекстСообщения = ТекстОшибки;

	ТекстКомандногоФайла = СтрШаблон("Send-MailMessage -From %1 -To %2 -Subject “%3” -Body “%4” -SMTPServer %5 %6",
	Параметры["АдресОтправителя"],
	Параметры["АдресПолучателяОшибки"],
	ТемаПисьма,
	ТекстСообщения,
	Параметры["АдресSMTP"],
	"-Encoding ([System.Text.Encoding]::UTF8)");

	КомандныйФайл = Новый КомандныйФайл;
	КомандныйФайл.УстановитьПриложение("C:\Windows\syswow64\Windowspowershell\v1.0\powershell.exe");
	КомандныйФайл.Создать("", ".ps1");
	КомандныйФайл.ПоказыватьВыводНемедленно(Ложь);
	КомандныйФайл.ДобавитьКоманду(ТекстКомандногоФайла);
	КодВозврата = КомандныйФайл.Исполнить();
	Если КодВозврата = 0 Тогда
	
		Мониторинг.Отладка("Письмо об ошибке отправлено");	

	Иначе

		Мониторинг.УвеличитьУровень();
		Мониторинг.Внимание(КомандныйФайл.ПолучитьВывод());
		Мониторинг.Ошибка("Ошибка при отправке письма об ошибке!");
		Мониторинг.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

Попытка

	ПолучитьАргументы();
	ПрочитатьПараметрыИзФайла();
	ИнициализироватьМониторинг();
	ПодключитьУправлениеКластером();

	Если БлокировкаУстановлена() Тогда

		ОтключитьПользователейИБ();
		ОтключитьСоединенияИнформационнойБазы();

		УстановитьКонтекстКонфигурации();
		ПолучитьКонфигурациюХранилища();
		
		СнятьБлокировкуИБ();
		ОтправитьПисьмоЗавершении();

	КонецЕсли;

	ЗавершитьОбновление();

Исключение

	ОбработатьИсключение(ОписаниеОшибки());

КонецПопытки;