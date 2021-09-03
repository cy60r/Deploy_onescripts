﻿#Использовать ReadParams
#Использовать monitoring
#Использовать Ext_v8runner
#Использовать Ext_v8storage
#Использовать Ext_v8rac
#Использовать gitrunner
#Использовать xml-parser
#Использовать tempfiles
#Использовать 1commands

// Параметры из конфигурационного файла json
Перем Параметры;
// Мониторинг Zabbix
Перем Мониторинг;
// Подключение к кластеру
Перем УправлениеКластером;
// Подключение к конфигуратору
Перем Конфигуратор;
// Гит репозиторий
Перем ГитРепозиторий;

#Область НачальныеНастройки

Процедура ПрочитатьПараметрыИзФайла()
	
	УстановитьТекущийКаталог("C:\scripts\Deploy_UPP_work");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "Deploy_UPP_work.json"));
	
КонецПроцедуры

Процедура ИнициализироватьМониторинг()
	
	Мониторинг = Новый УправлениеМониторингом();
	Мониторинг.УстановитьПараметрыМониторинга(Параметры["АдресZabbix"]);
	Мониторинг.УстановитьПараметрыЭлементаДанных(Параметры["УзелZabbix"], Параметры["КлючZabbix"]);
	Мониторинг.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Мониторинг.Информация("Начало выполнения деплоя");
	Мониторинг.УвеличитьУровень();
	
КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()
	
	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяВременнойБазы"],
		Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Мониторинг.Отладка("Информационная база подключена");
	
КонецПроцедуры

#КонецОбласти

#Область РаботаСКластером

Процедура ПодключитьУправлениеКластером()
	
	УправлениеКластером = Новый УправлениеКластером;
	УправлениеКластером.УстановитьКластер(Параметры["ИмяСервераКластера"]);
	УправлениеКластером.ИспользоватьВерсию(Параметры["ВерсияПлатформы"]);
	УправлениеКластером.Подключить();
	Мониторинг.Отладка("Управление кластером подключено");
	
КонецПроцедуры

Процедура ОтключитьПользователейИБ()
	
	УправлениеКластером.ОтключитьСеансыИнформационнойБазы(Параметры["ИмяБазы"]);
	Мониторинг.Отладка("Сеансы отключены");
	
КонецПроцедуры

Процедура ОтключитьСоединенияИнформационнойБазы()
	
	УправлениеКластером.ОтключитьСоединенияИнформационнойБазы(Параметры["ИмяБазы"]);
	Мониторинг.Отладка("Соединения отключены");
	
КонецПроцедуры

#КонецОбласти

#Область РаботаСХранилищем
Функция ТаблицаВерсийХранилища(НомерНачальнойВерсии, ПутьКХранилищу)
	
	ХранилищеКонфигурации = Новый МенеджерХранилищаКонфигурации();
	ХранилищеКонфигурации.УстановитьПутьКХранилищу(ПутьКХранилищу);
	ХранилищеКонфигурации.УстановитьПараметрыАвторизации(Параметры["ПользовательХранилища"],
		Параметры["ПарольХранилища"]);
	Мониторинг.Отладка("Получена таблица версий");
	Возврат ХранилищеКонфигурации.ПолучитьТаблицуВерсийСВерсии(НомерНачальнойВерсии);
	
КонецФункции

#КонецОбласти

#Область ВыполнениеДеплоя

Процедура ИнициализироватьГит()
	
	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьРабочийКаталог(Параметры["ОсновнойКаталог"]);
	Мониторинг.Отладка("GIT репозиторий подключен");
	
КонецПроцедуры

Процедура ПерейтиВВеткуГИТ(Отказ, ИмяВетки)
	
	Если Не Отказ Тогда
		
		ГитРепозиторий.ПерейтиВВетку(ИмяВетки, Ложь, Истина);
		Мониторинг.Отладка("Переход на ветку " + ИмяВетки);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура УстановитьДампКонфигурации(Отказ, ИмяВетки, Дамп)
	
	Если Не Отказ Тогда
		
		КопироватьФайл(Дамп, Параметры["ТекущийДампКонфигурации"]);
		Мониторинг.Отладка("Установлен дамп конфигурации ветки " + ИмяВетки);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура СохранитьДампКонфигурации(Отказ, ИмяВетки, Дамп)
	
	Если Не Отказ Тогда
		
		КопироватьФайл(Параметры["ТекущийДампКонфигурации"], Дамп);
		Мониторинг.Отладка("Сохранен дамп конфигурации ветки " + ИмяВетки);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ВыполнитьДеплой(Отказ, КлючПроекта, ИмяВетки, Дамп, ПутьКХранилищу)
	
	Если Не Отказ Тогда
		
		НомерВерсии = НомерТекущейВерсии();
		ТаблицаВерсий = ТаблицаВерсийХранилища(Строка(Число(НомерВерсии) + 1), ПутьКХранилищу);
		ТекстФайлаАвторов = ПрочитатьФайл(ОбъединитьПути(Параметры["ОсновнойКаталог"], "AUTHORS"));
		
		Мониторинг.УвеличитьУровень();
		ОбработкиВыгружены = Ложь;
		
		Для каждого Строка Из ТаблицаВерсий Цикл
			
			Если Не Отказ Тогда
				
				НомерВерсии = Строка.Номер;
				ВыгрузитьВИсходникиИнкрементно(Отказ, НомерВерсии, ПутьКХранилищу);
				
				Если Не ОбработкиВыгружены Тогда
				
					ВыгрузитьВнешниеОбработки(Отказ);
					ОбработкиВыгружены = Истина;
				
				КонецЕсли;
				
				ЗаписатьИнформациюОНовойВерсии(Отказ, НомерВерсии);
				СделатьКоммитВерсии(Отказ, Строка, ТекстФайлаАвторов);
				ВыполнитьСканирование(Отказ, КлючПроекта, Строка.Автор);
				СохранитьДампКонфигурации(Отказ, ИмяВетки, Дамп);
				ОтправитьГИТ(Отказ);
				Мониторинг.УменьшитьУровень();
				
			Иначе
				
				Возврат;
				
			КонецЕсли;
			
		КонецЦикла;
		
		Мониторинг.УменьшитьУровень();
		
	КонецЕсли;
	
КонецПроцедуры

Функция НомерТекущейВерсии()
	
	Процессор = Новый СериализацияДанныхXML();
	РезультатЧтения = Процессор.ПрочитатьИзФайла(ОбъединитьПути(Параметры["ОсновнойКаталог"], "VERSION"));
	Возврат РезультатЧтения["VERSION"];
	
КонецФункции

Процедура ВыгрузитьВИсходникиИнкрементно(Отказ, НомерВерсии, ПутьКХранилищу)
	
	Если Не Отказ Тогда
		
		Мониторинг.Отладка("Начало деплоя версии " + НомерВерсии);
		Мониторинг.УвеличитьУровень();
		
		Конфигуратор.ЗагрузитьКонфигурациюИзХранилища(ПутьКХранилищу,
			Параметры["ПользовательХранилища"], Параметры["ПарольХранилища"], НомерВерсии);
		Мониторинг.Отладка("Конфигурация версии загружена");
		
		ПараметрыКоманды = Конфигуратор.ПолучитьПараметрыЗапуска();
		ПараметрыКоманды.Добавить("/DumpConfigToFiles");
		ПараметрыКоманды.Добавить(Параметры["КаталогВыгрузки"]);
		ПараметрыКоманды.Добавить("-update");
		Конфигуратор.ВыполнитьКоманду(ПараметрыКоманды);
		
		Мониторинг.Отладка("Файлы конфигурации версии выгружены");
		
	КонецЕсли;
	
КонецПроцедуры

Процедура СделатьКоммитВерсии(Отказ, ДанныеВерсии, ТекстФайлаАвторов)
	
	Если Не Отказ Тогда
		
		АвторКоммита = ЗначениеИзТекста(ДанныеВерсии.Автор, ТекстФайлаАвторов);
		
		Если Не ЗначениеЗаполнено(АвторКоммита) Тогда
			
			Отказ = Истина;
			Мониторинг.КритическаяОшибка("Не найден автор коммита!");
			Возврат;
			
		КонецЕсли;
		
		ГитРепозиторий.ДобавитьФайлВИндекс(Параметры["ОсновнойКаталог"]);
		СообщениеКоммита = СообщениеКоммитаПоШаблону(ДанныеВерсии);
		ГитРепозиторий.Закоммитить(СообщениеКоммита, , , АвторКоммита,
			ДанныеВерсии.Дата, АвторКоммита, ДанныеВерсии.Дата);
		Мониторинг.Отладка("Коммит добавлен");
		
	КонецЕсли;
	
КонецПроцедуры

Функция СообщениеКоммитаПоШаблону(ДанныеВерсии)
	
	Возврат ?(ЗначениеЗаполнено(ДанныеВерсии.Комментарий),
		СтрШаблон("№%1%2%3", ДанныеВерсии.Номер, Символы.ПС, ДанныеВерсии.Комментарий),
		СтрШаблон("№%1", ДанныеВерсии.Номер));
	
КонецФункции

Процедура ЗаписатьИнформациюОНовойВерсии(Отказ, НоваяВерсия)
	
	Если Не Отказ Тогда
		
		ТекстСНомеромВерсии = ПрочитатьФайл(ОбъединитьПути(Параметры["ОсновнойКаталог"], "VERSION"));
		
		ТекстСНомеромВерсии = СтрЗаменить(ТекстСНомеромВерсии, НомерТекущейВерсии(), НоваяВерсия);
		ЗаписьТекста = Новый ЗаписьТекста(ОбъединитьПути(Параметры["ОсновнойКаталог"], "VERSION"));
		ЗаписьТекста.Записать(ТекстСНомеромВерсии);
		ЗаписьТекста.Закрыть();
		Мониторинг.Отладка("Файл версии обновлен");
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ОтправитьГИТ(Отказ)
	
	Если Не Отказ Тогда
		
		НастройкаОтправить = Новый НастройкаКомандыОтправить;
		НастройкаОтправить.УстановитьURLРепозиторияОтправки(Параметры["АдресРепозитория"]);
		НастройкаОтправить.ОтображатьПрогресс();
		НастройкаОтправить.ПерезаписатьИсторию();
		НастройкаОтправить.ПолнаяОтправка();
		
		ГитРепозиторий.УстановитьРабочийКаталог(Параметры["ОсновнойКаталог"]);
		ГитРепозиторий.УстановитьНастройкуКомандыОтправить(НастройкаОтправить);
		
		ГитРепозиторий.Отправить();
		Мониторинг.Отладка("Push выполнен");
		
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область РаботаСонарСканера

Процедура ВыполнитьСканирование(Отказ, КлючПроекта, Пользователь)
	
	Если Не Отказ Тогда
		
		КомандныйФайл = Новый КомандныйФайл;
		КомандныйФайл.Создать();
		
		КомандныйФайл.ДобавитьКоманду(СтрШаблон("%1:", Параметры["РабочийДиск"]));
		КомандныйФайл.ДобавитьКоманду(СтрШаблон("cd %1", Параметры["РабочийКаталог"]));
		
		Токен = ЗначениеИзТекста(Пользователь, ПрочитатьФайл(Параметры["ФайлТокенов"]));
		
		Если Не ЗначениеЗаполнено(Токен) Тогда
			
			Отказ = Истина;
			Мониторинг.КритическаяОшибка("Не найден токен пользователя!");
			Возврат;
			
		КонецЕсли;
		
		ПараметрКлючПроекта = СтрШаблон("-Dsonar.projectKey=%1", КлючПроекта);
		ПараметрТокен = СтрШаблон("-Dsonar.login=%1", Токен);
		
		ПараметрыСканера = СтрШаблон("%1 %2", ПараметрКлючПроекта, ПараметрТокен);
		
		КомандныйФайл.ДобавитьКоманду(СтрШаблон("%1 %2", Параметры["РасположениеСканера"], ПараметрыСканера));
		
		КодВозврата = КомандныйФайл.Исполнить();
		Если КодВозврата = 0 Тогда
			
			Мониторинг.Отладка("Сканирование sonar выполнено");
			
		Иначе
			
			Мониторинг.Ошибка("Ошибка при выполнении sonar сканирования!");
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ВыгрузкаВнешнихОбработок

Процедура ВыгрузитьВнешниеОбработки(Отказ)
	
	Если Не Отказ Тогда
		
		Команда = Новый Команда;
		
		Команда.УстановитьКоманду(Параметры["ПутьДляЗапуска1С"]);
		Команда.ДобавитьПараметр("ENTERPRISE");
		Команда.ДобавитьПараметр(СтрШаблон("/S %1\%2", Параметры["ИмяСервера"], Параметры["ИмяБазы"]));
		Команда.ДобавитьПараметр(СтрШаблон("/N %1", Параметры["ПользовательИБ"]));
		Команда.ДобавитьПараметр(СтрШаблон("/P %1", Параметры["ПарольИБ"]));
		Команда.ДобавитьПараметр(СтрШаблон("/Execute %1", Параметры["ОбработкаВыгрузкиОбработок"]));
		Команда.ДобавитьПараметр("/DisableStartupMessages");
		
		КодВозврата = Команда.Исполнить();
		Если КодВозврата = 0 Тогда
			
			Мониторинг.Отладка("Внешние отчеты и обработки выгружены");
			
		Иначе
			
			Отказ = Истина;
			Мониторинг.КритическаяОшибка("Ошибка при выгрузке внешних отчетов и обработок");
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область Дополнительно

Функция ПрочитатьФайл(АдресФайла)
	
	ЧтениеТекста = Новый ЧтениеТекста();
	ЧтениеТекста.Открыть(АдресФайла);
	ТекстФайла = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	
	Возврат ТекстФайла;
	
КонецФункции

Функция ЗначениеИзТекста(Ключ, Текст)
	
	ПозицияНачала = СтрНайти(Текст, Ключ);
	Если ПозицияНачала = 0 Тогда
		
		Возврат "";
		
	КонецЕсли;
	
	ОбрезокТекста = Прав(Текст, СтрДлина(Текст) - ПозицияНачала - СтрДлина(Ключ));
	ИскомоеЗначение = Лев(ОбрезокТекста, СтрНайти(ОбрезокТекста, Символы.ПС) - 1);
	
	Возврат ИскомоеЗначение;
	
КонецФункции

#КонецОбласти

#Область ЗаключительныеОперации

Процедура ЗавершитьВыполнение(Отказ)
	
	Мониторинг.УстановитьНулевойУровень();
	
	Если Не Отказ Тогда
		
		Мониторинг.Информация("Деплой выполнен успешно");
		
	Иначе
		
		Мониторинг.Информация("Во время деплоя произошла ошибка!");
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ОбработатьИсключение(ТекстОшибки)
	
	Мониторинг.УвеличитьУровень();
	Мониторинг.Внимание(ТекстОшибки);
	Мониторинг.УстановитьНулевойУровень();
	Мониторинг.КритическаяОшибка("Во время деплоя произошла ошибка!");
	Мониторинг.Информация("Деплой остановлен из-за ошибки!");
	
КонецПроцедуры

#КонецОбласти

ПрочитатьПараметрыИзФайла();
ИнициализироватьМониторинг();
ИнициализироватьГит();
Отказ = Ложь;

Попытка
	
	ПодключитьУправлениеКластером();
	ОтключитьПользователейИБ();
	ОтключитьСоединенияИнформационнойБазы();
	
	УстановитьКонтекстКонфигурации();
	
	ПерейтиВВеткуГИТ(Отказ, Параметры["ИмяВеткиРабочая"]);
	УстановитьДампКонфигурации(Отказ, Параметры["ИмяВеткиРабочая"], Параметры["ДампКонфигурацииРабочая"]);
	ВыполнитьДеплой(Отказ, Параметры["КлючПроектаРабочая"], Параметры["ИмяВеткиРабочая"],
		Параметры["ДампКонфигурацииРабочая"], Параметры["РабочееХранилище"]);
	
	ЗавершитьВыполнение(Отказ);
	
Исключение
	
	ОбработатьИсключение(ОписаниеОшибки());
	
КонецПопытки;