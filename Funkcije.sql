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

delimiter ;

select radnikBonus(281);
-- select ispisNaloga(2);
-- select brojPoGodini(2019, 5);
-- select odradeniKvarovi(1,1);



