#Использовать ReadParams
#Использовать Tmail
#Использовать cmdline
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
Перем ИнтернетПочта;				// Учетная запись электронной почты для отправки писем

Процедура ПрочитатьПараметрыИзФайла()

	УстановитьТекущийКаталог("C:\scripts\PrepareForUpdateWithoutCheck");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "PrepareForUpdateWithoutCheck.json"));

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

КонецПроцедуры

Процедура ИнициализироватьЛог()
	
	Логирование = Новый ТУправлениеЛогированием();
	Логирование.ДатаВремяВКаждойСтроке = Истина;
	Логирование.ВыводитьСообщенияПриЗаписи = Истина; 
	Логирование.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Логирование.ЗаписатьСтрокуЛога("Начало проверки наличия обновления " + Параметры["ИмяБазы"]);
	Логирование.УвеличитьУровень();

КонецПроцедуры

Процедура ИнициализироватьПочту()
	
	ИнтернетПочта = Новый ТУправлениеЭлектроннойПочтой();

	УчетнаяЗаписьЭП = ИнтернетПочта.УчетнаяЗаписьЭП;
	УчетнаяЗаписьЭП.АдресSMTP 			= Параметры["АдресSMTP"];
	УчетнаяЗаписьЭП.ПортSMTP 			= 25;
	Логирование.ЗаписатьСтрокуЛога("Электронная почта подключена");

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

Процедура ОтправитьПисьмоОбновления()
	
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыПолучателя = Параметры["АдресПолучателя"];
		
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыОтправителя = Параметры["АдресОтправителя"];
	СтруктураСообщения.ТемаСообщения = СтрШаблон(Параметры["ТемаПисьма"], ДатаНачалаБлокировки);
	
	СтруктураСообщения.ТипТекстаПочтовогоСообщения = "Строка";
	СтруктураСообщения.Вставить("ТекстСообщения", ТекстСообщенияОбновления());
	
	Если ИнтернетПочта.ОтправитьСообщение() Тогда
			
		Логирование.ЗаписатьСтрокуЛога("Письмо о планировании обновления отправлено");
	
	Иначе
		
		Логирование.УвеличитьУровень();
		Логирование.ЗаписатьСтрокуЛога(ОписаниеОшибки());
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
	
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыПолучателя = Параметры["АдресПолучателяОшибки"];
		
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыОтправителя = Параметры["АдресОтправителя"];
	СтруктураСообщения.ТемаСообщения = "ОШИБКА " + СтрШаблон(Параметры["ТемаПисьма"], ДатаНачалаБлокировки);
	
	СтруктураСообщения.ТипТекстаПочтовогоСообщения = "Строка";
	СтруктураСообщения.Вставить("ТекстСообщения", ТекстОшибки);
	
	Если ИнтернетПочта.ОтправитьСообщение() Тогда
			
		Логирование.ЗаписатьСтрокуЛога("Письмо об ошибке отправлено");
	
	Иначе
		
		Логирование.УвеличитьУровень();
		Логирование.ЗаписатьСтрокуЛога(ОписаниеОшибки());
		Логирование.УменьшитьУровень();
	
	КонецЕсли;

КонецПроцедуры

ПолучитьАргументы();
ПрочитатьПараметрыИзФайла();

Попытка

	ИнициализироватьЛог();
	ИнициализироватьПочту();

	ПодключитьУправлениеКластером();
	СнятьБлокировкуИБ();

	Если ОтключитьСеансКонфигуратора Тогда
		
		ОтключитьПользователейКонфигуратора();

	КонецЕсли;

	УстановитьКонтекстКонфигурации();
		
	УстановитьБлокировкуИБ();
	ОтправитьПисьмоОбновления();

	ЗавершитьПроверкуОбновления();

Исключение

	СнятьБлокировкуИБ();
	ОбработатьИсключение(ОписаниеОшибки());

КонецПопытки;