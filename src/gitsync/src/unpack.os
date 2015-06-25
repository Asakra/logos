﻿///////////////////////////////////////////////////////////////////////////////////////////////
//
// Модуль основан на проекте v83unpack (https://github.com/xDrivenDevelopment/v83unpack)
// и является скорее глубоким рефакторингом под 1Script, нежели самостоятельной разработкой.
//
// Использует также утилиту Tool_1CD от awa (http://infostart.ru/public/19633/)
//
///////////////////////////////////////////////////////////////////////////////////////////////

#Использовать tool1cd
#Использовать logos
#Использовать tempfiles
#Использовать v8runner
#Использовать strings

Перем Лог;
Перем мФайлПрограммыРаспаковки;

///////////////////////////////////////////////////////////////////////////////////////////////
// ПРОГРАММНЫЙ ИНТЕРФЕЙС


// Выполняет выгрузку конфигурации в файлы 
// и распределение файлов по каталогам согласно иерархии метаданных.
//
Процедура РазобратьФайлКонфигурации(Знач ФайлКонфигурации, Знач ВыходнойКаталог) Экспорт

	ОбъектФайл = Новый Файл(ФайлКонфигурации);
	Если Не ОбъектФайл.Существует() Тогда
		ВызватьИсключение СтроковыеФункции.ПодставитьПараметрыВСтроку("Файл конфигурации %1 не найден", ФайлКонфигурации.ПолноеИмя);
	КонецЕсли;

	КаталогПлоскойВыгрузки = ВременныеФайлы.СоздатьКаталог();
	
	Если Не (Новый Файл(ВыходнойКаталог).Существует()) Тогда
		СоздатьКаталог(ВыходнойКаталог);
	КонецЕсли;
	
	Попытка
		ВыгрузитьМодулиКонфигурации(ФайлКонфигурации, КаталогПлоскойВыгрузки);
		РазложитьМодули1СПоПапкамСогласноИерархииМетаданных(КаталогПлоскойВыгрузки, ВыходнойКаталог);
	Исключение
		ВременныеФайлы.УдалитьФайл(КаталогПлоскойВыгрузки);
		ВызватьИсключение;
	КонецПопытки;
	
	ВременныеФайлы.УдалитьФайл(КаталогПлоскойВыгрузки);

КонецПроцедуры

// Выполняет штатную выгрузку конфигурации в файлы (средствами платформы 8.3)
//
Процедура ВыгрузитьМодулиКонфигурации(Знач ФайлКонфигурации, Знач КаталогПлоскойВыгрузки) Экспорт
	
	Конфигуратор = ПолучитьМенеджерКонфигуратора();
	ЛогКонфигуратора = Логирование.ПолучитьЛог("oscript.lib.v8runner");
	ЛогКонфигуратора.УстановитьУровень(Лог.Уровень());
	
	Если Не (Новый Файл(КаталогПлоскойВыгрузки).Существует()) Тогда
		СоздатьКаталог(КаталогПлоскойВыгрузки);
	КонецЕсли;
	
	МассивФайлов = НайтиФайлы(КаталогПлоскойВыгрузки, ПолучитьМаскуВсеФайлы());
	Если МассивФайлов.Количество() <> 0 Тогда
		ВызватьИсключение "В каталоге <"+КаталогПлоскойВыгрузки+"> не должно быть файлов";
	КонецЕсли;
	
	ПараметрыЗапуска = Конфигуратор.ПолучитьПараметрыЗапуска();
	ПараметрыЗапуска.Добавить("/Visible");
	ПараметрыЗапуска.Добавить("/DumpConfigToFiles""" + КаталогПлоскойВыгрузки + """");
	
	ВыполнитьКомандуКонфигуратора(Конфигуратор, ПараметрыЗапуска);
	
КонецПроцедуры

Функция ПолучитьМенеджерКонфигуратора()
	Конфигуратор = Новый УправлениеКонфигуратором;
	КаталогСборки = ВременныеФайлы.СоздатьКаталог();
	Конфигуратор.КаталогСборки(КаталогСборки);
	Возврат Конфигуратор;
КонецФункции

Процедура ВыполнитьКомандуКонфигуратора(Знач Конфигуратор, Знач ПараметрыЗапуска)
	
	Попытка
		Конфигуратор.ВыполнитьКоманду(ПараметрыЗапуска);
	Исключение
		ВременныеФайлы.УдалитьФайл(Конфигуратор.КаталогСборки());
		ВызватьИсключение;
	КонецПопытки;
	
	ВременныеФайлы.УдалитьФайл(Конфигуратор.КаталогСборки());
	
КонецПроцедуры

// Выполняет перенос файлов из каталога плоской выгрузки в каталог с иерархической структурой метаданных.
//
Процедура РазложитьМодули1СПоПапкамСогласноИерархииМетаданных(Знач КаталогПлоскойВыгрузки, Знач КаталогИерархическойВыгрузки) Экспорт
	
	Лог.Информация("Раскладываем модули по папкам согласно иерархии метаданных");
	
	КэшПереименований = Новый Соответствие;
	
	УбедитьсяЧтоФайлИлиКаталогСуществует(КаталогПлоскойВыгрузки);
	
	Если ПустаяСтрока(КаталогИерархическойВыгрузки) Тогда
		ВызватьИсключение "Не задан каталог выгрузки модулей по иерархии";
	КонецЕсли;
	
	ФайлВыгрузкиКаталог = Новый Файл(КаталогИерархическойВыгрузки);
	Если Не ФайлВыгрузкиКаталог.Существует() Тогда
		СоздатьКаталог(КаталогИерархическойВыгрузки);
		//ЗарегистрироватьВременныйФайл(КаталогИерархическойСтруктурыМодулей); TODO выяснить почему временный?
	КонецЕсли;
	
	ЗавершитьПроцесс_TGitCache_exe();
	ОчиститьЦелевойКаталогВыгрузки(КаталогИерархическойВыгрузки);

	Переименования = Новый ТаблицаЗначений;
	Переименования.Колонки.Добавить("Источник");
	Переименования.Колонки.Добавить("Приемник");
	
	СписокФайлов = НайтиФайлы(КаталогПлоскойВыгрузки, ПолучитьМаскуВсеФайлы());
	Для Каждого Файл Из СписокФайлов Цикл
		Если Файл.ЭтоКаталог() Тогда
			ОбработатьКаталогРезультатаВыгрузки(Файл, КаталогИерархическойВыгрузки, Переименования);
			Продолжить;	
		КонецЕсли;
		
		ИмяФайла = СкорректироватьИмяФайлаМетаданных(Файл.ИмяБезРасширения);
		
		//Определим длину Наименования папки, по умолчанию не больше 60 символов.  
		Если СтрДлина(ИмяФайла)>144 Тогда
			СократитьДлинуИмениФайла(ИмяФайла, КаталогИерархическойВыгрузки);
		КонецЕсли;
		
		ИмяНовогоФайла = СтрЗаменить(ИмяФайла, ".", ПолучитьРазделительПути())+Файл.Расширение;
		НовыйФайл = Новый Файл(ОбъединитьПути(КаталогИерархическойВыгрузки, ИмяНовогоФайла));
		НовыйКаталог = Новый Файл(НовыйФайл.Путь);
		Если НЕ НовыйКаталог.Существует() Тогда
			СоздатьКаталог(НовыйКаталог.ПолноеИмя);
		КонецЕсли;
		
		ДобавитьПереименование(Переименования,Файл.Имя,ИмяНовогоФайла);
		
		КопироватьФайл(Файл.ПолноеИмя, НовыйФайл.ПолноеИмя);
		
		Если Прав(Файл.ПолноеИмя, 5) = ".Form" Тогда
			КаталогФормы = НовыйКаталог.ПолноеИмя+"\"+НовыйФайл.ИмяБезРасширения;
			СоздатьКаталог(КаталогФормы);
			РаспаковатьКонтейнерМетаданных(НовыйФайл.ПолноеИмя, КаталогФормы)
		КонецЕсли;
		
	КонецЦикла;
	
	ТекстовыйДокумент = Новый ЗаписьТекста(ОбъединитьПути(КаталогИерархическойВыгрузки, "renames.txt"));
	Для Каждого ЭлементСтроки Из Переименования Цикл
		ТекстовыйДокумент.ЗаписатьСтроку(ЭлементСтроки.Источник+"-->"+ЭлементСтроки.Приемник);
	КонецЦикла;
	ТекстовыйДокумент.Закрыть();
	
КонецПроцедуры

Процедура ОчиститьЦелевойКаталогВыгрузки(Знач КаталогИерархическойСтруктурыМодулей)
	
	СоответствиеИменФайловДляПропуска = Новый Соответствие;
	СоответствиеИменФайловДляПропуска.Вставить(".git", Истина);
	СоответствиеИменФайловДляПропуска.Вставить(ИмяФайлаАвторов(), Истина); //Соответствие авторов и транслитерации. 
	СоответствиеИменФайловДляПропуска.Вставить(ИмяФайлаВерсииХранилища(), Истина); //Номер версии, может использоватся для синхронизации с хранилищем. 
	
	//Удалим все каталоги с файлами в папке для разбора, кроме папки, начинающейся с с точки.
	ЕстьОшибкаУдаления = Ложь;
	Для НомерПопытки = 1 По 2 Цикл
		МассивФайлов = НайтиФайлы(КаталогИерархическойСтруктурыМодулей, ПолучитьМаскуВсеФайлы());
		Если МассивФайлов.Количество() = 0 Тогда
			Прервать;
		КонецЕсли;
		
		Для Каждого ЭлементМассива Из МассивФайлов Цикл
			Если СоответствиеИменФайловДляПропуска[ЭлементМассива.Имя] = Истина Тогда
				Продолжить;
			КонецЕсли;
			
			Попытка
				УдалитьФайлы(ЭлементМассива.ПолноеИмя);
			Исключение
				ЕстьОшибкаУдаления = Истина;
				Если НомерПопытки = 2 Тогда
					ВызватьИсключение;
				КонецЕсли;
			КонецПопытки;
		КонецЦикла;
		
		Если Не ЕстьОшибкаУдаления Тогда
			Прервать;
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ОбработатьКаталогРезультатаВыгрузки(Знач Файл, Знач КаталогИерархическойСтруктурыМодулей, Знач Переименования)
	Если Прав(Файл.Имя, 5) = "files" Тогда // файлы справки. 
		МассивФайлов = НайтиФайлы(Файл.ПолноеИмя, ПолучитьМаскуВсеФайлы());
		ИмяНовогоФайла = Лев(Файл.Имя, СтрДлина(Файл.Имя)-6);
		ИмяНовогоФайла = СтрЗаменить(ИмяНовогоФайла, ".", "\")+".del";
		НовыйФайл = Новый Файл(ОбъединитьПути(КаталогИерархическойСтруктурыМодулей, ИмяНовогоФайла));
		НовыйКаталог = Новый Файл(НовыйФайл.Путь);
		Если НЕ НовыйКаталог.Существует() Тогда
			СоздатьКаталог(НовыйКаталог.ПолноеИмя);
		КонецЕсли;
		НовыйФайл = Новый Файл(ОбъединитьПути(НовыйКаталог.ПолноеИмя, Файл.Имя));
		Если Не НовыйФайл.Существует() Тогда
			СоздатьКаталог(НовыйФайл.ПолноеИмя);
		КонецЕсли;
		Для Каждого ЭлементЦикла Из МассивФайлов Цикл
			ДобавитьПереименование(Переименования, 
				ОбъединитьПути(Файл.Имя, ЭлементЦикла.Имя), 
				СтрЗаменить(ОбъединитьПути(НовыйФайл.ПолноеИмя, ЭлементЦикла.Имя), КаталогИерархическойСтруктурыМодулей+ПолучитьРазделительПути(), ""));
		КонецЦикла;
	КонецЕсли;
КонецПроцедуры

Функция СкорректироватьИмяФайлаМетаданных(Знач ИмяФайла)

	Если Прав(ИмяФайла, 12) = "Форма.Модуль" Тогда
		ИмяФайла = Лев(ИмяФайла, СтрДлина(ИмяФайла)-12)+"МодульФормы";
	КонецЕсли;
	
	Если Прав(ИмяФайла, 6) = ".Макет" Тогда
		ИмяФайла = Лев(ИмяФайла, СтрДлина(ИмяФайла)-6);
	КонецЕсли;
	
	Если Прав(ИмяФайла, 17) = ".Картинка.Picture" Тогда
		ИмяФайла = Лев(ИмяФайла, СтрДлина(ИмяФайла)-17);
	КонецЕсли;
	
	Если Прав(ИмяФайла, 5) = ".Form" Тогда
		
	КонецЕсли;
	
	// Для 8.3 если файл содержит всего одну точку в имени, тогда создадим папки и туда его и кинем. 
	// 
	
	Если СтрЧислоВхождений(ИмяФайла, ".") = 1 Тогда
		//Увеличим наименование на Наименование объекта конфигурации описываемого. 
		НаименованиеОбъектаМетаданных = Сред(ИмяФайла, Найти(ИмяФайла, "."));
		ИмяФайла = СтрЗаменить(ИмяФайла, НаименованиеОбъектаМетаданных,НаименованиеОбъектаМетаданных+НаименованиеОбъектаМетаданных);
	КонецЕсли;
	
	Возврат ИмяФайла;
	
КонецФункции

Процедура СократитьДлинуИмениФайла(ИмяФайла, Знач КаталогИерархическойСтруктурыМодулей)
	
	КэшПереименований = Новый Соответствие;
	МассивИмен = СтроковыеФункции.РазложитьСтрокуВМассивПодстрок(ИмяФайла, ".");
				
	ИмяФайла = "";
	Счетчик = 0;
	КоличествоВсего = МассивИмен.Количество();
	Для Счетчик = 0 По КоличествоВсего-1 Цикл
		ЭлементМассива = МассивИмен.Получить(Счетчик);
		НовоеИмя = ЭлементМассива;
		ДлинаИменни = СтрДлина(ЭлементМассива);
		
		Если ДлинаИменни > 58 Тогда
			Лог.Отладка("Слишком длинное имя:"+ЭлементМассива +" длина:"+ДлинаИменни);
			
			Если КэшПереименований.Получить(ЭлементМассива) <> Неопределено Тогда
				НовоеИмя = КэшПереименований.Получить(ЭлементМассива);
			Иначе
				Разрядность = СтрДлина(Строка(ДлинаИменни));
				НовоеИмя = Лев(ЭлементМассива, 58-Разрядность-1)+"~"+ДлинаИменни;
				НовыйПутьПроверки = Новый Файл(КаталогИерархическойСтруктурыМодулей+"\"+ИмяФайла+НовоеИмя);
				Если НовыйПутьПроверки.Существует() Тогда
					СчетчикНовогоИмени = 0;
					МассивФайловСущуствующих = НайтиФайлы(КаталогИерархическойСтруктурыМодулей+"\"+ИмяФайла, Лев(ЭлементМассива, 58-Разрядность-3)+"*");
					СчетчикНовогоИмени = МассивФайловСущуствующих.Количество()+1;
					НовоеИмя = Лев(ЭлементМассива, 58-Разрядность-3)+"~"+ДлинаИменни+ФорматДвузначноеЧисло(Строка(СчетчикНовогоИмени));
				КонецЕсли;
				
				КэшПереименований.Вставить(ЭлементМассива, НовоеИмя);
			КонецЕсли;
			
			Лог.Отладка("Старое имя:"+ЭлементМассива +" новое имя:"+НовоеИмя);
		КонецЕсли;
		ИмяФайла=ИмяФайла+НовоеИмя+ПолучитьРазделительПути();
	КонецЦикла;
	ИмяФайла = ?(Прав(ИмяФайла,1)=ПолучитьРазделительПути(), Лев(ИмяФайла, СтрДлина(ИмяФайла)-1), ИмяФайла);
	
КонецПроцедуры

Процедура РаспаковатьКонтейнерМетаданных(Знач ФайлРаспаковки, Знач КаталогРаспаковки)
	ФайлДляРаспаковки = Новый файл(ФайлРаспаковки);
	Если КаталогРаспаковки = "" тогда
		КаталогРаспаковки = ВременныеФайлы.СоздатьКаталог();
	КонецЕсли;
	
	СтрокаЗапуска = """"+ФайлПрограммыРаспаковки()+""" -parse """+ФайлДляРаспаковки.ПолноеИмя+""" """+КаталогРаспаковки+"""";
	
	ЗапуститьПриложение(СтрокаЗапуска,,Истина);
	
КонецПроцедуры

// Выполняет чтение таблицы VERSIONS из хранилища 1С
//
// Возвращаемое значение: ТаблицаЗначений
//
Функция ПрочитатьТаблицуИсторииХранилища(Знач ФайлХранилища) Экспорт
	
	ЧтениеБазыДанных = Новый ЧтениеТаблицФайловойБазыДанных;
	ЧтениеБазыДанных.ОткрытьФайл(ФайлХранилища);
	Попытка
		ТаблицаБД = ЧтениеБазыДанных.ПрочитатьТаблицу("VERSIONS");
	Исключение
		ЧтениеБазыДанных.ЗакрытьФайл();
		ВызватьИсключение;
	КонецПопытки;
	
	ЧтениеБазыДанных.ЗакрытьФайл();
	
	ТаблицаВерсий = КонвертироватьТаблицуВерсийИзФорматаБД(ТаблицаБД);
	ТаблицаВерсий.Сортировать("НомерВерсии");
	
	Возврат ТаблицаВерсий;
	
КонецФункции

// Считывает таблицу USERS пользователей хранилища
//
Функция ПрочитатьТаблицуПользователейХранилища(Знач ФайлХранилища) Экспорт
	
	ЧтениеБазыДанных = Новый ЧтениеТаблицФайловойБазыДанных;
	ЧтениеБазыДанных.ОткрытьФайл(ФайлХранилища);
	Попытка
		ТаблицаБД = ЧтениеБазыДанных.ПрочитатьТаблицу("USERS");
	Исключение
		ЧтениеБазыДанных.ЗакрытьФайл();
		ВызватьИсключение;
	КонецПопытки;
	
	ЧтениеБазыДанных.ЗакрытьФайл();
	
	Возврат КонвертироватьТаблицуПользователейИзФорматаБД(ТаблицаБД);
	
КонецФункции

// Считывает из хранилища историю коммитов с привязкой к пользователям
//
Функция ПрочитатьИзХранилищаИсториюКоммитовСАвторами(Знач ФайлХранилища) Экспорт
	
	Перем ТаблицаВерсий;
	Перем ТаблицаПользователей;
	
	ЧтениеБазыДанных = Новый ЧтениеТаблицФайловойБазыДанных;
	ЧтениеБазыДанных.ОткрытьФайл(ФайлХранилища);
	Попытка
		Таблицы = ЧтениеБазыДанных.ВыгрузитьТаблицыВXML("USERS;VERSIONS");
		ТаблицаВерсий        = ЧтениеБазыДанных.ПрочитатьТаблицуИзXml(Таблицы["VERSIONS"]);
		ТаблицаПользователей = ЧтениеБазыДанных.ПрочитатьТаблицуИзXml(Таблицы["USERS"]);
	Исключение
		ЧтениеБазыДанных.ЗакрытьФайл();
		ВызватьИсключение;
	КонецПопытки;
	
	ЧтениеБазыДанных.ЗакрытьФайл();
	
	ТаблицаВерсий = КонвертироватьТаблицуВерсийИзФорматаБД(ТаблицаВерсий);
	ТаблицаПользователей = КонвертироватьТаблицуПользователейИзФорматаБД(ТаблицаПользователей);
	
	ДополнитьТаблицуВерсийИменамиАвторов(ТаблицаВерсий, ТаблицаПользователей);
	ТаблицаВерсий.Сортировать("НомерВерсии");
	
	Возврат ТаблицаВерсий;
	
КонецФункции

Функция КонвертироватьТаблицуВерсийИзФорматаБД(Знач ТаблицаБД)
	
	ТаблицаВерсий = НоваяТаблицаИсторииВерсий();
	
	Для Каждого СтрокаБД Из ТаблицаБД Цикл
		
		НоваяСтрока = ТаблицаВерсий.Добавить();
		НоваяСтрока.НомерВерсии = Число(СтрокаБД.VERNUM);
		НоваяСтрока.ГУИД_Автора = СтрокаБД.USERID;
		НоваяСтрока.Тэг = СтрокаБД.CODE;

		Дата = СтрЗаменить(СтрЗаменить(СтрокаБД.VERDATE, "-", ""), ":", "");
		Дата = СтрЗаменить(Дата, "T", "");
		Дата = Дата(Дата);
		НоваяСтрока.Дата = Дата;
		НоваяСтрока.Комментарий = СтрокаБД.COMMENT;
		
	КонецЦикла;
	
	Возврат ТаблицаВерсий;
КонецФункции

Функция КонвертироватьТаблицуПользователейИзФорматаБД(Знач ТаблицаБД)
	ТаблицаПользователей = НоваяТаблицаПользователейХранилища();
	
	Для Каждого СтрокаБД Из ТаблицаБД Цикл
		
		НоваяСтрока = ТаблицаПользователей.Добавить();
		НоваяСтрока.Автор       = СтрокаБД.NAME;
		НоваяСтрока.ГУИД_Автора = СтрокаБД.USERID;
		
	КонецЦикла;
	
	Возврат ТаблицаПользователей;
	
КонецФункции

Функция НоваяТаблицаИсторииВерсий()

	Таблица = Новый ТаблицаЗначений;
	Таблица.Колонки.Добавить("НомерВерсии");
	Таблица.Колонки.Добавить("ГУИД_Автора");
	Таблица.Колонки.Добавить("Автор");
	Таблица.Колонки.Добавить("Тэг");
	Таблица.Колонки.Добавить("Дата");
	Таблица.Колонки.Добавить("Комментарий");
	Таблица.Колонки.Добавить("ПредставлениеАвтора");
	
	Возврат Таблица;

КонецФункции

Функция НоваяТаблицаПользователейХранилища()
	
	Таблица = Новый ТаблицаЗначений;
	Таблица.Колонки.Добавить("Автор");
	Таблица.Колонки.Добавить("ГУИД_Автора");
	Таблица.Колонки.Добавить("ПредставлениеАвтора");
	
	Возврат Таблица;
	
КонецФункции

Процедура ДополнитьТаблицуВерсийИменамиАвторов(Знач ТаблицаВерсий, Знач ТаблицаПользователей)
	
	Для Каждого Строка Из ТаблицаВерсий Цикл
		строкаПользователя = ТаблицаПользователей.Найти(Строка.ГУИД_Автора, "ГУИД_Автора");
		Если строкаПользователя = Неопределено Тогда
			Сообщение = "Не удалось найти автора коммита из хранилища 1С по номеру версии <%1>, комментарий <%2>, ГУИД-у <%3> - ПолучитьТаблицуВерсийИзФайлаХранилища1С";
			Лог.Ошибка(СтроковыеФункции.ПодставитьПараметрыВСтроку(Сообщение, строка.НомерВерсии, строка.Комментарий, строка.ГУИД_Автора));
		Иначе
			строка.Автор = строкаПользователя.Автор;
		КонецЕсли; 
	КонецЦикла;
	
КонецПроцедуры


// Генерирует файл соответствия пользователей хранилища 1С и git
//
Процедура СформироватьПервичныйФайлПользователейДляGit(Знач ИмяФайлаХранилища, Знач ВыходнойФайл, Знач ДоменПочтыДляGit = "localhost") Экспорт

	резПутьКХМЛФайлуВерсийХранилища1С = "";
	резПутьКХМЛФайлуПользователейХранилища1С = "";
	
	Лог.Отладка("Формируем первичный файл авторов:
	| Файл хранилища: " + ИмяФайлаХранилища + "
	| Выходной файл: " + ВыходнойФайл);
	
	ТаблицаПользователейХранилища = ПрочитатьТаблицуПользователейХранилища(ИмяФайлаХранилища);
	ЗаписатьТаблицуПользователейВФайлАвторовGit(ТаблицаПользователейХранилища, ВыходнойФайл, ДоменПочтыДляGit);
	
КонецПроцедуры

Процедура ЗаписатьТаблицуПользователейВФайлАвторовGit(Знач ТаблицаПользователейХранилища, Знач ВыходнойФайл, Знач ДоменПочтыДляGit)

	ЗаписьФайла = Новый ЗаписьТекста(ВыходнойФайл, "utf-8");
	Попытка
		ШаблонЗаписи = "%1=%1 <%1@%2>";
		Для Каждого Запись Из ТаблицаПользователейХранилища Цикл
			СтрокаДляЗаписи = СтроковыеФункции.ПодставитьПараметрыВСтроку(ШаблонЗаписи, Запись.Автор, ДоменПочтыДляGit);
			ЗаписьФайла.ЗаписатьСтроку(СтрокаДляЗаписи);
		КонецЦикла;
		
		ЗаписьФайла.Закрыть();
	Исключение
		ОсвободитьОбъект(ЗаписьФайла);
		ВызватьИсключение;
	КонецПопытки;
	
КонецПроцедуры

// Определяет необходимость синхронизации хранилища и репо GIT.
//
Функция ТребуетсяСинхронизироватьХранилищеСГит(Знач ФайлХранилища, Знач ЛокальныйКаталогГит) Экспорт
	
	ТаблицаВерсий = ПрочитатьТаблицуИсторииХранилища(ФайлХранилища);
	ТекущаяВерсия = НомерСинхронизированнойВерсии(ЛокальныйКаталогГит);
	МаксимальнаяВерсияДляРазбора = ОпределитьМаксимальнуюВерсиюВХранилище(ТаблицаВерсий);
	
	Лог.Информация("Номер синхронизированной версии: " + ТекущаяВерсия);
	Лог.Информация("Номер последней версии в хранилище: " + МаксимальнаяВерсияДляРазбора);
	
	Возврат ТекущаяВерсия < МаксимальнаяВерсияДляРазбора;
	
КонецФункции

Функция НомерСинхронизированнойВерсии(Знач КаталогВыгрузки)
	
	ПутьФайлаВерсий = ОбъединитьПути(КаталогВыгрузки, ИмяФайлаВерсииХранилища());
	
	ТекущаяВерсия = ПрочитатьФайлВерсийГит(ПутьФайлаВерсий);
	Если ТекущаяВерсия <> Неопределено Тогда		
		Попытка
			ТекущаяВерсия=Число(ТекущаяВерсия);
		Исключение
			ТекущаяВерсия = 0;
		КонецПопытки;
	Иначе
		ТекущаяВерсия = 0;
	КонецЕсли;
	
	Возврат ТекущаяВерсия;
	
КонецФункции

Функция ПрочитатьФайлВерсийГит(Знач ПутьКФайлуВерсий)
	
	Перем Версия;
	
	Если Не Новый Файл(ПутьКФайлуВерсий).Существует() Тогда
		ВызватьИсключение "Файл с версией ГИТ <"+ПутьКФайлуВерсий+"> не существует";
	КонецЕсли;
	
	ЧтениеXML = Новый ЧтениеXML;
	ЧтениеXML.ОткрытьФайл(ПутьКФайлуВерсий);

	Пока ЧтениеXML.Прочитать() Цикл 
		Если ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента И ЧтениеXML.Имя = "VERSION" Тогда 

			Если Не ЧтениеXML.Прочитать() Тогда
				ВызватьИсключение "Чтение файла версий, у элемента Version нет текста";
			КонецЕсли;
			
			Если Не ЧтениеXML.ТипУзла = ТипУзлаXML.Текст Тогда
				ВызватьИсключение "Чтение файла версий, у элемента Version нет текста";
			КонецЕсли;

			Версия = ЧтениеXML.Значение;
			Лог.Отладка("Предыдущая версия из хранилища 1С: "+Версия);

			лРезультат = Истина;
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ЧтениеXML.Закрыть();

	Возврат Версия;
	
КонецФункции

Функция ОпределитьМаксимальнуюВерсиюВХранилище(Знач ТаблицаИсторииХранилища)
	
	Если ТаблицаИсторииХранилища.Количество() = 0 Тогда
		Возврат 0;
	КонецЕсли;
	
	МаксимальнаяВерсия = Число(ТаблицаИсторииХранилища[0].НомерВерсии);
	Для Сч = 1 По ТаблицаИсторииХранилища.Количество()-1 Цикл
		ЧислоВерсии = Число(ТаблицаИсторииХранилища[Сч].НомерВерсии);
		Если ЧислоВерсии > МаксимальнаяВерсия Тогда
			МаксимальнаяВерсия = ЧислоВерсии;
		КонецЕсли;
	КонецЦикла;
	
	Возврат МаксимальнаяВерсия;
	
КонецФункции

////////////////////////////////////////////////////////////////////////////////////////////////
// Общие функции

Функция ФайлПрограммыРаспаковки()

	Если мФайлПрограммыРаспаковки = Неопределено Тогда
		КаталогДвоичныхФайлов = ОбъединитьПути(ТекущийСценарий().Каталог, "bin");
		ФайлПрограммы = Новый Файл(ОбъединитьПути(КаталогДвоичныхФайлов, "UnpackV8.exe"));
		Если Не ФайлПрограммы.Существует() Тогда
			ВызватьИсключение СтроковыеФункции.ПодставитьПараметрыВСтроку("Не обнаружен файл программы распаковки: <%1>", ФайлПрограммы.ПолноеИмя);
		КонецЕсли;
		
		ФайлZLib = Новый Файл(ОбъединитьПути(КаталогДвоичныхФайлов, "zlib1.dll"));
		Если Не ФайлZLib.Существует() Тогда
			ВызватьИсключение СтроковыеФункции.ПодставитьПараметрыВСтроку("Не обнаружена библиотека zlib1: <%1>", ФайлZLib.ПолноеИмя);
		КонецЕсли;
		
		мФайлПрограммыРаспаковки = ФайлПрограммы.ПолноеИмя;
		
	КонецЕсли;
	
	Возврат мФайлПрограммыРаспаковки;

КонецФункции

Функция ИмяФайлаАвторов() Экспорт
	Возврат "AUTHORS";
КонецФункции

Функция ИмяФайлаВерсииХранилища() Экспорт
	Возврат "VERSION"
КонецФункции

Процедура ЗаписатьФайлВерсийГит(Знач КаталогФайлаВерсий, Знач Версия = "") Экспорт 
	
	ПутьКФайлуВерсий = ОбъединитьПути(КаталогФайлаВерсий, ИмяФайлаВерсииХранилища());
	Лог.Отладка("ПутьКФайлуВерсий =<"+ПутьКФайлуВерсий+">");
	Попытка
		Запись = Новый ЗаписьТекста(ПутьКФайлуВерсий, "utf-8");
		Запись.ЗаписатьСтроку("<?xml version=""1.0"" encoding=""UTF-8""?>");
		Запись.ЗаписатьСтроку("<VERSION>" + Версия + "</VERSION>");
		Запись.Закрыть();
	Исключение
		Если Запись <> Неопределено Тогда
			ОсвободитьОбъект(Запись);
		КонецЕсли;
		ВызватьИсключение;
	КонецПопытки;
	
КонецПроцедуры

Функция ДобавитьПереименование(Знач Переименования, Знач Источник, Знач Приемник)

	СтрокаПереименования = Переименования.Добавить();
	СтрокаПереименования.Источник = Источник;
	СтрокаПереименования.Приемник = Приемник;
	
	Возврат СтрокаПереименования;

КонецФункции

///////////////////////////////////////////////////////////////////////////////////////////////
// Вспомогательные функции

Процедура УбедитьсяЧтоФайлИлиКаталогСуществует(Знач Путь)
	
	Файл = Новый Файл(Путь);
	Если Не Файл.Существует() Тогда
		ВызватьИсключение СтроковыеФункции.ПодставитьПараметрыВСтроку("Файл <%1> должен существовать", Путь);
	КонецЕсли;
	
КонецПроцедуры

Функция ЗапуститьПриложениеИДождатьсяЗавершения(Знач СтрокаЗапуска, Знач ТекущийКаталог = "\.") 
	
	рез = -1;

	Попытка
		КодВозврата = "";
		ЗапуститьПриложение(СтрокаЗапуска, ТекущийКаталог, Истина, КодВозврата);
		рез = КодВозврата;
	Исключение
		// Для x64 ОС
		СтрокаЗапуска = "%windir%\Sysnative\" + СтрокаЗапуска;
		КодВозврата = "";
		ЗапуститьПриложение(СтрокаЗапуска, ТекущийКаталог, Истина, КодВозврата);
		рез = КодВозврата;
	КонецПопытки;
		
	Возврат рез;
	
КонецФункции // ЗапуститьПриложениеИДождатьсяЗавершения()

Процедура ЗавершитьПроцесс_TGitCache_exe()
	СтрокаКоманды = "taskkill /im TGitCache.exe  /T /F";
	Лог.Отладка("ЗавершитьПроцесс_TGitCache_exe: команда "+ СтрокаКоманды);

	ЗапуститьПриложениеИДождатьсяЗавершения(СтрокаКоманды);
КонецПроцедуры

Функция ФорматДвузначноеЧисло(ЗначениеЧисло)
	С = Строка(ЗначениеЧисло);
	Если СтрДлина(С) < 2 Тогда
		С = "0" + С;
	КонецЕсли;
	
	Возврат С;
КонецФункции

//////////////////////////////////////////////////////////////////////////////////////////////

Лог = Логирование.ПолучитьЛог("oscript.app.gitsync");