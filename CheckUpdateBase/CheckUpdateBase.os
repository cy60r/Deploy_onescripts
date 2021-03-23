#Использовать ReadParams
#Использовать cmdline
#Использовать Ext_1commands
#Использовать Ext_v8rac
#Использовать Ext_v8runner
#Использовать Ext_Tlog

Перем УправлениеКластером; 			// Подключение к кластеру
Перем Конфигуратор; 				// Подключение к конфигуратору
Перем Параметры; 					// Параметры из конфигурационного файла json
Перем Логирование; 					// История лога выполнения
Перем ПараметрыАвторизацииИБ; 		// Параметры для авторизации на кластере
Перем ДатаНачалаБлокировки; 		// Дата начала блокировки сеансов
Перем ДатаОкончанияБлокировки; 		// Дата Окончания блокировки сеансов
Перем ОтключитьСеансКонфигуратора;	// Отключение сеансов конфигуратора

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

Процедура ИнициализироватьЛог()
	
	Логирование = Новый ТУправлениеЛогированием();
	Логирование.ДатаВремяВКаждойСтроке = Истина;
	Логирование.ВыводитьСообщенияПриЗаписи = Истина; 
	Логирование.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Логирование.ЗаписатьСтрокуЛога("Начало проверки наличия обновления " + Параметры["ИмяБазы"]);
	Логирование.УвеличитьУровень();

КонецПроцедуры

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"]);
	УправлениеКластером.ИспользоватьВерсию(Параметры["ВерсияПлатформы"]);
	УправлениеКластером.УстановитьАвторизациюКластера(Параметры["ПользовательКластера"], Параметры["ПарольКластера"]);
	УправлениеКластером.Подключить();
	ПараметрыАвторизацииИБ = ПараметрыАвторизацииИБ();
	Логирование.ЗаписатьСтрокуЛога("Управление кластером подключено");

КонецПроцедуры

Процедура ОтключитьПользователейКонфигуратора()

	Массив = Новый Массив;
	Массив.Добавить("Designer");
	Фильтр = Новый Структура("Приложение", Массив);
	
	УправлениеКластером.ОтключитьСеансыИнформационнойБазыПоФильтру(Параметры["ИмяБазы"], Фильтр);
	Логирование.ЗаписатьСтрокуЛога("Сеансы конфигуратора отключены");

КонецПроцедуры

Процедура УстановитьБлокировкуИБ()
	
	СообщениеОБлокировке = СообщениеОБлокировкеПоШаблону();
	ДатаНачалаБлокировкиФормат = ФорматДатыДляБлокировки(ДатаНачалаБлокировки);
	ДатаОкончанияБлокировкиФормат = ФорматДатыДляБлокировки(ДатаОкончанияБлокировки);
	УправлениеКластером.БлокировкаИнформационнойБазы(Параметры["ИмяБазы"], СообщениеОБлокировке, 
	Параметры["КлючРазрешенияЗапуска"], ДатаНачалаБлокировкиФормат, 
	ДатаОкончанияБлокировкиФормат, Ложь, ПараметрыАвторизацииИБ);
	Логирование.ЗаписатьСтрокуЛога("Блокировка ИБ установлена");

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
	Логирование.ЗаписатьСтрокуЛога("Блокировка ИБ снята");	

КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Логирование.ЗаписатьСтрокуЛога("Информационная база подключена");

КонецПроцедуры

Функция КонфигурацияОтличаетсяОтХранилища()

	Конфигуратор.УстановитьКодЯзыкаСеанса("ru");
	Результат = Конфигуратор.КонфигурацияИХранилищеИдентичны(Параметры["ПутьКХранилищу"], 
	Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"]);
	Логирование.ЗаписатьСтрокуЛога("Сравнение конфигурации ИБ и конфигурации хранилища выполнено");
	Логирование.ЗаписатьСтрокуЛога(?(Результат, "Конфигурации идентичны", "Конфигурации различаются"));
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
	
		Логирование.ЗаписатьСтрокуЛога("Письмо о планировании обновления отправлено");	

	Иначе

		Логирование.УвеличитьУровень();
		Логирование.ЗаписатьСтрокуЛога(КомандныйФайл.ПолучитьВывод());
		Логирование.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

Функция ТекстСообщенияОбновления()

	ТекстовыйФайл = Новый ЧтениеТекста(ОбъединитьПути(ТекущийКаталог(), "CheckUpdateBaseMessage.txt"));
	Сообщение = ТекстовыйФайл.Прочитать();
	ТекстовыйФайл.Закрыть();
	
	Возврат СтрШаблон(Сообщение, ДатаНачалаБлокировки, ДатаОкончанияБлокировки);

КонецФункции

Процедура ЗавершитьПроверкуОбновления()
	
	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Проверка обновления завершена");	

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	Логирование.УвеличитьУровень();
	Логирование.ЗаписатьСтрокуЛога(ТекстОшибки);
	Логирование.УменьшитьУровень();
	ОтправитьПисьмоОбОшибке(ТекстОшибки);
	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Во время обновления произошла ошибка!");	

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
	
		Логирование.ЗаписатьСтрокуЛога("Письмо об ошибке отправлено");	

	Иначе

		Логирование.УвеличитьУровень();
		Логирование.ЗаписатьСтрокуЛога(КомандныйФайл.ПолучитьВывод());
		Логирование.УменьшитьУровень();

	КонецЕсли;

КонецПроцедуры

ПолучитьАргументы();
ПрочитатьПараметрыИзФайла();

Попытка

	ИнициализироватьЛог();

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