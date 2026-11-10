/*5.2. U bazi autoradionica: Napisati proceduru (koristeći KURSOR) 
koja će za zadani prioritet naloga prikazati sve odjele koji su ostvarili više od jednog naloga sa zadanim prioritetom.
Za svaki odjel potrebno je ispisati:
• id odjela,
• naziv odjela,
• iznos prosječno ostvarenih sati,
• broja naloga,
• tip odjela prema broju odrađenih naloga i to
- UNDER_VOLUME ako ima manje od 20 naloga i
- OVER_VOLUME ako ima više ili jednako 20 naloga.
Zadatak riješiti pomoću kursora i privremene tablice, bez korištenja handlera. Sortirati silazno prema broju naloga.
Napisati primjer poziva procedure.*/
use studenti;

delimiter $
drop procedure if exists tipOdjel $
create procedure tipOdjel(P int)
begin 

    declare redaka, i, c_sif, c_brNaloga int default null;
    declare c_naziv, c_tipOdjela varchar(50) default null;
    declare c_prosjek decimal(5,2) default null;

    declare kursor cursor for 
        select sifOdjel, nazivOdjel, count(*) as brNaloga, avg(OstvareniSatiRada) as prosjek
        from odjel
        natural join radnik 
        natural join nalog 
        where prioritetNalog = P
        group by sifOdjel, nazivOdjel;
    
    drop temporary table if exists tmp;
    create temporary table tmp(sif int, naziv varchar(50), brNaloga int,prosjek decimal(4,2), tipOdjela varchar(50));
    set redaka = FOUND_ROWS();
    set i = 0;
    open kursor;

    while i <= redaka do 
        fetch kursor into c_sif, c_naziv, c_brNaloga, c_prosjek;

        if c_brNaloga >= 20 then 
            set c_tipOdjela = "OVER_VOLUME";
        else set c_tipOdjela = "UNDER_VOLUME";
        end if;

        insert into tmp(sif, naziv, brNaloga, prosjek, tipOdjela)
        values(c_sif, c_naziv, c_brNaloga,c_prosjek, c_tipOdjela);

        set i = i + 1;
    end while;

    close kursor;
    select * from tmp;
end ; $

delimiter ;

-- call tipOdjel(1);

/************************************************/
            -- LABOS_STUDENTI: -- 
/*
ALTER TABLE studenti 
ADD COLUMN brPozitivnih INT, 
ADD COLUMN brNegativnih INT, 
ADD COLUMN prosjecnaOcjena DECIMAL(4,2);*/

use radionica;

delimiter $
drop function if exists brojiOcjene $
create function brojiOcjene(zadani_idSmjera INT) returns varchar(255) deterministic
begin 
    declare redaka, azurirano, c_neg, c_poz int default 0;
    declare flag bool default false;
    declare c_jmbag char(10) default null;
    declare c_prosjek decimal(3,2) default null;

    declare kursor cursor for 
        select jmbagStudent, 
               count(case when ocjena = 1 then 1 else null end) as brNegativnih,
               count(case when ocjena > 1 then 1 else null end) as brPozitivnih,
               avg(ocjena) as prosjek
        from ocjene  
        inner join studenti on jmbag = jmbagStudent
        where idSmjer = zadani_idSmjera
        group by jmbagStudent;

    declare continue handler for not found set flag = TRUE;


    open kursor;
    set redaka = FOUND_ROWS();
    petlja:loop
        fetch kursor into c_jmbag, c_neg, c_poz, c_prosjek;

        if flag = TRUE then 
            leave petlja;
        end if; 

        update studenti
        set brPozitivnih = c_poz,
            brNegativnih = c_neg,
            prosjecnaOcjena = c_prosjek
        where jmbag = c_jmbag;

        set azurirano = azurirano + 1;
    end loop;
    close kursor;

    return CONCAT("Dohvaćeno: ", redaka, " Ažrurirano: ", azurirano);
end ; $

delimiter ;

select brojiOcjene(10);


