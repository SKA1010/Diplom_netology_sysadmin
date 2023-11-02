# Дипломная работа по профессии «Системный администратор»

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.


---------

## Решение

Согласно заданию, при помощи terraform были развёрнуты 6 ВМ, для них созданы внутренние IP адреса, к ним привязаны группы безопасности, разрешающие траффик по портам приложений.

Главное окно:
![yandex cloud main](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/bc68fcd2-54bf-4390-a761-f90be2f4eb6a)

Созданные машины (все на базе Debian 11)
![yandex cloud vm](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/b6a497fa-b9cc-48f0-90d0-df73e425bc52)

Так же был создан облачный балансировщик траффика

![yandex cloud balancer](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/e1475f3b-dc2d-449a-9f6c-373419ee9071)

Для каждой машины были написаны Ansible роли. Так как прямого доступа по SSH к машинам у нас нет, сперва устанавливаем Ansible и копируем плейбуки на Бастион хост при помощи заранее написанного плейбука.  
После копирования запускаем наш основной плейбук. Когда все службы развернутся, можем проверить что все необходимые ресурсы доступны.
Проверим работу балансировщика и серверов Nginx:

![image](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/d7698a15-3a98-4286-8294-d589c665be5a)

Проверяем работу сайта:

![image](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/d43bd23a-8d80-4720-88fb-23e14a6b0798)

Подключимся к kibana и посмотрим, поступают ли туда наши логи, предварительно добавив items:

![Kibana-1](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/aaa7b3fd-db5b-4fb9-b2e4-88a07d650304)

Видим, что логи с обоих серверов идут:
![Kibana-2](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/02485e8b-cae2-472e-b1c9-d07cbc908a10)

Переходим к мониторингу. Создаём свой шаблон и добавляем item

![zabbix-3](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/774ea26e-f8c0-4018-aa47-28816f95537f)

Добавляем узлы:

![zabbix-2](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/e92e830f-1b1c-4ab7-b4db-4dbecde01fb1)

Настраиваем по своему усмотрению дашборды:

![zabbix-1](https://github.com/SKA1010/Diplom_netology_sysadmin/assets/125235217/5405ab75-71a8-4398-920e-5d9bb69a6620)






