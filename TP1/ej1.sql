--Query 1. List the name of boats that have deviated from their shipping lane by more than one
--kilometer, and the most recent time when they did this.
SELECT Name , MAX(Time) 
FROM Boat NATURAL JOIN Position p NATURAL JOIN ShippingLane s
WHERE  ST_Distance(p.Geom::Geography , s.Geom::Geography) > 1000
GROUP BY Name;



--Query 2. For each boat, find how far it has gone on its latest shipping lane. This progress will be
--presented as a percentage of the total length of the shipping lane.


/*Primero busco el ultimo position del Boat*/
SELECT *
FROM Boat b NATURAL JOIN Position p1 NATURAL JOIN ShippingLane s
WHERE p1.Time = (
	SELECT MAX(Time)
	FROM Position p2
	Where b.BoatId = p2.BoatId
	)
--o bien usando DISTICT ON
SELECT DISTINCT ON (p.BoatId) b.Name, p.Geom, p.Time
FROM Position p
JOIN Boat b ON b.BoatId = p.BoatId
ORDER BY p.BoatId, p.Time DESC;
/* Para solucionar la query vamos a necesitar una funcion de PostGis que dado un punto y una linea me devuelva un numeroque represente cuanto recorri de esa linea
esa funcion es https://postgis.net/docs/ST_LineLocatePoint.html la cual dado un punto
*/


SELECT b.name , ST_LineLocatePoint(s.Geom, p1.Geom) * 100 AS progress_percentage
FROM Boat b NATURAL JOIN Position p1 NATURAL JOIN ShippingLane s
WHERE p1.Time = (
	SELECT MAX(Time)
	FROM Position p2
	Where b.BoatId = p2.BoatId
	)

--Query 3. For each boat, count how many boats it has crossed so far. We suppose two boats have
--crossed each other if they have been ever less than 500 meters from each other.

SELECT BoatId, count(DISTINCT p2.BoatId) --no se si va el distinct, depende de la interpretacion del enunciado
FROM Position p1, Position p2
WHERE p1.BoatId != p2.BoatId AND p1.Time = p2.Time AND 
	ST_Distance(p1.Geom::Geography,p2.Geom::Geography) < 500
GROUP BY BoatId;


--Query 4. Find the shipping lanes that cross the shipping lane where the oldest boat (that is still
--running) has last been.

/*Primero busco el barco mas viejo en funionamiento*/
SELECT BoatId
FROM Boat
WHERE ToDate IS  NULL AND FromDate = (
	SELECT MIN(FromDate)
	FROM Boat
	WHERE ToDate IS NULL);
	
/*Busco su ultima ShippingLane*/

SELECT LaneId
FROM Position p1
WHERE p1.Time = (
	SELECT MAX(Time)
	FROM Position p2
	WHERE p1.BoatId = p2.BoatId
)
AND p1.BoatId = (
	SELECT BoatId
	FROM Boat
	WHERE ToDate IS NULL
	  AND FromDate = (
		SELECT MIN(FromDate)
		FROM Boat
		WHERE ToDate IS NULL
	  )
);

/*Ahora puedo conseguir la query final usando la funcion ST_Crosses()*/
SELECT s2.LaneID, s2.Geom
FROM ShippingLane s1 JOIN ShippingLane s2 
	ON ST_Crosses(s1.geom,s2.geom)
WHERE s1.LaneId = (SELECT LaneId
FROM Position p1
WHERE p1.Time = (
	SELECT MAX(Time)
	FROM Position p2
	WHERE p1.BoatId = p2.BoatId
)
AND p1.BoatId = (
	SELECT BoatId
	FROM Boat
	WHERE ToDate IS NULL
	  AND FromDate = (
		SELECT MIN(FromDate)
		FROM Boat
		WHERE ToDate IS NULL
	  )
))
	AND s1.LaneId <> s2.LaneId;
