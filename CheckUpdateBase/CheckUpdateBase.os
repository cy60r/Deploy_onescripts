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
// Дата Окончания блокировки сеансов
Перем ДатаОкончанияБлокировки;
// Отключение сеансов конфигуратора
Перем ОтключитьСеансКонфигуратора;

Процедура ПрочитатьПараметрыИзФайла()

	УстановитьТекущийКаталог("C:\scripts\CheckUpdateBase");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "CheckUpdateBase.json"));

КонецПроцедуры

Процедура ПолучитьАргументы()

	Парсер = Новый ПарсерАргументовКоманднойСтроки();

	Парсер.ДобавитьИменованныйПараметр("--denied-from");
	Парсер.ДобавитьИменованныйПараметр("--denied-to");
	Парсер.ДобавитьИменованныйПараметр("--kick-designer");
	
	ПараметрыКоманднойСтроки 	= Парсер.Разобрать(АргументыКоманднойСтроки);
	ДатаНачалаБлокировки 		= ПараметрыКоманднойСтроки["--denied-from"];
	ДатаОкончанияБлокировки 	= ПараметрыКоманднойСтроки["--denied-to"];
	ОтключитьСеансКонфигуратора = ?(ПараметрыКоманднойСтроки["--kick-designer"] = "yes", Истина, Ложь);

	// Стандартное время обновления 13:00
	Если Не ЗначениеЗаполнено(ДатаНачалаБлокировки) Тогда
	
		ДатаНачалаБлокировки 		= "13:00";
		ДатаОкончанияБлокировки 	= "13:20";		

	КонецЕсли;

КонецПроцедуры

Процедура ИнициализироватьМониторинг()
	
	Мониторинг = Новый УправлениеМониторингом();
	Мониторинг.УстановитьПараметрыМониторинга(Параметры["АдресZabbix"], Параметры["ZabbixSender"]);
	Мониторинг.УстановитьПараметрыЭлементаДанных(Параметры["УзелZabbix"], Параметры["КлючZabbix"]);
	Мониторинг.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Мониторинг.Информация("Начало проверки наличия обновления " + Параметры["ИмяБазы"]);
	Мониторинг.УвеличитьУровень();

КонецПроцедуры

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"]);
	УправлениеКластером.ИспользоватьВерсию(Параметры["ВерсияПлатформы"]);
	УправлениеКластером.УстановитьАвторизациюКластера(Параметры["ПользовательКластера"], Параметры["ПарольКластера"]);
	УправлениеКластером.Подключить();
	ПараметрыАвторизацииИБ = ПараметрыАвторизацииИБ();
	Мониторинг.Отладка("Управление кластером подключено");

КонецПроцедуры

Процедура ОтключитьПользователейКонфигуратора()

	Массив = Новый Массив;
	Массив.Добавить("Designer");
	Фильтр = Новый Структура("Приложение", Массив);
	
	УправлениеКластером.ОтключитьСеансыИнформационнойБазыПоФильтру(Параметры["ИмяБазы"], Фильтр);
	Мониторинг.Отладка("Сеансы конфигуратора отключены");

КонецПроцедуры

Процедура УстановитьБлокировкуИБ()
	
	СообщениеОБлокировке = СообщениеОБлокировкеПоШаблону();
	ДатаНачалаБлокировкиФормат = ФорматДатыДляБлокировки(ДатаНачалаБлокировки);
	ДатаОкончанияБлокировкиФормат = ФорматДатыДляБлокировки(ДатаОкончанияБлокировки);
	УправлениеКластером.БлокировкаИнформационнойБазы(Параметры["ИмяБазы"], СообщениеОБлокировке, 
	Параметры["КлючРазрешенияЗапуска"], ДатаНачалаБлокировкиФормат, 
	ДатаОкончанияБлокировкиФормат, Ложь, ПараметрыАвторизацииИБ);
	Мониторинг.Отладка("Блокировка ИБ установлена");

КонецПроцедуры

Функция ФорматДатыДляБлокировки(Дата)

	Возврат ПрочитатьДатуJSON(Формат(ТекущаяДата(), "ДФ=yyyy-MM-ddT") + Дата + ":00Z", ФорматДатыJSON.ISO); 	

КонецФункции

Функция СообщениеОБлокировкеПоШаблону()

	ТекстовыйФайл = Новый ЧтениеТекста(ОбъединитьПути(ТекущийКаталог(), "BlockMessage.txt"));
	СообщениеОБлокировке = СтрШаблон(ТекстовыйФайл.Прочитать(), ДатаНачалаБлокировки, ДатаОкончанияБлокировки);
	ТекстовыйФайл.Закрыть();
	
	Возврат СообщениеОБлокировке;

КонецФункции

Функция ПараметрыАвторизацииИБ()
	
	ПараметрыАвторизации = Новый Структура();
	ПараметрыАвторизации.Вставить("Пользователь", Параметры["ПользовательИБ"]);
	ПараметрыАвторизации.Вставить("Пароль", Параметры["ПарольИБ"]);

	Возврат ПараметрыАвторизации;

КонецФункции

Процедура СнятьБлокировкуИБ()

	УправлениеКластером.СнятьБлокировкуИнформационнойБазы(Параметры["ИмяБазы"], Ложь, ПараметрыАвторизацииИБ);
	Мониторинг.Отладка("Блокировка ИБ снята");	

КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Мониторинг.Отладка("Информационная база подключена");

КонецПроцедуры

Функция КонфигурацияОтличаетсяОтХранилища()

	Конфигуратор.УстановитьКодЯзыкаСеанса("ru");
	Результат = Конфигуратор.КонфигурацияИХранилищеИдентичны(Параметры["ПутьКХранилищу"], 
	Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"]);
	Мониторинг.Отладка("Сравнение конфигурации ИБ и конфигурации хранилища выполнено");
	Мониторинг.Отладка(?(Результат, "Конфигурации идентичны", "Конфигурации различаются"));
	Возврат Не Результат;

КонецФункции

Процедура ОтправитьПисьмоОбновления()

	ТемаПисьма = СтрШаблон(Параметры["ТемаПисьма"], ДатаНачалаБлокировки);
	ТекстСообщения = ТекстСообщенияОбновления();

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
	
		Мониторинг.Отладка("Письмо о планировании обновления отправлено");	

	Иначе

		Мониторинг.УвеличитьУровень();
		Мониторинг.Внимание(КомандныйФайл.ПолучитьВывод());
		Мониторинг.Ошибка("Произошла ошибка при отправке письма!");
		Мониторинг.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

Функция ТекстСообщенияОбновления()

	ТекстовыйФайл = Новый ЧтениеТекста(ОбъединитьПути(ТекущийКаталог(), "CheckUpdateBaseMessage.txt"));
	Сообщение = ТекстовыйФайл.Прочитать();
	ТекстовыйФайл.Закрыть();
	
	Возврат СтрШаблон(Сообщение, ДатаНачалаБлокировки, ДатаОкончанияБлокировки);

КонецФункции

Процедура ЗавершитьПроверкуОбновления()
	
	Мониторинг.УменьшитьУровень();
	Мониторинг.Информация("Проверка обновления завершена");	

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	Мониторинг.УвеличитьУровень();
	Мониторинг.Внимание(ТекстОшибки);
	ОтправитьПисьмоОбОшибке(ТекстОшибки);
	Мониторинг.УстановитьНулевойУровень();
	Мониторинг.КритическаяОшибка("Во время проверки обновления произошла ошибка!");
	Мониторинг.Информация("Проверка базы на обновление не было выполнено");

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
		Мониторинг.Ошибка("Письмо об ошибке не было отправлено!");
		Мониторинг.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

ПолучитьАргументы();
ПрочитатьПараметрыИзФайла();

Попытка

	ИнициализироватьМониторинг();

	ПодключитьУправлениеКластером();
	СнятьБлокировкуИБ();

	Если ОтключитьСеансКонфигуратора Тогда
		
		ОтключитьПользователейКонфигуратора();

	КонецЕсли;

	УстановитьКонтекстКонфигурации();

	Если КонфигурацияОтличаетсяОтХранилища() Тогда
		
		УстановитьБлокировкуИБ();
		ОтправитьПисьмоОбновления();

	КонецЕсли;

	ЗавершитьПроверкуОбновления();

Исключение

	СнятьБлокировкуИБ();
	ОбработатьИсключение(ОписаниеОшибки());

КонецПопытки;