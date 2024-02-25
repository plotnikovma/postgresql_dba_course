Буферный кэш СУБД

Называется он так потому, что представляет собой массив буферов.
Каждый буфер — это место под одну страницу данных (блок), плюс заголовок.
Заголовок, в числе прочего, содержит:

* расположение на диске страницы, находящейся в буфере (файл и номер блока в нем);
* признак того, что данные на странице изменились и рано или поздно должны быть записаны на диск (такой буфер называют грязным);
* число обращений к буферу (usage count);
* признак закрепления буфера (pin count).

Буферный кеш располагается в общей памяти сервера и доступен всем процессам.
Чтобы работать с данными — читать или изменять, — процессы читают страницы в кеш.
Пока страница находится в кеше, мы работаем с ней в оперативной памяти и экономим на обращениях к диску.

Существует расширение, которое позволяет заглянуть внутрь буферного кеша:

CREATE EXTENSION pg_buffercache;

SELECT bufferid,
  CASE relforknumber
    WHEN 0 THEN 'main'
    WHEN 1 THEN 'fsm'
    WHEN 2 THEN 'vm'
  END relfork,
  relblocknumber,
  isdirty,
  usagecount,
  pinning_backends
FROM pg_buffercache

Размер кеша устанавливается параметром shared_buffers. Значение по умолчанию — 128 Мб.
Это один из параметров, которые имеет смысл увеличить сразу же после установки PostgreSQL.

SELECT setting, unit FROM pg_settings WHERE name = 'shared_buffers';

Изменение параметра требует перезапуска сервера, поскольку вся необходимая под кеш память выделяется при старте сервера.

рекомендованное значение - от 25% до 40% RAM. Увеличение shared_buffers влечет за собой потребность в увеличении max_wal_size
