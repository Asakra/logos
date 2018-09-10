﻿//////////////////////////////////////////////////////////////////////////
//
// LOGOS: вывод в консоль
//
//////////////////////////////////////////////////////////////////////////

Перем КартаСтатусовИУровней;

Процедура ВывестиСобытие(Знач СобытиеЛога) Экспорт
	Сообщение = СобытиеЛога.ПолучитьСообщение();
	УровеньСообщения = СобытиеЛога.ПолучитьУровень();

	Сообщить(Сообщение, КартаСтатусовИУровней[УровеньСообщения]);
КонецПроцедуры

Процедура Закрыть() Экспорт

КонецПроцедуры

// Устанавливает свойство аппендера, заданное в конфигурационном файле
//
Процедура УстановитьСвойство(Знач ИмяСвойства, Знач Значение) Экспорт
	
КонецПроцедуры // УстановитьСвойство()

КартаСтатусовИУровней = Новый Соответствие;
КартаСтатусовИУровней.Вставить(УровниЛога.Отладка, СтатусСообщения.БезСтатуса);
КартаСтатусовИУровней.Вставить(УровниЛога.Информация, СтатусСообщения.Обычное);
КартаСтатусовИУровней.Вставить(УровниЛога.Предупреждение, СтатусСообщения.Внимание);
КартаСтатусовИУровней.Вставить(УровниЛога.Ошибка, СтатусСообщения.Важное);
КартаСтатусовИУровней.Вставить(УровниЛога.КритичнаяОшибка, СтатусСообщения.ОченьВажное);