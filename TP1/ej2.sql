--Ej 2
--Query 1. Draw a line between cities in Flanders and Wallonia that are less than 30~km away from
--each other.
/*Flanders es una region compuesta por las provincias de West-Vlaanderen y Oost-Vlaanderen
  Wallonia es otra region compuesta por las provincias de Hainaut,Namur,Luxembourg,Liege y Brabant*/

SELECT provincekey
from province
where provincename IN ('West-Vlaanderen','Oost-Vlaanderen','Hainaut','Namur','Luxembourg','Liege','Brabant');

/*
PREGUNTAR: SRIDS CUANDO CASTEPO A GEOGRAPHY!!!
*/


create view ej2_30km as
WITH cities_in_flanders AS (
    SELECT c.*
    FROM city c, province p
    WHERE p.provincekey IN (
        SELECT provincekey
        from province
        where provincename IN ('West-Vlaanderen','Oost-Vlaanderen')
    ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo),
cities_in_wallomia AS (
        SELECT c.*
        FROM city c, province p
        WHERE p.provincekey IN (
        SELECT provincekey
        from province
        where provincename IN ('Hainaut','Namur','Luxembourg','Liege','Brabant')
        ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo)

SELECT row_number() OVER () AS id,
       ST_MakeLine(c1.citygeo, c2.citygeo) AS geom
FROM cities_in_flanders c1 , cities_in_wallomia c2
WHERE ST_Distance(ST_Transform(c1.citygeo, 4326)::geography,   --CREO QUE ES AL PEDO EL CASTEO PORQUE EL SRID ORIGINAL YA ESTA EN METROS!
                  ST_Transform(c2.citygeo, 4326)::geography) < 30000;

create view ej2_60km as
WITH cities_in_flanders AS (
    SELECT c.*
    FROM city c, province p
    WHERE p.provincekey IN (
        SELECT provincekey
        from province
        where provincename IN ('West-Vlaanderen','Oost-Vlaanderen')
    ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo),
     cities_in_wallomia AS (
         SELECT c.*
         FROM city c, province p
         WHERE p.provincekey IN (
             SELECT provincekey
             from province
             where provincename IN ('Hainaut','Namur','Luxembourg','Liege','Brabant')
         ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo)

SELECT row_number() OVER () AS id,
       ST_MakeLine(c1.citygeo, c2.citygeo) AS geom
FROM cities_in_flanders c1 , cities_in_wallomia c2
WHERE ST_Distance(ST_Transform(c1.citygeo, 4326)::geography,
                  ST_Transform(c2.citygeo, 4326)::geography) < 60000;

create view ej2_10km as
WITH cities_in_flanders AS (
    SELECT c.*
    FROM city c, province p
    WHERE p.provincekey IN (
        SELECT provincekey
        from province
        where provincename IN ('West-Vlaanderen','Oost-Vlaanderen')
    ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo),
     cities_in_wallomia AS (
         SELECT c.*
         FROM city c, province p
         WHERE p.provincekey IN (
             SELECT provincekey
             from province
             where provincename IN ('Hainaut','Namur','Luxembourg','Liege','Brabant')
         ) AND st_contains(p.provincegeo,c.citygeo) AND p.provincegeo && c.citygeo)

SELECT row_number() OVER () AS id,
       ST_MakeLine(c1.citygeo, c2.citygeo) AS geom
FROM cities_in_flanders c1 , cities_in_wallomia c2
WHERE ST_Distance(ST_Transform(c1.citygeo, 4326)::geography,
                  ST_Transform(c2.citygeo, 4326)::geography) < 10000;

--Query 3. Compute the provinces that contain cities that are at an altitude higher than 300~m
--above sea level, and at less than 2~km from a river.

/* Usamos la funcion ST_Value(raster,point) que me devuelve el valor del raster en el punto*/

-- busco las municipalities con altitud mayor a 300
SELECT distinct  municipalitykey
FROM city
WHERE st_value((SELECT elevation from countryelevation),citygeo) > 300;

-- ahora lo uso como subquery para consegir las provincias

SELECT distinct provincekey
from municipality
where municipalitykey in (SELECT distinct  municipalitykey
                          FROM city
                          WHERE st_value((SELECT elevation from countryelevation),citygeo) > 300);

--otra forma usando join espacial
SELECT distinct p.*
FROM city c JOIN province p ON st_contains(p.provincegeo,c.citygeo)
WHERE st_value((SELECT elevation from countryelevation),c.citygeo) > 300;

--Query 4. Compute and display in QGIS the longest road by province. (vista en clase)
WITH t1 AS (
    SELECT p.ProvinceName, r.RoadId, ST_Length(ST_Intersection(r.RoadGeo, p.ProvinceGeo)) AS Length
    FROM Country c, Province p, Road r
    WHERE c.CountryName = 'Belgium' AND
        ST_Intersects(c.CountryGeo, p.ProvinceGeo) AND
        ST_Intersects(p.ProvinceGeo, r.RoadGeo) ),
     t2 AS (
         SELECT *, ROW_NUMBER() OVER (PARTITION BY ProvinceName ORDER BY Length DESC) AS RowNo
         FROM t1)
SELECT ProvinceName, RoadId, Length
FROM t2
WHERE RowNo = 1;