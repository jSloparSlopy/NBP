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
    set i = 0;
    open kursor;
    set redaka = FOUND_ROWS();

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

/************************************************/
            -- LABOS_ODJEL: -- 
/*
ALTER TABLE odjel 
ADD COLUMN brRadnika INT, 
ADD COLUMN brNaloga INT; */ 

use studenti;

delimiter $
drop function if exists azurirajOdjel $
create function azurirajOdjel(zadana_sifOdjel INT) returns varchar(255) deterministic
begin 
    declare redaka, azurirano, c_brRadnika, c_brNaloga, c_sif int default 0;
    declare flag bool default false;

    declare kursor cursor for 
        select sifOdjel, count(distinct sifRadnik) as brRadnika, count(prioritetNalog) as brNaloga
        from radnik
        left join nalog using (sifRadnik)
        group by sifOdjel;

    declare continue handler for not found set flag = TRUE;

    open kursor;
    set redaka = FOUND_ROWS();

    petlja:loop
        fetch kursor into c_sif, c_brRadnika, c_brNaloga;
        if flag = TRUE then 
            leave petlja;

        end if;

        update odjel 
        set brRadnika = c_brRadnika,
            brNaloga = c_brNaloga
        where sifOdjel = c_sif;

        set azurirano = azurirano + 1;
    end loop;

    close kursor;
    return CONCAT("Dohvaćeno: ", redaka, " Ažrurirano: ", azurirano);
   
end ; $

delimiter ;

/************************************************/
            -- LABOS_RADNIK_KVAR: -- 
/*
Napisati proceduru (koristeći KURSOR) koja će za zadani naziv kvara
dohvatiti sve radnike koji su imali više od 5 naloga s tim kvarom.
Za svakog radnika potrebno je ažurirati stupac brNaloga u tablici radnik
te podatke upisati u privremenu tablicu (šifra radnika, broj naloga).
Procedura ima izlazni parametar poruka u kojem se vraća broj dohvaćenih
i broj obrađenih redaka. Na kraju ispisati sadržaj privremene tablice.
Napisati primjer poziva procedure.
*/

-- ALTER TABLE radnik ADD COLUMN brNaloga INT DEFAULT -1;

use studenti;

delimiter $
drop procedure if exists proc $
create procedure proc(in i_nazivKvar varchar(50), out poruka varchar(50))
begin
    declare v_dohvat, v_obrad, v_zastavica int default 0;
    declare c_sifRadnik, c_brNaloga int;

    declare kur cursor for
        select n.sifRadnik, count(*) as broj
        from nalog n
        natural join kvar k
        where nazivKvar = i_nazivKvar
        group by n.sifRadnik
        having count(*) > 5;

    declare continue handler for not found set v_zastavica = 1;

    set v_zastavica = 0;
    drop temporary table if exists tmp;
    create temporary table tmp(sifra int, broj int);

    open kur;
    select found_rows() into v_dohvat;

    petlja:loop
        fetch kur into c_sifRadnik, c_brNaloga;

        if v_zastavica = 1 then
            leave petlja;
        end if;

        update radnik
        set brNaloga = c_brNaloga
        where sifRadnik = c_sifRadnik;

        set v_obrad = v_obrad + 1;

        insert into tmp(sifra, broj)
        values(c_sifRadnik, c_brNaloga);
    end loop;

    close kur;

    set poruka = concat('Dohvaceno: ', v_dohvat, ', Obradeno: ', v_obrad);

    select * from tmp;
    drop temporary table tmp;
end ; $

delimiter ;

call proc('Zamjena blatobrana', @por);
select @por;


select azurirajOdjel(9);
 select * from odjel;
