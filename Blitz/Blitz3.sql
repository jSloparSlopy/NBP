/*
Napišite pohranjenu funkciju ocjeneUstanove koja prima OIB ustanove (CHAR(11)) i vraća tekst (VARCHAR) s brojem ispita za svaku ocjenu. Funkcija treba odrediti koliko je ispita te ustanove ocijenjeno ocjenom 1, 2, 3, 4 i 5.

Rezultat se gradi pomoću petlje (WHILE, REPEAT ili LOOP). Petlja prolazi ocjene od 1 do 5, za svaku ocjenu prebroji ispite zadane ustanove i dodaje taj broj u rezultat. Brojevi se u rezultatu odvajaju znakovima -, a iza zadnjeg broja separatora nema:

oc1 - oc2 - oc3 - oc4 - oc5
*/

delimiter $
use radionica $
drop function if exists ocjeneUstanove $
create function ocjeneUstanove(oib_ varchar(11)) returns varchar(50)
deterministic
begin
    declare i, oc int default 0;
    declare ispis varchar(50) default '';

    if not exists (select 1 from ustanove where oib = oib_) then
        return 'Ne postoji oib.';
    end if;

    set i = 1;
    while i <= 5 do
        select count(*) into oc
        from ocjene o
        inner join kolegiji k on k.id = o.idKolegij
        inner join smjerovi smj on smj.id = k.idSmjer
        where o.ocjena = i and smj.oibUstanova = oib_;

        if i = 1 then
            set ispis = oc;
        else
            set ispis = concat(ispis, ' - ', oc);
        end if;

        set i = i + 1;
    end while;

    return ispis;
end $

delimiter ;

select ocjeneUstanove('08814003451');