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
delimiter ;
-- call vratiOdjel(2);
select vratiBrojOcjena(5);

