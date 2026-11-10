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