-- Script to insert 60 players matching requested demographics.
-- Automatically resolves the schema containing the "Player" table so it can be re-run safely.
BEGIN;

DO $$
DECLARE
  target_schema text;
BEGIN
  SELECT table_schema
    INTO target_schema
    FROM information_schema.tables
   WHERE table_name = 'Player'
   ORDER BY CASE WHEN table_schema = 'public' THEN 0 ELSE 1 END, table_schema
   LIMIT 1;

  IF target_schema IS NULL THEN
    RAISE EXCEPTION 'No se encontró la tabla "Player". ¿Ejecutaste las migraciones de Prisma?';
  END IF;

  PERFORM set_config('search_path', target_schema, true);
END;
$$;

INSERT INTO "Player" ("firstName", "lastName", "birthDate", "dni", "gender", "clubId", "addressStreet", "addressNumber", "addressCity") VALUES
  ('Mateo', 'Gómez', '2017-01-05', '90000001', 'MASCULINO', NULL, 'Av. San Martín', '101', 'Rosario'),
  ('Santiago', 'Fernández', '2017-02-14', '90000002', 'MASCULINO', NULL, 'Calle Belgrano', '214', 'Santa Fe'),
  ('Benjamín', 'Rodríguez', '2017-03-22', '90000003', 'MASCULINO', NULL, 'Pasaje Mitre', '087', 'Córdoba'),
  ('Thiago', 'López', '2017-04-11', '90000004', 'MASCULINO', NULL, 'Boulevard Rivadavia', '320', 'Mendoza'),
  ('Lautaro', 'Pérez', '2017-05-19', '90000005', 'MASCULINO', NULL, 'Calle Lavalle', '045', 'La Plata'),
  ('Joaquín', 'Martínez', '2017-06-08', '90000006', 'MASCULINO', NULL, 'Av. Libertad', '560', 'Bahía Blanca'),
  ('Franco', 'Sosa', '2017-07-27', '90000007', 'MASCULINO', NULL, 'Calle Moreno', '233', 'Mar del Plata'),
  ('Bautista', 'Díaz', '2017-08-16', '90000008', 'MASCULINO', NULL, 'Calle Sarmiento', '178', 'Posadas'),
  ('Valentino', 'Rojas', '2017-09-03', '90000009', 'MASCULINO', NULL, 'Av. Independencia', '402', 'Resistencia'),
  ('Bruno', 'Acosta', '2017-10-21', '90000010', 'MASCULINO', NULL, 'Calle Italia', '096', 'Salta'),
  ('Felipe', 'Molina', '2017-11-12', '90000011', 'MASCULINO', NULL, 'Calle España', '275', 'Neuquén'),
  ('Emiliano', 'Castro', '2017-12-30', '90000012', 'MASCULINO', NULL, 'Av. Alem', '510', 'San Juan'),
  ('Tomás', 'Rivero', '2017-05-07', '90000013', 'MASCULINO', NULL, 'Calle Güemes', '134', 'San Luis'),
  ('Gael', 'Chávez', '2017-09-18', '90000014', 'MASCULINO', NULL, 'Calle Dorrego', '222', 'Bariloche'),
  ('Luca', 'Peralta', '2017-12-05', '90000015', 'MASCULINO', NULL, 'Calle 25 de Mayo', '389', 'Río Cuarto'),
  ('Juan', 'Navarro', '2018-01-09', '90000016', 'MASCULINO', NULL, 'Calle 9 de Julio', '157', 'Rosario'),
  ('Lucas', 'Herrera', '2018-02-28', '90000017', 'MASCULINO', NULL, 'Calle Tucumán', '446', 'Santa Fe'),
  ('Nicolás', 'Ortiz', '2018-03-17', '90000018', 'MASCULINO', NULL, 'Calle Entre Ríos', '118', 'Córdoba'),
  ('Ignacio', 'Silva', '2018-04-25', '90000019', 'MASCULINO', NULL, 'Calle Santiago del Estero', '361', 'Mendoza'),
  ('Agustín', 'Torres', '2018-05-14', '90000020', 'MASCULINO', NULL, 'Calle Catamarca', '205', 'La Plata'),
  ('Julián', 'Ramos', '2018-06-02', '90000021', 'MASCULINO', NULL, 'Calle Salta', '492', 'Bahía Blanca'),
  ('Bastián', 'Medina', '2018-07-21', '90000022', 'MASCULINO', NULL, 'Calle Jujuy', '163', 'Mar del Plata'),
  ('Pedro', 'Figueroa', '2018-08-10', '90000023', 'MASCULINO', NULL, 'Calle Chacabuco', '307', 'Posadas'),
  ('Dylan', 'Vega', '2018-09-29', '90000024', 'MASCULINO', NULL, 'Calle Bolívar', '521', 'Resistencia'),
  ('Simón', 'Arias', '2018-10-18', '90000025', 'MASCULINO', NULL, 'Calle French', '189', 'Salta'),
  ('Ramiro', 'Cáceres', '2018-11-06', '90000026', 'MASCULINO', NULL, 'Calle Saavedra', '340', 'Neuquén'),
  ('Facundo', 'Luna', '2018-12-25', '90000027', 'MASCULINO', NULL, 'Pasaje Rawson', '077', 'San Juan'),
  ('Jerónimo', 'Ibarra', '2018-05-30', '90000028', 'MASCULINO', NULL, 'Calle Liniers', '268', 'San Luis'),
  ('Enzo', 'Suárez', '2018-09-08', '90000029', 'MASCULINO', NULL, 'Calle Urquiza', '415', 'Bariloche'),
  ('Amaro', 'Paz', '2018-12-19', '90000030', 'MASCULINO', NULL, 'Calle Mitre', '502', 'Río Cuarto'),
  ('Camila', 'Ruiz', '2009-01-15', '90000031', 'FEMENINO', NULL, 'Calle Azcuénaga', '243', 'Rosario'),
  ('Valentina', 'Moreno', '2008-03-02', '90000032', 'FEMENINO', NULL, 'Calle San Lorenzo', '384', 'Santa Fe'),
  ('Martina', 'Gutiérrez', '2007-06-21', '90000033', 'FEMENINO', NULL, 'Calle Ituzaingó', '159', 'Córdoba'),
  ('Sofía', 'Álvarez', '2008-09-09', '90000034', 'FEMENINO', NULL, 'Calle Güiraldes', '276', 'Mendoza'),
  ('Isabella', 'Benítez', '2009-12-28', '90000035', 'FEMENINO', NULL, 'Calle Alsina', '347', 'La Plata'),
  ('Mía', 'Cano', '2008-05-17', '90000036', 'FEMENINO', NULL, 'Calle Arenales', '098', 'Bahía Blanca'),
  ('Jazmín', 'Delgado', '2007-11-05', '90000037', 'FEMENINO', NULL, 'Calle Caseros', '431', 'Mar del Plata'),
  ('Abigail', 'Ledesma', '2008-07-24', '90000038', 'FEMENINO', NULL, 'Calle Perón', '214', 'Posadas'),
  ('Renata', 'Ponce', '2009-02-12', '90000039', 'FEMENINO', NULL, 'Calle Pueyrredón', '365', 'Resistencia'),
  ('Catalina', 'Villar', '2007-04-01', '90000040', 'FEMENINO', NULL, 'Calle Laprida', '142', 'Salta'),
  ('Josefina', 'Aguilar', '2008-10-20', '90000041', 'FEMENINO', NULL, 'Calle Vélez Sarsfield', '508', 'Neuquén'),
  ('Luana', 'Carrizo', '2009-06-08', '90000042', 'FEMENINO', NULL, 'Calle Olazábal', '121', 'San Juan'),
  ('Ariana', 'Paredes', '2007-08-26', '90000043', 'FEMENINO', NULL, 'Calle Arístides Villanueva', '396', 'San Luis'),
  ('Paula', 'Quiroga', '2009-11-14', '90000044', 'FEMENINO', NULL, 'Calle Maipú', '287', 'Bariloche'),
  ('Lola', 'Serrano', '2008-01-30', '90000045', 'FEMENINO', NULL, 'Calle Rioja', '178', 'Río Cuarto'),
  ('Guadalupe', 'Toledo', '2007-05-19', '90000046', 'FEMENINO', NULL, 'Calle San Juan', '333', 'Paraná'),
  ('Clara', 'Vidal', '2008-09-27', '90000047', 'FEMENINO', NULL, 'Calle Santa Fe', '254', 'Corrientes'),
  ('Elena', 'Zárate', '2007-12-16', '90000048', 'FEMENINO', NULL, 'Calle Belgrano Sur', '489', 'Formosa'),
  ('Florencia', 'Barrios', '1999-02-05', '90000049', 'FEMENINO', NULL, 'Calle Lavalleja', '312', 'Rosario'),
  ('Carolina', 'Bustamante', '1998-04-22', '90000050', 'FEMENINO', NULL, 'Calle Junín', '205', 'Santa Fe'),
  ('Daniela', 'Crespo', '1997-07-11', '90000051', 'FEMENINO', NULL, 'Calle Ayacucho', '427', 'Córdoba'),
  ('Mariana', 'Domínguez', '1995-10-29', '90000052', 'FEMENINO', NULL, 'Calle French Norte', '168', 'Mendoza'),
  ('Julieta', 'Escobar', '2003-12-18', '90000053', 'FEMENINO', NULL, 'Calle Brandsen', '351', 'La Plata'),
  ('Agustina', 'Farias', '1996-06-07', '90000054', 'FEMENINO', NULL, 'Calle Catamarca Norte', '219', 'Bahía Blanca'),
  ('Milagros', 'Giménez', '2000-08-25', '90000055', 'FEMENINO', NULL, 'Calle Moreno Sur', '402', 'Mar del Plata'),
  ('Pilar', 'Ibáñez', '2002-11-13', '90000056', 'FEMENINO', NULL, 'Calle Sarmiento Norte', '143', 'Posadas'),
  ('Ludmila', 'Juárez', '1995-01-02', '90000057', 'FEMENINO', NULL, 'Calle Tucumán Sur', '286', 'Resistencia'),
  ('Josefina', 'Krause', '1997-03-21', '90000058', 'FEMENINO', NULL, 'Calle Entre Ríos Norte', '319', 'Salta'),
  ('Antonella', 'Leiva', '1996-05-30', '90000059', 'FEMENINO', NULL, 'Calle Salta Norte', '264', 'Neuquén'),
  ('Brenda', 'Maldonado', '2001-09-18', '90000060', 'FEMENINO', NULL, 'Calle Jujuy Norte', '197', 'San Juan'),
  ('Carla', 'Nazar', '1998-12-07', '90000061', 'FEMENINO', NULL, 'Calle Balcarce', '308', 'San Luis'),
  ('Rocío', 'Ocampo', '1995-02-24', '90000062', 'FEMENINO', NULL, 'Calle Dorrego Norte', '251', 'Bariloche'),
  ('Tamara', 'Pizarro', '2004-04-12', '90000063', 'FEMENINO', NULL, 'Calle Libertad Norte', '472', 'Río Cuarto'),
  ('Victoria', 'Quiñones', '2000-07-01', '90000064', 'FEMENINO', NULL, 'Calle Anchorena', '195', 'Paraná'),
  ('Natalia', 'Roldán', '1999-09-20', '90000065', 'FEMENINO', NULL, 'Calle San Martín Oeste', '388', 'Corrientes'),
  ('Gabriela', 'Sosa', '1996-11-09', '90000066', 'FEMENINO', NULL, 'Calle Rivadavia Sur', '266', 'Formosa')
ON CONFLICT ("dni") DO NOTHING;

COMMIT;
