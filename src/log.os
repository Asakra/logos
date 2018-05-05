﻿//////////////////////////////////////////////////////////////////////////
//
// LOGOS: реализация логирования в стиле log4j для OneScript
//
//////////////////////////////////////////////////////////////////////////

Перем мТекущийУровень;
Перем мСпособыВывода;
Перем мСпособВыводаЗаданВручную;
Перем мУровниАппендеров;

Перем мИдентификатор;
Перем мРаскладкаСообщения;

Функция Уровень() Экспорт
	Возврат мТекущийУровень;
КонецФункции

Процедура УстановитьУровень(Знач Уровень) Экспорт
	Если Уровень < 0 или Уровень > УровниЛога.Отключить Тогда
		ВызватьИсключение "Неверное значение аргумента 'Уровень'";
	КонецЕсли;

	мТекущийУровень = Уровень;

	Если ЗначениеЗаполнено(мУровниАппендеров) Тогда
		Для каждого КлючЗначение Из мУровниАппендеров Цикл
			СпособВывода = КлючЗначение.Ключ;
			НастройкаСпособаВывода = КлючЗначение.Значение;
			Если Не НастройкаСпособаВывода.ЗаданЯвно Тогда
				НастройкаСпособаВывода.Уровень = Уровень;
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;


КонецПроцедуры

Процедура УстановитьРаскладку(Знач Раскладка) Экспорт
	мРаскладкаСообщения = Раскладка;
КонецПроцедуры

Процедура Закрыть() Экспорт
	Для Каждого СпособВывода Из мСпособыВывода Цикл
		СпособВывода.Закрыть();
	КонецЦикла;
	мСпособыВывода.Очистить();
	мУровниАппендеров.Очистить();
КонецПроцедуры

Процедура ДобавитьСпособВывода(Знач СпособВывода, Знач НовыйУровеньСпособаВывода = Неопределено) Экспорт

	Если Не мСпособВыводаЗаданВручную Тогда
		Закрыть();
		мСпособВыводаЗаданВручную = Истина;
	КонецЕсли;

	мСпособыВывода.Добавить(СпособВывода);

	Если НовыйУровеньСпособаВывода <> Неопределено Тогда
		НовыйУровень = НовыйУровеньСпособаВывода;
		ЗаданЯвно = Истина;
	Иначе
		НовыйУровень = Уровень();
		ЗаданЯвно = Ложь;
	КонецЕсли;
	
	НастройкаСпособаВывода = НоваяНастройкаСпособаВывода(НовыйУровень, ЗаданЯвно);
	мУровниАппендеров[СпособВывода] = НастройкаСпособаВывода;

	ПроверитьПоддержкуAPIВывести(СпособВывода, НастройкаСпособаВывода);

КонецПроцедуры

Процедура ПроверитьПоддержкуAPIВывести(СпособВывода, НастройкаСпособаВывода)
	Рефлектор = Новый Рефлектор;
	Методы = Рефлектор.ПолучитьТаблицуМетодов(СпособВывода);
	МетодВывести = Методы.Найти("Вывести");
	Сообщить("ПРоверка " + Методы.Количество());
	Если МетодВывести <> Неопределено Тогда
		Если МетодВывести.КоличествоПараметров = 2 Тогда
			Сообщить("Есть 2 параметра");
			НастройкаСпособаВывода.ВерсияAPI = 2;
		Иначе
			Сообщить("Число параметров:" + МетодВывести.КоличествоПараметров);
			СпособВывода.Вывести("Метод Вывести должен иметь 2 параметра.
			|В будущих версиях logos данный способ вывода перестанет работать.");
		КонецЕсли;
	Иначе
		Сообщить("Нет метода вывести в классе " + ТипЗнч(СпособВывода));
	КонецЕсли;
КонецПроцедуры

Процедура УдалитьСпособВывода(Знач СпособВывода) Экспорт

	Для Сч = 0 По мСпособыВывода.Количество()-1 Цикл
		Если мСпособыВывода[Сч] = СпособВывода Тогда
			мУровниАппендеров.Удалить(СпособВывода);
			СпособВывода.Закрыть();
			мСпособыВывода.Удалить(Сч);
			Прервать;
		КонецЕсли;
	КонецЦикла;

КонецПроцедуры

Функция УровеньСпособаВывода(Знач СпособВывода) Экспорт
	РезУровень = мУровниАппендеров[СпособВывода].Уровень;
	Возврат РезУровень;
КонецФункции

Функция ПолучитьИдентификатор() Экспорт
	Возврат мИдентификатор;
КонецФункции

Процедура Отладка(Знач Сообщение,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Вывести(Сообщение, УровниЛога.Отладка, Параметр1,
		Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);
КонецПроцедуры

Процедура Информация(Знач Сообщение,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Вывести(Сообщение, УровниЛога.Информация, Параметр1,
		Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);

КонецПроцедуры

Процедура Предупреждение(Знач Сообщение,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Вывести(Сообщение, УровниЛога.Предупреждение, Параметр1,
		Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);

КонецПроцедуры

Процедура Ошибка(Знач Сообщение,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Вывести(Сообщение, УровниЛога.Ошибка, Параметр1,
		Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);

КонецПроцедуры

Процедура КритичнаяОшибка(Знач Сообщение,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Вывести(Сообщение, УровниЛога.КритичнаяОшибка, Параметр1,
		Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);

КонецПроцедуры

Процедура Вывести(Знач Сообщение, Знач УровеньСообщения,
		Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено) Экспорт

	Если ЕстьЗаполненныеПараметры(Параметр1, Параметр2, Параметр3,
		Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9) Тогда
		
		Сообщение = СтрШаблон(Сообщение, Параметр1,
			Параметр2, Параметр3, Параметр4, Параметр5, Параметр6, Параметр7, Параметр8, Параметр9);
	КонецЕсли;

	Если УровеньСообщения >= Уровень() Тогда
		ВыводимоеСообщение = мРаскладкаСообщения.Форматировать(УровеньСообщения, Сообщение);
		Для Каждого СпособВывода Из мСпособыВывода Цикл
			НастройкаАппендера = мУровниАппендеров[СпособВывода];
			УровеньСпособаВывода = НастройкаАппендера.Уровень;
			Если УровеньСпособаВывода = Неопределено Или УровеньСообщения >= УровеньСпособаВывода Тогда
				Если НастройкаАппендера.ВерсияAPI = 2 Тогда
					СпособВывода.Вывести(ВыводимоеСообщение, УровеньСообщения);
				Иначе
					СпособВывода.Вывести(ВыводимоеСообщение);
				КонецЕсли;
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;

КонецПроцедуры

Функция ЕстьЗаполненныеПараметры(Знач Параметр1 = Неопределено, Знач Параметр2 = Неопределено, Знач Параметр3 = Неопределено,
		Знач Параметр4 = Неопределено, Знач Параметр5 = Неопределено, Знач Параметр6 = Неопределено,
		Знач Параметр7 = Неопределено, Знач Параметр8 = Неопределено, Знач Параметр9 = Неопределено)

	Если НЕ Параметр1 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр2 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр3 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр4 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр5 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр6 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр7 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр8 = Неопределено Тогда
		Возврат Истина;
	ИначеЕсли НЕ Параметр9 = Неопределено Тогда
		Возврат Истина;
	КонецЕсли;
	 
	Возврат Ложь;

КонецФункции

Процедура Инициализация()

	УстановитьУровень(УровниЛога.Информация);
	ИнициализироватьСпособыВывода();
	мИдентификатор = Новый УникальныйИдентификатор;

КонецПроцедуры

Процедура ИнициализироватьСпособыВывода()

	мРаскладкаСообщения = Новый ОсновнаяРаскладкаСообщения;

	мСпособВыводаЗаданВручную = Ложь;
	мСпособыВывода = Новый Массив;
	мУровниАппендеров = Новый Соответствие;

	ВыводПоУмолчанию = Новый ВыводЛогаВКонсоль();
	ДобавитьСпособВывода(ВыводПоУмолчанию);
	
КонецПроцедуры

Функция НоваяНастройкаСпособаВывода(Знач НовыйУровень, Знач ЗаданЯвно)
	
	НастройкаСпособаВывода = Новый Структура("Уровень, ЗаданЯвно, ВерсияAPI", НовыйУровень, ЗаданЯвно, Неопределено);
	Возврат НастройкаСпособаВывода;

КонецФункции

Инициализация();
