/* ============================================================================
   Dodatni zadaci – 5. Kursori i handleri
   Baze: autoradionica (5.10, 5.11, 5.12, 5.15) i studenti (5.13, 5.14)
   ============================================================================ */

/*
5.10. U bazi autoradionica: Napisati proceduru koja će ispisati podatke klijenta (šifru,
      ime i prezime), broj njegovih naloga, ukupno ostvarene sate rada te kategoriju
      klijenta. Kategorija se dodjeljuje po slijedećem principu:
               •   SILVER za 3 ili više naloga,
               •   GOLD za 5 ili više naloga,
               •   PLATINUM za 10 ili više naloga.

      Ispisati samo one klijente koji imaju pravo na kategoriju. Ispis sortirati silazno po
      broju naloga, a zatim silazno po ukupnom broju sati. Osigurati da po završetku
      procedure privremena tablica više nije dostupna.

      Potrebno je koristiti kursor, handler i privremenu tablicu.

      Napisati primjer poziva ovog pohranjenog zadatka.
*/
USE autoradionica;

DROP PROCEDURE IF EXISTS klasificiraj_klijente;
DELIMITER //
CREATE PROCEDURE klasificiraj_klijente()
BEGIN
   DECLARE sif, brNaloga, brSati INT;
   DECLARE ime, prezime VARCHAR(255);
   DECLARE nastavi BOOL;
   DECLARE kur CURSOR FOR
        SELECT k.sifKlijent, k.imeKlijent, k.prezimeKlijent,
               COUNT(*), SUM(n.OstvareniSatiRada)
          FROM klijent k
            JOIN nalog n ON k.sifKlijent = n.sifKlijent
          GROUP BY k.sifKlijent, k.imeKlijent, k.prezimeKlijent;

   DECLARE CONTINUE HANDLER FOR NOT FOUND SET nastavi = FALSE;
   SET nastavi = TRUE;
   DROP TEMPORARY TABLE IF EXISTS tmp;
   CREATE TEMPORARY TABLE tmp (
        sif INT,
        ime VARCHAR(255),
        prezime VARCHAR(255),
        brojNaloga INT,
        ukupnoSati INT,
        kategorija VARCHAR(20)
   );

   OPEN kur;
   petlja:LOOP
      FETCH kur INTO sif, ime, prezime, brNaloga, brSati;
      IF nastavi = FALSE THEN
          LEAVE petlja;
      END IF;
      IF brNaloga >= 10 THEN
          INSERT INTO tmp VALUES(sif, ime, prezime, brNaloga, brSati, 'PLATINUM');
      ELSEIF brNaloga >= 5 THEN
          INSERT INTO tmp VALUES(sif, ime, prezime, brNaloga, brSati, 'GOLD');
      ELSEIF brNaloga >= 3 THEN
          INSERT INTO tmp VALUES(sif, ime, prezime, brNaloga, brSati, 'SILVER');
      END IF;
   END LOOP;
   CLOSE kur;
   SELECT * FROM tmp ORDER BY brojNaloga DESC, ukupnoSati DESC;
   DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

/* Poziv procedure */
CALL klasificiraj_klijente();


/*
5.11. U bazi autoradionica: Napisati proceduru koja će svim radnicima čiji je ukupan broj
      ostvarenih sati rada (kroz sve naloge) veći od prosjeka ukupnih sati svih radnika,
      povećati koeficijent plaće za 0.10. Potrebno je osigurati da se koeficijent plaće ne
      može postaviti na vrijednost veću od 3.00.

      Procedura mora vratiti broj n-torki koje je dohvatila i broj n-torki koje je obradila.
      U optimalno postavljenim petljama, očekujemo da će ove dvije vrijednosti biti
      identične.

      Zadatak riješiti pomoću kursora i handlera. Napisati primjer poziva procedure.
*/
USE autoradionica;

DROP PROCEDURE IF EXISTS povecaj_koeficijente;
DELIMITER //
CREATE PROCEDURE povecaj_koeficijente()
BEGIN
   DECLARE c_sif, dohvaceno, povecano INT;
   DECLARE flag BOOL DEFAULT FALSE;
   DECLARE kurs CURSOR FOR
      SELECT sifRadnik
         FROM nalog
         GROUP BY sifRadnik
         HAVING SUM(OstvareniSatiRada) >
            (SELECT AVG(ukupno) FROM
                (SELECT SUM(OstvareniSatiRada) AS ukupno
                    FROM nalog GROUP BY sifRadnik) AS t);
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
   SET povecano=0;

   OPEN kurs;
   SELECT FOUND_ROWS() INTO dohvaceno;

   petlja:LOOP
      FETCH kurs INTO c_sif;
      IF flag=TRUE THEN
         LEAVE petlja;
      END IF;
      UPDATE radnik SET KoefPlaca = LEAST(KoefPlaca + 0.10, 3.00)
         WHERE sifRadnik = c_sif;
      SET povecano=povecano+1;
   END LOOP;
   CLOSE kurs;

   SELECT dohvaceno AS dohvaceno_radnika, povecano AS povecani_koeficijenti;
END//
DELIMITER ;

/* Poziv procedure i provjera rezultata */
SELECT sifRadnik, KoefPlaca FROM radnik WHERE sifRadnik IN (289, 514, 501);
CALL povecaj_koeficijente();
SELECT sifRadnik, KoefPlaca FROM radnik WHERE sifRadnik IN (289, 514, 501);


/*
5.12. U bazi autoradionica: Napisati funkciju koja za zadanu šifru odjela korigira planirane
      sate (satiKvar) svim kvarovima tog odjela kod kojih je prosječno ostvareni broj sati
      rada po nalogu (zaokružen na cijeli broj) veći od planiranih sati. Takvim kvarovima
      planirani sati postaju jednaki zaokruženom prosjeku. Provjeriti postoji li zadani odjel.

      Funkcija mora vratiti poruku s brojem kvarova koje je dohvatila i brojem kvarova koje
      je korigirala.

      Zadatak riješiti pomoću kursora i handlera. Napisati primjer poziva funkcije.
*/
USE autoradionica;

DROP FUNCTION IF EXISTS KorigirajSate;
DELIMITER //
CREATE FUNCTION KorigirajSate (p_sifOdjel INT) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
   DECLARE c_sifKvar, c_prosjek, dohvaceno, korigirano INT DEFAULT 0;
   DECLARE flag BOOL DEFAULT FALSE;
   DECLARE kurs CURSOR FOR
      SELECT k.sifKvar, ROUND(AVG(n.OstvareniSatiRada))
         FROM kvar k
            JOIN nalog n ON k.sifKvar = n.sifKvar
         WHERE k.sifOdjel = p_sifOdjel
         GROUP BY k.sifKvar, k.satiKvar
         HAVING ROUND(AVG(n.OstvareniSatiRada)) > k.satiKvar;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;

   IF p_sifOdjel IN (SELECT DISTINCT sifOdjel FROM kvar) THEN
      OPEN kurs;
         SELECT FOUND_ROWS() INTO dohvaceno;
         petlja:LOOP
            FETCH kurs INTO c_sifKvar, c_prosjek;
            IF flag=TRUE THEN
               LEAVE petlja;
            END IF;
            UPDATE kvar SET satiKvar = c_prosjek WHERE sifKvar = c_sifKvar;
            SET korigirano = korigirano + 1;
         END LOOP;
      CLOSE kurs;
      RETURN CONCAT('Dohvaćeno ', dohvaceno, ', korigirano ', korigirano, ' kvarova.');
   ELSE
      RETURN 'Nepostojeća šifra odjela!';
   END IF;
END//
DELIMITER ;

/* Pozivi funkcije */
SELECT sifKvar, satiKvar FROM kvar WHERE sifOdjel = 6;
SELECT KorigirajSate(6) AS poruka;
SELECT sifKvar, satiKvar FROM kvar WHERE sifOdjel = 6;
SELECT KorigirajSate(999) AS poruka;


/*
5.13. U bazi studenti: Napisati proceduru koja će za zadani smjer ispisati podatke o
      prolaznosti svih njegovih kolegija koji imaju barem jedno polaganje. Za svaki kolegij
      ispisati:
               •   id kolegija,
               •   naziv kolegija,
               •   broj polaganja,
               •   postotak prolaznosti (udio pozitivnih ocjena u svim polaganjima),
               •   prosječnu ocjenu (uključujući negativne),
               •   težinu kolegija i to:
               -   TEŽAK ako je prolaznost manja od 50%,
               -   SREDNJI ako je prolaznost manja od 80%,
               -   LAGAN u ostalim slučajevima.

      Ispis sortirati uzlazno po prolaznosti. Osigurati da po završetku procedure
      privremena tablica više nije dostupna.

      Potrebno je koristiti kursor, handler i privremenu tablicu.

      Napisati primjer poziva procedure.
*/
USE studenti;

DROP PROCEDURE IF EXISTS prolaznost_kolegija;
DELIMITER //
CREATE PROCEDURE prolaznost_kolegija(p_smjer INT)
BEGIN
   DECLARE c_id, c_brPol, c_brPoz INT;
   DECLARE c_naziv VARCHAR(100);
   DECLARE c_prosjek DECIMAL(3,2);
   DECLARE c_prolaznost DECIMAL(5,2);
   DECLARE nastavi BOOL;
   DECLARE kur CURSOR FOR
        SELECT k.id, k.naziv, COUNT(*), COUNT(IF(o.ocjena > 1, 1, NULL)),
               AVG(o.ocjena)
          FROM kolegiji k
            JOIN ocjene o ON k.id = o.idKolegij
          WHERE k.idSmjer = p_smjer
          GROUP BY k.id, k.naziv;

   DECLARE CONTINUE HANDLER FOR NOT FOUND SET nastavi = FALSE;
   SET nastavi = TRUE;
   DROP TEMPORARY TABLE IF EXISTS tmp;
   CREATE TEMPORARY TABLE tmp (
        idKolegij INT,
        naziv VARCHAR(100),
        brojPolaganja INT,
        prolaznost DECIMAL(5,2),
        prosjekOcjena DECIMAL(3,2),
        tezina VARCHAR(10)
   );

   OPEN kur;
   petlja:LOOP
      FETCH kur INTO c_id, c_naziv, c_brPol, c_brPoz, c_prosjek;
      IF nastavi = FALSE THEN
          LEAVE petlja;
      END IF;
      SET c_prolaznost = c_brPoz / c_brPol * 100;
      IF c_prolaznost < 50 THEN
          INSERT INTO tmp VALUES(c_id, c_naziv, c_brPol, c_prolaznost, c_prosjek, 'TEŽAK');
      ELSEIF c_prolaznost < 80 THEN
          INSERT INTO tmp VALUES(c_id, c_naziv, c_brPol, c_prolaznost, c_prosjek, 'SREDNJI');
      ELSE
          INSERT INTO tmp VALUES(c_id, c_naziv, c_brPol, c_prolaznost, c_prosjek, 'LAGAN');
      END IF;
   END LOOP;
   CLOSE kur;
   SELECT * FROM tmp ORDER BY prolaznost ASC;
   DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

/* Poziv procedure */
CALL prolaznost_kolegija(1);


/*
5.14. U bazi studenti: Napisati funkciju koja će za zadani prag prosjeka označiti sve
      studente čiji je prosjek pozitivnih ocjena veći ili jednak zadanom pragu. U atributu
      prezime, nakon prezimena dodati oznaku ' PROSJEK = x', gdje je x izračunati prosjek.
      Provjeriti je li prag ispravno zadan (dozvoljene vrijednosti su od 2 do 5).

      Funkcija mora vratiti poruku s brojem studenata koje je dohvatila i brojem studenata
      koje je označila.

      Zadatak riješiti pomoću kursora i handlera. Napisati primjer poziva funkcije.
*/
USE studenti;

ALTER TABLE studenti
MODIFY COLUMN prezime VARCHAR(500);

DROP FUNCTION IF EXISTS MarkAverage;
DELIMITER //
CREATE FUNCTION MarkAverage (p_prag DECIMAL(4,2)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
   DECLARE c_jmbag VARCHAR(10) DEFAULT NULL;
   DECLARE c_prosjek DECIMAL(3,2) DEFAULT 0;
   DECLARE dohvaceno, oznaceno INT DEFAULT 0;
   DECLARE flag BOOL DEFAULT FALSE;
   DECLARE kurs CURSOR FOR
      SELECT jmbagStudent, AVG(ocjena)
         FROM ocjene
         WHERE ocjena > 1
         GROUP BY jmbagStudent
         HAVING AVG(ocjena) >= p_prag;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;

   IF p_prag < 2 OR p_prag > 5 THEN
      RETURN 'Neispravan prag prosjeka (dozvoljeno 2 - 5).';
   END IF;
   OPEN kurs;
      SELECT FOUND_ROWS() INTO dohvaceno;
      petlja:LOOP
         FETCH kurs INTO c_jmbag, c_prosjek;
         IF flag=TRUE THEN
            LEAVE petlja;
         END IF;
         UPDATE studenti SET prezime =
            CONCAT(prezime, ' PROSJEK = ', c_prosjek)
            WHERE jmbag = c_jmbag;
         SET oznaceno = oznaceno + 1;
      END LOOP;
   CLOSE kurs;
   RETURN CONCAT('Dohvaćeno ', dohvaceno, ', označeno ', oznaceno, ' studenata.');
END//
DELIMITER ;

/* Pozivi funkcije */
SELECT MarkAverage(4.5) AS poruka;
SELECT jmbag, ime, prezime FROM studenti WHERE prezime LIKE '%PROSJEK%';
SELECT MarkAverage(7) AS poruka;


/*
5.15. U bazi autoradionica: Napisati proceduru (koristeći KURSOR) koja će za zadanu županiju
      prikazati sva mjesta u kojima žive radnici.

      Za svako mjesto potrebno je ispisati:
               •   poštanski broj mjesta,
               •   naziv mjesta,
               •   broj radnika,
               •   prosječni koeficijent plaće radnika,
               •   tip mjesta prema broju radnika i to
               -   VELIKO ako ima 5 ili više radnika,
               -   SREDNJE ako ima 2 ili više radnika,
               -   MALO u ostalim slučajevima.

      Zadatak riješiti pomoću kursora i privremene tablice, bez korištenja handlera.
      Sortirati silazno prema broju radnika.

      Napisati primjer poziva procedure.
*/
USE autoradionica;

DROP PROCEDURE IF EXISTS mjesta_radnika;
DELIMITER $$
CREATE PROCEDURE mjesta_radnika(p_sifZup INT)
BEGIN
   DECLARE c_pbr, c_brRad, dohvaceno INT DEFAULT NULL;
   DECLARE c_naziv VARCHAR(255) DEFAULT NULL;
   DECLARE c_avgKoef DECIMAL(4,2) DEFAULT 0;
   DECLARE i INT DEFAULT 0;
   DECLARE kur CURSOR FOR
      WITH agr AS
         (SELECT r.pbrStan, COUNT(*) AS br_radnika,
                 AVG(r.KoefPlaca) AS avg_koef
            FROM radnik r
            GROUP BY r.pbrStan)
      SELECT m.pbrMjesto, m.nazivMjesto, a.br_radnika, a.avg_koef
         FROM agr a
            JOIN mjesto m ON a.pbrStan = m.pbrMjesto
         WHERE m.sifZupanija = p_sifZup
         ORDER BY 3 DESC;

   DROP TEMPORARY TABLE IF EXISTS tmp;
   CREATE TEMPORARY TABLE tmp (pbr INT, naziv VARCHAR(255),
         brRadnika INT, avgKoef DECIMAL(4,2), tipMjesta VARCHAR(20));

   OPEN kur;
      SELECT FOUND_ROWS() INTO dohvaceno;
      WHILE i < dohvaceno DO
         FETCH kur INTO c_pbr, c_naziv, c_brRad, c_avgKoef;
         INSERT INTO tmp (pbr, naziv, brRadnika, avgKoef, tipMjesta)
            VALUES (c_pbr, c_naziv, c_brRad, c_avgKoef,
                    IF(c_brRad >= 5, 'VELIKO',
                       IF(c_brRad >= 2, 'SREDNJE', 'MALO')));
         SET i = i + 1;
      END WHILE;
   CLOSE kur;
   SELECT * FROM tmp;
END; $$
DELIMITER ;

/* Poziv procedure */
CALL mjesta_radnika(17);