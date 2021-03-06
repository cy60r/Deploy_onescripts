#Использовать ReadParams
#Использовать Ext_v8runner
#Использовать Ext_Tlog

Перем Параметры; 					// Параметры из конфигурационного файла json
Перем Логирование; 					// История лога выполнения
Перем Конфигуратор; 				// Подключение к конфигуратору
Перем ИмяФайлаВыгрузкиЛокальный; 	// Локальный полный путь до файла выгрузки  
Перем ИмяФайлаВыгрузки; 			// Сетевой полный путь до файла выгрузки

Процедура ПрочитатьПараметрыИзФайла()

	УстановитьТекущийКаталог("C:\scripts\ExportActualVersionCF");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "ExportActualVersionCF.json"));

КонецПроцедуры

Процедура ИнициализироватьЛог()
	
	Логирование = Новый ТУправлениеЛогированием();
	Логирование.ДатаВремяВКаждойСтроке = Истина;
	Логирование.ВыводитьСообщенияПриЗаписи = Истина; 
	Логирование.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Логирование.ЗаписатьСтрокуЛога("Начало подготовки обновления базы из хранилища");
	Логирование.УвеличитьУровень();

КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()

	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"], 
	Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Логирование.ЗаписатьСтрокуЛога("Информационная база подключена");

КонецПроцедуры

Процедура СформироватьКаталогиВыгрузок()

	ИмяФайлаВыгрузкиЛокальный = ИмяФайлаВыгрузкиКонфигурации(Параметры["КаталогВыгрузкиЛокальный"]);
	ИмяФайлаВыгрузки = ИмяФайлаВыгрузкиКонфигурации(Параметры["КаталогВыгрузки"]);	
	
КонецПроцедуры

Процедура ВыгрузитьКонфигурациюХранилища()
	
	Конфигуратор.ВыгрузитьКонфигурациюХранилищаВФайл(Параметры["ПутьКХранилищу"], Параметры["ПользовательХранилища"], 
	Параметры["ПарольХранилища"], "-1", ИмяФайлаВыгрузкиЛокальный);
	Логирование.ЗаписатьСтрокуЛога("Конфигурация хранилища выгружена");

КонецПроцедуры

Процедура ПереместитьФайлВыгрузки()
	
	КопироватьФайл(ИмяФайлаВыгрузкиЛокальный, ИмяФайлаВыгрузки);
	Логирование.ЗаписатьСтрокуЛога("Файл выгрузки конфигурации перемещен");
	УдалитьФайлы(ИмяФайлаВыгрузкиЛокальный);
	Логирование.ЗаписатьСтрокуЛога("Локальный файл выгрузки удален");

КонецПроцедуры

Функция ИмяФайлаВыгрузкиКонфигурации(Каталог)
	
	Возврат СокрЛП(Каталог) + "\" + Формат(ТекущаяДата(), "ДФ=ddMMyyyy") + ".cf";

КонецФункции

Процедура ЗавершитьПодготовку()

	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Окончание подготовки обновления");	

КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)

	Логирование.ЗаписатьСтрокуЛога(ТекстОшибки);
	Логирование.УменьшитьУровень();
	Логирование.ЗаписатьСтрокуЛога("Во время подготовки обновления произошла ошибка!");	

КонецПроцедуры

Попытка

	ПрочитатьПараметрыИзФайла();
	ИнициализироватьЛог();
	УстановитьКонтекстКонфигурации();
	СформироватьКаталогиВыгрузок();
	ВыгрузитьКонфигурациюХранилища();
	ПереместитьФайлВыгрузки();

	ЗавершитьПодготовку();

Исключение

	ОбработатьИсключение(ОписаниеОшибки());

КонецПопытки;