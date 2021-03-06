#Использовать ReadParams
#Использовать Ext_v8rac
#Использовать Ext_v8runner
#Использовать Ext_v8storage
#Использовать Ext_Tlog
#Использовать TMail

// Параметры из конфигурационного файла json
Перем Параметры;
// История лога выполнения
Перем Логирование;
// Подключение к кластеру
Перем УправлениеКластером;
// Подключение к конфигуратору
Перем Конфигуратор;

Процедура ПрочитатьПараметрыИзФайла()

	УстановитьТекущийКаталог("C:\scripts\ActualizeExt");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "ActualizeExt.json"));

КонецПроцедуры

Процедура ИнициализироватьЛог()
	
	Логирование = Новый ТУправлениеЛогированием();
	Логирование.ДатаВремяВКаждойСтроке = Истина;
	Логирование.ВыводитьСообщенияПриЗаписи = Истина; 
	Логирование.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Логирование.ЗаписатьСтрокуЛога("Начало актуализации расширения");
	Логирование.УвеличитьУровень();

КонецПроцедуры

Процедура ОтключитьПользователейИБ()

	ПодключитьУправлениеКластером();
	УправлениеКластером.ОтключитьСеансыИнформационнойБазы(Параметры["ИмяБазы"]);
	Логирование.ЗаписатьСтрокуЛога("Сеансы отключены");

КонецПроцедуры

Процедура ОтключитьСоединенияИнформационнойБазы()

	УправлениеКластером.ОтключитьСоединенияИнформационнойБазы(Параметры["ИмяБазы"]);
	Логирование.ЗаписатьСтрокуЛога("Соединения отключены");	

КонецПроцедуры

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"]);
	УправлениеКластером.Подключить();
	Логирование.ЗаписатьСтрокуЛога("Управление кластером подключено");

КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Логирование.ЗаписатьСтрокуЛога("Информационная база подключена");

КонецПроцедуры

Процедура ВыгрузитьКонфигурациюРасширенияДоОбновления()

	ИмяФайлаВыгрузки = ИмяФайлаВыгрузкиКонфигурации();
	Конфигуратор.ВыгрузитьРасширениеВФайл(ИмяФайлаВыгрузки, Параметры["ИмяРасширения"]);
	Логирование.ЗаписатьСтрокуЛога("Конфигурация расширения выгружена");
	
КонецПроцедуры

Функция ИмяФайлаВыгрузкиКонфигурации()
	
	Возврат СтрШаблон("%1\%2.cfe", СокрЛП(Параметры["КаталогАрхива"]), Формат(ТекущаяДата(), "ДФ=ddMMyyyy"));

КонецФункции

Процедура ПолучитьКонфигурациюРасширения()

	Конфигуратор.ОбновитьКонфигурациюБазыДанныхИзХранилища(Параметры["ПутьКХранилишу"], 
	Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"], , Параметры["ИмяРасширения"]);
	Логирование.ЗаписатьСтрокуЛога("Конфигурация расширения обновлена");

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Произошла ошибка: " + ТекстОшибки);

КонецПроцедуры

ПрочитатьПараметрыИзФайла();
ИнициализироватьЛог();

Попытка

	ОтключитьПользователейИБ();
	ОтключитьСоединенияИнформационнойБазы();
	УстановитьКонтекстКонфигурации();
	ВыгрузитьКонфигурациюРасширенияДоОбновления();
	ПолучитьКонфигурациюРасширения();
	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Окончание актуализации расширения");

Исключение

	ОбработатьИсключение(ОписаниеОшибки());

КонецПопытки;