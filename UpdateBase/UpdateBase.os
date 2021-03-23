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

Процедура ИнициализироватьЛог()
	
	Логирование = Новый ТУправлениеЛогированием();
	Логирование.ДатаВремяВКаждойСтроке = Истина;
	Логирование.ВыводитьСообщенияПриЗаписи = Истина; 
	Логирование.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Логирование.ЗаписатьСтрокуЛога("Начало обновления базы " + Параметры["ИмяБазы"]);
	Логирование.УвеличитьУровень();

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
	Логирование.ЗаписатьСтрокуЛога("Управление кластером подключено");

КонецПроцедуры

Функция БлокировкаУстановлена()
	
	ОписаниеИБ = УправлениеКластером.ПолучитьПодробноеОписаниеИнформационнойБазы(Параметры["ИмяБазы"]);
	Результат = ОписаниеИБ.ЗапретПодключенияСессий;
	Логирование.ЗаписатьСтрокуЛога("ИБ " + ?(Результат, "", "не ") + "требует обновления");

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
	Логирование.ЗаписатьСтрокуЛога("Сеансы отключены");

КонецПроцедуры

Процедура ОтключитьСоединенияИнформационнойБазы()

	УправлениеКластером.ОтключитьСоединенияИнформационнойБазы(Параметры["ИмяБазы"]);
	Логирование.ЗаписатьСтрокуЛога("Соединения отключены");	

КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Логирование.ЗаписатьСтрокуЛога("Информационная база подключена");

КонецПроцедуры

Процедура ПолучитьКонфигурациюХранилища()

	Конфигуратор.УстановитьКлючРазрешенияЗапуска(Параметры["КлючРазрешенияЗапуска"]);
	Конфигуратор.ОбновитьКонфигурациюБазыДанныхИзХранилища(Параметры["ПутьКХранилищу"], 
	Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"]);
	Логирование.ЗаписатьСтрокуЛога("Информационная база обновлена");

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
	
		Логирование.ЗаписатьСтрокуЛога("Письмо о завершении обновления отправлено");	

	Иначе

		Логирование.УвеличитьУровень();
		Логирование.ЗаписатьСтрокуЛога(КомандныйФайл.ПолучитьВывод());
		Логирование.УменьшитьУровень();

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
	Логирование.ЗаписатьСтрокуЛога("Блокировка ИБ снята");	

КонецПроцедуры

Процедура ЗавершитьОбновление()

	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Окончание обновления базы");	

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	СнятьБлокировкуИБ();
	Логирование.ЗаписатьСтрокуЛога(ТекстОшибки);
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

Попытка

	ПолучитьАргументы();
	ПрочитатьПараметрыИзФайла();
	ИнициализироватьЛог();
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