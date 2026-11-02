/*
Napišite funkciju koja prima šifru županije (id) te vraća tekst u obliku: 
"NAZIV (šifraŽupanije) ima N mjesta" ; gdje je N ukupan broj mjesta u toj županiji.
*/

delimiter $ 
drop function if exists vratiBrMjesta $
create function vratiBrMjesta(id_ int) returns varchar(250)
deterministic 
begin 
    declare ime varchar(50);
    declare br int default 0;

    select nazivZupanija,count(*) into ime, br
    from zupanije
    natural join mjesta
    where id = id_
    group by id, nazivZupanija;

    return CONCAT(ime, " (", id_, ")", " ima ", br, " mjesta.");

end ; $

delimiter ;

select *, vratiBrMjesta(id) 
from zupanije;