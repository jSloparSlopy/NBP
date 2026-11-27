set autocommit = 0;
start transaction;

update radnik 
set prezimeRadnik = CONCAT(prezimeRadnik, " - VIP")
where pbrStan in (select pbrMjesto 
                  from mjesto
                  natural join zupanija
                  where nazivZupanija like "%Zagreb%");

savepoint tocka;

update radnik 
set prezimeRadnik = CONCAT(prezimeRadnik, " - REG")
where pbrStan in (select pbrMjesto 
                  from mjesto
                  natural join zupanija
                  where nazivZupanija not like like "%Zagreb%");

rollback to savepoint tocka;
commit;
set autocommit = 1;