# language: ru

Функционал: Выгрузка расширения в файлы
	Как Разработчик
	Я хочу выгружать конфигурацию разрабатываемого расширения в файлы
  Чтобы бэкапить текущие наработки и контролировать версии через GIT

Контекст: Скрипт выполнения
  Когда я подготовил конфигурационный файл
  И запустил скрипт

Сценарий: Начальные настройки

  Когда Я прочитал конфигурационный файл
  Тогда Я получил необходимые параметры
  И расшифроваю токен с данными аутентификации
  И инициализирую мониторинг
  И подключаюсь к репозиторию GIT

Сценарий: Подготовка выгрузки
  
  Когда Я установил контекст конфигурации разработки
  И подключил управление кластером
  Тогда отключаю пользователей конфигуратора в конфигурации разработки

Сценарий: Выгрузка расширения

  Когда Я переключаю репозиторий на свою ветку
  Тогда выгружаю конфигурацию расширения в файлы инкрементно
  И делаю коммит с указанием даты выполнения