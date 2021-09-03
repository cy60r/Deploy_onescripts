#Использовать ReadParams
#Использовать monitoring
#Использовать Tmail
#Использовать sql
#Использовать gitrunner
#Использовать xml-parser
#Использовать tempfiles
#Использовать 1commands
#Использовать Ext_v8runner
#Использовать Ext_v8storage
#Использовать Ext_v8rac

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
// Учетная запись электронной почты для отправки писем
Перем ИнтернетПочта;

#Область НачальныеНастройки

Процедура ПрочитатьПараметрыИзФайла()
	
	УстановитьТекущийКаталог("C:\scripts\Deploy_UPP_develop");
	Параметры = ЧтениеПараметров.Прочитать(ОбъединитьПути(ТекущийКаталог(), "Deploy_UPP_develop.json"));
	
КонецПроцедуры

Процедура ИнициализироватьМониторинг()

	Мониторинг = Новый УправлениеМониторингом();
	Мониторинг.УстановитьПараметрыМониторинга(Параметры["АдресZabbix"]);
	Мониторинг.УстановитьПараметрыЭлементаДанных(Параметры["УзелZabbix"], Параметры["КлючZabbix"]);
	Мониторинг.СоздатьФайлЛога(Параметры["ИмяЛога"], Параметры["КаталогЛога"]);
	Мониторинг.Информация("Начало выполнения деплоя");
	Мониторинг.УвеличитьУровень();
	
КонецПроцедуры

Процедура ИнициализироватьПочту()
	
	ИнтернетПочта = Новый ТУправлениеЭлектроннойПочтой();
	
	УчетнаяЗаписьЭП = ИнтернетПочта.УчетнаяЗаписьЭП;
	УчетнаяЗаписьЭП.АдресSMTP = Параметры["АдресSMTP"];
	УчетнаяЗаписьЭП.ПортSMTP = 25;
	Мониторинг.Отладка("Электронная почта подключена");
	
КонецПроцедуры

Процедура УстановитьКонтекстКонфигурации()
		
	Конфигуратор = Новый УправлениеКонфигуратором();
	Конфигуратор.ИспользоватьВерсиюПлатформы(Параметры["ВерсияПлатформы"], РазрядностьПлатформы.x64x86);
	Конфигуратор.УстановитьКонтекст("/S" + Параметры["ИмяСервера"] + "\" + Параметры["ИмяБазы"],
		Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
	Мониторинг.Отладка("Контекст конфигуратора деплоя установлен");
	
КонецПроцедуры

#КонецОбласти

#Область РаботаСХранилищем
Функция ТаблицаВерсийХранилища(НомерНачальнойВерсии, ПутьКХранилищу)
	
	ХранилищеКонфигурации = Новый МенеджерХранилищаКонфигурации( , Конфигуратор);
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
		
		Если ТаблицаВерсий.Количество() = 0 Тогда
			
			Мониторинг.Информация("Новых версий не обнаружено!");
			УдалитьФайлы(Мониторинг.ПолучитьИмяФайлаЛога());
			ЗавершитьРаботу(0);
			
		КонецЕсли;
		
		УстановитьДампКонфигурации(Отказ, Параметры["ИмяВеткиРазработки"], Параметры["ДампКонфигурацииРазработка"]);

		Мониторинг.УвеличитьУровень();
		
		Для каждого Строка Из ТаблицаВерсий Цикл
			
			Если Не Отказ Тогда
				
				НомерВерсии = Строка.Номер;
				ВыгрузитьВИсходникиИнкрементно(Отказ, НомерВерсии, ПутьКХранилищу);
				ЗаписатьИнформациюОНовойВерсии(Отказ, НомерВерсии);
				СделатьКоммитВерсии(Отказ, Строка, ТекстФайлаАвторов);
				СохранитьДампКонфигурации(Отказ, ИмяВетки, Дамп);
				ВыполнитьОперацииВФоне(Отказ, КлючПроекта, Строка.Автор, ТекстФайлаАвторов);
				ОтправитьГИТ(Отказ);
				Мониторинг.УменьшитьУровень();
				
			Иначе
				
				Возврат;
				
			КонецЕсли;
			
		КонецЦикла;
		
		Мониторинг.УменьшитьУровень();
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ВыполнитьОперацииВФоне(Отказ, КлючПроекта, Автор, ТекстФайлаАвторов)

	МассивПараметров = МассивПараметровДляВыполненияФоновыхЗаданий(Отказ, КлючПроекта, Автор);
	ФоновыеЗадания.Выполнить(ЭтотОбъект, "ВыполнитьСканирование", МассивПараметров);

	МассивПараметров = МассивПараметровДляВыполненияФоновыхЗаданий(Отказ, Автор, ТекстФайлаАвторов);
	ФоновыеЗадания.Выполнить(ЭтотОбъект, "ВыполнитьДымовыеТесты", МассивПараметров);

	Попытка
		
		ФоновыеЗадания.ОжидатьЗавершенияЗадач();

	Исключение
		
		МассивОшибок = ИнформацияОбОшибке().Параметры;
		Если МассивОшибок <> Неопределено Тогда
			
			Для Каждого Задание Из МассивОшибок Цикл
				
				Отказ = Истина;
				Мониторинг.Внимание(Задание.ИнформацияОбОшибке.Описание);
				Мониторинг.КритическаяОшибка("Ошибка при выполнении фоновых заданий!");

			КонецЦикла;

		КонецЕсли;

	КонецПопытки;

КонецПроцедуры

Функция МассивПараметровДляВыполненияФоновыхЗаданий(Параметр1 = Неопределено, Параметр2 = Неопределено, 
	Параметр3 = Неопределено)

	МассивПараметров = Новый Массив;

	Если Параметр1 <> Неопределено Тогда
	
		МассивПараметров.Добавить(Параметр1);

	КонецЕсли;

	Если Параметр2 <> Неопределено Тогда
	
		МассивПараметров.Добавить(Параметр2);

	КонецЕсли;

	Если Параметр3 <> Неопределено Тогда
	
		МассивПараметров.Добавить(Параметр3);

	КонецЕсли;

	Возврат МассивПараметров;

КонецФункции

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

		Конфигуратор.ОбновитьКонфигурациюБазыДанных();
		Мониторинг.Отладка("Конфигурация обновлена");
				
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

Процедура ВыполнитьСканирование(Отказ, КлючПроекта, Пользователь) Экспорт
	
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
			
			Мониторинг.Ошибка("Ошибка при выполнении сканирования sonar!");
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ДымовыеТесты

Процедура ВыполнитьДымовыеТесты(Отказ, Автор, ТекстФайлаАвторов) Экспорт
	
	Если Не Отказ Тогда
		
		ИмяФайлаОтчета = ИмяФайлаОтчетаТестирования();
		
		Команда = Новый Команда;
		ПараметрыВхода = СтрШаблон("/IBConnectionString Srvr=%1;Ref=%2 /N %3 /P %4",
				Параметры["ИмяСервера"], Параметры["ИмяБазы"], Параметры["ПользовательИБ"], Параметры["ПарольИБ"]);
		ПараметрОбработки = СтрШаблон("/Execute %1 /C """, Команда.ОбернутьВКавычки(Параметры["ОбработкаЗапускаТестов"]));
		ПараметрКонфига = СтрШаблон("xddConfig %1;", ДопПараметрОбработки(Параметры["ФайлКонфигурацииТестов"]));
		ПараметрКаталога = СтрШаблон("xddRun ЗагрузчикКаталога %1;", ДопПараметрОбработки(Параметры["КаталогТестов"]));
		ПараметрОтчета = СтрШаблон("xddReport ГенераторОтчетаMXL %1;", ДопПараметрОбработки(ИмяФайлаОтчета));
		ПараметрЗакрытия = СтрШаблон("%1;""", Параметры["ПараметрЗакрытия"]);
		
		Команда.УстановитьКоманду(Параметры["ПутьДляЗапуска1С"]);
		Команда.ДобавитьПараметр(Параметры["ПараметрПриложения"]);
		Команда.ДобавитьПараметр(ПараметрыВхода);
		Команда.ДобавитьПараметр(Параметры["ПараметрыЗапуска"]);
		Команда.ДобавитьПараметр(ПараметрОбработки);
		Команда.ДобавитьПараметр(ПараметрКонфига);
		Команда.ДобавитьПараметр(ПараметрКаталога);
		Команда.ДобавитьПараметр(ПараметрОтчета);
		Команда.ДобавитьПараметр(ПараметрЗакрытия);
		
		КодВозврата = Команда.Исполнить();
		Если КодВозврата = 0 Тогда
			
			Мониторинг.Отладка("Дымовые тесты выполнены");
			ТекстСообщения = ТекстСообщенияРезультатовТестов(ИмяФайлаОтчета);
			Если ЗначениеЗаполнено(ТекстСообщения) Тогда
				
				ОтправитьОтчетТестирования(ТекстСообщения, Автор, ТекстФайлаАвторов, ИмяФайлаОтчета);
				
			Иначе
				
				УдалитьФайлы(ИмяФайлаОтчета);
				
			КонецЕсли;
			
		Иначе
			
			Мониторинг.Ошибка("Ошибка выполнения дымовых тестов");
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

Функция ИмяФайлаОтчетаТестирования()
	
	НаименованиеФайла = Формат(ТекущаяДата(), "ДФ=dd_MM_yyyy_ЧЧ_мм_сс") + "_smoke_report.txt";
	ИмяФайла = ОбъединитьПути(Параметры["КаталогЛоговТестов"], НаименованиеФайла);
	НовыйТекстовыйФайл = Новый ТекстовыйДокумент();
	НовыйТекстовыйФайл.Записать(ИмяФайла);
	Возврат ИмяФайла;
	
КонецФункции

Функция ДопПараметрОбработки(Знач Строка) Экспорт
	
	Пока СтрНайти(Строка, "/") <> 0 Цикл
		
		Строка = СтрЗаменить(Строка, "/", "\");
		
	КонецЦикла;
	
	Возврат """""" + Строка + """""";
	
КонецФункции

Функция ТекстСообщенияРезультатовТестов(ИмяФайла)
	
	ТекстовыйФайл = Новый ЧтениеТекста(ИмяФайла);
	Сообщение = ТекстовыйФайл.ПрочитатьСтроку();
	ТекстовыйФайл.Закрыть();
	
	Возврат Сообщение;
	
КонецФункции

#КонецОбласти

#Область ИнтернетПочта

Процедура ОтправитьОтчетТестирования(ТекстСообщения, Автор, ТекстФайлаАвторов, ИмяФайлаОтчета)
	
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыПолучателя = АдресПочтыАвтора(Автор, ТекстФайлаАвторов);
	
	СтруктураСообщения = ИнтернетПочта.СтруктураСообщения;
	СтруктураСообщения.АдресЭлектроннойПочтыОтправителя = Параметры["АдресОтправителя"];
	СтруктураСообщения.ТемаСообщения = Параметры["ТемаПисьмаТесты"];
	
	СтруктураСообщения.ТипТекстаПочтовогоСообщения = "Строка";
	СтруктураСообщения.Вставить("ТекстСообщения", ТекстСообщения);
	
	СтруктураСообщения.Вложения = ИмяФайлаОтчета;
	
	Если ИнтернетПочта.ОтправитьСообщение() Тогда
		
		Мониторинг.Отладка("Ошибки дымовых тестов отправлены");
		
	Иначе
		
		Мониторинг.УвеличитьУровень();
		Мониторинг.Внимание(ИнтернетПочта.ТекстОшибки);
		Мониторинг.Ошибка("Ошибка при отправке письма о выполнении дымовых тестов");
		Мониторинг.УменьшитьУровень();
		
	КонецЕсли;
	
КонецПроцедуры

Функция АдресПочтыАвтора(Автор, Текст)
	
	ПолноеИмяАвтора = ЗначениеИзТекста(Автор, Текст);
	
	ПозицияНачала = СтрНайти(ПолноеИмяАвтора, "<");
	ПозицияОкончания = СтрНайти(ПолноеИмяАвтора, ">");
	
	АдресПочты = Сред(ПолноеИмяАвтора, ПозицияНачала + 1, ПозицияОкончания - ПозицияНачала - 1);
	
	Возврат АдресПочты;
	
КонецФункции

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
ИнициализироватьПочту();
Отказ = Ложь;

Попытка

	УстановитьКонтекстКонфигурации();
	ПерейтиВВеткуГИТ(Отказ, Параметры["ИмяВеткиРазработки"]);

	ВыполнитьДеплой(Отказ, Параметры["КлючПроектаРазработка"], Параметры["ИмяВеткиРазработки"],
		Параметры["ДампКонфигурацииРазработка"], Параметры["ХранилищеРазработки"]);
	
	ЗавершитьВыполнение(Отказ);
	
Исключение
	
	ОбработатьИсключение(ОписаниеОшибки());
	
КонецПопытки;