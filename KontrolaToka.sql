-- 4.1
delimiter %
use studenti %
drop procedure IF EXISTS vratiOdjel %
create procedure vratiOdjel(id int)
begin 
    declare prosjek int default null;
    select avg(OstvareniSatiRada) into prosjek from nalog;
    with cte_prosjek as (
        select n.sifRadnik, avg(n.OstvareniSatiRada) as prosjekSati
        from nalog n
        group by n.sifRadnik
    )
    select r.sifRadnik, concat(r.imeRadnik,' ', r.prezimeRadnik) as ImePrezime, cp.prosjekSati, 
            if(cp.prosjekSati >= prosjek, "Overperformer", "Underperformer") as opis
    from radnik r
    join cte_prosjek cp on cp.sifRadnik = r.sifRadnik
    where r.sifOdjel = id
    group by r.sifRadnik
    order by cp.prosjekSati desc;
end; 
%


use radionica %
drop function if exists vratiBrojOcjena %
create function vratiBrojOcjena(ocj int) returns varchar(50)
DETERMINISTIC
BEGIN
    declare br int;
    IF ocj > 5 or ocj < 1
    then return "Neispravno unesena ocjena";
    else 
    select count(*) into br
    from ocjene
    where ocjena = ocj;
    return concat("Ocjenom ", ocj, " ocijenjeno je ", br, " studenata.");

    end if;
   
END;
%

delimiter %
use studenti %
drop function if exists imena %
create function imena(sifra int) returns varchar(250)
deterministic
BEGIN
    declare br, i int;
    declare izlaz, ime varchar(250);

    select length(imeRadnik), imeRadnik into br, ime
    from radnik 
    where sifRadnik = sifra;
    set izlaz = '';
    set i = 1;
    while i <= br do
        if i < br 
            then set izlaz  = concat(izlaz, ime, ' - ');
        else set  izlaz  = concat(izlaz, ime);

        end if;
        set i = i + 1;
    end while;
    return izlaz;
end; %

use studenti %
drop procedure if exists period %
create procedure period(in od_god int, in do_god int, out poruka varchar(50)) 
BEGIN
    if od_god <= do_god 
        and length(od_god) = 4 and length(do_god) = 4
        and (od_god in (select distinct YEAR(datPrimitkaNalog) from nalog))
        and (do_god in (select distinct YEAR(datPrimitkaNalog) from nalog))
    then
        select YEAR(n.datPrimitkaNalog) as Godina, 
                MONTH(n.datPrimitkaNalog) as Mjesec,
                count(*) as BrojRadnik, round(avg(r.KoefPlaca * r.IznosOsnovice), 2) as ProsjecnaPlaca, round(count(*) * avg(r.KoefPlaca * r.IznosOsnovice), 2) as Trosak
        from nalog n
        natural join radnik r
        where YEAR(n.datPrimitkaNalog) between od_god and do_god
        group by YEAR(n.datPrimitkaNalog), MONTH(n.datPrimitkaNalog)
        order by YEAR(n.datPrimitkaNalog);
    else set poruka = "Neispravno unesene godine";
    end if;
end; 
%

-- 4.6
drop procedure if exists kvarovi %
create procedure kvarovi(in sifra int, out vkvar varchar(50), out brojNaloga int, out brojRazKlijenata int)
BEGIN
    if sifra not in (select sifKvar from kvar)
    THEN
        select "Nepostojeća šifra kvara. " as Poruka;
    else 
        select kv.nazivKvar, count(*), count(distinct sifKlijent) into vkvar, brojNaloga, brojRazKlijenata
        from kvar kv
        natural join nalog n
        where kv.sifKvar = sifra
        group by kv.nazivKvar;
    end if;
end ;
%

-- 4.7
use radionica %
drop procedure if exists smjer %
create procedure smjer(in sifra int, out prosjek double)
BEGIN
    select avg(ocjena) into prosjek from ocjene;

    if sifra not in (select id from smjerovi)
    then 
        select "Nepostojeća šifra smjera." as Poruka;

    else 
        select s.jmbag ,
               concat(s.ime, " ", s.prezime) as ImePrezime, 
               avg(o.ocjena)                 as ProsjekStudenta,
               count(*)                      as BrojIspita,
               if(avg(o.ocjena) > prosjek, '↑', '↓') as flag
        from studenti s
        inner join ocjene o on o.jmbagStudent = s.jmbag
        where s.idSmjer = sifra
        group by s.jmbag
        order by avg(o.ocjena) desc, count(*) desc;

    end if;
end;
%

delimiter ;


-- call smjer(1, @prosjek);
-- select @prosjek;

-- call kvarovi(27, @v, @br, @k);
-- select @v, @br, @k;

-- call period(2018, 2019, @poruka);
-- select @poruka;

-- call vratiRadnike(2);
-- select sifRadnik, imeRadnik, imena(sifRadnik) from radnik order by imeRadnik;
-- call vratiOdjel(2);
-- select vratiBrojOcjena(5);

