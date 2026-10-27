/* 
U bazi autoradionica: Napisati funkciju koja će za zadani prioritet naloga ispisati koliko
je bilo takvih naloga i njihov prosječan broj sati (na dvije decimale), prema sljedećem
formatu. 'Broj naloga = n; Prosjek sati = x'
*/


delimiter //

use radionica //
drop function if exists brojPoGodini //
create function brojPoGodini(zadanaGodina int, smjer int) returns varchar(100)
deterministic
begin
    declare br int default null;
    select count(*) into br
    from studenti  
    where YEAR(datumUpisa) = zadanaGodina and idSmjer = smjer;
    return concat("Broj upisanih studenata = ", br, "; Godina = ", zadanaGodina);
end //

use studenti //
drop function if exists odradeniKvarovi //
create function odradeniKvarovi(kvartal int, sifraKvara int) returns varchar(100)
DETERMINISTIC
BEGIN
    declare odradeno int DEFAULT null;
    select count(*) into odradeno
    from nalog
    where year(datPrimitkaNalog) = kvartal and sifKvar = sifraKvara;
    return concat("Broj odrađenih naloga: ", odradeno, " Kvartal: ", sifraKvara);
end //

-- select * from nalog// '> 5'

drop function if exists radnikBonus //
create function radnikBonus(sifra int) returns INT
DETERMINISTIC
BEGIN
    declare placaBonus int default null;
    select (r.KoefPlaca * r.IznosOsnovice * 1.15) into placaBonus
    from radnik r
    where r.sifRadnik = sifra;
    return concat_ws('Bonus: ', placaBonus);
end //

/*Napisati funkciju koja će za zadanog radnika ispisati koliko klijenata (kojem je vozilo popravljao taj radnik) 
živi u mjestu u kojem živi i taj radnik.*/
use studenti //
drop function if exists zadaniRadnik //
create function zadaniRadnik(radnik int) returns int
DETERMINISTIC
BEGIN
    declare br int default null;
    select count(*) into br
    from radnik 
    inner join mjesto on mjesto.pbrMjesto = radnik.pbrStan
    inner join klijent on klijent.pbrKlijent = mjesto.pbrMjesto
    where radnik.pbrStan = klijent.pbrKlijent and radnik.sifRadnik = radnik;
    return br;
end //

/*
Modificirati tablicu radnik tako da dodate novi atribut najvecaPlaca odgovarajuceg tipa. 
Napisati proceduru koja će:  
-> primiti šifru radnika 
-> za tog radnika pronaći županiju stanovanja 
-> u novostvoreni atribut najvecaPlaca unijeti koliki je najveći iznos plaće koju ima bilo koj 

select * from radnik //
drop procedure if exists najvecaPlaca //
create procedure najvecaPlaca(sifraRadika int)
BEGIN
    alter table radnik add column najvecaPlaca int(11);

    select z.sifZupanija
    from zupanije z
    inner join mjesto m on m.sifZupanija = z.sifZupanija
    inner join radnik r on r.pbrStan = m.pbrMjesto
    where r.sifRadnik = sifraRadnika;

    select max(koef)

END // */

delimiter ;

-- select zadaniRadnik(277);

-- select radnikBonus(281);
-- select ispisNaloga(2);
-- select brojPoGodini(2019, 5);
-- select odradeniKvarovi(1,1);



