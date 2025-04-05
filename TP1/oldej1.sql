-- Query 1
-- List the name of boats that have deviated from their
-- shipping lane by more than one
-- kilometer, and the most recent time when they did this.

--primera forma (fea)
WITH t11 AS( (
	SELECT b.Name as Name, p.Time as Time
	FROM Boat b, ShippingLane s, Position p
	WHERE p.BoatId = b.BoatId AND p.LaneId = s.LaneId
		AND ST_Distance(p.Geom::Geography,s.Geom::Geography) > 1000),
t2 AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Time DESC) AS RowN
	FROM t1)
SELECT Name,Time
From t2
Where RowNo = 1;

--segunda opcion
SELECT
    b.Name,
    MAX(p.Time) AS MostRecentDeviationTime
FROM Position p
JOIN Boat b ON p.BoatId = b.BoatId
JOIN ShippingLane s ON p.LaneId = s.LaneId
WHERE ST_Distance(p.Geom::Geography, s.Geom::Geography) > 1000  -- Distancia en metros
GROUP BY b.Name;

--Query 2. For each boat, find how far it has gone on its latest shipping lane. This progress will be
--presented as a percentage of the total length of the shipping lane.
SELECT BoatId, MAX(Time)
From Position
GROUP BY BoatId

SELECT
    p.BoatId,
    s.LaneId,
    100 * ST_LineLocatePoint(s.Geom, p.Geom) AS ProgressPercentage
FROM Position p
JOIN ShippingLane s ON p.LaneId = s.LaneId
JOIN (
    SELECT BoatId, MAX(Time) AS MostRecentTime
    FROM Position
    GROUP BY BoatId
) latest ON p.BoatId = latest.BoatId AND p.Time = latest.MostRecentTime;



--Query 3. For each boat, count how many boats it has crossed so far. We suppose two boats have
--crossed each other if they have been ever less than 500 meters from each other.
SELECT *
FROM Position p1, position p2
WHERE p1.boatId != p2.boatId --pido que las tuplas que me queden del prod cartesiano sean de barcos distintos
AND p1.Time = p2.Time -- en el mismo momento (podria agregar un rango de 5min para verificar)
AND ST_Distance(p1.geom::Geography, p2.geom::Geography) < 500
-- esta consulta me da las tuplas de dos barcos que en el mismo tiempoestuvieron a menos de 50m
--falta la parte de contar. Notemos que la info esta repetida, si dos barcos A y B se cruzaron
--Primero voy a tener la tupla a.id, time, a.geom , b.id, time ,b.geom y despues b.id,time,...,a.id. puedo agrupar por p1.boatid y contar

SELECT p1.Boatid, count(p2.boatId) as ShipsCrossed
FROM Position p1, position p2
WHERE p1.boatId != p2.boatId --pido que las tuplas que me queden del prod cartesiano sean de barcos distintos
AND p1.Time = p2.Time -- en el mismo momento (podria agregar un rango de 5min para verificar)
AND ST_Distance(p1.geom::Geography, p2.geom::Geography) < 500
GROUP BY p1.boatId

--Query 4. Find the shipping lanes that cross the shipping lane where the oldest boat (that is still
--running) has last been.

--busco el barco mas viejo activo
Select BoatId
From Boat
Where ToDate IS NULL AND FromDate
