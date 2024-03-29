# nginx formula

Формула для установки и настройки `nginx`.

## Доступные стейты

* [nginx](nginx)
* [nginx.repo](nginx.repo)
* [nginx.install](nginx.install)
* [nginx.selinux](nginx.selinux)
* [nginx.prepare](nginx.prepare)
* [nginx.certs](nginx.certs)
* [nginx.snippets](nginx.snippets)
* [nginx.config](nginx.config)
* [nginx.sites](nginx.sites)
* [nginx.check](nginx.check)
* [nginx.service](nginx.service)

### nginx

Основной стейт выполнит все остальне стейты.

### nginx.repo

Стейт для управления репозиторием, в зависимости от параметра `nginx:use_official_repo`:

* `true` подключит официальный репозиторий
* `false` (значение по умолчанию) удалит настроенный репозиторий

### nginx.install

Данный стейт отвечает за установку пакета `nginx` или пакетов из списка `nginx:package`

### nginx.selinux

Данный стейт отвечает за настройку SELinux на системах где это применимо. Настройка SELinux может быть необходима в случах если вы используете nginx как реверс прокси - для корректной работы необходимо разрешить `httpd_can_network_relay` или `httpd_can_network_connect`, а так же если требуется прослушивать какой-либо нестандартный порт, в этом случае добавьте нужные порты в список `nginx:selinxu:listen_ports`

### nginx.prepare

Вспомогательные стейт для настройки рабочего окружения

### nginx.certs

Стейт для управления сертификатами. Возможно использовать готовые сертификаты в виде файлов или данных из пилларов или же выпуск самоподписанных сертификатов.

### nginx.snippets

Стейт для управления сниппетами. Сниппеты - кусочки конфигурции, которые можно использовать многократно путем подключения их в других конфигурциях.

### nginx.config

Стейт для управления основным файлом конфигурации (обычно `nginx.conf`) и дополнительными конфигурциями вроде `conf.d/*.conf` или `custom/*.conf`

### nginx.sites

Стейт управления "сайтами". Сайт обычно представляет собой конфигурационный файл из одного блока `server`, который сохраняется в `/etc/nginx/sites-available`, при этом сам конфигурационный файл не подключен в основном конфиге `nginx` для его подключения необходимо создать символическую ссылку в каталоге `/etc/nginx/sites-enabled`. Благодаря подобной структуре имеется возможность включать и отключать сайты не трогая сам файл конфигурации, а только создавая / удаляя символическую ссылку.

### nginx.check

Вспомогательный стейт для проверки валидности конфигурации.

### nginx.service

Стейт для управления сервисом `nginx` запуск / остановка сервиса, включения / отключение сервиса при загрузке ОС
