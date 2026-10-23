/*
DELIMITER //
DROP PROCEDURE IF EXISTS vratiNalogeSate //
CREATE PROCEDURE vratiNalogeSate(zadaniKlijent INT, OUT Total_sati INT)
BEGIN
SELECT k.jmbgKlijent Jmbg_klijent,
 CONCAT(k.imeKlijent, ' ', k.prezimeKlijent) Ime_prezime,
 YEAR(datUnosKlijent) God_unosa, COUNT(*) Br_naloga,
 SUM(OstvareniSatiRada) Sati_rada
FROM nalog n NATURAL JOIN klijent k
WHERE k.sifKlijent = zadaniKlijent
GROUP BY k.sifKlijent, k.jmbgKlijent, k.imeKlijent, k.prezimeKlijent, k.datUnosKlijent;
-- izračun ukupnog broja sati i pohrana u izlazni parametar
SELECT SUM(OstvareniSatiRada) INTO Total_sati
FROM nalog;
END //
DELIMITER ;
/* Poziv procedure i ispis rezultata u izlaznoj varijabli */
/*
CALL vratiNalogeSate(1167, @tot_sati);
SELECT @tot_sati;
*/

/*
2.4. 
U bazi autoradionica: Napisati proceduru koristeći CTE koja će za zadanu šifru odjela i
mjesec kojeg je potrebno izostaviti iz dohvata (ispisa) podataka vratiti

• šifru radnika,
• ime i prezime radnika spojeno,
• broj odrađenih naloga,
• prosječne sate rada,
• koeficijent plaće,
• iznos osnovice te
• plaću na dvije decimale (plaća je umnožak osnovice i koeficijent plaće).
Napisati smisleni primjer poziva ovog pohranjenog zadatka.
*/
/*
use studenti;
drop procedure if exists nalogRadnik;
delimiter //
create procedure nalogRadnik(trazeniOdjel int, mjesec int)
begin 
    with cte_radnik as (
        SELECT r.sifRadnik, count(*) as brNaloga, avg(n.OstvareniSatiRada) as pros_sati 
        from radnik r
        inner join nalog n on n.sifRadnik = r.sifRadnik
        group by r.sifRadnik
    ) 
    select r.sifRadnik, concat_ws(" ", r.imeRadnik, r.prezimeRadnik) imePrezime, cr.*, r.KoefPlaca, r.IznosOsnovice, r.KoefPlaca, (r.IznosOsnovice * r.KoefPlaca) as placa
    from radnik r
    inner join cte_radnik cr on cr.sifRadnik = r.sifRadnik;

end //
delimiter ;

call nalogRadnik(12, 12); */


/*
2.5. 
U bazi studenti: Napisati proceduru koristeći CTE koja će za zadani raspon prosječnih
ocjena (prosjecna_ocjena_od, prosjecna_ocjena_do) prikazati po kolegijima sljedeće
podatke:
• id kolegija,
• naziv kolegija,
• id smjera kojem kolegij pripada,
• broj položenih ispita i
• prosječnu ocjenu kolegija.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.
*/

/*
use radionica;

delimiter //
drop procedure if exists rasponProsjecnih //
create procedure rasponProsjecnih(prosjecna_ocjena_od int, prosjecna_ocjena_do int)
BEGIN
    with cte_raspon as (
        SELECT o.idKolegij, count(case when o.ocjena > 1 then 1 else 0 end) as brPolozenih, avg(o.ocjena) as prosKolegija
        from ocjene o
        group by o.idKolegij
        having prosKolegija >= prosjecna_ocjena_od and prosKolegija <= prosjecna_ocjena_do
    )
    select k.id, k.naziv, k.idSmjer, cr.*
    from kolegiji k
    inner join cte_raspon cr on cr.idKolegij = k.id;

end //
delimiter ;

CALL rasponProsjecnih(2.2, 3.3); */

/*
2.6. 
U bazi studenti: Napisati proceduru koristeći CTE koja će za zadani smjer prikazati
podatke po studentima koji su na ispitima dobili ocjene nedovoljan (1) ili dovoljan (2) te
da im je prosjek tih ocjena veći od 1. Prikazati sljedeće podatke:
• id smjera,
• naziv smjera,
• jmbag studenta,
• broj ispita,
• prosječnu ocjenu prema zadanom kriteriju.             */


use radionica;

delimiter //
drop procedure if exists smjeroviStudenti //
create PROCEDURE smjeroviStudenti(zadaniSmjer varchar(50))
BEGIN
    with cte as (
        SELECT st.idSmjer, st.jmbag, count(*) as broj_ispita, avg(o.ocjena) as prosjek
        from studenti st
        inner join ocjene o on o.jmbagStudent = st.jmbag
        group by st.idSmjer, st.jmbag
        having avg(o.ocjena) > 1
    )
    select s.id, s.naziv
    from smjerovi s
    where s.naziv = zadaniSmjer;
END //

delimiter ;

/*
2.9. 
U bazi autoradionica: Napisati proceduru koristeći CTE koja će za zadani poštanski broj
prebivanja studenata prikazati sljedeće podatke o tim studentima:
• JMBAG studenta,
• ime studenta,
• prezime studenta,
• poštanski broj prebivanja,
• poštanski broj stanovanja,
• broj položenih ispita,
• prosječnu ocjenu položenih ispita.

Odabrati studente s više od jednog položenog ispita i prosjekom položenih ispita između
2 i 4.
Potrebno je putem ulazno izlaznog parametra vratiti prosjek svih ocjena svih studenata
koji prebivaju u zadanom mjestu.
Ispis sortirati po prezimenu pa imenu.                                              */

use radionica;
delimiter //
drop procedure if exists postanskiProsjek //
create procedure postanskiProsjek(postanskiBroj int)
begin
    with cte_pros as (
        select jmbagStudent, count(*) as brPolozenih, avg(ocjena) as prosOcjena
        from ocjene
        group by jmbagStudent
        having count(*) > 1 and avg(ocjena) between 2.00 and 4.00
    )
    select s.jmbag, s.ime, s.prezime, s.postBrPrebivanje, s.postBrStanovanja, cp.*
    from studenti s
    join cte_pros cp on cp.jmbagStudent = s.jmbag
    where s.postBrPrebivanje = postanskiBroj;

end //  

delimiter ;

-- SET @var = 32000;
-- CALL postanskiProsjek(@var);

/*
2.7. 
U bazi studenti: Napisati proceduru koristeći CTE koja će za zadani kvartal prikazati
podatke po kolegijima. Izuzeti negativne ocjene i kolegije koji su imali samo 1 položeni
ispit.

Prikazati sljedeće podatke:
• naziv kolegija i id kolegija u zagradi nakon naziva,
• opis kolegija (prvih 100 znakova),
• najmanju ocjenu,
• najveću ocjenu te broj ispita.

Ispis sortirati po šifri kolegija obrnutim redoslijedom.
Napisati smisleni primjer poziva ovog pohranjenog zadatka.
 */

delimiter //
use radionica //
drop procedure if exists kolegijPodaci //
create procedure kolegijPodaci(zadaniKvartal int)
BEGIN
    with cte_ocjena as (
        select idKolegij, min(ocjena) min_ocj, max(ocjena) max_ocj, count(*) br_ispita
        from ocjene 
        group by idKolegij
    )
    select k.naziv, k.id, k.opis, co.min_ocj, co.max_ocj, co.br_ispita
    from kolegiji k
    inner join cte_ocjene co on co.idKolegij = k.id;
end //

delimiter ;

call kolegijPodaci(1);













