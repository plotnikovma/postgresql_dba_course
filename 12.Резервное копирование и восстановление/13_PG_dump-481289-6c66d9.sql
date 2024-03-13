-- Создаем сетевую инфраструктуру и саму VM:
yc vpc network create --name otus-net --description "otus-net" && \
yc vpc subnet create --name otus-subnet --range 192.168.0.0/24 --network-name otus-net --description "otus-subnet" && \
yc compute instance create --name otus-vm --hostname otus-vm --cores 2 --memory 4 --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub 

-- Подключимся к VM:
vm_ip_address=$(yc compute instance show --name otus-vm | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 

-- Установим PostgreSQL:
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 

create database otus;
\c otus
create table students as select generate_series(1, 10) as id, md5(random()::text)::char(10) as fio;


-- ЛОГИЧЕСКИЙ БЭКАП
-- \help copy

\copy students to '/tmp/backup_copy.sql';
\copy students from '/tmp/backup_copy.sql';

\copy students to '/tmp/backup_copy.sql' with delimiter ',';
insert into students values (11, 'mos, ru');
\copy students from '/tmp/backup_copy.sql' with delimiter ',';

-- cd ~/../../../tmp


-- pg_dump
sudo -u postgres pg_dump -d otus --create > /tmp/backup_dump.sql
sudo -u postgres psql < /tmp/backup_dump.sql


-- АРХИВ (pg_restore)

-- Одна из опций команды pg_restore определяет количество параллельных потоков, которые запускаются во время выполнения наиболее затратных по времени задач, загрузки данных, создания индексов или ограничений. Документация по pg_restore говорит, что лучше начинать с количества потоков, равного количеству ядер. 
sudo -u postgres pg_dump -d otus --create -Fc > /tmp/backup_dump.gz -- бинарный формат(кастомный формат с метаданными)
sudo -u postgres createdb otus && sudo -u postgres pg_restore -d otus -j 2 /tmp/backup_dump.gz

-- под капотом(архив с оглавлением):
sudo -u postgres pg_dump -d otus --create -Fd -f /tmp/test.dir
sudo -u postgres createdb otus && sudo -u postgres pg_restore -d otus -j 2 /tmp/test.dir

-- Эта команда распаковывает файл при помощи zcat(аналог cat для сжатых файлов) и выводит его в stdout, который, в свою очередь, можно направить в psql.
sudo -u postgres pg_dump -d otus --create | gzip > /tmp/backup_dump2.gz -- текстовый формат(обычный архив)
zcat /tmp/backup_dump2.gz | sudo -u postgres psql -- gzip -dc backup_dump2.gz

-- Создаем новый инстанс и восстановимся на него:
sudo pg_createcluster 14 main2
pg_lsclusters
sudo pg_ctlcluster 14 main2 start

sudo -u postgres psql -p 5433 < /tmp/backup_dump.sql
sudo -u postgres psql -p 5433
\conninfo


-- pg_dumpall
sudo -u postgres pg_dumpall > /tmp/backup_alldump.sql
sudo -u postgres psql < /tmp/backup_alldump.sql


--- ФИЗИЧЕСКИЙ БЭКАП (СОЗДАНИЕ АВТОНОМНОГО БЭКАПА)

sudo rm -rf /var/lib/postgresql/14/main2
sudo -u postgres pg_basebackup -p 5432 -D /var/lib/postgresql/14/main2
sudo pg_ctlcluster 14 main2 start

pg_lsclusters
sudo pg_ctlcluster 14 main2 stop
sudo pg_dropcluster 14 main2

select name, setting from pg_settings where name in ('archive_mode','archive_command','archive_timeout');


-- Удалим VM, сети и локальную переменную vm_ip_address:
yc compute instance delete otus-vm && yc vpc subnet delete otus-subnet && yc vpc network delete otus-net && unset vm_ip_address

-- Установка демонстрационной базы данных demo:
wget https://edu.postgrespro.ru/demo_small.zip && sudo apt install unzip && unzip demo_small.zip && sudo -u postgres psql -d postgres -f /home/yc-user/demo_small.sql -с 'alter database demo set search_path to bookings;'

-- Установка демонстрационной базы данных dvdrental:
wget https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip && unzip dvdrental.zip && sudo -u postgres psql -c 'create database dvdrental;' && sudo -u postgres pg_restore -d dvdrental dvdrental.tar