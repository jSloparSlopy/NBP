/*
6.7. 
U bazi studenti: Izraditi upit uz korištenje CTE-a koji će po nastavnicima prikazati
sljedeće podatke: ime i prezime nastavnika, njegov JMBAG, broj ispita, broj negativnih i
pozitivnih ocjena kao i najmanju i najveću ocjenu koju je nastavnik dao i MAX ocjenu.
Prikazati samo one nastavnike koji su imali više od 3 ispita (3 ocjene iz kolegija). Sortirati
po prosječnoj ocjeni padajući.
*/

use radionica;

with cte_nastavnik as (
    select i.jmbgNastavnik, COUNT(o.ocjena) as br_ispita, 
            sum(case when o.ocjena = 1 then 1 else 0 end) as br_neg,
            sum(case when o.ocjena > 1 then 1 else 0 end) as br_poz,
            min(o.ocjena) as MIN_ocj,
            max(o.ocjena) as MAX_ocj,
            AVG(o.ocjena) as AVG_ocj
    from ocjene o
    inner join kolegiji k on k.id = o.idKolegij
    inner join izvrsitelji i on i.idKolegij = k.id
    group by i.jmbgNastavnik
    having count(o.ocjena) > 3
    order by AVG_ocj desc
)
select n.ime, n.prezime, n.jmbg as jmbgNastavnik, cn.br_ispita, cn.br_neg, cn.br_poz, cn.MIN_ocj, cn.MAX_ocj, cn.AVG_ocj
from nastavnici n
inner join cte_nastavnik cn on cn.jmbgNastavnik = jmbgNastavnik
order by 9;



/* 6.8 */

with cte_kol as (
    select idKolegij, AVG(ocjena) as pros_kolegija, 
            sum(case when ocjena = 1 then 1 else 0 end) as br_1,
            sum(case when ocjena = 2 then 1 else 0 end) as br_2,
            sum(case when ocjena = 3 then 1 else 0 end) as br_3,
            sum(case when ocjena = 4 then 1 else 0 end) as br_4,
            sum(case when ocjena = 5 then 1 else 0 end) as br_5,
            count(ocjena) as Br_ispita
    from ocjene
    group by idKolegij
),
    cte_smjer as (
    select s.id, AVG(o.ocjena) as pros_smjera
    from smjerovi s
    join kolegiji k on k.idSmjer = s.id 
    join ocjene o on o.idKolegij = k.id
    group by idSmjer
)
select k.naziv, k.id, ck.*, cs.*
from kolegiji k
join cte_kol ck on ck.idKolegij = k.id 
join cte_smjer cs on cs.id = k.idSmjer
order by pros_kolegija;


/*
6.3. 
U bazi autoradionica: Izraditi upit uz korištenje CTE-a koji će po kolegijima prikazati
sljedeće podatke:
• id kolegija,
• naziv kolegija,
• broj položenih ispita,
• najmanju i najveću ocjenu iz kolegija (uzeti samo pozitivne ocjene).

Prikazati samo one kolegije koji su imali više od 3 pozitivna ispita. Sortirati po broju ispita
padajući i maksimalnoj ocjeni rastući.

*/

with cte_kolegij as (
    select idKolegij, COUNT(ocjena) as br_ispita, MIN(ocjena) as min_ocj, MAX(ocjena) as max_ocj
    from ocjene
    group by idKolegij
    having COUNT(case when ocjena > 1 then 1 else 0 end)
    order by br_ispita desc, max_ocj asc
)
select k.id, k.naziv, ck.*
from kolegiji k
join cte_kolegij ck on ck.idKolegij = k.id


