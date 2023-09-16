-- 12. Formulați în limbaj natural și implementați 5 cereri SQL complexe ce vor utiliza, în ansamblul lor, următoarele elemente:
-- • subcereri sincronizate în care intervin cel puțin 3 tabele
-- • subcereri nesincronizate în clauza FROM
-- • grupări de date cu subcereri nesincronizate in care intervin cel putin 3 tabele, funcții grup, filtrare la nivel de grupuri (in cadrul aceleiasi cereri)
-- • ordonări si utilizarea funcțiilor NVL și DECODE (in cadrul aceleiasi cereri)
-- • utilizarea a cel puțin 2 funcții pe șiruri de caractere, 2 funcții pe date calendaristice, a cel puțin unei expresii CASE
-- • utilizarea a cel puțin 1 bloc de cerere (clauza WITH)
-- Observație: Într-o cerere se vor regăsi mai multe elemente dintre cele enumerate mai sus, astfel încât cele 5 cereri să le cuprindă pe toate.

-- subcereri sincronizate în care intervin cel puțin 3 tabele: Afiseaza dintre toti userii, doar pe cei care au cel putin o comanda, iar tara lor din adresa este germania
    SELECT USERS.*, USER_ADDRESS.*
    FROM USERS
    JOIN USER_ADDRESS
    ON USERS.USER_ID = USER_ADDRESS.USER_ID
    WHERE EXISTS(
        SELECT orders.user_id
        FROM ORDERS
        WHERE orders.USER_ID = users.USER_ID
    )
    AND EXISTS(
        SELECT USER_ADDRESS.user_id
        FROM USER_ADDRESS
        WHERE USER_ADDRESS.USER_ID = USERS.USER_ID
        AND USER_ADDRESS.COUNTRY_ID = 'DE'
    )

-- • subcereri nesincronizate în clauza FROM : afisati pretul mediu al produselor de tip GME
    SELECT AVG(tabelNou.Price) AS AveragePrice
    FROM (select price from PRODUCTS where PRODUCT_TYPE_ID = 'GME') tabelNou;

-- grupări de date cu subcereri nesincronizate in care intervin cel putin 3 tabele, funcții grup, filtrare la nivel de grupuri (in cadrul aceleiasi cereri)
-- vrem sa afisam userii care au cumparat ceva, ce anume au cumparat cat a costat si cate au cumparat, alaturi de pretul mediu. lista trebuie sa fie ordonata dupa 
-- total amount, si sa fie afisati doar cei care au cheltuit mai mult de 100$
    SELECT u.USER_ID, u.username, u.firstname,
        u.lastname,
        p.NAME,
        SUM(p.price * pfo.QUANTITY) AS TotalAmount,
        SUM(pfo.QUANTITY) AS TotalQuantity,
        AVG(p.PRICE) AS AveragePrice
    FROM users u
    JOIN orders o ON u.user_id = o.USER_ID
    JOIN PRODUCT_FROM_ORDER pfo ON pfo.ORDER_ID = o.ORDER_ID
    JOIN products p ON pfo.PRODUCT_ID = p.PRODUCT_ID
    WHERE u.USER_ID IN(
        SELECT o.USER_ID
        FROM  orders o
        JOIN PRODUCT_FROM_ORDER pfo ON pfo.ORDER_ID = o.ORDER_ID
        JOIN PRODUCTS p ON p.PRODUCT_ID = pfo.PRODUCT_ID
        )
    GROUP BY
        u.USER_ID, u.username, u.firstname, u.lastname, p.NAME
    HAVING
        SUM(p.price * pfo.QUANTITY) > 100
    ORDER BY TotalAmount

    
-- • ordonări si utilizarea funcțiilor NVL și DECODE (in cadrul aceleiasi cereri) -selectati userii care au comenzi, vezi ce au comandat
-- daca nu au lastModified, atunci pune timestamp din momentul query ului, iar tipurile de categorii le transformi in format lung, GME GAME, samd.
-- de asemenea vrem sa vedem datele comenzii, id ul, id ul produsului, cantitatea comandata, pretul unui produs si costul total pentru
    SELECT
        u.USER_ID,
        u.USERNAME,
        NVL(u.MODIFIED, systimestamp) AS userModified,
        p.NAME as productName,
        DECODE(p.PRODUCT_TYPE_ID, 'GME', 'GAME', 'DLC', 'Downloadable Content', 'ADD', 'Addon') AS productType,
        o.ORDER_ID,
        p.PRODUCT_ID,
        pfo.QUANTITY,
        p.PRICE,
        SUM(p.PRICE * pfo.QUANTITY) AS costTotal
    FROM
        users u
    JOIN ORDERS o ON o.USER_ID = u.USER_ID
    join PRODUCT_FROM_ORDER pfo ON pfo.ORDER_ID = o.ORDER_ID
    join PRODUCTS p ON p.PRODUCT_ID = pfo.PRODUCT_ID

    GROUP BY u.USER_ID, u.USERNAME, NVL(u.MODIFIED, systimestamp), p.NAME,
            DECODE(p.PRODUCT_TYPE_ID, 'GME', 'GAME', 'DLC', 'Downloadable Content', 'ADD', 'Addon'),
            o.ORDER_ID, p.PRODUCT_ID, pfo.QUANTITY, p.PRICE
    order by ORDER_ID

--  • utilizarea a cel puțin 2 funcții pe șiruri de caractere, 2 funcții pe date calendaristice, a cel puțin unei expresii CASE
-- vrem sa unim prenumele si numele userilor intr o singura coloana si anume FULL_NAME, sa formatam tipul timestamp in string si sa ne apara doar anul, lune si ziua
-- de asemenea vrem ziua saptamanii sa fie afisata, si avem 2 cazuri, daca luna cand a fost creat contul este a 6 a sa apara iunie, daca e 7 sa apara iulie, altfel alta luna 
-- iar coloana sa se numeasca created_month
    SELECT
        UPPER(firstname) || ' ' || UPPER(lastname) AS full_name,
        TO_CHAR(CREATED, 'YYYY-MM-DD') AS formatted_created_date,
        TO_CHAR(CREATED, 'D') AS day_of_week,
        CASE
            WHEN EXTRACT(MONTH FROM CREATED) = 6 THEN 'JUNE'
            WHEN EXTRACT(MONTH FROM CREATED) = 7 THEN 'JULY'
                ELSE 'OTHER MONTH'
            END AS created_month
    FROM USERS

-- utilizarea a cel puțin 1 bloc de cerere (clauza WITH) - vrem sa facem un tabel addresses cu adresele existente din ITALIA, apoi din acel tabel temporar
-- sa selectam doar randurile cu orasul ROMA 'Rome', si sa ne afiseze numele intreg a persoanei care locuieste acolo, si adresa sa de email

    WITH addresses AS(
        SELECT USER_ADDRESS_ID, COUNTRY_ID, "state/province", CITY, STREET, ZIP, PHONE, USER_ID
        FROM USER_ADDRESS
        WHERE COUNTRY_ID = 'IT'
    ),
        addressFromItaly AS (
            select USER_ADDRESS_ID, COUNTRY_ID, "state/province", CITY, STREET, ZIP, PHONE, user_id
            from addresses
            where CITY = 'Rome'
        )
    select afi.user_address_id, aFI.country_id, aFI."state/province", aFI.city, aFI.street, aFI.zip, aFI.phone, aFI.user_id,
        UPPER(u.firstname) || ' ' || UPPER(u.lastname) AS full_name,
        u.EMAIL
    FROM addressFromItaly aFI
    join users u ON u.USER_ID = afi.USER_ID

-- 13. Implementarea a 3 operații de actualizare și de suprimare a datelor utilizând subcereri.
-- ACTUALIZARE:
-- scadem pretul produselor de tip Addon cu 5 dolari

    UPDATE PRODUCTS
    SET PRICE = PRICE - 5
    WHERE PRODUCT_TYPE_ID IN (
        SELECT PRODUCT_TYPE_ID
        FROM PRODUCT_TYPE
        WHERE PRODUCT_TYPE_ID = 'ADD'
        )
    AND PRICE > 10;

-- actualizam coloana amount din product_from_order, sa calculam cat a costat comanda la pretul pe care l avea produsul in momentul cumpararii
    UPDATE PRODUCT_FROM_ORDER pfo
    SET AMOUNT = (
        SELECT p.price * pfo.QUANTITY
        FROM products p
        WHERE p.PRODUCT_ID = pfo.PRODUCT_ID
        )

-- facem o reducere de 20% produselor care nu au facut parte din vreo comanda pana acum
    UPDATE PRODUCTS
    SET PRICE = PRICE * 0.8
    WHERE PRODUCT_TYPE_ID IN (
            SELECT PRODUCT_TYPE_ID
            FROM PRODUCT_TYPE
        )
    AND PRODUCT_ID NOT IN (
        SELECT PRODUCT_ID
        FROM PRODUCT_FROM_ORDER
        )
-- SUPRIMARE
-- stergem datele de payment pentru userii a caror username incepe cu orice litera si se termina in mily, de ex: Emily
    DELETE FROM USER_PAYMENT
    WHERE USER_ID IN (
        SELECT USER_ID
        FROM USERS
        WHERE USERNAME like '_mily'
        )
-- stergem randurile care au account_no de lungime mai mare decat 15
    DELETE FROM USER_PAYMENT
    WHERE ACCOUNT_NO IN (
        SELECT ACCOUNT_NO
        FROM USER_PAYMENT
        WHERE LENGTH(account_no) > 15
        )

-- stergem userii care au contul facut inainte de 2010, si care nu au nicio comanda plasata vreodata
    DELETE FROM USERS
    WHERE USER_ID IN (
        SELECT USER_ID
        FROM USERS
        WHERE TO_CHAR(CREATED, 'YYYY') < '2010'
        )
    AND USER_ID NOT IN (
        SELECT USER_ID
        FROM ORDERS
        )

-- 14. Crearea unei vizualizări complexe. Dați un exemplu de operație LMD permisă pe vizualizarea respectivă și un exemplu de operație LMD nepermisă.
-- Crearea view ului
    CREATE VIEW myComplexView AS
        SELECT
            orders.order_id,
            users.user_id,
            users.USERNAME,
            products.name,
            PRODUCT_FROM_ORDER.quantity,
            PRODUCT_FROM_ORDER.amount
    FROM ORDERS
    JOIN USERS ON orders.USER_ID = USERS.USER_ID
    JOIN PRODUCT_FROM_ORDER ON PRODUCT_FROM_ORDER.ORDER_ID = orders.ORDER_ID
    JOIN PRODUCTS ON PRODUCTS.PRODUCT_ID = PRODUCT_FROM_ORDER.PRODUCT_ID
    WHERE PRODUCT_FROM_ORDER.AMOUNT > 30
    ORDER BY AMOUNT

-- exemplu de operatie LMD nepermisa: 
-- fiind view complex, nu putem folosi insert pe mai multe dintre tabelele de baza deodata, trebuie doar unul care este protejat prin cheie
-- avand in vedere ca avem join, o instructiune poate afecta doar un singur tabel
    insert into MYCOMPLEXVIEW (ORDER_ID, USER_ID, USERNAME, NAME, QUANTITY, AMOUNT) values (1, 2, 'test', 'test', 3, 34)

-- exemplu de operatie LMD permisa: 
-- afectam doar tabelul de baza product_from_order, din care provine coloana amount
    update MYCOMPLEXVIEW
    set amount = amount + 1
    where user_id = 3

-- 15. Formulați în limbaj natural și implementați în SQL: o cerere ce utilizează operația outer-join pe minimum 4 tabele, o cerere ce utilizează operația division și o cerere care implementează analiza top-n.
-- cerere ce utilizează operația outer-join pe minimum 4 tabele
-- dorim sa afisam toti utilizatorii care au cel putin o recenzie, alaturi  de produsele care au cel putin un review, sunt de tip GME, si sa nu ramana la final coloane null datorita outer joinului
-- datorita faptului ca avem mai multe tabele si este un outer join, vom avea multe coloane nule, asa ca la final ne asiguram ca user_id nu e null, la fel si 
-- product_id, si afisati doa
select u.USER_ID, u.USERNAME, u.FIRSTNAME || ' ' || u.LASTNAME AS fullname,
       u.EMAIL, r.OPINION, r.RATING, p.product_id, p.PRODUCT_TYPE_ID, p.NAME,
        g.NAME AS genre,
     pbl.NAME AS publisher, pbl.EMAIL AS publisher_contact
from USERS u
RIGHT OUTER JOIN REVIEWS r ON u.USER_ID = r.USER_ID --da mi doar userii care au review uri
LEFT OUTER JOIN PRODUCTS p ON p.PRODUCT_ID = r.PRODUCT_ID --luam doar produsele care au review
FULL OUTER JOIN PRODUCT_GENRES pg ON pg.PRODUCT_ID = p.PRODUCT_ID --le luam pe toate pt ca toate produsele de tip GME au cel putin un gen asociat
FULL  OUTER JOIN GENRES g ON g.GENRE_ID = pg.GENRE_ID --facem rost de numele genurilor
FULL OUTER JOIN PUBLISHERS pbl ON pbl.PUBLISHER_ID = p.PUBLISHER_ID
where u.USER_ID IS NOT NULL AND p.PRODUCT_ID IS NOT NULL AND p.PRODUCT_TYPE_ID = 'GME'
ORDER BY u.USERNAME

-- o cerere ce utilizează operația division- afisati id ul tuturor comenzilor care contin toate produsele cu pretul mai mare decat 70 dolari. cum nu exista produse cu pretul mai mare de 70 dolari, 
-- vor fi afisate toate comenzile
-- am folosit metoda 1 pentru a utiliza operatia division, in care ne folosim de 2 not exists
SELECT DISTINCT ORDER_ID
FROM PRODUCT_FROM_ORDER a
WHERE NOT EXISTS(
    SELECT 1
    FROM products p
    WHERE price > 70
    AND NOT EXISTS(
        SELECT 'x'
        FROM PRODUCT_FROM_ORDER b
        WHERE p.PRODUCT_ID = b.PRODUCT_ID
        AND b.ORDER_ID = a.ORDER_ID
    )
)
-- cerere care implementează analiza top-n: 
-- dorim sa afisam primele 10 randuri din tabelul cu produsele sortate dupa pret
-- pentru asta avem la dispozitie 2 metode, fie sortam prima data tot tabelul cu un subquery
-- iar pe urma selectam din el doar primele 10 randuri: 
SELECT * FROM (
    SELECT * FROM PRODUCTS
    ORDER BY PRICE
) WHERE ROWNUM <= 10

-- fie folosim fetch 
select * from PRODUCTS
order by price
fetch first 10 rows only

-- 16. Optimizarea unei cereri, aplicând regulile de optimizare ce derivă din proprietățile operatorilor algebrei relaționale. Cererea va fi exprimată prin expresie algebrică, arbore algebric și limbaj (SQL), atât anterior cât și ulterior optimizării. ALTERNATIVĂ: două instrucțiuni select echivalente semantic, de comparat din punct de vedere a execuției (explicat plan de execuție).
--  vom rezolva alternativa, iar cele doua interogari pe care le vom analiza vor fi cele de la exercitiul anterior: 

SELECT * FROM (
    SELECT * FROM PRODUCTS
    ORDER BY PRICE
) WHERE ROWNUM <= 10

-- Aceasta interogare ne rezulta acest plan de executie: 
-- Plan hash value: 101034194
 
-- ------------------------------------------------------------------------------------
-- | Id  | Operation               | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-- ------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT        |          |    10 |   960 |     4  (25)| 00:00:01 |
-- |*  1 |  COUNT STOPKEY          |          |       |       |            |          |
-- |   2 |   VIEW                  |          |    44 |  4224 |     4  (25)| 00:00:01 |
-- |*  3 |    SORT ORDER BY STOPKEY|          |    44 |  1760 |     4  (25)| 00:00:01 |
-- |   4 |     TABLE ACCESS FULL   | PRODUCTS |    44 |  1760 |     3   (0)| 00:00:01 |
-- ------------------------------------------------------------------------------------
 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
 
--    1 - filter(ROWNUM<=10)
--    3 - filter(ROWNUM<=10)

-- TOTAL BYTES UTILIZATI PENTRU INTEROGARE: 8704

-- /////////////

select * from PRODUCTS
order by price
fetch first 10 rows only


-- Interogarea de mai sus, are acest plan de executie:
-- Plan hash value: 2063928979
 
-- -------------------------------------------------------------------------------------
-- | Id  | Operation                | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-- -------------------------------------------------------------------------------------
-- |   0 | SELECT STATEMENT         |          |    10 |  1220 |     4  (25)| 00:00:01 |
-- |*  1 |  VIEW                    |          |    10 |  1220 |     4  (25)| 00:00:01 |
-- |*  2 |   WINDOW SORT PUSHED RANK|          |    44 |  1760 |     4  (25)| 00:00:01 |
-- |   3 |    TABLE ACCESS FULL     | PRODUCTS |    44 |  1760 |     3   (0)| 00:00:01 |
-- -------------------------------------------------------------------------------------
 
-- Predicate Information (identified by operation id):
-- ---------------------------------------------------
 
-- "   1 - filter(""from$_subquery$_002"".""rowlimit_$$_rownumber""<=10)"
-- "   2 - filter(ROW_NUMBER() OVER ( ORDER BY ""PRODUCTS"".""PRICE"")<=10)"

-- TOTAL BYTES UTILIZATI PENTRU INTEROGARE: 5960

-- Interogarea cu subcerere incepe cu un acces la tabelul Products (4), apoi sorteaza, (*) ne arata ca la acel pas se creeaza o filtrare
-- pe urma creeaza o vizualizare, iar in punctul 1 numara din nou si filteaza, conditia WHERE ROWNUM <= 10. In final, sunt afisate randurile ramase

-- Interogarea cu fetch incepe cu un acces la tabelul Products(3), apoi direct se creeaza filtrarea prin order by price. in pasul (1), 
-- putem observa deja ca mai avem doar 10 randuri, deci a fost facut si fetchul

-- Ca diferenta intre ele, observam ca este prezis faptul ca interogarea cu fetch ar folosi mai putina memorie, deoarece avem un pas in minus.


-- EXERCITIUL 18 CONSISTENCY LEVELS

-- T1

CREATE TABLE PRD AS SELECT * FROM PRODUCTS;



--EXEMPLU DE DIRTY WRITE: 



--T1

SELECT PRICE FROM PRD WHERE PRODUCT_ID = 3;

-- 35

UPDATE PRD
SET PRICE = PRICE - 5
WHERE PRODUCT_ID = 3
AND PRICE > 10;

-- 30


-- T2
UPDATE PRD
SET PRICE = PRICE - 10
WHERE PRODUCT_ID = 3
AND PRICE > 10;
-- aici ar fi 20

--dar face T1 rollback inainte sa dea T2 commit
-- T1
rollback;  
-- A REVENIT LA 35

-- T2
SELECT PRICE FROM PRD WHERE PRODUCT_ID = 3;

-- VA FI 25 LA AMANDOI
commit; 

-- T1
SELECT PRICE FROM PRD WHERE PRODUCT_ID = 3;
-- 25





--EXEMPLU DE LOST UPDATE: 


-- T1

SELECT PRICE FROM PRD WHERE PRODUCT_ID = 3;
-- 35

UPDATE PRD
SET PRICE = PRICE + 10
WHERE PRODUCT_ID = 3;

-- 45

-- T2

UPDATE PRD
SET PRICE = PRICE + 20
WHERE PRODUCT_ID = 3;

-- 65

-- T1

commit

-- T2 

SELECT SALARY FROM PRD WHERE PRODUCT_ID = 3;
commit


-- T1

SELECT SALARY FROM PRD WHERE PRODUCT_ID = 3;


-- DIFERENTA DINTRE DIRTY WRITE I LOST UPDATE ESTE FAPTUL CA T1 FACE COMMIT IN LOC DE ROLLBACK

