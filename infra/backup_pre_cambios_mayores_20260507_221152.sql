--
-- PostgreSQL database dump
--

\restrict lB1eU2HEIln9ptCBEu4g0VprBmCaMqZA3fMuJccMwnb7owYpLBMQygeMCXEkpIG

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.tournament DROP CONSTRAINT IF EXISTS "tournament_leagueId_fkey";
ALTER TABLE IF EXISTS ONLY public."Zone" DROP CONSTRAINT IF EXISTS "Zone_tournamentId_fkey";
ALTER TABLE IF EXISTS ONLY public."ZoneMatchday" DROP CONSTRAINT IF EXISTS "ZoneMatchday_zoneId_fkey";
ALTER TABLE IF EXISTS ONLY public."User" DROP CONSTRAINT IF EXISTS "User_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserToken" DROP CONSTRAINT IF EXISTS "UserToken_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_roleId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_leagueId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_categoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."TournamentPosterTemplate" DROP CONSTRAINT IF EXISTS "TournamentPosterTemplate_tournamentId_fkey";
ALTER TABLE IF EXISTS ONLY public."TournamentCategory" DROP CONSTRAINT IF EXISTS "TournamentCategory_tournamentId_fkey";
ALTER TABLE IF EXISTS ONLY public."TournamentCategory" DROP CONSTRAINT IF EXISTS "TournamentCategory_categoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."Team" DROP CONSTRAINT IF EXISTS "Team_tournamentCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."Team" DROP CONSTRAINT IF EXISTS "Team_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."Roster" DROP CONSTRAINT IF EXISTS "Roster_tournamentCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."Roster" DROP CONSTRAINT IF EXISTS "Roster_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."RosterPlayer" DROP CONSTRAINT IF EXISTS "RosterPlayer_rosterId_fkey";
ALTER TABLE IF EXISTS ONLY public."RosterPlayer" DROP CONSTRAINT IF EXISTS "RosterPlayer_playerId_fkey";
ALTER TABLE IF EXISTS ONLY public."RolePermission" DROP CONSTRAINT IF EXISTS "RolePermission_roleId_fkey";
ALTER TABLE IF EXISTS ONLY public."RolePermission" DROP CONSTRAINT IF EXISTS "RolePermission_permissionId_fkey";
ALTER TABLE IF EXISTS ONLY public."PlayerTournamentClub" DROP CONSTRAINT IF EXISTS "PlayerTournamentClub_tournamentId_fkey";
ALTER TABLE IF EXISTS ONLY public."PlayerTournamentClub" DROP CONSTRAINT IF EXISTS "PlayerTournamentClub_playerId_fkey";
ALTER TABLE IF EXISTS ONLY public."PlayerTournamentClub" DROP CONSTRAINT IF EXISTS "PlayerTournamentClub_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."PasswordResetToken" DROP CONSTRAINT IF EXISTS "PasswordResetToken_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."PasswordChangeRequest" DROP CONSTRAINT IF EXISTS "PasswordChangeRequest_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."OtherGoal" DROP CONSTRAINT IF EXISTS "OtherGoal_matchCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."OtherGoal" DROP CONSTRAINT IF EXISTS "OtherGoal_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."Match" DROP CONSTRAINT IF EXISTS "Match_zoneId_fkey";
ALTER TABLE IF EXISTS ONLY public."Match" DROP CONSTRAINT IF EXISTS "Match_tournamentId_fkey";
ALTER TABLE IF EXISTS ONLY public."Match" DROP CONSTRAINT IF EXISTS "Match_homeClubId_fkey";
ALTER TABLE IF EXISTS ONLY public."Match" DROP CONSTRAINT IF EXISTS "Match_awayClubId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchPosterCache" DROP CONSTRAINT IF EXISTS "MatchPosterCache_matchId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchLog" DROP CONSTRAINT IF EXISTS "MatchLog_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchLog" DROP CONSTRAINT IF EXISTS "MatchLog_matchId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchCategory" DROP CONSTRAINT IF EXISTS "MatchCategory_tournamentCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchCategory" DROP CONSTRAINT IF EXISTS "MatchCategory_matchId_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchCategory" DROP CONSTRAINT IF EXISTS "MatchCategory_closedById_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchAttachment" DROP CONSTRAINT IF EXISTS "MatchAttachment_uploadedById_fkey";
ALTER TABLE IF EXISTS ONLY public."MatchAttachment" DROP CONSTRAINT IF EXISTS "MatchAttachment_matchId_fkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_playerId_fkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_matchCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."FlyerTemplate" DROP CONSTRAINT IF EXISTS "FlyerTemplate_competitionId_fkey";
ALTER TABLE IF EXISTS ONLY public."EmailVerificationToken" DROP CONSTRAINT IF EXISTS "EmailVerificationToken_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."EmailChangeRequest" DROP CONSTRAINT IF EXISTS "EmailChangeRequest_userId_fkey";
ALTER TABLE IF EXISTS ONLY public."Club" DROP CONSTRAINT IF EXISTS "Club_leagueId_fkey";
ALTER TABLE IF EXISTS ONLY public."ClubZone" DROP CONSTRAINT IF EXISTS "ClubZone_zoneId_fkey";
ALTER TABLE IF EXISTS ONLY public."ClubZone" DROP CONSTRAINT IF EXISTS "ClubZone_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."CategoryStanding" DROP CONSTRAINT IF EXISTS "CategoryStanding_zoneId_fkey";
ALTER TABLE IF EXISTS ONLY public."CategoryStanding" DROP CONSTRAINT IF EXISTS "CategoryStanding_tournamentCategoryId_fkey";
ALTER TABLE IF EXISTS ONLY public."CategoryStanding" DROP CONSTRAINT IF EXISTS "CategoryStanding_clubId_fkey";
ALTER TABLE IF EXISTS ONLY public."AuditLog" DROP CONSTRAINT IF EXISTS "AuditLog_userId_fkey";
DROP INDEX IF EXISTS public."Zone_tournamentId_name_key";
DROP INDEX IF EXISTS public."ZoneMatchday_zoneId_matchday_key";
DROP INDEX IF EXISTS public."User_email_key";
DROP INDEX IF EXISTS public."UserToken_token_key";
DROP INDEX IF EXISTS public."UserRole_userId_roleId_leagueId_clubId_categoryId_key";
DROP INDEX IF EXISTS public."TournamentPosterTemplate_tournamentId_key";
DROP INDEX IF EXISTS public."TournamentCategory_tournamentId_categoryId_key";
DROP INDEX IF EXISTS public."Team_clubId_tournamentCategoryId_publicName_key";
DROP INDEX IF EXISTS public."Roster_clubId_tournamentCategoryId_key";
DROP INDEX IF EXISTS public."RosterPlayer_rosterId_playerId_key";
DROP INDEX IF EXISTS public."Role_key_key";
DROP INDEX IF EXISTS public."Player_dni_key";
DROP INDEX IF EXISTS public."PlayerTournamentClub_playerId_tournamentId_key";
DROP INDEX IF EXISTS public."Permission_module_action_scope_key";
DROP INDEX IF EXISTS public."PasswordResetToken_token_key";
DROP INDEX IF EXISTS public."PasswordChangeRequest_token_key";
DROP INDEX IF EXISTS public."MatchPosterCache_matchId_key";
DROP INDEX IF EXISTS public."League_slug_key";
DROP INDEX IF EXISTS public."FlyerTemplate_competitionId_key";
DROP INDEX IF EXISTS public."EmailVerificationToken_token_key";
DROP INDEX IF EXISTS public."EmailChangeRequest_token_key";
DROP INDEX IF EXISTS public."Club_slug_key";
DROP INDEX IF EXISTS public."ClubZone_zoneId_clubId_key";
DROP INDEX IF EXISTS public."ClubZone_clubId_zoneId_key";
DROP INDEX IF EXISTS public."Category_name_key";
DROP INDEX IF EXISTS public."CategoryStanding_zoneId_tournamentCategoryId_clubId_key";
ALTER TABLE IF EXISTS ONLY public.tournament DROP CONSTRAINT IF EXISTS tournament_pkey;
ALTER TABLE IF EXISTS ONLY public._prisma_migrations DROP CONSTRAINT IF EXISTS _prisma_migrations_pkey;
ALTER TABLE IF EXISTS ONLY public."Zone" DROP CONSTRAINT IF EXISTS "Zone_pkey";
ALTER TABLE IF EXISTS ONLY public."ZoneMatchday" DROP CONSTRAINT IF EXISTS "ZoneMatchday_pkey";
ALTER TABLE IF EXISTS ONLY public."User" DROP CONSTRAINT IF EXISTS "User_pkey";
ALTER TABLE IF EXISTS ONLY public."UserToken" DROP CONSTRAINT IF EXISTS "UserToken_pkey";
ALTER TABLE IF EXISTS ONLY public."UserRole" DROP CONSTRAINT IF EXISTS "UserRole_pkey";
ALTER TABLE IF EXISTS ONLY public."TournamentPosterTemplate" DROP CONSTRAINT IF EXISTS "TournamentPosterTemplate_pkey";
ALTER TABLE IF EXISTS ONLY public."TournamentCategory" DROP CONSTRAINT IF EXISTS "TournamentCategory_pkey";
ALTER TABLE IF EXISTS ONLY public."Team" DROP CONSTRAINT IF EXISTS "Team_pkey";
ALTER TABLE IF EXISTS ONLY public."SiteIdentity" DROP CONSTRAINT IF EXISTS "SiteIdentity_pkey";
ALTER TABLE IF EXISTS ONLY public."Roster" DROP CONSTRAINT IF EXISTS "Roster_pkey";
ALTER TABLE IF EXISTS ONLY public."RosterPlayer" DROP CONSTRAINT IF EXISTS "RosterPlayer_pkey";
ALTER TABLE IF EXISTS ONLY public."Role" DROP CONSTRAINT IF EXISTS "Role_pkey";
ALTER TABLE IF EXISTS ONLY public."RolePermission" DROP CONSTRAINT IF EXISTS "RolePermission_pkey";
ALTER TABLE IF EXISTS ONLY public."Player" DROP CONSTRAINT IF EXISTS "Player_pkey";
ALTER TABLE IF EXISTS ONLY public."PlayerTournamentClub" DROP CONSTRAINT IF EXISTS "PlayerTournamentClub_pkey";
ALTER TABLE IF EXISTS ONLY public."Permission" DROP CONSTRAINT IF EXISTS "Permission_pkey";
ALTER TABLE IF EXISTS ONLY public."PasswordResetToken" DROP CONSTRAINT IF EXISTS "PasswordResetToken_pkey";
ALTER TABLE IF EXISTS ONLY public."PasswordChangeRequest" DROP CONSTRAINT IF EXISTS "PasswordChangeRequest_pkey";
ALTER TABLE IF EXISTS ONLY public."OtherGoal" DROP CONSTRAINT IF EXISTS "OtherGoal_pkey";
ALTER TABLE IF EXISTS ONLY public."Match" DROP CONSTRAINT IF EXISTS "Match_pkey";
ALTER TABLE IF EXISTS ONLY public."MatchPosterCache" DROP CONSTRAINT IF EXISTS "MatchPosterCache_pkey";
ALTER TABLE IF EXISTS ONLY public."MatchLog" DROP CONSTRAINT IF EXISTS "MatchLog_pkey";
ALTER TABLE IF EXISTS ONLY public."MatchCategory" DROP CONSTRAINT IF EXISTS "MatchCategory_pkey";
ALTER TABLE IF EXISTS ONLY public."MatchAttachment" DROP CONSTRAINT IF EXISTS "MatchAttachment_pkey";
ALTER TABLE IF EXISTS ONLY public."League" DROP CONSTRAINT IF EXISTS "League_pkey";
ALTER TABLE IF EXISTS ONLY public."Goal" DROP CONSTRAINT IF EXISTS "Goal_pkey";
ALTER TABLE IF EXISTS ONLY public."FlyerTemplate" DROP CONSTRAINT IF EXISTS "FlyerTemplate_pkey";
ALTER TABLE IF EXISTS ONLY public."EmailVerificationToken" DROP CONSTRAINT IF EXISTS "EmailVerificationToken_pkey";
ALTER TABLE IF EXISTS ONLY public."EmailChangeRequest" DROP CONSTRAINT IF EXISTS "EmailChangeRequest_pkey";
ALTER TABLE IF EXISTS ONLY public."Club" DROP CONSTRAINT IF EXISTS "Club_pkey";
ALTER TABLE IF EXISTS ONLY public."ClubZone" DROP CONSTRAINT IF EXISTS "ClubZone_pkey";
ALTER TABLE IF EXISTS ONLY public."Category" DROP CONSTRAINT IF EXISTS "Category_pkey";
ALTER TABLE IF EXISTS ONLY public."CategoryStanding" DROP CONSTRAINT IF EXISTS "CategoryStanding_pkey";
ALTER TABLE IF EXISTS ONLY public."AuditLog" DROP CONSTRAINT IF EXISTS "AuditLog_pkey";
ALTER TABLE IF EXISTS public.tournament ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."ZoneMatchday" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Zone" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."UserToken" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."UserRole" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."User" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."TournamentPosterTemplate" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."TournamentCategory" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Team" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."RosterPlayer" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Roster" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Role" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."PlayerTournamentClub" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Player" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Permission" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."PasswordResetToken" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."PasswordChangeRequest" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."OtherGoal" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."MatchPosterCache" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."MatchLog" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."MatchCategory" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."MatchAttachment" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Match" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."League" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Goal" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."FlyerTemplate" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."EmailVerificationToken" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."EmailChangeRequest" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."ClubZone" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Club" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."CategoryStanding" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."Category" ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public."AuditLog" ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.tournament_id_seq;
DROP TABLE IF EXISTS public.tournament;
DROP TABLE IF EXISTS public._prisma_migrations;
DROP SEQUENCE IF EXISTS public."Zone_id_seq";
DROP SEQUENCE IF EXISTS public."ZoneMatchday_id_seq";
DROP TABLE IF EXISTS public."ZoneMatchday";
DROP TABLE IF EXISTS public."Zone";
DROP SEQUENCE IF EXISTS public."User_id_seq";
DROP SEQUENCE IF EXISTS public."UserToken_id_seq";
DROP TABLE IF EXISTS public."UserToken";
DROP SEQUENCE IF EXISTS public."UserRole_id_seq";
DROP TABLE IF EXISTS public."UserRole";
DROP TABLE IF EXISTS public."User";
DROP SEQUENCE IF EXISTS public."TournamentPosterTemplate_id_seq";
DROP TABLE IF EXISTS public."TournamentPosterTemplate";
DROP SEQUENCE IF EXISTS public."TournamentCategory_id_seq";
DROP TABLE IF EXISTS public."TournamentCategory";
DROP SEQUENCE IF EXISTS public."Team_id_seq";
DROP TABLE IF EXISTS public."Team";
DROP TABLE IF EXISTS public."SiteIdentity";
DROP SEQUENCE IF EXISTS public."Roster_id_seq";
DROP SEQUENCE IF EXISTS public."RosterPlayer_id_seq";
DROP TABLE IF EXISTS public."RosterPlayer";
DROP TABLE IF EXISTS public."Roster";
DROP SEQUENCE IF EXISTS public."Role_id_seq";
DROP TABLE IF EXISTS public."RolePermission";
DROP TABLE IF EXISTS public."Role";
DROP SEQUENCE IF EXISTS public."Player_id_seq";
DROP SEQUENCE IF EXISTS public."PlayerTournamentClub_id_seq";
DROP TABLE IF EXISTS public."PlayerTournamentClub";
DROP TABLE IF EXISTS public."Player";
DROP SEQUENCE IF EXISTS public."Permission_id_seq";
DROP TABLE IF EXISTS public."Permission";
DROP SEQUENCE IF EXISTS public."PasswordResetToken_id_seq";
DROP TABLE IF EXISTS public."PasswordResetToken";
DROP SEQUENCE IF EXISTS public."PasswordChangeRequest_id_seq";
DROP TABLE IF EXISTS public."PasswordChangeRequest";
DROP SEQUENCE IF EXISTS public."OtherGoal_id_seq";
DROP TABLE IF EXISTS public."OtherGoal";
DROP SEQUENCE IF EXISTS public."Match_id_seq";
DROP SEQUENCE IF EXISTS public."MatchPosterCache_id_seq";
DROP TABLE IF EXISTS public."MatchPosterCache";
DROP SEQUENCE IF EXISTS public."MatchLog_id_seq";
DROP TABLE IF EXISTS public."MatchLog";
DROP SEQUENCE IF EXISTS public."MatchCategory_id_seq";
DROP TABLE IF EXISTS public."MatchCategory";
DROP SEQUENCE IF EXISTS public."MatchAttachment_id_seq";
DROP TABLE IF EXISTS public."MatchAttachment";
DROP TABLE IF EXISTS public."Match";
DROP SEQUENCE IF EXISTS public."League_id_seq";
DROP TABLE IF EXISTS public."League";
DROP SEQUENCE IF EXISTS public."Goal_id_seq";
DROP TABLE IF EXISTS public."Goal";
DROP SEQUENCE IF EXISTS public."FlyerTemplate_id_seq";
DROP TABLE IF EXISTS public."FlyerTemplate";
DROP SEQUENCE IF EXISTS public."EmailVerificationToken_id_seq";
DROP TABLE IF EXISTS public."EmailVerificationToken";
DROP SEQUENCE IF EXISTS public."EmailChangeRequest_id_seq";
DROP TABLE IF EXISTS public."EmailChangeRequest";
DROP SEQUENCE IF EXISTS public."Club_id_seq";
DROP SEQUENCE IF EXISTS public."ClubZone_id_seq";
DROP TABLE IF EXISTS public."ClubZone";
DROP TABLE IF EXISTS public."Club";
DROP SEQUENCE IF EXISTS public."Category_id_seq";
DROP SEQUENCE IF EXISTS public."CategoryStanding_id_seq";
DROP TABLE IF EXISTS public."CategoryStanding";
DROP TABLE IF EXISTS public."Category";
DROP SEQUENCE IF EXISTS public."AuditLog_id_seq";
DROP TABLE IF EXISTS public."AuditLog";
DROP TYPE IF EXISTS public."ZoneStatus";
DROP TYPE IF EXISTS public."TournamentStatus";
DROP TYPE IF EXISTS public."TournamentChampionMode";
DROP TYPE IF EXISTS public."Scope";
DROP TYPE IF EXISTS public."Round";
DROP TYPE IF EXISTS public."RoleKey";
DROP TYPE IF EXISTS public."Module";
DROP TYPE IF EXISTS public."MatchdayStatus";
DROP TYPE IF EXISTS public."MatchStatus";
DROP TYPE IF EXISTS public."Gender";
DROP TYPE IF EXISTS public."GameDay";
DROP TYPE IF EXISTS public."Action";
--
-- Name: Action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Action" AS ENUM (
    'VIEW',
    'CREATE',
    'UPDATE',
    'DELETE',
    'MANAGE'
);


--
-- Name: GameDay; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."GameDay" AS ENUM (
    'DOMINGO',
    'LUNES',
    'MARTES',
    'MIERCOLES',
    'JUEVES',
    'VIERNES',
    'SABADO'
);


--
-- Name: Gender; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Gender" AS ENUM (
    'MASCULINO',
    'FEMENINO',
    'MIXTO'
);


--
-- Name: MatchStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."MatchStatus" AS ENUM (
    'PROGRAMMED',
    'PENDING',
    'FINISHED'
);


--
-- Name: MatchdayStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."MatchdayStatus" AS ENUM (
    'PENDING',
    'IN_PROGRESS',
    'INCOMPLETE',
    'PLAYED'
);


--
-- Name: Module; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Module" AS ENUM (
    'LIGAS',
    'TORNEOS',
    'ZONAS',
    'FIXTURE',
    'PARTIDOS',
    'RESULTADOS',
    'TABLAS',
    'CLUBES',
    'CATEGORIAS',
    'JUGADORES',
    'PLANTELES',
    'CONFIGURACION',
    'USUARIOS',
    'ROLES',
    'PERMISOS',
    'REPORTES'
);


--
-- Name: RoleKey; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."RoleKey" AS ENUM (
    'ADMIN',
    'COLLABORATOR',
    'DELEGATE',
    'COACH',
    'USER'
);


--
-- Name: Round; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Round" AS ENUM (
    'FIRST',
    'SECOND'
);


--
-- Name: Scope; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."Scope" AS ENUM (
    'GLOBAL',
    'LIGA',
    'CLUB',
    'CATEGORIA'
);


--
-- Name: TournamentChampionMode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TournamentChampionMode" AS ENUM (
    'ROUND_AND_ANNUAL',
    'GLOBAL'
);


--
-- Name: TournamentStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TournamentStatus" AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'FINISHED'
);


--
-- Name: ZoneStatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."ZoneStatus" AS ENUM (
    'OPEN',
    'IN_PROGRESS',
    'PLAYING',
    'FINISHED'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AuditLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AuditLog" (
    id integer NOT NULL,
    "userId" integer,
    action text NOT NULL,
    metadata jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: AuditLog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."AuditLog_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: AuditLog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."AuditLog_id_seq" OWNED BY public."AuditLog".id;


--
-- Name: Category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Category" (
    id integer NOT NULL,
    name text NOT NULL,
    "birthYearMin" integer NOT NULL,
    "birthYearMax" integer NOT NULL,
    gender public."Gender" NOT NULL,
    "minPlayers" integer DEFAULT 7 NOT NULL,
    mandatory boolean DEFAULT true NOT NULL,
    promotional boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: CategoryStanding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CategoryStanding" (
    id integer NOT NULL,
    "zoneId" integer NOT NULL,
    "tournamentCategoryId" integer NOT NULL,
    "clubId" integer NOT NULL,
    played integer DEFAULT 0 NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    draws integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    "goalsFor" integer DEFAULT 0 NOT NULL,
    "goalsAgainst" integer DEFAULT 0 NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    "goalDifference" integer DEFAULT 0 NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: CategoryStanding_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."CategoryStanding_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: CategoryStanding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."CategoryStanding_id_seq" OWNED BY public."CategoryStanding".id;


--
-- Name: Category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Category_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Category_id_seq" OWNED BY public."Category".id;


--
-- Name: Club; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Club" (
    id integer NOT NULL,
    name text NOT NULL,
    "shortName" text,
    slug text NOT NULL,
    "leagueId" integer,
    "primaryColor" text,
    "secondaryColor" text,
    active boolean DEFAULT true NOT NULL,
    "logoKey" text,
    "logoUrl" text,
    "instagramUrl" text,
    "facebookUrl" text,
    latitude numeric(11,8),
    longitude numeric(11,8),
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "homeAddress" text
);


--
-- Name: ClubZone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ClubZone" (
    id integer NOT NULL,
    "clubId" integer NOT NULL,
    "zoneId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ClubZone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ClubZone_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ClubZone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ClubZone_id_seq" OWNED BY public."ClubZone".id;


--
-- Name: Club_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Club_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Club_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Club_id_seq" OWNED BY public."Club".id;


--
-- Name: EmailChangeRequest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmailChangeRequest" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    "newEmail" text NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "confirmedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: EmailChangeRequest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."EmailChangeRequest_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EmailChangeRequest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."EmailChangeRequest_id_seq" OWNED BY public."EmailChangeRequest".id;


--
-- Name: EmailVerificationToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmailVerificationToken" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "usedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: EmailVerificationToken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."EmailVerificationToken_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EmailVerificationToken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."EmailVerificationToken_id_seq" OWNED BY public."EmailVerificationToken".id;


--
-- Name: FlyerTemplate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."FlyerTemplate" (
    id integer NOT NULL,
    "competitionId" integer,
    "backgroundKey" text,
    "layoutKey" text,
    "layoutFileName" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: FlyerTemplate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."FlyerTemplate_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: FlyerTemplate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."FlyerTemplate_id_seq" OWNED BY public."FlyerTemplate".id;


--
-- Name: Goal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Goal" (
    id integer NOT NULL,
    "matchCategoryId" integer NOT NULL,
    "playerId" integer NOT NULL,
    "clubId" integer NOT NULL,
    minute integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Goal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Goal_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Goal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Goal_id_seq" OWNED BY public."Goal".id;


--
-- Name: League; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."League" (
    id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    "colorHex" text DEFAULT '#0057b8'::text NOT NULL,
    "gameDay" public."GameDay" NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: League_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."League_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: League_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."League_id_seq" OWNED BY public."League".id;


--
-- Name: Match; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Match" (
    id integer NOT NULL,
    "tournamentId" integer NOT NULL,
    "zoneId" integer NOT NULL,
    matchday integer NOT NULL,
    round public."Round" NOT NULL,
    date timestamp(3) without time zone,
    status public."MatchStatus" DEFAULT 'PROGRAMMED'::public."MatchStatus" NOT NULL,
    "homeClubId" integer,
    "awayClubId" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: MatchAttachment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MatchAttachment" (
    id integer NOT NULL,
    "matchId" integer NOT NULL,
    url text NOT NULL,
    "uploadedById" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: MatchAttachment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."MatchAttachment_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: MatchAttachment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."MatchAttachment_id_seq" OWNED BY public."MatchAttachment".id;


--
-- Name: MatchCategory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MatchCategory" (
    id integer NOT NULL,
    "matchId" integer NOT NULL,
    "tournamentCategoryId" integer NOT NULL,
    "kickoffTime" text,
    "isPromocional" boolean DEFAULT false NOT NULL,
    "homeScore" integer DEFAULT 0 NOT NULL,
    "awayScore" integer DEFAULT 0 NOT NULL,
    "closedAt" timestamp(3) without time zone,
    "closedById" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: MatchCategory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."MatchCategory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: MatchCategory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."MatchCategory_id_seq" OWNED BY public."MatchCategory".id;


--
-- Name: MatchLog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MatchLog" (
    id integer NOT NULL,
    "matchId" integer NOT NULL,
    "userId" integer,
    action text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: MatchLog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."MatchLog_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: MatchLog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."MatchLog_id_seq" OWNED BY public."MatchLog".id;


--
-- Name: MatchPosterCache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MatchPosterCache" (
    id integer NOT NULL,
    "matchId" integer NOT NULL,
    "templateVersion" integer NOT NULL,
    hash text NOT NULL,
    "storageKey" text NOT NULL,
    "generatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: MatchPosterCache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."MatchPosterCache_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: MatchPosterCache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."MatchPosterCache_id_seq" OWNED BY public."MatchPosterCache".id;


--
-- Name: Match_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Match_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Match_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Match_id_seq" OWNED BY public."Match".id;


--
-- Name: OtherGoal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."OtherGoal" (
    id integer NOT NULL,
    "matchCategoryId" integer NOT NULL,
    "clubId" integer NOT NULL,
    goals integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: OtherGoal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."OtherGoal_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: OtherGoal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."OtherGoal_id_seq" OWNED BY public."OtherGoal".id;


--
-- Name: PasswordChangeRequest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PasswordChangeRequest" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    token text NOT NULL,
    "newPassword" text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "confirmedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: PasswordChangeRequest_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."PasswordChangeRequest_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: PasswordChangeRequest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."PasswordChangeRequest_id_seq" OWNED BY public."PasswordChangeRequest".id;


--
-- Name: PasswordResetToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PasswordResetToken" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "usedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: PasswordResetToken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."PasswordResetToken_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: PasswordResetToken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."PasswordResetToken_id_seq" OWNED BY public."PasswordResetToken".id;


--
-- Name: Permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Permission" (
    id integer NOT NULL,
    module public."Module" NOT NULL,
    action public."Action" NOT NULL,
    scope public."Scope" NOT NULL,
    description text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Permission_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Permission_id_seq" OWNED BY public."Permission".id;


--
-- Name: Player; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Player" (
    id integer NOT NULL,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "birthDate" timestamp(3) without time zone NOT NULL,
    dni text NOT NULL,
    gender public."Gender" DEFAULT 'MASCULINO'::public."Gender" NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "addressStreet" text,
    "addressNumber" text,
    "addressCity" text,
    "emergencyName" text,
    "emergencyRelationship" text,
    "emergencyPhone" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: PlayerTournamentClub; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PlayerTournamentClub" (
    id integer NOT NULL,
    "playerId" integer NOT NULL,
    "clubId" integer NOT NULL,
    "tournamentId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: PlayerTournamentClub_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."PlayerTournamentClub_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: PlayerTournamentClub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."PlayerTournamentClub_id_seq" OWNED BY public."PlayerTournamentClub".id;


--
-- Name: Player_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Player_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Player_id_seq" OWNED BY public."Player".id;


--
-- Name: Role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Role" (
    id integer NOT NULL,
    key public."RoleKey" NOT NULL,
    name text NOT NULL,
    description text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: RolePermission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RolePermission" (
    "roleId" integer NOT NULL,
    "permissionId" integer NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: Role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Role_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Role_id_seq" OWNED BY public."Role".id;


--
-- Name: Roster; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Roster" (
    id integer NOT NULL,
    "clubId" integer NOT NULL,
    "tournamentCategoryId" integer NOT NULL,
    "lockedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: RosterPlayer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."RosterPlayer" (
    id integer NOT NULL,
    "rosterId" integer NOT NULL,
    "playerId" integer NOT NULL,
    jersey integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: RosterPlayer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."RosterPlayer_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: RosterPlayer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."RosterPlayer_id_seq" OWNED BY public."RosterPlayer".id;


--
-- Name: Roster_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Roster_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Roster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Roster_id_seq" OWNED BY public."Roster".id;


--
-- Name: SiteIdentity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SiteIdentity" (
    id integer DEFAULT 1 NOT NULL,
    title text DEFAULT 'Ligas Deportivas'::text NOT NULL,
    "iconKey" text,
    "faviconHash" text,
    "flyerKey" text,
    "backgroundImage" text,
    "layoutSvg" text,
    "tokenConfig" jsonb,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Team" (
    id integer NOT NULL,
    "clubId" integer NOT NULL,
    "tournamentCategoryId" integer NOT NULL,
    "publicName" text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: Team_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Team_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Team_id_seq" OWNED BY public."Team".id;


--
-- Name: TournamentCategory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TournamentCategory" (
    id integer NOT NULL,
    "tournamentId" integer NOT NULL,
    "categoryId" integer NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    "kickoffTime" text,
    "countsForGeneral" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: TournamentCategory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."TournamentCategory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: TournamentCategory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."TournamentCategory_id_seq" OWNED BY public."TournamentCategory".id;


--
-- Name: TournamentPosterTemplate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."TournamentPosterTemplate" (
    id integer NOT NULL,
    "tournamentId" integer NOT NULL,
    template jsonb NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    "backgroundKey" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: TournamentPosterTemplate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."TournamentPosterTemplate_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: TournamentPosterTemplate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."TournamentPosterTemplate_id_seq" OWNED BY public."TournamentPosterTemplate".id;


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id integer NOT NULL,
    email text NOT NULL,
    "passwordHash" text NOT NULL,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "emailVerifiedAt" timestamp(3) without time zone,
    language text,
    "avatarHash" text,
    "avatarUpdatedAt" timestamp(3) without time zone,
    "avatarMime" text,
    "clubId" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: UserRole; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserRole" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    "roleId" integer NOT NULL,
    "leagueId" integer,
    "clubId" integer,
    "categoryId" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: UserRole_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."UserRole_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: UserRole_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."UserRole_id_seq" OWNED BY public."UserRole".id;


--
-- Name: UserToken; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."UserToken" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: UserToken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."UserToken_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: UserToken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."UserToken_id_seq" OWNED BY public."UserToken".id;


--
-- Name: User_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."User_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: User_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."User_id_seq" OWNED BY public."User".id;


--
-- Name: Zone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Zone" (
    id integer NOT NULL,
    "tournamentId" integer NOT NULL,
    name text NOT NULL,
    status public."ZoneStatus" DEFAULT 'OPEN'::public."ZoneStatus" NOT NULL,
    "lockedAt" timestamp(3) without time zone,
    "fixtureSeed" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ZoneMatchday; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ZoneMatchday" (
    id integer NOT NULL,
    "zoneId" integer NOT NULL,
    matchday integer NOT NULL,
    status public."MatchdayStatus" DEFAULT 'PENDING'::public."MatchdayStatus" NOT NULL,
    date timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ZoneMatchday_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ZoneMatchday_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ZoneMatchday_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ZoneMatchday_id_seq" OWNED BY public."ZoneMatchday".id;


--
-- Name: Zone_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Zone_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Zone_id_seq" OWNED BY public."Zone".id;


--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Name: tournament; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournament (
    id integer NOT NULL,
    "leagueId" integer NOT NULL,
    name text NOT NULL,
    year integer NOT NULL,
    gender public."Gender" DEFAULT 'MIXTO'::public."Gender" NOT NULL,
    "pointsWin" integer DEFAULT 3 NOT NULL,
    "pointsDraw" integer DEFAULT 1 NOT NULL,
    "pointsLoss" integer DEFAULT 0 NOT NULL,
    "championMode" public."TournamentChampionMode" DEFAULT 'GLOBAL'::public."TournamentChampionMode" NOT NULL,
    "startDate" timestamp(3) without time zone,
    "endDate" timestamp(3) without time zone,
    "fixtureLockedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    status public."TournamentStatus" DEFAULT 'ACTIVE'::public."TournamentStatus" NOT NULL
);


--
-- Name: tournament_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tournament_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tournament_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tournament_id_seq OWNED BY public.tournament.id;


--
-- Name: AuditLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog" ALTER COLUMN id SET DEFAULT nextval('public."AuditLog_id_seq"'::regclass);


--
-- Name: Category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Category" ALTER COLUMN id SET DEFAULT nextval('public."Category_id_seq"'::regclass);


--
-- Name: CategoryStanding id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CategoryStanding" ALTER COLUMN id SET DEFAULT nextval('public."CategoryStanding_id_seq"'::regclass);


--
-- Name: Club id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Club" ALTER COLUMN id SET DEFAULT nextval('public."Club_id_seq"'::regclass);


--
-- Name: ClubZone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ClubZone" ALTER COLUMN id SET DEFAULT nextval('public."ClubZone_id_seq"'::regclass);


--
-- Name: EmailChangeRequest id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailChangeRequest" ALTER COLUMN id SET DEFAULT nextval('public."EmailChangeRequest_id_seq"'::regclass);


--
-- Name: EmailVerificationToken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailVerificationToken" ALTER COLUMN id SET DEFAULT nextval('public."EmailVerificationToken_id_seq"'::regclass);


--
-- Name: FlyerTemplate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FlyerTemplate" ALTER COLUMN id SET DEFAULT nextval('public."FlyerTemplate_id_seq"'::regclass);


--
-- Name: Goal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Goal" ALTER COLUMN id SET DEFAULT nextval('public."Goal_id_seq"'::regclass);


--
-- Name: League id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."League" ALTER COLUMN id SET DEFAULT nextval('public."League_id_seq"'::regclass);


--
-- Name: Match id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match" ALTER COLUMN id SET DEFAULT nextval('public."Match_id_seq"'::regclass);


--
-- Name: MatchAttachment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchAttachment" ALTER COLUMN id SET DEFAULT nextval('public."MatchAttachment_id_seq"'::regclass);


--
-- Name: MatchCategory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchCategory" ALTER COLUMN id SET DEFAULT nextval('public."MatchCategory_id_seq"'::regclass);


--
-- Name: MatchLog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchLog" ALTER COLUMN id SET DEFAULT nextval('public."MatchLog_id_seq"'::regclass);


--
-- Name: MatchPosterCache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchPosterCache" ALTER COLUMN id SET DEFAULT nextval('public."MatchPosterCache_id_seq"'::regclass);


--
-- Name: OtherGoal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OtherGoal" ALTER COLUMN id SET DEFAULT nextval('public."OtherGoal_id_seq"'::regclass);


--
-- Name: PasswordChangeRequest id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordChangeRequest" ALTER COLUMN id SET DEFAULT nextval('public."PasswordChangeRequest_id_seq"'::regclass);


--
-- Name: PasswordResetToken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordResetToken" ALTER COLUMN id SET DEFAULT nextval('public."PasswordResetToken_id_seq"'::regclass);


--
-- Name: Permission id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Permission" ALTER COLUMN id SET DEFAULT nextval('public."Permission_id_seq"'::regclass);


--
-- Name: Player id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Player" ALTER COLUMN id SET DEFAULT nextval('public."Player_id_seq"'::regclass);


--
-- Name: PlayerTournamentClub id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PlayerTournamentClub" ALTER COLUMN id SET DEFAULT nextval('public."PlayerTournamentClub_id_seq"'::regclass);


--
-- Name: Role id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Role" ALTER COLUMN id SET DEFAULT nextval('public."Role_id_seq"'::regclass);


--
-- Name: Roster id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Roster" ALTER COLUMN id SET DEFAULT nextval('public."Roster_id_seq"'::regclass);


--
-- Name: RosterPlayer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RosterPlayer" ALTER COLUMN id SET DEFAULT nextval('public."RosterPlayer_id_seq"'::regclass);


--
-- Name: Team id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team" ALTER COLUMN id SET DEFAULT nextval('public."Team_id_seq"'::regclass);


--
-- Name: TournamentCategory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentCategory" ALTER COLUMN id SET DEFAULT nextval('public."TournamentCategory_id_seq"'::regclass);


--
-- Name: TournamentPosterTemplate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentPosterTemplate" ALTER COLUMN id SET DEFAULT nextval('public."TournamentPosterTemplate_id_seq"'::regclass);


--
-- Name: User id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User" ALTER COLUMN id SET DEFAULT nextval('public."User_id_seq"'::regclass);


--
-- Name: UserRole id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole" ALTER COLUMN id SET DEFAULT nextval('public."UserRole_id_seq"'::regclass);


--
-- Name: UserToken id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserToken" ALTER COLUMN id SET DEFAULT nextval('public."UserToken_id_seq"'::regclass);


--
-- Name: Zone id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Zone" ALTER COLUMN id SET DEFAULT nextval('public."Zone_id_seq"'::regclass);


--
-- Name: ZoneMatchday id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ZoneMatchday" ALTER COLUMN id SET DEFAULT nextval('public."ZoneMatchday_id_seq"'::regclass);


--
-- Name: tournament id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament ALTER COLUMN id SET DEFAULT nextval('public.tournament_id_seq'::regclass);


--
-- Data for Name: AuditLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AuditLog" (id, "userId", action, metadata, "createdAt") FROM stdin;
\.


--
-- Data for Name: Category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Category" (id, name, "birthYearMin", "birthYearMax", gender, "minPlayers", mandatory, promotional, active, "createdAt", "updatedAt") FROM stdin;
16	Damas	1960	1996	FEMENINO	0	t	f	t	2026-02-11 11:09:55.113	2026-02-12 10:43:41.041
15	Primera	1997	2008	FEMENINO	0	t	f	t	2026-02-11 11:09:36.864	2026-02-12 10:43:45.517
11	Sub 11	2015	2016	FEMENINO	0	t	f	t	2026-02-11 11:07:38.029	2026-02-12 10:43:50.582
12	Sub 13	2013	2014	FEMENINO	0	t	f	t	2026-02-11 11:08:08.659	2026-02-12 10:43:55.93
13	Sub 15	2011	2012	FEMENINO	0	t	f	t	2026-02-11 11:08:49.869	2026-02-12 10:44:00.984
14	Sub 17	2009	2010	FEMENINO	0	t	f	t	2026-02-11 11:09:09.502	2026-02-12 10:44:05.083
6	2012	2012	2012	MASCULINO	0	t	f	t	2026-01-12 17:29:45.273	2026-02-12 11:51:30.328
5	2013	2013	2013	MASCULINO	0	t	f	t	2026-01-12 17:29:32.857	2026-02-12 11:51:33.687
3	2015	2015	2015	MASCULINO	0	t	f	t	2026-01-12 17:29:14.341	2026-02-12 11:51:39.992
2	2016	2016	2016	MASCULINO	0	t	f	t	2026-01-12 17:29:01.136	2026-02-12 11:51:43.409
1	2017	2017	2017	MASCULINO	0	t	f	t	2026-01-12 16:28:28.909	2026-02-12 11:51:47.835
7	2018	2018	2018	MASCULINO	0	t	f	t	2026-01-12 17:29:56.923	2026-02-12 11:51:51.939
8	2019	2019	2019	MASCULINO	0	t	f	t	2026-01-12 17:30:29.263	2026-02-12 11:51:56.027
10	Sub 9	2017	2020	FEMENINO	0	t	f	t	2026-02-11 11:06:44.898	2026-02-13 14:59:07.185
4	2014	2014	2014	MIXTO	0	t	f	t	2026-01-12 17:29:23.859	2026-02-15 01:09:16.622
9	2020	2020	2021	MASCULINO	0	t	f	t	2026-01-12 17:30:52.556	2026-02-15 23:22:42.766
\.


--
-- Data for Name: CategoryStanding; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CategoryStanding" (id, "zoneId", "tournamentCategoryId", "clubId", played, wins, draws, losses, "goalsFor", "goalsAgainst", points, "goalDifference", "updatedAt") FROM stdin;
13584	4	32	10	10	8	0	2	25	19	24	6	2026-05-04 22:57:15.89
13585	4	32	1	10	4	3	3	14	14	15	0	2026-05-04 22:57:15.89
13586	4	32	9	9	2	2	5	16	18	8	-2	2026-05-04 22:57:15.89
13587	4	32	13	10	3	1	6	19	22	10	-3	2026-05-04 22:57:15.89
13588	4	32	12	9	3	3	3	13	14	12	-1	2026-05-04 22:57:15.89
13589	4	32	11	10	4	1	5	23	23	13	0	2026-05-04 22:57:15.89
13620	4	28	10	10	3	2	5	18	25	11	-7	2026-05-04 22:57:16.033
13621	4	28	1	10	5	1	4	28	22	16	6	2026-05-04 22:57:16.033
13622	4	28	9	9	3	0	6	17	35	9	-18	2026-05-04 22:57:16.033
13623	4	28	13	10	3	1	6	11	18	10	-7	2026-05-04 22:57:16.033
13624	4	28	12	9	3	1	5	17	28	10	-11	2026-05-04 22:57:16.033
13625	4	28	11	10	9	1	0	52	15	28	37	2026-05-04 22:57:16.033
851	1	3	4	2	1	1	0	2	1	4	1	2026-01-20 11:28:16.023
852	1	3	2	3	0	0	3	0	4	0	-4	2026-01-20 11:28:16.023
853	1	3	3	3	1	1	1	3	2	4	1	2026-01-20 11:28:16.023
854	1	3	1	2	2	0	0	2	0	6	2	2026-01-20 11:28:16.023
855	1	3	5	2	1	0	1	1	1	3	0	2026-01-20 11:28:16.023
856	1	4	4	2	1	0	1	4	4	3	0	2026-01-20 11:28:16.03
857	1	4	2	3	1	0	2	3	4	3	-1	2026-01-20 11:28:16.03
858	1	4	3	3	1	0	2	3	5	3	-2	2026-01-20 11:28:16.03
859	1	4	1	2	2	0	0	5	2	6	3	2026-01-20 11:28:16.03
860	1	4	5	2	1	0	1	3	3	3	0	2026-01-20 11:28:16.03
861	1	6	4	2	0	1	1	3	5	1	-2	2026-01-20 11:28:16.038
862	1	6	2	3	0	2	1	5	6	2	-1	2026-01-20 11:28:16.038
863	1	6	3	3	2	1	0	6	3	7	3	2026-01-20 11:28:16.038
864	1	6	1	2	2	0	0	5	3	6	2	2026-01-20 11:28:16.038
865	1	6	5	2	0	0	2	0	2	0	-2	2026-01-20 11:28:16.038
866	1	5	4	2	0	1	1	1	2	1	-1	2026-01-20 11:28:16.046
867	1	5	2	3	1	1	1	3	4	4	-1	2026-01-20 11:28:16.046
868	1	5	3	3	1	2	0	3	2	5	1	2026-01-20 11:28:16.046
869	1	5	1	2	2	0	0	6	2	6	4	2026-01-20 11:28:16.046
870	1	5	5	2	0	0	2	1	4	0	-3	2026-01-20 11:28:16.046
871	1	2	4	2	0	0	2	1	3	0	-2	2026-01-20 11:28:16.055
872	1	2	2	3	1	1	1	2	2	4	0	2026-01-20 11:28:16.055
873	1	2	3	3	1	2	0	4	3	5	1	2026-01-20 11:28:16.055
874	1	2	1	2	2	0	0	3	1	6	2	2026-01-20 11:28:16.055
875	1	2	5	2	0	1	1	2	3	1	-1	2026-01-20 11:28:16.055
7500	3	23	1	5	2	1	2	10	8	7	2	2026-03-12 18:10:03.472
7501	3	23	7	5	4	1	0	10	5	13	5	2026-03-12 18:10:03.472
7502	3	23	8	5	0	2	3	8	13	2	-5	2026-03-12 18:10:03.472
7503	3	23	6	5	1	2	2	4	6	5	-2	2026-03-12 18:10:03.472
7504	3	19	1	5	3	1	1	6	4	10	2	2026-03-12 18:10:03.48
7505	3	19	7	5	4	0	1	21	16	12	5	2026-03-12 18:10:03.48
7506	3	19	8	5	1	2	2	11	12	5	-1	2026-03-12 18:10:03.48
7507	3	19	6	5	0	1	4	12	18	1	-6	2026-03-12 18:10:03.48
7508	3	20	1	5	1	0	4	15	17	3	-2	2026-03-12 18:10:03.488
7509	3	20	7	5	2	1	2	15	16	7	-1	2026-03-12 18:10:03.488
7510	3	20	8	5	2	1	2	16	18	7	-2	2026-03-12 18:10:03.488
7511	3	20	6	5	3	2	0	18	13	11	5	2026-03-12 18:10:03.488
7512	3	21	1	5	1	0	4	9	12	3	-3	2026-03-12 18:10:03.496
7513	3	21	7	5	5	0	0	12	3	15	9	2026-03-12 18:10:03.496
7514	3	21	8	5	4	0	1	14	11	12	3	2026-03-12 18:10:03.496
7515	3	21	6	5	0	0	5	7	16	0	-9	2026-03-12 18:10:03.496
7516	3	22	1	5	0	0	5	7	18	0	-11	2026-03-12 18:10:03.504
7517	3	22	7	5	3	1	1	12	9	10	3	2026-03-12 18:10:03.504
7518	3	22	8	5	5	0	0	22	11	15	11	2026-03-12 18:10:03.504
7519	3	22	6	5	1	1	3	12	15	4	-3	2026-03-12 18:10:03.504
7520	3	25	1	5	0	0	5	4	16	0	-12	2026-03-12 18:10:03.511
7521	3	25	7	5	3	2	0	9	6	11	3	2026-03-12 18:10:03.511
7522	3	25	8	5	3	0	2	10	6	9	4	2026-03-12 18:10:03.511
7523	3	25	6	5	2	2	1	12	7	8	5	2026-03-12 18:10:03.511
7524	3	24	1	5	0	0	5	5	21	0	-16	2026-03-12 18:10:03.519
7525	3	24	7	5	3	0	2	9	7	9	2	2026-03-12 18:10:03.519
7526	3	24	8	5	4	1	0	19	8	13	11	2026-03-12 18:10:03.519
7527	3	24	6	5	2	1	2	9	6	7	3	2026-03-12 18:10:03.519
7528	3	26	1	5	1	0	4	5	11	3	-6	2026-03-12 18:10:03.527
7529	3	26	7	5	3	1	1	5	4	10	1	2026-03-12 18:10:03.527
7530	3	26	8	5	3	2	0	11	4	11	7	2026-03-12 18:10:03.527
7531	3	26	6	5	0	3	2	4	6	3	-2	2026-03-12 18:10:03.527
7532	3	27	1	5	2	1	2	6	3	7	3	2026-03-12 18:10:03.534
7533	3	27	7	5	3	0	2	5	3	9	2	2026-03-12 18:10:03.534
7534	3	27	8	5	1	2	2	2	4	5	-2	2026-03-12 18:10:03.534
7535	3	27	6	5	2	1	2	4	7	7	-3	2026-03-12 18:10:03.534
13590	4	30	10	10	10	0	0	33	1	30	32	2026-05-04 22:57:15.904
13591	4	30	1	10	8	0	2	27	11	24	16	2026-05-04 22:57:15.904
13592	4	30	9	9	2	1	6	14	24	7	-10	2026-05-04 22:57:15.904
13593	4	30	13	10	3	0	7	6	18	9	-12	2026-05-04 22:57:15.904
13594	4	30	12	9	4	0	5	13	17	12	-4	2026-05-04 22:57:15.904
13595	4	30	11	10	1	1	8	10	32	4	-22	2026-05-04 22:57:15.904
13596	4	34	10	10	8	1	1	33	8	25	25	2026-05-04 22:57:15.945
13597	4	34	1	10	9	0	1	31	6	27	25	2026-05-04 22:57:15.945
13598	4	34	9	9	2	2	5	11	23	8	-12	2026-05-04 22:57:15.945
13599	4	34	13	10	3	0	7	7	16	9	-9	2026-05-04 22:57:15.945
13600	4	34	12	9	2	0	7	12	21	6	-9	2026-05-04 22:57:15.945
13601	4	34	11	10	3	1	6	15	35	10	-20	2026-05-04 22:57:15.945
13602	4	31	10	10	3	0	7	15	16	9	-1	2026-05-04 22:57:15.969
13603	4	31	1	10	8	2	0	26	6	26	20	2026-05-04 22:57:15.969
13604	4	31	9	9	1	0	8	5	40	3	-35	2026-05-04 22:57:15.969
13605	4	31	13	10	3	0	7	11	15	9	-4	2026-05-04 22:57:15.969
13606	4	31	12	9	4	1	4	17	11	13	6	2026-05-04 22:57:15.969
13607	4	31	11	10	8	1	1	23	9	25	14	2026-05-04 22:57:15.969
13608	4	33	10	10	6	2	2	30	18	20	12	2026-05-04 22:57:15.986
13609	4	33	1	10	5	2	3	26	24	17	2	2026-05-04 22:57:15.986
13610	4	33	9	9	8	1	0	42	10	25	32	2026-05-04 22:57:15.986
13611	4	33	13	10	3	0	7	18	21	9	-3	2026-05-04 22:57:15.986
13612	4	33	12	9	2	0	7	13	43	6	-30	2026-05-04 22:57:15.986
13613	4	33	11	10	2	1	7	23	36	7	-13	2026-05-04 22:57:15.986
13614	4	29	10	10	3	0	7	17	44	9	-27	2026-05-04 22:57:16.003
13615	4	29	1	10	8	0	2	40	14	24	26	2026-05-04 22:57:16.003
13616	4	29	9	9	5	1	3	25	16	16	9	2026-05-04 22:57:16.003
13617	4	29	13	10	4	1	5	20	16	13	4	2026-05-04 22:57:16.003
13618	4	29	12	9	3	1	5	14	37	10	-23	2026-05-04 22:57:16.003
13619	4	29	11	10	4	1	5	27	16	13	11	2026-05-04 22:57:16.003
\.


--
-- Data for Name: Club; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Club" (id, name, "shortName", slug, "leagueId", "primaryColor", "secondaryColor", active, "logoKey", "logoUrl", "instagramUrl", "facebookUrl", latitude, longitude, "createdAt", "updatedAt", "homeAddress") FROM stdin;
4	Club Deportivo Nogues	Deportivo Nogues	deportivo-nogues	\N	#A3853C	#F40402	t	uploads/c317b8fb-ce0c-4ede-afa6-4f73bd3d5bf7.png	/storage/uploads/c317b8fb-ce0c-4ede-afa6-4f73bd3d5bf7.png	\N	\N	\N	\N	2026-01-12 17:27:03.464	2026-01-12 17:27:03.999	\N
11	S.F. Gral Don José De San Martin	S.F. San Martin	san-martin	\N	#0001FC	#FDFDFD	t	uploads/a25d7f43-0490-468e-a77c-45d588c22ecc.png	/storage/uploads/a25d7f43-0490-468e-a77c-45d588c22ecc.png	\N	\N	-34.48716300	-58.70333700	2026-02-11 11:01:11.842	2026-02-12 13:38:48.056	G.Matorras y Sgto. Cabral - P. Nogues
3	Club Social y Deportivo San Antonio	CSD San Antonio	csd-san-antonio	\N	#008239	#FFFFFF	f	uploads/eca6b958-ad2e-459a-8bba-67ea16b683ef.png	/storage/uploads/eca6b958-ad2e-459a-8bba-67ea16b683ef.png	\N	\N	\N	\N	2026-01-12 17:26:02.682	2026-02-13 16:55:13.285	\N
5	Footbal Club Barcelona	Barça	footbal-club-barcelona	\N	#A50044	#004D98	f	uploads/bf0c2fab-1594-4d78-b6c8-37e8c82b7d83.png	/storage/uploads/bf0c2fab-1594-4d78-b6c8-37e8c82b7d83.png	\N	\N	\N	\N	2026-01-12 17:28:20.712	2026-02-13 16:55:22.217	\N
2	Club Real Polvorines	Real Polvorines	real-polvorines	\N	#F81A0F	#FFFFFF	t	uploads/229b0700-44bb-4ca4-862e-792477c2e08c.png	/storage/uploads/229b0700-44bb-4ca4-862e-792477c2e08c.png	\N	\N	\N	\N	2026-01-12 17:24:34.684	2026-03-12 13:36:09.092	\N
13	Deportivo Polvorines	Dep Polvorines	deportivo-polvorines	\N	#12218A	#FFFFFF	t	uploads/d5284082-c862-4f09-8557-79b2cefe0804.png	/storage/uploads/d5284082-c862-4f09-8557-79b2cefe0804.png	\N	\N	\N	\N	2026-02-11 11:05:09.252	2026-03-25 17:28:40.156	Pozo de Vargas 2250 - P. Nogues
1	Club Social y Deportivo Soler	CSD Soler	club-social-y-deportivo-soler	\N	#AA0000	#0C7800	t	uploads/975704c2-e221-443f-abb3-eded041f27fe.png	/storage/uploads/975704c2-e221-443f-abb3-eded041f27fe.png	https://instagram.com/csd_soler	https://facebook.com/csdsoler	-34.47913400	-58.69953800	2026-01-12 16:25:45.972	2026-02-03 12:02:59.942	Daguerre 979 - Pablo Nogues
6	Torino	Torino	torino	\N	#FDFDFD	#0000FD	t	uploads/7d5b41c8-b29f-4779-8fcb-2c2dc2009edb.png	/storage/uploads/7d5b41c8-b29f-4779-8fcb-2c2dc2009edb.png	\N	\N	-34.47081400	-58.69073300	2026-02-02 13:28:13.348	2026-02-03 12:09:57.542	Cap. Giachino 1207 - Pablo Nogués
8	Lucero de la Cabaña	El Lucero	lucero-de-la-cabaa	\N	#000000	#009142	t	uploads/a97e12a1-3b3a-4630-a75e-d1293e080efc.png	/storage/uploads/a97e12a1-3b3a-4630-a75e-d1293e080efc.png	\N	\N	-34.48002300	-58.68928300	2026-02-02 13:28:44.567	2026-02-03 12:11:31.221	Cangallo 4590 - Pablo Nogues
7	Deportivo Wilson	Wilson	deportivo-wilson	\N	#004214	#F3F3F3	t	uploads/a6aa6361-bd4c-4885-919f-6f1f5ec628f0.png	/storage/uploads/a6aa6361-bd4c-4885-919f-6f1f5ec628f0.png	\N	\N	-34.48962800	-58.66607200	2026-02-02 13:28:28.861	2026-02-03 12:12:27.044	Eva Perón 5595 - Villa de Mayo
9	Deportivo Magdalena	Magdalena	magdalena	\N	#750008	#EFC921	t	uploads/d8088197-3a5f-40ed-b775-8078925efde7.png	/storage/uploads/d8088197-3a5f-40ed-b775-8078925efde7.png	\N	\N	-34.50639200	-58.71294300	2026-02-11 10:52:05.559	2026-02-11 10:52:06.752	Cerrito y S. Ignacio - Polvorines
10	Club Mariano Moreno	Mariano Moreno	mariano-moreno	\N	#1D2686	#DDDDDD	t	uploads/0b953f69-d384-4278-b2ca-372de6f38534.png	/storage/uploads/0b953f69-d384-4278-b2ca-372de6f38534.png	\N	\N	-34.51372900	-58.71012600	2026-02-11 10:56:29.489	2026-02-11 10:56:30.644	Colombres 3197 - Polvorines
12	Malvinense Junior	Malvinense	malvinense	\N	#02B0EC	#FFFFFF	t	uploads/309ec8ed-42ff-48b2-aca8-9a44320570c4.png	/storage/uploads/309ec8ed-42ff-48b2-aca8-9a44320570c4.png	\N	\N	-34.46250200	-58.71532600	2026-02-11 11:03:38.805	2026-02-11 11:03:39.64	Guatemala 2931- Grand Bourg
\.


--
-- Data for Name: ClubZone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ClubZone" (id, "clubId", "zoneId", "createdAt", "updatedAt") FROM stdin;
1	4	1	2026-01-14 18:33:11.626	2026-01-14 18:33:11.626
2	2	1	2026-01-14 18:33:11.812	2026-01-14 18:33:11.812
3	3	1	2026-01-14 18:33:11.997	2026-01-14 18:33:11.997
4	1	1	2026-01-14 18:33:12.198	2026-01-14 18:33:12.198
5	5	1	2026-01-14 18:33:12.396	2026-01-14 18:33:12.396
6	4	2	2026-01-30 22:39:39.842	2026-01-30 22:39:39.842
7	2	2	2026-01-30 22:39:40.049	2026-01-30 22:39:40.049
8	3	2	2026-01-30 22:39:40.256	2026-01-30 22:39:40.256
9	1	2	2026-01-30 22:39:40.458	2026-01-30 22:39:40.458
10	1	3	2026-02-02 13:53:17.924	2026-02-02 13:53:17.924
11	7	3	2026-02-02 13:53:18.134	2026-02-02 13:53:18.134
12	8	3	2026-02-02 13:53:18.336	2026-02-02 13:53:18.336
13	6	3	2026-02-02 13:53:18.536	2026-02-02 13:53:18.536
14	10	4	2026-02-11 11:13:38.502	2026-02-11 11:13:38.502
15	1	4	2026-02-11 11:13:38.726	2026-02-11 11:13:38.726
16	9	4	2026-02-11 11:13:38.935	2026-02-11 11:13:38.935
17	13	4	2026-02-11 11:13:39.131	2026-02-11 11:13:39.131
18	12	4	2026-02-11 11:13:39.325	2026-02-11 11:13:39.325
19	11	4	2026-02-11 11:13:39.519	2026-02-11 11:13:39.519
\.


--
-- Data for Name: EmailChangeRequest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EmailChangeRequest" (id, "userId", "newEmail", token, "expiresAt", "confirmedAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: EmailVerificationToken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."EmailVerificationToken" (id, "userId", token, "expiresAt", "usedAt", "createdAt") FROM stdin;
1	2	2f926ab40a64eeb3278edf1ab63acc3db028cb1c37b66a37d5ac6f49ad152f29	2026-01-13 16:13:10.837	2026-01-12 16:13:30.387	2026-01-12 16:13:10.838
3	4	7d423934aafc8a5f9a76e635507e07b153debe0d903c73e3392ef65978566b98	2026-02-10 13:06:36.413	2026-02-09 13:08:21.024	2026-02-09 13:06:36.414
\.


--
-- Data for Name: FlyerTemplate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."FlyerTemplate" (id, "competitionId", "backgroundKey", "layoutKey", "layoutFileName", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: Goal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Goal" (id, "matchCategoryId", "playerId", "clubId", minute, "createdAt") FROM stdin;
1	5	5	4	\N	2026-01-16 11:28:51.649
2	5	9	3	\N	2026-01-16 11:28:51.649
3	4	11	4	\N	2026-01-20 11:23:02.154
4	4	16	3	\N	2026-01-20 11:23:02.154
8	2	32	4	\N	2026-01-20 11:23:19.877
9	2	36	3	\N	2026-01-20 11:23:19.877
12	3	21	4	\N	2026-01-20 11:23:43.403
13	3	21	4	\N	2026-01-20 11:23:43.403
14	3	25	3	\N	2026-01-20 11:23:43.403
15	3	25	3	\N	2026-01-20 11:23:43.403
16	3	25	3	\N	2026-01-20 11:23:43.403
17	1	33	4	\N	2026-01-20 11:23:49.929
18	1	34	4	\N	2026-01-20 11:23:49.929
19	1	45	3	\N	2026-01-20 11:23:49.929
20	1	46	3	\N	2026-01-20 11:23:49.929
21	1	46	3	\N	2026-01-20 11:23:49.929
22	10	3	1	\N	2026-01-20 11:24:21.088
23	9	18	1	\N	2026-01-20 11:24:24.219
24	8	27	1	\N	2026-01-20 11:24:28.728
25	8	27	1	\N	2026-01-20 11:24:28.728
26	7	38	2	\N	2026-01-20 11:24:34.176
27	7	39	1	\N	2026-01-20 11:24:34.176
28	7	39	1	\N	2026-01-20 11:24:34.176
29	7	39	1	\N	2026-01-20 11:24:34.176
30	6	44	2	\N	2026-01-20 11:24:43.134
31	6	44	2	\N	2026-01-20 11:24:43.134
32	6	44	2	\N	2026-01-20 11:24:43.134
33	6	47	1	\N	2026-01-20 11:24:43.134
34	6	47	1	\N	2026-01-20 11:24:43.134
35	6	48	1	\N	2026-01-20 11:24:43.134
36	6	48	1	\N	2026-01-20 11:24:43.134
37	15	8	3	\N	2026-01-20 11:25:23.043
38	15	10	5	\N	2026-01-20 11:25:23.043
39	14	20	5	\N	2026-01-20 11:25:27.498
40	13	30	5	\N	2026-01-20 11:25:31.302
41	12	36	3	\N	2026-01-20 11:25:36.149
42	20	6	2	\N	2026-01-20 11:25:50.134
43	19	12	4	\N	2026-01-20 11:25:54.253
44	18	24	2	\N	2026-01-20 11:25:59.683
45	18	22	4	\N	2026-01-20 11:25:59.683
46	18	22	4	\N	2026-01-20 11:25:59.683
47	17	37	2	\N	2026-01-20 11:26:03.819
48	16	43	2	\N	2026-01-20 11:26:08.691
49	16	33	4	\N	2026-01-20 11:26:08.691
50	11	45	3	\N	2026-01-20 11:26:59.257
51	25	2	5	\N	2026-01-20 11:27:21.755
52	25	4	1	\N	2026-01-20 11:27:21.755
53	25	4	1	\N	2026-01-20 11:27:21.755
54	24	18	1	\N	2026-01-20 11:27:26.637
55	23	30	5	\N	2026-01-20 11:27:32.971
56	23	30	5	\N	2026-01-20 11:27:32.971
57	23	27	1	\N	2026-01-20 11:27:32.971
58	23	27	1	\N	2026-01-20 11:27:32.971
59	23	27	1	\N	2026-01-20 11:27:32.971
64	22	42	5	\N	2026-01-20 11:27:41.204
65	22	39	1	\N	2026-01-20 11:27:41.204
66	22	40	1	\N	2026-01-20 11:27:41.204
67	22	40	1	\N	2026-01-20 11:27:41.204
68	21	47	1	\N	2026-01-20 11:27:45.771
69	30	8	3	\N	2026-01-20 11:27:55.094
70	30	7	2	\N	2026-01-20 11:27:55.094
71	29	16	3	\N	2026-01-20 11:28:00.133
72	29	16	3	\N	2026-01-20 11:28:00.133
73	28	24	2	\N	2026-01-20 11:28:03.75
74	28	24	2	\N	2026-01-20 11:28:03.75
76	27	36	3	\N	2026-01-20 11:28:11.288
77	27	38	2	\N	2026-01-20 11:28:11.288
78	26	45	3	\N	2026-01-20 11:28:16.004
79	26	44	2	\N	2026-01-20 11:28:16.004
80	219	270	1	\N	2026-02-14 14:16:19.922
81	219	361	1	\N	2026-02-14 14:16:19.922
82	219	269	1	\N	2026-02-14 14:16:19.922
83	219	269	1	\N	2026-02-14 14:16:19.922
87	217	160	11	\N	2026-02-14 14:18:08.072
88	217	160	11	\N	2026-02-14 14:18:08.072
89	217	160	11	\N	2026-02-14 14:18:08.072
90	217	371	1	\N	2026-02-14 14:18:08.072
91	220	140	11	\N	2026-02-14 14:18:35.285
92	220	382	1	\N	2026-02-14 14:18:35.285
93	218	280	1	\N	2026-02-14 14:19:37.341
94	218	276	1	\N	2026-02-14 14:19:37.341
95	218	276	1	\N	2026-02-14 14:19:37.341
96	222	186	11	\N	2026-02-14 14:20:28.03
97	222	391	1	\N	2026-02-14 14:20:28.03
98	222	398	1	\N	2026-02-14 14:20:28.03
99	222	388	1	\N	2026-02-14 14:20:28.03
100	222	392	1	\N	2026-02-14 14:20:28.03
101	222	392	1	\N	2026-02-14 14:20:28.03
102	222	392	1	\N	2026-02-14 14:20:28.03
103	216	182	11	\N	2026-02-14 14:27:59.358
104	216	182	11	\N	2026-02-14 14:27:59.358
105	216	182	11	\N	2026-02-14 14:27:59.358
106	216	182	11	\N	2026-02-14 14:27:59.358
107	216	182	11	\N	2026-02-14 14:27:59.358
108	216	150	11	\N	2026-02-14 14:27:59.358
109	216	147	11	\N	2026-02-14 14:27:59.358
110	216	399	1	\N	2026-02-14 14:27:59.358
111	215	290	9	\N	2026-02-14 16:43:52.432
112	215	408	10	\N	2026-02-14 16:43:52.432
113	211	413	10	\N	2026-02-14 16:45:15.158
114	211	412	10	\N	2026-02-14 16:45:15.158
115	211	412	10	\N	2026-02-14 16:45:15.158
116	211	417	10	\N	2026-02-14 16:45:15.158
117	211	415	10	\N	2026-02-14 16:45:15.158
118	211	415	10	\N	2026-02-14 16:45:15.158
119	212	424	10	\N	2026-02-14 16:45:46.536
120	212	424	10	\N	2026-02-14 16:45:46.536
121	212	422	10	\N	2026-02-14 16:45:46.536
122	212	422	10	\N	2026-02-14 16:45:46.536
123	212	425	10	\N	2026-02-14 16:45:46.536
124	212	425	10	\N	2026-02-14 16:45:46.536
125	213	323	9	\N	2026-02-14 16:46:20.912
126	213	316	9	\N	2026-02-14 16:46:20.912
127	213	431	10	\N	2026-02-14 16:46:20.912
128	213	431	10	\N	2026-02-14 16:46:20.912
129	213	430	10	\N	2026-02-14 16:46:20.912
130	210	330	9	\N	2026-02-14 16:47:03.935
131	210	336	9	\N	2026-02-14 16:47:03.935
132	210	333	9	\N	2026-02-14 16:47:03.935
133	210	340	9	\N	2026-02-14 16:47:03.935
134	210	340	9	\N	2026-02-14 16:47:03.935
135	210	340	9	\N	2026-02-14 16:47:03.935
136	210	340	9	\N	2026-02-14 16:47:03.935
137	210	340	9	\N	2026-02-14 16:47:03.935
138	209	349	9	\N	2026-02-14 16:47:29.608
139	209	343	9	\N	2026-02-14 16:47:29.608
140	209	445	10	\N	2026-02-14 16:47:29.608
141	221	171	11	\N	2026-02-14 16:49:16.072
142	221	172	11	\N	2026-02-14 16:49:16.072
143	221	282	1	\N	2026-02-14 16:49:16.072
144	221	282	1	\N	2026-02-14 16:49:16.072
145	221	286	1	\N	2026-02-14 16:49:16.072
146	229	237	13	\N	2026-02-14 19:21:38.991
147	229	237	13	\N	2026-02-14 19:21:38.991
148	225	244	13	\N	2026-02-14 19:22:00.19
149	226	453	12	\N	2026-02-14 19:22:27.762
150	226	248	13	\N	2026-02-14 19:22:27.762
151	226	248	13	\N	2026-02-14 19:22:27.762
152	227	206	12	\N	2026-02-14 19:22:55.16
153	227	458	13	\N	2026-02-14 19:22:55.16
154	228	220	12	\N	2026-02-14 19:23:52.578
155	228	468	13	\N	2026-02-14 19:23:52.578
156	228	468	13	\N	2026-02-14 19:23:52.578
157	228	468	13	\N	2026-02-14 19:23:52.578
158	228	469	13	\N	2026-02-14 19:23:52.578
159	228	470	13	\N	2026-02-14 19:23:52.578
160	228	470	13	\N	2026-02-14 19:23:52.578
161	228	470	13	\N	2026-02-14 19:23:52.578
162	224	221	12	\N	2026-02-14 19:24:28.361
163	224	221	12	\N	2026-02-14 19:24:28.361
164	224	265	13	\N	2026-02-14 19:24:28.361
165	224	265	13	\N	2026-02-14 19:24:28.361
166	224	265	13	\N	2026-02-14 19:24:28.361
167	224	265	13	\N	2026-02-14 19:24:28.361
168	224	265	13	\N	2026-02-14 19:24:28.361
169	224	264	13	\N	2026-02-14 19:24:28.361
170	223	226	12	\N	2026-02-14 19:24:57.343
171	223	231	12	\N	2026-02-14 19:24:57.343
172	223	486	13	\N	2026-02-14 19:24:57.343
173	223	482	13	\N	2026-02-14 19:24:57.343
174	223	482	13	\N	2026-02-14 19:24:57.343
175	214	325	9	\N	2026-02-14 19:32:12.975
176	214	487	9	\N	2026-02-14 19:32:12.975
177	214	329	9	\N	2026-02-14 19:32:12.975
178	103	512	1	\N	2026-02-18 10:34:30.027
179	103	516	1	\N	2026-02-18 10:34:30.027
180	103	269	1	\N	2026-02-18 10:34:30.027
181	103	517	6	\N	2026-02-18 10:34:30.027
182	106	494	1	\N	2026-02-18 10:35:20.987
183	106	511	6	\N	2026-02-18 10:35:20.987
184	106	505	6	\N	2026-02-18 10:35:20.987
185	106	508	6	\N	2026-02-18 10:35:20.987
186	106	510	6	\N	2026-02-18 10:35:20.987
187	106	510	6	\N	2026-02-18 10:35:20.987
188	102	530	1	\N	2026-02-18 10:36:33.878
189	102	530	1	\N	2026-02-18 10:36:33.878
190	102	530	1	\N	2026-02-18 10:36:33.878
191	102	530	1	\N	2026-02-18 10:36:33.878
192	102	530	1	\N	2026-02-18 10:36:33.878
193	102	536	6	\N	2026-02-18 10:36:33.878
194	107	541	6	\N	2026-02-18 10:37:42.843
195	107	541	6	\N	2026-02-18 10:37:42.843
196	107	540	6	\N	2026-02-18 10:37:42.843
197	107	545	6	\N	2026-02-18 10:37:42.843
198	107	542	6	\N	2026-02-18 10:37:42.843
199	107	542	6	\N	2026-02-18 10:37:42.843
200	107	542	6	\N	2026-02-18 10:37:42.843
201	107	542	6	\N	2026-02-18 10:37:42.843
202	109	557	1	\N	2026-02-18 10:38:41.466
203	109	557	1	\N	2026-02-18 10:38:41.466
204	109	557	1	\N	2026-02-18 10:38:41.466
205	109	556	1	\N	2026-02-18 10:38:41.466
206	109	556	1	\N	2026-02-18 10:38:41.466
207	108	559	6	\N	2026-02-18 10:39:09.459
208	104	568	6	\N	2026-02-18 10:39:49.01
209	104	569	6	\N	2026-02-18 10:39:49.01
210	230	343	9	\N	2026-02-21 13:39:34.391
211	230	150	11	\N	2026-02-21 13:39:34.391
212	230	150	11	\N	2026-02-21 13:39:34.391
213	230	150	11	\N	2026-02-21 13:39:34.391
214	230	145	11	\N	2026-02-21 13:39:34.391
215	230	146	11	\N	2026-02-21 13:39:34.391
216	230	147	11	\N	2026-02-21 13:39:34.391
217	230	147	11	\N	2026-02-21 13:39:34.391
218	231	330	9	\N	2026-02-21 13:40:37.703
219	231	333	9	\N	2026-02-21 13:40:37.703
220	231	340	9	\N	2026-02-21 13:40:37.703
221	231	340	9	\N	2026-02-21 13:40:37.703
222	231	340	9	\N	2026-02-21 13:40:37.703
223	231	340	9	\N	2026-02-21 13:40:37.703
224	231	163	11	\N	2026-02-21 13:40:37.703
225	231	156	11	\N	2026-02-21 13:40:37.703
226	234	137	11	\N	2026-02-21 13:41:05.055
227	234	137	11	\N	2026-02-21 13:41:05.055
228	235	328	9	\N	2026-02-21 13:41:27.346
229	235	328	9	\N	2026-02-21 13:41:27.346
230	235	328	9	\N	2026-02-21 13:41:27.346
231	235	328	9	\N	2026-02-21 13:41:27.346
232	235	362	11	\N	2026-02-21 13:41:27.346
233	233	307	9	\N	2026-02-21 13:42:08.828
234	233	175	11	\N	2026-02-21 13:42:08.828
235	233	176	11	\N	2026-02-21 13:42:08.828
236	233	176	11	\N	2026-02-21 13:42:08.828
237	232	300	9	\N	2026-02-21 13:42:57.467
238	232	303	9	\N	2026-02-21 13:42:57.467
239	232	660	11	\N	2026-02-21 13:42:57.467
240	232	181	11	\N	2026-02-21 13:42:57.467
241	236	290	9	\N	2026-02-21 13:43:34.459
242	236	291	9	\N	2026-02-21 13:43:34.459
243	236	186	11	\N	2026-02-21 13:43:34.459
244	236	152	11	\N	2026-02-21 13:43:34.459
245	250	388	1	\N	2026-02-21 17:08:35.84
246	250	392	1	\N	2026-02-21 17:08:35.84
247	246	386	1	\N	2026-02-21 17:08:58.533
248	246	280	1	\N	2026-02-21 17:08:58.533
249	247	359	1	\N	2026-02-21 17:09:26.514
250	247	269	1	\N	2026-02-21 17:09:26.514
251	248	377	1	\N	2026-02-21 17:09:57.643
252	249	284	1	\N	2026-02-21 17:10:33.752
253	249	286	1	\N	2026-02-21 17:10:33.752
254	249	286	1	\N	2026-02-21 17:10:33.752
255	249	283	1	\N	2026-02-21 17:10:33.752
256	249	467	13	\N	2026-02-21 17:10:33.752
257	249	467	13	\N	2026-02-21 17:10:33.752
258	249	469	13	\N	2026-02-21 17:10:33.752
259	245	675	1	\N	2026-02-21 17:11:08.692
260	245	268	13	\N	2026-02-21 17:11:08.692
261	245	265	13	\N	2026-02-21 17:11:08.692
262	245	264	13	\N	2026-02-21 17:11:08.692
263	244	399	1	\N	2026-02-21 17:11:38.644
264	244	400	1	\N	2026-02-21 17:11:38.644
265	244	482	13	\N	2026-02-21 17:11:38.644
266	244	483	13	\N	2026-02-21 17:11:38.644
267	244	483	13	\N	2026-02-21 17:11:38.644
268	238	433	10	\N	2026-02-26 11:42:47.882
269	238	438	10	\N	2026-02-26 11:42:47.882
270	238	438	10	\N	2026-02-26 11:42:47.882
271	238	435	10	\N	2026-02-26 11:42:47.882
272	243	407	10	\N	2026-02-26 11:43:28.101
273	243	403	10	\N	2026-02-26 11:43:28.101
274	243	405	10	\N	2026-02-26 11:43:28.101
275	243	405	10	\N	2026-02-26 11:43:28.101
276	243	686	12	\N	2026-02-26 11:43:28.101
277	243	686	12	\N	2026-02-26 11:43:28.101
278	239	413	10	\N	2026-02-26 11:44:10.225
279	239	413	10	\N	2026-02-26 11:44:10.225
280	239	412	10	\N	2026-02-26 11:44:10.225
281	239	412	10	\N	2026-02-26 11:44:10.225
282	239	415	10	\N	2026-02-26 11:44:10.225
283	239	415	10	\N	2026-02-26 11:44:10.225
284	240	689	10	\N	2026-02-26 11:45:00.065
285	240	454	12	\N	2026-02-26 11:45:00.065
286	240	199	12	\N	2026-02-26 11:45:00.065
287	240	199	12	\N	2026-02-26 11:45:00.065
288	241	428	10	\N	2026-02-26 11:45:40.641
289	241	430	10	\N	2026-02-26 11:45:40.641
290	241	211	12	\N	2026-02-26 11:45:40.641
291	242	696	10	\N	2026-02-26 11:46:30.126
292	242	696	10	\N	2026-02-26 11:46:30.126
293	242	490	10	\N	2026-02-26 11:46:30.126
294	242	695	10	\N	2026-02-26 11:46:30.126
295	242	491	10	\N	2026-02-26 11:46:30.126
296	242	492	10	\N	2026-02-26 11:46:30.126
297	242	697	10	\N	2026-02-26 11:46:30.126
298	242	697	10	\N	2026-02-26 11:46:30.126
299	237	444	10	\N	2026-02-26 11:46:48.664
300	237	229	12	\N	2026-02-26 11:46:48.664
301	257	237	13	\N	2026-02-28 21:52:45.652
302	257	237	13	\N	2026-02-28 21:52:45.652
303	257	237	13	\N	2026-02-28 21:52:45.652
304	257	237	13	\N	2026-02-28 21:52:45.652
305	257	290	9	\N	2026-02-28 21:52:45.652
306	254	259	13	\N	2026-02-28 21:53:34.631
307	254	259	13	\N	2026-02-28 21:53:34.631
308	254	248	13	\N	2026-02-28 21:53:34.631
309	254	258	13	\N	2026-02-28 21:53:34.631
310	255	706	13	\N	2026-02-28 21:54:20.855
311	255	706	13	\N	2026-02-28 21:54:20.855
312	255	706	13	\N	2026-02-28 21:54:20.855
313	255	706	13	\N	2026-02-28 21:54:20.855
314	255	706	13	\N	2026-02-28 21:54:20.855
315	255	317	9	\N	2026-02-28 21:54:20.855
316	255	317	9	\N	2026-02-28 21:54:20.855
317	255	323	9	\N	2026-02-28 21:54:20.855
318	255	316	9	\N	2026-02-28 21:54:20.855
319	256	469	13	\N	2026-02-28 21:55:19.193
320	256	474	13	\N	2026-02-28 21:55:19.193
321	256	471	13	\N	2026-02-28 21:55:19.193
322	256	489	9	\N	2026-02-28 21:55:19.193
323	256	328	9	\N	2026-02-28 21:55:19.193
324	256	328	9	\N	2026-02-28 21:55:19.193
325	256	328	9	\N	2026-02-28 21:55:19.193
326	256	328	9	\N	2026-02-28 21:55:19.193
327	252	268	13	\N	2026-02-28 21:55:54.316
328	252	263	13	\N	2026-02-28 21:55:54.316
329	251	484	13	\N	2026-02-28 21:56:55.391
330	251	483	13	\N	2026-02-28 21:56:55.391
331	251	483	13	\N	2026-02-28 21:56:55.391
332	251	712	13	\N	2026-02-28 21:56:55.391
333	251	712	13	\N	2026-02-28 21:56:55.391
334	251	343	9	\N	2026-02-28 21:56:55.391
335	251	714	9	\N	2026-02-28 21:56:55.391
336	264	407	10	\N	2026-02-28 22:02:14.994
337	264	407	10	\N	2026-02-28 22:02:14.994
338	264	407	10	\N	2026-02-28 22:02:14.994
339	264	404	10	\N	2026-02-28 22:02:14.994
340	264	404	10	\N	2026-02-28 22:02:14.994
341	264	403	10	\N	2026-02-28 22:02:14.994
342	264	403	10	\N	2026-02-28 22:02:14.994
343	264	403	10	\N	2026-02-28 22:02:14.994
344	260	413	10	\N	2026-02-28 22:02:32.847
345	260	413	10	\N	2026-02-28 22:02:32.847
346	260	415	10	\N	2026-02-28 22:02:32.847
347	260	415	10	\N	2026-02-28 22:02:32.847
348	261	174	11	\N	2026-02-28 22:03:00.242
349	261	183	11	\N	2026-02-28 22:03:00.242
350	261	421	10	\N	2026-02-28 22:03:00.242
351	262	140	11	\N	2026-02-28 22:03:44.531
352	262	140	11	\N	2026-02-28 22:03:44.531
353	262	140	11	\N	2026-02-28 22:03:44.531
354	262	428	10	\N	2026-02-28 22:03:44.531
355	262	430	10	\N	2026-02-28 22:03:44.531
356	263	362	11	\N	2026-02-28 22:04:23.813
357	263	172	11	\N	2026-02-28 22:04:23.813
358	263	696	10	\N	2026-02-28 22:04:23.813
359	263	493	10	\N	2026-02-28 22:04:23.813
360	263	490	10	\N	2026-02-28 22:04:23.813
361	263	695	10	\N	2026-02-28 22:04:23.813
362	259	157	11	\N	2026-02-28 22:05:17.193
363	259	157	11	\N	2026-02-28 22:05:17.193
364	259	156	11	\N	2026-02-28 22:05:17.193
365	259	156	11	\N	2026-02-28 22:05:17.193
366	259	156	11	\N	2026-02-28 22:05:17.193
367	259	159	11	\N	2026-02-28 22:05:17.193
368	259	159	11	\N	2026-02-28 22:05:17.193
369	259	368	11	\N	2026-02-28 22:05:17.193
370	259	160	11	\N	2026-02-28 22:05:17.193
371	259	160	11	\N	2026-02-28 22:05:17.193
372	259	160	11	\N	2026-02-28 22:05:17.193
373	259	434	10	\N	2026-02-28 22:05:17.193
374	258	145	11	\N	2026-02-28 22:06:02.343
375	258	145	11	\N	2026-02-28 22:06:02.343
376	258	145	11	\N	2026-02-28 22:06:02.343
377	258	146	11	\N	2026-02-28 22:06:02.343
378	258	147	11	\N	2026-02-28 22:06:02.343
379	258	147	11	\N	2026-02-28 22:06:02.343
380	258	149	11	\N	2026-02-28 22:06:02.343
381	258	718	10	\N	2026-02-28 22:06:02.343
382	258	718	10	\N	2026-02-28 22:06:02.343
383	258	443	10	\N	2026-02-28 22:06:02.343
384	265	399	1	\N	2026-02-28 22:19:48.493
385	265	399	1	\N	2026-02-28 22:19:48.493
386	265	399	1	\N	2026-02-28 22:19:48.493
387	265	400	1	\N	2026-02-28 22:19:48.493
388	265	680	1	\N	2026-02-28 22:19:48.493
389	265	721	1	\N	2026-02-28 22:19:48.493
390	265	721	1	\N	2026-02-28 22:19:48.493
391	266	222	12	\N	2026-02-28 22:20:48.78
392	266	675	1	\N	2026-02-28 22:20:48.78
393	266	374	1	\N	2026-02-28 22:20:48.78
394	266	374	1	\N	2026-02-28 22:20:48.78
395	266	676	1	\N	2026-02-28 22:20:48.78
396	266	676	1	\N	2026-02-28 22:20:48.78
397	266	676	1	\N	2026-02-28 22:20:48.78
398	266	676	1	\N	2026-02-28 22:20:48.78
399	266	676	1	\N	2026-02-28 22:20:48.78
400	266	676	1	\N	2026-02-28 22:20:48.78
401	270	213	12	\N	2026-02-28 22:21:42.947
402	270	365	1	\N	2026-02-28 22:21:42.947
403	270	282	1	\N	2026-02-28 22:21:42.947
404	270	282	1	\N	2026-02-28 22:21:42.947
405	270	286	1	\N	2026-02-28 22:21:42.947
406	269	210	12	\N	2026-02-28 22:22:12.955
407	269	210	12	\N	2026-02-28 22:22:12.955
408	269	211	12	\N	2026-02-28 22:22:12.955
409	268	202	12	\N	2026-02-28 22:23:40.796
410	268	195	12	\N	2026-02-28 22:23:40.796
411	268	270	1	\N	2026-02-28 22:23:40.796
412	268	359	1	\N	2026-02-28 22:23:40.796
413	267	663	1	\N	2026-02-28 22:24:39.163
414	267	663	1	\N	2026-02-28 22:24:39.163
415	267	666	1	\N	2026-02-28 22:24:39.163
416	267	666	1	\N	2026-02-28 22:24:39.163
417	271	446	12	\N	2026-02-28 22:25:10.736
418	271	398	1	\N	2026-02-28 22:25:10.736
419	271	388	1	\N	2026-02-28 22:25:10.736
420	286	150	11	\N	2026-03-10 10:39:05.64
421	286	145	11	\N	2026-03-10 10:39:05.64
422	286	145	11	\N	2026-03-10 10:39:05.64
423	286	147	11	\N	2026-03-10 10:39:05.64
424	286	147	11	\N	2026-03-10 10:39:05.64
425	286	147	11	\N	2026-03-10 10:39:05.64
426	286	731	12	\N	2026-03-10 10:39:05.64
427	286	731	12	\N	2026-03-10 10:39:05.64
428	287	157	11	\N	2026-03-10 10:39:50.23
429	287	161	11	\N	2026-03-10 10:39:50.23
430	287	156	11	\N	2026-03-10 10:39:50.23
431	287	159	11	\N	2026-03-10 10:39:50.23
432	287	368	11	\N	2026-03-10 10:39:50.23
433	287	368	11	\N	2026-03-10 10:39:50.23
434	287	368	11	\N	2026-03-10 10:39:50.23
435	287	368	11	\N	2026-03-10 10:39:50.23
436	287	160	11	\N	2026-03-10 10:39:50.23
437	292	186	11	\N	2026-03-10 10:40:35.668
438	292	186	11	\N	2026-03-10 10:40:35.668
439	292	151	11	\N	2026-03-10 10:40:35.668
440	292	152	11	\N	2026-03-10 10:40:35.668
441	292	687	12	\N	2026-03-10 10:40:35.668
442	292	686	12	\N	2026-03-10 10:40:35.668
443	288	660	11	\N	2026-03-10 10:41:17.926
444	288	688	12	\N	2026-03-10 10:41:17.926
445	288	450	12	\N	2026-03-10 10:41:17.926
446	288	450	12	\N	2026-03-10 10:41:17.926
447	288	201	12	\N	2026-03-10 10:41:17.926
448	288	201	12	\N	2026-03-10 10:41:17.926
449	288	201	12	\N	2026-03-10 10:41:17.926
450	291	171	11	\N	2026-03-10 10:44:51.658
451	291	171	11	\N	2026-03-10 10:44:51.658
452	291	363	11	\N	2026-03-10 10:44:51.658
453	291	362	11	\N	2026-03-10 10:44:51.658
454	291	172	11	\N	2026-03-10 10:44:51.658
455	291	172	11	\N	2026-03-10 10:44:51.658
456	291	172	11	\N	2026-03-10 10:44:51.658
457	291	170	11	\N	2026-03-10 10:44:51.658
458	291	170	11	\N	2026-03-10 10:44:51.658
459	291	213	12	\N	2026-03-10 10:44:51.658
460	291	464	12	\N	2026-03-10 10:44:51.658
461	291	464	12	\N	2026-03-10 10:44:51.658
462	291	218	12	\N	2026-03-10 10:44:51.658
463	290	137	11	\N	2026-03-10 10:45:34.023
464	290	137	11	\N	2026-03-10 10:45:34.023
465	290	137	11	\N	2026-03-10 10:45:34.023
466	290	140	11	\N	2026-03-10 10:45:34.023
467	290	140	11	\N	2026-03-10 10:45:34.023
468	290	208	12	\N	2026-03-10 10:45:34.023
469	290	693	12	\N	2026-03-10 10:45:34.023
470	290	210	12	\N	2026-03-10 10:45:34.023
471	289	183	11	\N	2026-03-10 10:45:53.429
472	289	177	11	\N	2026-03-10 10:45:53.429
473	285	408	10	\N	2026-03-12 12:30:06.832
474	285	403	10	\N	2026-03-12 12:30:06.832
475	285	403	10	\N	2026-03-12 12:30:06.832
476	281	412	10	\N	2026-03-12 12:30:50.43
477	281	412	10	\N	2026-03-12 12:30:50.43
478	281	417	10	\N	2026-03-12 12:30:50.43
479	281	415	10	\N	2026-03-12 12:30:50.43
480	281	415	10	\N	2026-03-12 12:30:50.43
481	282	259	13	\N	2026-03-12 12:31:09.663
482	282	248	13	\N	2026-03-12 12:31:09.663
483	282	258	13	\N	2026-03-12 12:31:09.663
484	282	258	13	\N	2026-03-12 12:31:09.663
485	283	428	10	\N	2026-03-12 12:32:01.92
486	283	428	10	\N	2026-03-12 12:32:01.92
487	283	428	10	\N	2026-03-12 12:32:01.92
488	283	428	10	\N	2026-03-12 12:32:01.92
489	283	674	13	\N	2026-03-12 12:32:01.92
490	283	674	13	\N	2026-03-12 12:32:01.92
491	283	674	13	\N	2026-03-12 12:32:01.92
492	283	674	13	\N	2026-03-12 12:32:01.92
493	283	670	13	\N	2026-03-12 12:32:01.92
494	283	459	13	\N	2026-03-12 12:32:01.92
495	283	459	13	\N	2026-03-12 12:32:01.92
496	283	706	13	\N	2026-03-12 12:32:01.92
497	284	695	10	\N	2026-03-12 12:32:57.427
498	284	467	13	\N	2026-03-12 12:32:57.427
499	284	469	13	\N	2026-03-12 12:32:57.427
500	284	471	13	\N	2026-03-12 12:32:57.427
501	280	438	10	\N	2026-03-12 12:33:38.332
502	280	192	10	\N	2026-03-12 12:33:38.332
503	280	192	10	\N	2026-03-12 12:33:38.332
504	280	710	13	\N	2026-03-12 12:33:38.332
505	280	268	13	\N	2026-03-12 12:33:38.332
506	280	268	13	\N	2026-03-12 12:33:38.332
507	280	268	13	\N	2026-03-12 12:33:38.332
508	280	268	13	\N	2026-03-12 12:33:38.332
509	280	268	13	\N	2026-03-12 12:33:38.332
510	280	268	13	\N	2026-03-12 12:33:38.332
511	280	678	13	\N	2026-03-12 12:33:38.332
512	280	265	13	\N	2026-03-12 12:33:38.332
513	279	441	10	\N	2026-03-12 12:33:54.212
514	279	441	10	\N	2026-03-12 12:33:54.212
515	299	685	12	\N	2026-03-18 12:47:36.673
516	299	687	12	\N	2026-03-18 12:47:36.673
517	299	686	12	\N	2026-03-18 12:47:36.673
518	299	686	12	\N	2026-03-18 12:47:36.673
519	295	450	12	\N	2026-03-18 12:47:55.004
520	295	450	12	\N	2026-03-18 12:47:55.004
521	295	300	9	\N	2026-03-18 12:47:55.004
522	296	197	12	\N	2026-03-18 12:48:47.879
523	296	202	12	\N	2026-03-18 12:48:47.879
524	296	202	12	\N	2026-03-18 12:48:47.879
525	296	454	12	\N	2026-03-18 12:48:47.879
526	298	213	12	\N	2026-03-18 12:49:42.774
527	298	324	9	\N	2026-03-18 12:49:42.774
528	298	324	9	\N	2026-03-18 12:49:42.774
529	298	489	9	\N	2026-03-18 12:49:42.774
530	298	489	9	\N	2026-03-18 12:49:42.774
531	298	328	9	\N	2026-03-18 12:49:42.774
532	298	328	9	\N	2026-03-18 12:49:42.774
533	294	725	12	\N	2026-03-18 12:50:09.375
534	294	330	9	\N	2026-03-18 12:50:09.375
535	293	232	12	\N	2026-03-18 12:50:35.952
536	293	232	12	\N	2026-03-18 12:50:35.952
537	293	232	12	\N	2026-03-18 12:50:35.952
538	293	343	9	\N	2026-03-18 12:50:35.952
543	304	429	10	\N	2026-03-18 12:51:57.31
544	304	429	10	\N	2026-03-18 12:51:57.31
545	304	430	10	\N	2026-03-18 12:51:57.31
546	306	391	1	\N	2026-03-18 12:52:22.713
547	306	388	1	\N	2026-03-18 12:52:22.713
548	306	403	10	\N	2026-03-18 12:52:22.713
549	303	269	1	\N	2026-03-18 12:52:35.561
550	302	276	1	\N	2026-03-18 12:52:55.811
551	302	412	10	\N	2026-03-18 12:52:55.811
552	302	415	10	\N	2026-03-18 12:52:55.811
553	301	374	1	\N	2026-03-18 12:53:27.002
554	301	369	1	\N	2026-03-18 12:53:27.002
555	301	369	1	\N	2026-03-18 12:53:27.002
556	301	435	10	\N	2026-03-18 12:53:27.002
557	305	286	1	\N	2026-03-18 12:53:53.99
558	305	283	1	\N	2026-03-18 12:53:53.99
559	305	283	1	\N	2026-03-18 12:53:53.99
560	305	695	10	\N	2026-03-18 12:53:53.99
561	305	697	10	\N	2026-03-18 12:53:53.99
562	305	697	10	\N	2026-03-18 12:53:53.99
563	313	239	13	\N	2026-03-18 13:28:05.298
564	309	246	13	\N	2026-03-18 13:28:33.066
565	309	246	13	\N	2026-03-18 13:28:33.066
566	309	246	13	\N	2026-03-18 13:28:33.066
567	309	660	11	\N	2026-03-18 13:28:33.066
568	310	259	13	\N	2026-03-18 13:28:58.606
569	310	174	11	\N	2026-03-18 13:28:58.606
570	310	183	11	\N	2026-03-18 13:28:58.606
571	311	737	13	\N	2026-03-18 13:30:57.811
572	311	737	13	\N	2026-03-18 13:30:57.811
573	311	737	13	\N	2026-03-18 13:30:57.811
574	311	706	13	\N	2026-03-18 13:30:57.811
575	311	706	13	\N	2026-03-18 13:30:57.811
576	312	469	13	\N	2026-03-18 13:31:27.913
577	312	470	13	\N	2026-03-18 13:31:27.913
578	320	407	10	\N	2026-03-25 10:40:34.32
579	320	403	10	\N	2026-03-25 10:40:34.32
580	320	403	10	\N	2026-03-25 10:40:34.32
581	316	412	10	\N	2026-03-25 10:41:00.016
582	316	415	10	\N	2026-03-25 10:41:00.016
583	316	415	10	\N	2026-03-25 10:41:00.016
584	317	424	10	\N	2026-03-25 10:41:14.573
585	317	422	10	\N	2026-03-25 10:41:14.573
586	318	428	10	\N	2026-03-25 10:41:28.514
587	319	695	10	\N	2026-03-25 10:42:22.937
588	319	694	10	\N	2026-03-25 10:42:22.937
589	319	694	10	\N	2026-03-25 10:42:22.937
590	319	325	9	\N	2026-03-25 10:42:22.937
591	319	487	9	\N	2026-03-25 10:42:22.937
592	319	489	9	\N	2026-03-25 10:42:22.937
593	314	443	10	\N	2026-03-25 10:43:57.277
594	314	441	10	\N	2026-03-25 10:43:57.277
595	314	345	9	\N	2026-03-25 10:43:57.277
596	314	352	9	\N	2026-03-25 10:43:57.277
597	314	713	9	\N	2026-03-25 10:43:57.277
598	314	343	9	\N	2026-03-25 10:43:57.277
599	315	433	10	\N	2026-03-25 10:45:43.684
600	315	699	10	\N	2026-03-25 10:45:43.684
601	315	437	10	\N	2026-03-25 10:45:43.684
602	315	332	9	\N	2026-03-25 10:45:43.684
603	315	333	9	\N	2026-03-25 10:45:43.684
604	315	333	9	\N	2026-03-25 10:45:43.684
605	315	748	9	\N	2026-03-25 10:45:43.684
606	315	334	9	\N	2026-03-25 10:45:43.684
613	326	282	1	\N	2026-03-25 10:47:31.077
614	326	282	1	\N	2026-03-25 10:47:31.077
615	326	286	1	\N	2026-03-25 10:47:31.077
616	326	171	11	\N	2026-03-25 10:47:31.077
617	326	172	11	\N	2026-03-25 10:47:31.077
618	326	170	11	\N	2026-03-25 10:47:31.077
619	325	378	1	\N	2026-03-25 10:48:25.747
620	325	375	1	\N	2026-03-25 10:48:25.747
621	325	375	1	\N	2026-03-25 10:48:25.747
622	323	386	1	\N	2026-03-25 10:49:07.375
623	323	278	1	\N	2026-03-25 10:49:07.375
624	323	279	1	\N	2026-03-25 10:49:07.375
625	323	279	1	\N	2026-03-25 10:49:07.375
626	323	660	11	\N	2026-03-25 10:49:07.375
627	323	660	11	\N	2026-03-25 10:49:07.375
628	327	390	1	\N	2026-03-25 10:49:59.965
629	327	394	1	\N	2026-03-25 10:49:59.965
630	327	388	1	\N	2026-03-25 10:49:59.965
631	327	388	1	\N	2026-03-25 10:49:59.965
632	324	272	1	\N	2026-03-25 10:50:31.789
633	324	178	11	\N	2026-03-25 10:50:31.789
634	321	754	1	\N	2026-03-25 16:45:00.641
635	321	182	11	\N	2026-03-25 16:45:00.641
636	321	150	11	\N	2026-03-25 16:45:00.641
637	321	150	11	\N	2026-03-25 16:45:00.641
638	321	150	11	\N	2026-03-25 16:45:00.641
639	321	147	11	\N	2026-03-25 16:45:00.641
640	300	400	1	\N	2026-03-25 16:45:20.744
641	300	400	1	\N	2026-03-25 16:45:20.744
642	300	443	10	\N	2026-03-25 16:45:20.744
643	300	441	10	\N	2026-03-25 16:45:20.744
644	341	186	11	\N	2026-03-31 12:06:59.704
645	341	186	11	\N	2026-03-31 12:06:59.704
646	341	289	9	\N	2026-03-31 12:06:59.704
647	341	290	9	\N	2026-03-31 12:06:59.704
648	341	288	9	\N	2026-03-31 12:06:59.704
649	341	288	9	\N	2026-03-31 12:06:59.704
650	341	291	9	\N	2026-03-31 12:06:59.704
651	337	296	9	\N	2026-03-31 12:09:13.813
652	337	744	9	\N	2026-03-31 12:09:13.813
653	337	744	9	\N	2026-03-31 12:09:13.813
654	337	295	9	\N	2026-03-31 12:09:13.813
655	337	295	9	\N	2026-03-31 12:09:13.813
656	338	176	11	\N	2026-03-31 12:09:39.426
657	338	358	11	\N	2026-03-31 12:09:39.426
658	338	358	11	\N	2026-03-31 12:09:39.426
659	338	177	11	\N	2026-03-31 12:09:39.426
660	338	177	11	\N	2026-03-31 12:09:39.426
661	338	177	11	\N	2026-03-31 12:09:39.426
662	339	140	11	\N	2026-03-31 12:10:37.772
663	339	315	9	\N	2026-03-31 12:10:37.772
664	339	315	9	\N	2026-03-31 12:10:37.772
665	339	317	9	\N	2026-03-31 12:10:37.772
666	339	317	9	\N	2026-03-31 12:10:37.772
667	339	320	9	\N	2026-03-31 12:10:37.772
668	340	172	11	\N	2026-03-31 12:11:09.871
669	340	324	9	\N	2026-03-31 12:11:09.871
670	340	325	9	\N	2026-03-31 12:11:09.871
671	340	325	9	\N	2026-03-31 12:11:09.871
672	340	327	9	\N	2026-03-31 12:11:09.871
673	340	328	9	\N	2026-03-31 12:11:09.871
674	340	328	9	\N	2026-03-31 12:11:09.871
675	340	328	9	\N	2026-03-31 12:11:09.871
676	340	328	9	\N	2026-03-31 12:11:09.871
677	340	328	9	\N	2026-03-31 12:11:09.871
678	340	328	9	\N	2026-03-31 12:11:09.871
679	336	335	9	\N	2026-03-31 12:11:19.751
680	336	335	9	\N	2026-03-31 12:11:19.751
681	335	150	11	\N	2026-03-31 12:12:22.831
682	335	150	11	\N	2026-03-31 12:12:22.831
683	335	150	11	\N	2026-03-31 12:12:22.831
684	335	146	11	\N	2026-03-31 12:12:22.831
685	335	146	11	\N	2026-03-31 12:12:22.831
686	335	146	11	\N	2026-03-31 12:12:22.831
687	335	147	11	\N	2026-03-31 12:12:22.831
688	335	147	11	\N	2026-03-31 12:12:22.831
689	335	352	9	\N	2026-03-31 12:12:22.831
690	335	343	9	\N	2026-03-31 12:12:22.831
691	272	352	9	\N	2026-04-03 19:53:33.651
692	272	343	9	\N	2026-04-03 19:53:33.651
693	272	754	1	\N	2026-04-03 19:53:33.651
694	272	399	1	\N	2026-04-03 19:53:33.651
695	272	399	1	\N	2026-04-03 19:53:33.651
696	272	399	1	\N	2026-04-03 19:53:33.651
697	272	400	1	\N	2026-04-03 19:53:33.651
698	272	400	1	\N	2026-04-03 19:53:33.651
699	272	402	1	\N	2026-04-03 19:53:33.651
700	273	675	1	\N	2026-04-03 19:54:05.212
701	273	675	1	\N	2026-04-03 19:54:05.212
702	273	374	1	\N	2026-04-03 19:54:05.212
703	273	676	1	\N	2026-04-03 19:54:05.212
704	273	759	1	\N	2026-04-03 19:54:05.212
705	277	324	9	\N	2026-04-03 19:54:39.219
706	277	325	9	\N	2026-04-03 19:54:39.219
707	277	709	9	\N	2026-04-03 19:54:39.219
708	277	709	9	\N	2026-04-03 19:54:39.219
709	277	709	9	\N	2026-04-03 19:54:39.219
710	277	489	9	\N	2026-04-03 19:54:39.219
711	277	328	9	\N	2026-04-03 19:54:39.219
712	277	286	1	\N	2026-04-03 19:54:39.219
713	276	317	9	\N	2026-04-03 19:55:03.818
714	276	378	1	\N	2026-04-03 19:55:03.818
715	276	378	1	\N	2026-04-03 19:55:03.818
716	276	377	1	\N	2026-04-03 19:55:03.818
717	275	313	9	\N	2026-04-03 19:55:37.38
718	275	359	1	\N	2026-04-03 19:55:37.38
719	275	359	1	\N	2026-04-03 19:55:37.38
720	275	668	1	\N	2026-04-03 19:55:37.38
721	275	667	1	\N	2026-04-03 19:55:37.38
722	275	756	1	\N	2026-04-03 19:55:37.38
723	275	272	1	\N	2026-04-03 19:55:37.38
724	274	296	9	\N	2026-04-03 19:56:12.196
725	274	300	9	\N	2026-04-03 19:56:12.196
726	274	663	1	\N	2026-04-03 19:56:12.196
727	274	663	1	\N	2026-04-03 19:56:12.196
728	274	664	1	\N	2026-04-03 19:56:12.196
729	274	279	1	\N	2026-04-03 19:56:12.196
730	278	391	1	\N	2026-04-03 19:56:34.835
731	278	396	1	\N	2026-04-03 19:56:34.835
732	278	396	1	\N	2026-04-03 19:56:34.835
733	278	396	1	\N	2026-04-03 19:56:34.835
734	278	388	1	\N	2026-04-03 19:56:34.835
735	278	388	1	\N	2026-04-03 19:56:34.835
736	346	206	12	\N	2026-04-03 21:14:16.376
737	346	428	10	\N	2026-04-03 21:14:16.376
738	346	430	10	\N	2026-04-03 21:14:16.376
739	345	207	12	\N	2026-04-03 21:15:21.65
740	345	199	12	\N	2026-04-03 21:15:21.65
741	345	425	10	\N	2026-04-03 21:15:21.65
742	347	464	12	\N	2026-04-03 21:15:50.748
743	347	493	10	\N	2026-04-03 21:15:50.748
744	347	490	10	\N	2026-04-03 21:15:50.748
745	347	697	10	\N	2026-04-03 21:15:50.748
746	344	412	10	\N	2026-04-03 21:16:27.761
747	344	415	10	\N	2026-04-03 21:16:27.761
748	348	407	10	\N	2026-04-03 21:16:49.227
749	348	408	10	\N	2026-04-03 21:16:49.227
750	342	731	12	\N	2026-04-03 21:17:47.401
751	342	731	12	\N	2026-04-03 21:17:47.401
752	342	731	12	\N	2026-04-03 21:17:47.401
753	342	734	12	\N	2026-04-03 21:17:47.401
754	342	445	10	\N	2026-04-03 21:17:47.401
755	343	725	12	\N	2026-04-03 21:18:14.56
756	343	223	12	\N	2026-04-03 21:18:14.56
776	376	391	1	\N	2026-04-16 23:04:43.938
777	376	392	1	\N	2026-04-16 23:04:43.938
778	376	392	1	\N	2026-04-16 23:04:43.938
779	376	392	1	\N	2026-04-16 23:04:43.938
780	376	392	1	\N	2026-04-16 23:04:43.938
781	373	668	1	\N	2026-04-16 23:05:27.421
782	373	668	1	\N	2026-04-16 23:05:27.421
783	374	375	1	\N	2026-04-16 23:05:45.917
784	374	205	12	\N	2026-04-16 23:05:45.917
785	375	284	1	\N	2026-04-16 23:06:19.077
786	375	282	1	\N	2026-04-16 23:06:19.077
787	375	282	1	\N	2026-04-16 23:06:19.077
788	375	282	1	\N	2026-04-16 23:06:19.077
789	375	283	1	\N	2026-04-16 23:06:19.077
790	371	676	1	\N	2026-04-16 23:07:03.968
791	371	676	1	\N	2026-04-16 23:07:03.968
792	371	676	1	\N	2026-04-16 23:07:03.968
793	371	676	1	\N	2026-04-16 23:07:03.968
794	371	676	1	\N	2026-04-16 23:07:03.968
795	371	752	1	\N	2026-04-16 23:07:03.968
796	371	759	1	\N	2026-04-16 23:07:03.968
797	371	759	1	\N	2026-04-16 23:07:03.968
798	371	725	12	\N	2026-04-16 23:07:03.968
799	371	725	12	\N	2026-04-16 23:07:03.968
800	371	725	12	\N	2026-04-16 23:07:03.968
801	371	477	12	\N	2026-04-16 23:07:03.968
802	370	399	1	\N	2026-04-16 23:07:24.361
803	370	399	1	\N	2026-04-16 23:07:24.361
804	370	400	1	\N	2026-04-16 23:07:24.361
805	370	400	1	\N	2026-04-16 23:07:24.361
806	370	732	12	\N	2026-04-16 23:07:24.361
809	383	391	1	\N	2026-04-25 12:16:28.797
812	381	379	1	\N	2026-04-25 13:31:22.224
813	381	377	1	\N	2026-04-25 13:31:22.224
814	381	317	9	\N	2026-04-25 13:31:22.224
815	381	316	9	\N	2026-04-25 13:31:22.224
816	379	663	1	\N	2026-04-25 13:31:58.686
817	379	664	1	\N	2026-04-25 13:31:58.686
818	379	280	1	\N	2026-04-25 13:31:58.686
819	379	280	1	\N	2026-04-25 13:31:58.686
820	379	280	1	\N	2026-04-25 13:31:58.686
821	379	296	9	\N	2026-04-25 13:31:58.686
822	379	300	9	\N	2026-04-25 13:31:58.686
823	378	676	1	\N	2026-04-25 13:32:33.045
824	378	676	1	\N	2026-04-25 13:32:33.045
825	378	759	1	\N	2026-04-25 13:32:33.045
826	378	333	9	\N	2026-04-25 13:32:33.045
827	380	270	1	\N	2026-04-25 13:33:09.924
828	380	269	1	\N	2026-04-25 13:33:09.924
829	380	272	1	\N	2026-04-25 13:33:09.924
830	380	767	1	\N	2026-04-25 13:33:09.924
831	377	400	1	\N	2026-04-25 13:33:34.278
832	377	400	1	\N	2026-04-25 13:33:34.278
833	377	346	9	\N	2026-04-25 13:33:34.278
834	382	328	9	\N	2026-04-25 13:33:51.607
835	382	328	9	\N	2026-04-25 13:33:51.607
836	391	731	12	\N	2026-04-25 13:38:11.308
837	391	150	11	\N	2026-04-25 13:38:11.308
838	391	150	11	\N	2026-04-25 13:38:11.308
839	391	150	11	\N	2026-04-25 13:38:11.308
840	391	145	11	\N	2026-04-25 13:38:11.308
841	391	147	11	\N	2026-04-25 13:38:11.308
842	393	688	12	\N	2026-04-25 13:39:04.246
843	393	450	12	\N	2026-04-25 13:39:04.246
844	393	450	12	\N	2026-04-25 13:39:04.246
845	397	686	12	\N	2026-04-25 13:39:29.713
846	397	186	11	\N	2026-04-25 13:39:29.713
847	397	152	11	\N	2026-04-25 13:39:29.713
848	395	693	12	\N	2026-04-25 13:39:43.424
849	394	358	11	\N	2026-04-25 13:39:58.664
850	396	760	12	\N	2026-04-25 13:40:33.922
851	396	760	12	\N	2026-04-25 13:40:33.922
852	396	218	12	\N	2026-04-25 13:40:33.922
853	396	170	11	\N	2026-04-25 13:40:33.922
854	368	493	10	\N	2026-04-28 12:14:09.035
855	368	490	10	\N	2026-04-28 12:14:09.035
856	368	491	10	\N	2026-04-28 12:14:09.035
857	368	362	11	\N	2026-04-28 12:14:09.035
858	368	170	11	\N	2026-04-28 12:14:09.035
859	367	428	10	\N	2026-04-28 12:14:40.976
860	367	431	10	\N	2026-04-28 12:14:40.976
861	367	430	10	\N	2026-04-28 12:14:40.976
862	367	141	11	\N	2026-04-28 12:14:40.976
863	366	689	10	\N	2026-04-28 12:15:11.141
864	366	176	11	\N	2026-04-28 12:15:11.141
865	366	177	11	\N	2026-04-28 12:15:11.141
866	365	419	10	\N	2026-04-28 12:15:27.421
867	365	419	10	\N	2026-04-28 12:15:27.421
868	363	442	10	\N	2026-04-28 12:16:10.65
869	363	445	10	\N	2026-04-28 12:16:10.65
870	363	443	10	\N	2026-04-28 12:16:10.65
871	363	150	11	\N	2026-04-28 12:16:10.65
872	363	150	11	\N	2026-04-28 12:16:10.65
873	363	145	11	\N	2026-04-28 12:16:10.65
874	363	145	11	\N	2026-04-28 12:16:10.65
875	363	147	11	\N	2026-04-28 12:16:10.65
876	369	407	10	\N	2026-04-28 12:17:51.305
877	369	407	10	\N	2026-04-28 12:17:51.305
878	369	407	10	\N	2026-04-28 12:17:51.305
879	369	408	10	\N	2026-04-28 12:17:51.305
880	369	403	10	\N	2026-04-28 12:17:51.305
881	369	405	10	\N	2026-04-28 12:17:51.305
882	369	186	11	\N	2026-04-28 12:17:51.305
883	369	152	11	\N	2026-04-28 12:17:51.305
\.


--
-- Data for Name: League; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."League" (id, name, slug, "colorHex", "gameDay", "createdAt", "updatedAt") FROM stdin;
1	Liga de futbol Infantil (D)	infantil-dom	#0057B8	DOMINGO	2026-01-12 16:18:23.401	2026-01-12 16:18:23.401
2	Liga de futbol Infantil (S)	liga-de-futbol-infantil-s	#00FF55	SABADO	2026-01-14 12:13:00.217	2026-01-14 12:13:00.217
3	Liga de verano	liga-de-verano	#0057B8	SABADO	2026-02-02 13:29:29.053	2026-02-02 13:29:29.053
\.


--
-- Data for Name: Match; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Match" (id, "tournamentId", "zoneId", matchday, round, date, status, "homeClubId", "awayClubId", "createdAt", "updatedAt") FROM stdin;
7	1	1	4	FIRST	\N	PROGRAMMED	2	5	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
8	1	1	4	FIRST	\N	PROGRAMMED	4	1	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
9	1	1	5	FIRST	\N	PROGRAMMED	5	4	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
10	1	1	5	FIRST	\N	PROGRAMMED	1	3	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
11	1	1	6	SECOND	\N	PROGRAMMED	3	4	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
12	1	1	6	SECOND	\N	PROGRAMMED	1	2	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
13	1	1	7	SECOND	\N	PROGRAMMED	5	3	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
14	1	1	7	SECOND	\N	PROGRAMMED	4	2	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
15	1	1	8	SECOND	\N	PROGRAMMED	1	5	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
16	1	1	8	SECOND	\N	PROGRAMMED	2	3	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
17	1	1	9	SECOND	\N	PROGRAMMED	5	2	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
18	1	1	9	SECOND	\N	PROGRAMMED	1	4	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
19	1	1	10	SECOND	\N	PROGRAMMED	4	5	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
20	1	1	10	SECOND	\N	PROGRAMMED	3	1	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
28	3	3	4	SECOND	\N	FINISHED	7	1	2026-02-02 14:57:25.958	2026-03-12 12:37:54.485
1	1	1	1	FIRST	\N	FINISHED	4	3	2026-01-15 12:23:14.223	2026-01-20 11:23:49.935
2	1	1	1	FIRST	\N	FINISHED	2	1	2026-01-15 12:23:14.233	2026-01-20 11:24:43.138
4	1	1	2	FIRST	\N	FINISHED	2	4	2026-01-15 12:23:14.243	2026-01-20 11:26:08.695
3	1	1	2	FIRST	\N	FINISHED	3	5	2026-01-15 12:23:14.238	2026-01-20 11:26:59.263
5	1	1	3	FIRST	\N	FINISHED	5	1	2026-01-15 12:23:14.248	2026-01-20 11:27:45.775
6	1	1	3	FIRST	\N	FINISHED	3	2	2026-01-15 12:23:14.253	2026-01-20 11:28:16.008
31	3	3	6	SECOND	\N	PROGRAMMED	6	1	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
32	3	3	6	SECOND	\N	PROGRAMMED	8	7	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
60	4	4	10	SECOND	\N	PROGRAMMED	9	12	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
34	4	4	1	FIRST	\N	FINISHED	11	1	2026-02-11 11:40:23.638	2026-02-14 16:49:16.077
35	4	4	1	FIRST	\N	FINISHED	12	13	2026-02-11 11:40:23.642	2026-02-14 19:24:57.348
33	4	4	1	FIRST	\N	FINISHED	9	10	2026-02-11 11:40:23.629	2026-02-14 19:32:12.981
21	3	3	1	FIRST	\N	FINISHED	1	6	2026-02-02 14:57:25.929	2026-02-18 10:40:36.483
22	3	3	1	FIRST	\N	FINISHED	7	8	2026-02-02 14:57:25.937	2026-02-18 10:42:55.494
24	3	3	2	FIRST	\N	FINISHED	8	1	2026-02-02 14:57:25.944	2026-02-20 10:27:18.925
36	4	4	2	FIRST	\N	FINISHED	9	11	2026-02-11 11:40:23.646	2026-02-21 13:43:34.464
38	4	4	2	FIRST	\N	FINISHED	1	13	2026-02-11 11:40:23.653	2026-02-21 17:11:38.648
37	4	4	2	FIRST	\N	FINISHED	10	12	2026-02-11 11:40:23.649	2026-02-26 11:46:48.668
25	3	3	3	FIRST	\N	FINISHED	1	7	2026-02-02 14:57:25.948	2026-02-27 10:16:29.456
39	4	4	3	FIRST	\N	FINISHED	13	9	2026-02-11 11:40:23.656	2026-02-28 21:56:55.399
40	4	4	3	FIRST	\N	FINISHED	11	10	2026-02-11 11:40:23.66	2026-02-28 22:06:02.351
41	4	4	3	FIRST	\N	FINISHED	12	1	2026-02-11 11:40:23.663	2026-02-28 22:25:10.741
44	4	4	4	FIRST	\N	FINISHED	11	12	2026-02-11 11:40:23.674	2026-03-10 10:45:53.433
29	3	3	5	SECOND	\N	FINISHED	7	6	2026-02-02 14:57:25.961	2026-03-12 12:25:12.574
43	4	4	4	FIRST	\N	FINISHED	10	13	2026-02-11 11:40:23.67	2026-03-12 12:33:54.218
23	3	3	2	FIRST	\N	FINISHED	6	7	2026-02-02 14:57:25.941	2026-03-12 18:09:26.154
26	3	3	3	FIRST	\N	FINISHED	8	6	2026-02-02 14:57:25.951	2026-03-12 18:09:41.458
27	3	3	4	SECOND	\N	FINISHED	6	8	2026-02-02 14:57:25.955	2026-03-12 18:09:49.927
30	3	3	5	SECOND	\N	FINISHED	1	8	2026-02-02 14:57:25.964	2026-03-12 18:10:03.458
48	4	4	6	SECOND	\N	FINISHED	10	9	2026-02-11 11:40:23.687	2026-03-25 10:45:43.69
49	4	4	6	SECOND	\N	FINISHED	1	11	2026-02-11 11:40:23.691	2026-03-25 16:45:00.653
46	4	4	5	FIRST	\N	FINISHED	1	10	2026-02-11 11:40:23.68	2026-03-25 16:45:20.753
47	4	4	5	FIRST	\N	FINISHED	13	11	2026-02-11 11:40:23.684	2026-03-25 16:46:43.798
45	4	4	5	FIRST	\N	FINISHED	12	9	2026-02-11 11:40:23.677	2026-03-25 16:47:50.436
51	4	4	7	SECOND	\N	FINISHED	11	9	2026-02-11 11:40:23.698	2026-03-31 12:12:22.837
42	4	4	4	FIRST	\N	FINISHED	9	1	2026-02-11 11:40:23.667	2026-04-03 19:56:34.842
52	4	4	7	SECOND	\N	FINISHED	12	10	2026-02-11 11:40:23.702	2026-04-03 21:18:14.565
54	4	4	8	SECOND	\N	FINISHED	9	13	2026-02-11 11:40:23.708	2026-04-23 19:13:34.936
56	4	4	8	SECOND	\N	FINISHED	1	12	2026-02-11 11:40:23.714	2026-04-16 23:44:22.76
50	4	4	6	SECOND	\N	FINISHED	13	12	2026-02-11 11:40:23.694	2026-04-23 19:11:39.324
53	4	4	7	SECOND	\N	FINISHED	13	1	2026-02-11 11:40:23.705	2026-04-23 19:12:08.855
58	4	4	9	SECOND	\N	FINISHED	13	10	2026-02-11 11:40:23.72	2026-04-23 19:14:12.475
62	4	4	10	SECOND	\N	FINISHED	11	13	2026-02-11 11:40:23.731	2026-04-23 19:14:52.164
57	4	4	9	SECOND	\N	FINISHED	1	9	2026-02-11 11:40:23.717	2026-04-25 13:33:51.613
59	4	4	9	SECOND	\N	FINISHED	12	11	2026-02-11 11:40:23.722	2026-04-25 13:40:33.926
55	4	4	8	SECOND	\N	FINISHED	10	11	2026-02-11 11:40:23.711	2026-04-28 12:19:03.872
61	4	4	10	SECOND	\N	FINISHED	10	1	2026-02-11 11:40:23.729	2026-05-04 22:57:15.827
\.


--
-- Data for Name: MatchAttachment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MatchAttachment" (id, "matchId", url, "uploadedById", "createdAt") FROM stdin;
\.


--
-- Data for Name: MatchCategory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MatchCategory" (id, "matchId", "tournamentCategoryId", "kickoffTime", "isPromocional", "homeScore", "awayScore", "closedAt", "closedById", "createdAt", "updatedAt") FROM stdin;
31	7	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
32	7	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
33	7	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
34	7	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
35	7	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.258	2026-01-15 12:23:14.258
36	8	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
37	8	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
38	8	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
39	8	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
40	8	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.262	2026-01-15 12:23:14.262
41	9	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
42	9	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
43	9	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
44	9	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
45	9	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.266	2026-01-15 12:23:14.266
46	10	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
47	10	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
48	10	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
49	10	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
50	10	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.27	2026-01-15 12:23:14.27
51	11	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
52	11	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
53	11	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
54	11	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
55	11	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.275	2026-01-15 12:23:14.275
56	12	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
57	12	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
58	12	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
59	12	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
60	12	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.278	2026-01-15 12:23:14.278
61	13	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
62	13	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
63	13	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
64	13	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
65	13	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.28	2026-01-15 12:23:14.28
66	14	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
67	14	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
68	14	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
69	14	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
70	14	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.283	2026-01-15 12:23:14.283
71	15	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
72	15	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
73	15	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
74	15	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
75	15	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.286	2026-01-15 12:23:14.286
76	16	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
77	16	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
78	16	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
79	16	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
80	16	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.288	2026-01-15 12:23:14.288
81	17	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
82	17	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
83	17	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
84	17	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
85	17	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.291	2026-01-15 12:23:14.291
86	18	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
87	18	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
88	18	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
89	18	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
90	18	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.294	2026-01-15 12:23:14.294
91	19	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
92	19	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
93	19	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
94	19	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
95	19	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.296	2026-01-15 12:23:14.296
96	20	2	10:00	f	0	0	\N	\N	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
97	20	3	10:40	f	0	0	\N	\N	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
4	1	3	10:40	f	1	1	2026-01-20 11:23:02.156	2	2026-01-15 12:23:14.223	2026-01-20 11:23:02.157
10	2	2	10:00	f	0	1	2026-01-20 11:24:21.088	2	2026-01-15 12:23:14.233	2026-01-20 11:24:21.089
2	1	5	12:00	f	1	1	2026-01-20 11:23:19.878	2	2026-01-15 12:23:14.223	2026-01-20 11:23:19.879
1	1	6	12:40	f	2	4	2026-01-20 11:23:49.932	2	2026-01-15 12:23:14.223	2026-01-20 11:23:49.933
9	2	3	10:40	f	0	1	2026-01-20 11:24:24.219	2	2026-01-15 12:23:14.233	2026-01-20 11:24:24.22
8	2	4	11:20	f	0	2	2026-01-20 11:24:28.728	2	2026-01-15 12:23:14.233	2026-01-20 11:24:28.729
7	2	5	12:00	f	1	3	2026-01-20 11:24:34.177	2	2026-01-15 12:23:14.233	2026-01-20 11:24:34.178
6	2	6	12:40	f	3	4	2026-01-20 11:24:43.135	2	2026-01-15 12:23:14.233	2026-01-20 11:24:43.135
14	3	3	10:40	f	0	1	2026-01-20 11:25:27.498	2	2026-01-15 12:23:14.238	2026-01-20 11:25:27.499
13	3	4	11:20	f	0	1	2026-01-20 11:25:31.303	2	2026-01-15 12:23:14.238	2026-01-20 11:25:31.304
12	3	5	12:00	f	1	0	2026-01-20 11:25:36.149	2	2026-01-15 12:23:14.238	2026-01-20 11:25:36.15
20	4	2	10:00	f	1	0	2026-01-20 11:25:50.134	2	2026-01-15 12:23:14.243	2026-01-20 11:25:50.135
19	4	3	10:40	f	0	1	2026-01-20 11:25:54.254	2	2026-01-15 12:23:14.243	2026-01-20 11:25:54.254
18	4	4	11:20	f	1	2	2026-01-20 11:25:59.684	2	2026-01-15 12:23:14.243	2026-01-20 11:25:59.684
17	4	5	12:00	f	1	0	2026-01-20 11:26:03.819	2	2026-01-15 12:23:14.243	2026-01-20 11:26:03.82
11	3	6	12:40	f	1	0	2026-01-20 11:26:59.259	2	2026-01-15 12:23:14.238	2026-01-20 11:26:59.26
25	5	2	10:00	f	1	2	2026-01-20 11:27:21.756	2	2026-01-15 12:23:14.248	2026-01-20 11:27:21.757
24	5	3	10:40	f	0	1	2026-01-20 11:27:26.638	2	2026-01-15 12:23:14.248	2026-01-20 11:27:26.639
23	5	4	11:20	f	2	3	2026-01-20 11:27:32.972	2	2026-01-15 12:23:14.248	2026-01-20 11:27:32.973
21	5	6	12:40	f	0	1	2026-01-20 11:27:45.771	2	2026-01-15 12:23:14.248	2026-01-20 11:27:45.772
22	5	5	12:00	f	1	3	2026-01-20 11:27:41.205	2	2026-01-15 12:23:14.248	2026-01-20 11:27:41.206
29	6	3	10:40	f	2	0	2026-01-20 11:28:00.135	2	2026-01-15 12:23:14.253	2026-01-20 11:28:00.135
28	6	4	11:20	f	0	2	2026-01-20 11:28:03.75	2	2026-01-15 12:23:14.253	2026-01-20 11:28:03.751
26	6	6	12:40	f	1	1	2026-01-20 11:28:16.005	2	2026-01-15 12:23:14.253	2026-01-20 11:28:16.006
27	6	5	12:00	f	1	1	2026-01-20 11:28:11.289	2	2026-01-15 12:23:14.253	2026-01-20 11:28:11.291
98	20	4	11:20	f	0	0	\N	\N	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
99	20	5	12:00	f	0	0	\N	\N	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
100	20	6	12:40	f	0	0	\N	\N	2026-01-15 12:23:14.299	2026-01-15 12:23:14.299
5	1	2	10:00	f	1	2	2026-01-16 11:28:51.653	2	2026-01-15 12:23:14.223	2026-01-16 11:28:51.654
3	1	4	11:20	f	2	3	2026-01-20 11:23:43.405	2	2026-01-15 12:23:14.223	2026-01-20 11:23:43.405
15	3	2	10:00	f	1	1	2026-01-20 11:25:23.043	2	2026-01-15 12:23:14.238	2026-01-20 11:25:23.044
16	4	6	12:40	f	1	1	2026-01-20 11:26:08.692	2	2026-01-15 12:23:14.243	2026-01-20 11:26:08.693
30	6	2	10:00	f	1	1	2026-01-20 11:27:55.095	2	2026-01-15 12:23:14.253	2026-01-20 11:27:55.096
103	21	21	18:00	f	3	1	2026-02-18 10:34:30.03	2	2026-02-02 14:57:25.929	2026-02-18 10:34:30.031
106	21	24	21:20	f	1	5	2026-02-18 10:35:20.989	2	2026-02-02 14:57:25.929	2026-02-18 10:35:20.99
102	21	20	22:40	f	5	6	2026-02-18 10:36:33.881	2	2026-02-02 14:57:25.929	2026-02-18 10:36:33.882
107	21	25	20:00	f	1	8	2026-02-18 10:37:42.847	2	2026-02-02 14:57:25.929	2026-02-18 10:37:42.848
109	21	27	19:20	f	5	0	2026-02-18 10:38:41.468	2	2026-02-02 14:57:25.929	2026-02-18 10:38:41.469
104	21	22	18:40	f	2	3	2026-02-18 10:39:49.015	2	2026-02-02 14:57:25.929	2026-02-18 10:39:49.016
105	21	23	22:00	f	3	1	2026-02-18 10:40:23.233	2	2026-02-02 14:57:25.929	2026-02-18 10:40:23.234
101	21	19	23:20	f	1	0	2026-02-18 10:40:36.48	2	2026-02-02 14:57:25.929	2026-02-18 10:40:36.481
118	22	27	19:20	f	2	0	2026-02-18 10:41:34.518	2	2026-02-02 14:57:25.937	2026-02-18 10:41:34.518
117	22	26	20:40	f	0	2	2026-02-18 10:41:39.293	2	2026-02-02 14:57:25.937	2026-02-18 10:41:39.294
116	22	25	20:00	f	3	2	2026-02-18 10:41:47.429	2	2026-02-02 14:57:25.937	2026-02-18 10:41:47.43
115	22	24	21:20	f	3	4	2026-02-18 10:41:56.593	2	2026-02-02 14:57:25.937	2026-02-18 10:41:56.593
113	22	22	18:40	f	2	4	2026-02-18 10:42:11.15	2	2026-02-02 14:57:25.937	2026-02-18 10:42:11.151
112	22	21	18:00	f	2	0	2026-02-18 10:42:18.188	2	2026-02-02 14:57:25.937	2026-02-18 10:42:18.189
111	22	20	22:40	f	7	5	2026-02-18 10:42:47.151	2	2026-02-02 14:57:25.937	2026-02-18 10:42:47.152
110	22	19	23:20	f	6	5	2026-02-18 10:42:55.489	2	2026-02-02 14:57:25.937	2026-02-18 10:42:55.49
119	23	19	23:20	f	8	11	2026-02-18 11:15:41.213	2	2026-02-02 14:57:25.941	2026-02-18 11:15:41.214
120	23	20	22:40	f	4	2	2026-02-18 11:16:09.826	2	2026-02-02 14:57:25.941	2026-02-18 11:16:09.827
122	23	22	18:40	f	4	4	2026-02-18 11:16:38.059	2	2026-02-02 14:57:25.941	2026-02-18 11:16:38.06
123	23	23	22:00	f	1	1	2026-02-18 11:16:50.426	2	2026-02-02 14:57:25.941	2026-02-18 11:16:50.427
124	23	24	21:20	f	2	0	2026-02-18 11:17:01.564	2	2026-02-02 14:57:25.941	2026-02-18 11:17:01.565
126	23	26	20:40	f	0	1	2026-02-18 11:17:22.625	2	2026-02-02 14:57:25.941	2026-02-18 11:17:22.626
127	23	27	19:20	f	1	2	2026-02-18 11:17:37.562	2	2026-02-02 14:57:25.941	2026-02-18 11:17:37.563
136	24	27	19:20	f	2	0	2026-02-20 10:25:42.49	2	2026-02-02 14:57:25.944	2026-02-20 10:25:42.491
135	24	26	20:40	f	5	1	2026-02-20 10:25:57.713	2	2026-02-02 14:57:25.944	2026-02-20 10:25:57.714
133	24	24	21:20	f	5	1	2026-02-20 10:26:25.428	2	2026-02-02 14:57:25.944	2026-02-20 10:26:25.429
132	24	23	22:00	f	1	3	2026-02-20 10:26:40.137	2	2026-02-02 14:57:25.944	2026-02-20 10:26:40.138
131	24	22	18:40	f	5	1	2026-02-20 10:26:50.26	2	2026-02-02 14:57:25.944	2026-02-20 10:26:50.261
130	24	21	18:00	f	1	0	2026-02-20 10:26:57.503	2	2026-02-02 14:57:25.944	2026-02-20 10:26:57.504
129	24	20	22:40	f	3	2	2026-02-20 10:27:06.903	2	2026-02-02 14:57:25.944	2026-02-20 10:27:06.904
128	24	19	23:20	f	0	1	2026-02-20 10:27:18.922	2	2026-02-02 14:57:25.944	2026-02-20 10:27:18.923
154	26	27	19:20	f	0	0	2026-03-12 18:09:41.454	2	2026-02-02 14:57:25.951	2026-03-12 18:09:41.455
144	25	26	20:40	f	1	2	2026-02-25 16:24:00.678	2	2026-02-02 14:57:25.948	2026-02-25 16:24:00.679
139	25	21	18:00	f	2	4	2026-02-25 16:24:09.749	2	2026-02-02 14:57:25.948	2026-02-25 16:24:09.75
148	26	21	18:00	f	4	3	2026-02-25 16:24:49.612	2	2026-02-02 14:57:25.951	2026-02-25 16:24:49.613
149	26	22	18:40	f	4	3	2026-02-25 16:25:02.343	2	2026-02-02 14:57:25.951	2026-02-25 16:25:02.344
152	26	25	20:00	f	0	3	2026-02-25 16:25:13.176	2	2026-02-02 14:57:25.951	2026-02-25 16:25:13.177
153	26	26	20:40	f	1	1	2026-02-25 16:25:23.19	2	2026-02-02 14:57:25.951	2026-02-25 16:25:23.19
150	26	23	22:00	f	1	2	2026-02-25 16:25:45.26	2	2026-02-02 14:57:25.951	2026-02-25 16:25:45.261
147	26	20	22:40	f	4	4	2026-02-25 16:25:55.272	2	2026-02-02 14:57:25.951	2026-02-25 16:25:55.272
146	26	19	23:20	f	2	2	2026-02-25 16:26:03.703	2	2026-02-02 14:57:25.951	2026-02-25 16:26:03.704
141	25	23	22:00	f	1	2	2026-02-25 16:48:54.552	2	2026-02-02 14:57:25.948	2026-02-25 16:48:54.553
137	25	19	23:20	f	3	2	2026-02-25 16:49:02.036	2	2026-02-02 14:57:25.948	2026-02-25 16:49:02.037
142	25	24	21:20	f	1	4	2026-02-25 17:12:23.302	2	2026-02-02 14:57:25.948	2026-02-25 17:12:23.303
140	25	22	18:40	f	1	4	2026-02-27 10:16:29.451	2	2026-02-02 14:57:25.948	2026-02-27 10:16:29.452
145	25	27	19:20	f	1	0	2026-02-25 17:43:22.596	2	2026-02-02 14:57:25.948	2026-02-25 17:43:22.597
163	27	27	19:20	f	2	0	2026-03-10 10:46:43.324	2	2026-02-02 14:57:25.955	2026-03-10 10:46:43.324
162	27	26	20:40	f	1	1	2026-03-10 10:46:50.819	2	2026-02-02 14:57:25.955	2026-03-10 10:46:50.819
161	27	25	20:00	f	0	5	2026-03-10 10:47:01.131	2	2026-02-02 14:57:25.955	2026-03-10 10:47:01.132
160	27	24	21:20	f	1	1	2026-03-10 10:47:10.069	2	2026-02-02 14:57:25.955	2026-03-10 10:47:10.07
158	27	22	18:40	f	2	4	2026-03-10 10:47:30.847	2	2026-02-02 14:57:25.955	2026-03-10 10:47:30.848
157	27	21	18:00	f	2	4	2026-03-10 10:47:41.595	2	2026-02-02 14:57:25.955	2026-03-10 10:47:41.596
155	27	19	23:20	f	2	3	2026-03-10 10:48:04.381	2	2026-02-02 14:57:25.955	2026-03-10 10:48:04.382
186	30	23	22:00	f	3	3	2026-03-10 10:49:41.932	2	2026-02-02 14:57:25.964	2026-03-10 10:49:41.933
182	30	19	23:20	f	1	1	2026-03-10 10:48:42.593	2	2026-02-02 14:57:25.964	2026-03-10 10:48:42.594
183	30	20	22:40	f	2	3	2026-03-10 10:49:06.999	2	2026-02-02 14:57:25.964	2026-03-10 10:49:07.001
184	30	21	18:00	f	4	5	2026-03-10 10:49:15.779	2	2026-02-02 14:57:25.964	2026-03-10 10:49:15.78
185	30	22	18:40	f	3	5	2026-03-10 10:49:30.26	2	2026-02-02 14:57:25.964	2026-03-10 10:49:30.26
173	29	19	23:20	f	1	0	2026-03-12 12:24:20.573	2	2026-02-02 14:57:25.961	2026-03-12 12:24:20.574
174	29	20	22:40	f	1	1	2026-03-12 12:24:31.372	2	2026-02-02 14:57:25.961	2026-03-12 12:24:31.373
175	29	21	18:00	f	1	0	2026-03-12 12:24:36.807	2	2026-02-02 14:57:25.961	2026-03-12 12:24:36.808
176	29	22	18:40	f	1	0	2026-03-12 12:24:41.165	2	2026-02-02 14:57:25.961	2026-03-12 12:24:41.166
177	29	23	22:00	f	1	0	2026-03-12 12:24:48.395	2	2026-02-02 14:57:25.961	2026-03-12 12:24:48.396
178	29	24	21:20	f	1	0	2026-03-12 12:24:52.543	2	2026-02-02 14:57:25.961	2026-03-12 12:24:52.544
179	29	25	20:00	f	1	1	2026-03-12 12:25:01.274	2	2026-02-02 14:57:25.961	2026-03-12 12:25:01.275
181	29	27	19:20	f	0	1	2026-03-12 12:25:12.571	2	2026-02-02 14:57:25.961	2026-03-12 12:25:12.572
164	28	19	23:20	f	1	0	2026-03-12 12:37:22.551	2	2026-02-02 14:57:25.958	2026-03-12 12:37:22.552
165	28	20	22:40	f	1	0	2026-03-12 12:37:26.138	2	2026-02-02 14:57:25.958	2026-03-12 12:37:26.139
166	28	21	18:00	f	1	0	2026-03-12 12:37:29.447	2	2026-02-02 14:57:25.958	2026-03-12 12:37:29.447
168	28	23	22:00	f	1	0	2026-03-12 12:37:40.211	2	2026-02-02 14:57:25.958	2026-03-12 12:37:40.212
167	28	22	18:40	f	1	0	2026-03-12 12:37:36.432	2	2026-02-02 14:57:25.958	2026-03-12 12:37:36.433
169	28	24	21:20	f	1	0	2026-03-12 12:37:43.916	2	2026-02-02 14:57:25.958	2026-03-12 12:37:43.917
171	28	26	20:40	f	1	0	2026-03-12 12:37:51.522	2	2026-02-02 14:57:25.958	2026-03-12 12:37:51.522
172	28	27	19:20	f	1	0	2026-03-12 12:37:54.483	2	2026-02-02 14:57:25.958	2026-03-12 12:37:54.484
159	27	23	22:00	f	0	0	2026-03-12 18:09:49.924	2	2026-02-02 14:57:25.955	2026-03-12 18:09:49.925
125	23	25	20:00	f	0	0	2026-03-12 18:09:26.15	2	2026-02-02 14:57:25.941	2026-03-12 18:09:26.151
191	31	19	23:20	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
192	31	20	22:40	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
193	31	21	18:00	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
194	31	22	18:40	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
195	31	23	22:00	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
196	31	24	21:20	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
197	31	25	20:00	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
198	31	26	20:40	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
199	31	27	19:20	f	0	0	\N	\N	2026-02-02 14:57:25.968	2026-02-02 14:57:25.968
200	32	19	23:20	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
201	32	20	22:40	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
202	32	21	18:00	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
203	32	22	18:40	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
204	32	23	22:00	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
205	32	24	21:20	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
206	32	25	20:00	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
207	32	26	20:40	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
208	32	27	19:20	f	0	0	\N	\N	2026-02-02 14:57:25.971	2026-02-02 14:57:25.971
229	35	34	19:15	f	0	2	2026-02-14 19:21:38.993	2	2026-02-11 11:40:23.642	2026-02-14 19:21:38.993
220	34	32	21:15	f	1	1	2026-02-14 14:18:35.287	2	2026-02-11 11:40:23.638	2026-02-14 14:18:35.288
218	34	30	19:55	f	2	3	2026-02-14 14:19:37.344	2	2026-02-11 11:40:23.638	2026-02-14 14:19:37.345
222	34	34	19:15	f	1	6	2026-02-14 14:20:28.032	2	2026-02-11 11:40:23.638	2026-02-14 14:20:28.033
216	34	28	23:45	f	7	1	2026-02-14 14:27:59.362	2	2026-02-11 11:40:23.638	2026-02-14 14:27:59.363
215	33	34	19:15	f	1	1	2026-02-14 16:43:52.433	2	2026-02-11 11:40:23.629	2026-02-14 16:43:52.434
211	33	30	19:55	f	0	6	2026-02-14 16:45:15.16	2	2026-02-11 11:40:23.629	2026-02-14 16:45:15.16
212	33	31	20:35	f	0	6	2026-02-14 16:45:46.539	2	2026-02-11 11:40:23.629	2026-02-14 16:45:46.54
210	33	29	22:55	f	8	0	2026-02-14 16:47:03.938	2	2026-02-11 11:40:23.629	2026-02-14 16:47:03.939
209	33	28	23:45	f	2	1	2026-02-14 16:47:29.61	2	2026-02-11 11:40:23.629	2026-02-14 16:47:29.611
221	34	33	22:05	f	2	3	2026-02-14 16:49:16.074	2	2026-02-11 11:40:23.638	2026-02-14 16:49:16.075
225	35	30	19:55	f	0	1	2026-02-14 19:22:00.191	2	2026-02-11 11:40:23.642	2026-02-14 19:22:00.192
226	35	31	20:35	f	1	2	2026-02-14 19:22:27.763	2	2026-02-11 11:40:23.642	2026-02-14 19:22:27.765
227	35	32	21:15	f	1	1	2026-02-14 19:22:55.161	2	2026-02-11 11:40:23.642	2026-02-14 19:22:55.162
228	35	33	22:05	f	1	7	2026-02-14 19:23:52.581	2	2026-02-11 11:40:23.642	2026-02-14 19:23:52.582
223	35	28	23:45	f	2	3	2026-02-14 19:24:57.345	2	2026-02-11 11:40:23.642	2026-02-14 19:24:57.346
214	33	33	22:05	f	3	0	2026-02-14 19:32:12.977	2	2026-02-11 11:40:23.629	2026-02-14 19:32:12.978
230	36	28	23:45	f	1	7	2026-02-21 13:39:34.393	2	2026-02-11 11:40:23.646	2026-02-21 13:39:34.394
231	36	29	22:55	f	6	2	2026-02-21 13:40:37.707	2	2026-02-11 11:40:23.646	2026-02-21 13:40:37.707
234	36	32	21:15	f	0	3	2026-02-21 13:41:05.057	2	2026-02-11 11:40:23.646	2026-02-21 13:41:05.058
235	36	33	22:05	f	4	1	2026-02-21 13:41:27.347	2	2026-02-11 11:40:23.646	2026-02-21 13:41:27.348
232	36	30	19:55	f	2	2	2026-02-21 13:42:57.467	2	2026-02-11 11:40:23.646	2026-02-21 13:42:57.468
236	36	34	19:15	f	2	2	2026-02-21 13:43:34.461	2	2026-02-11 11:40:23.646	2026-02-21 13:43:34.462
250	38	34	19:15	f	2	0	2026-02-21 17:08:35.841	2	2026-02-11 11:40:23.653	2026-02-21 17:08:35.842
246	38	30	19:55	f	2	0	2026-02-21 17:08:58.534	2	2026-02-11 11:40:23.653	2026-02-21 17:08:58.535
247	38	31	20:35	f	2	0	2026-02-21 17:09:26.515	2	2026-02-11 11:40:23.653	2026-02-21 17:09:26.516
248	38	32	21:15	f	1	0	2026-02-21 17:09:57.644	2	2026-02-11 11:40:23.653	2026-02-21 17:09:57.645
249	38	33	22:05	f	4	3	2026-02-21 17:10:33.754	2	2026-02-11 11:40:23.653	2026-02-21 17:10:33.755
244	38	28	23:45	f	2	3	2026-02-21 17:11:38.645	2	2026-02-11 11:40:23.653	2026-02-21 17:11:38.646
238	37	29	22:55	f	4	0	2026-02-26 11:42:47.885	2	2026-02-11 11:40:23.649	2026-02-26 11:42:47.886
243	37	34	19:15	f	4	2	2026-02-26 11:43:28.104	2	2026-02-11 11:40:23.649	2026-02-26 11:43:28.105
239	37	30	19:55	f	6	0	2026-02-26 11:44:10.228	2	2026-02-11 11:40:23.649	2026-02-26 11:44:10.229
240	37	31	20:35	f	1	3	2026-02-26 11:45:00.066	2	2026-02-11 11:40:23.649	2026-02-26 11:45:00.067
241	37	32	21:15	f	2	1	2026-02-26 11:45:40.642	2	2026-02-11 11:40:23.649	2026-02-26 11:45:40.642
242	37	33	22:05	f	8	0	2026-02-26 11:46:30.128	2	2026-02-11 11:40:23.649	2026-02-26 11:46:30.129
257	39	34	19:15	f	4	1	2026-02-28 21:52:45.655	2	2026-02-11 11:40:23.656	2026-02-28 21:52:45.656
253	39	30	19:55	f	2	0	2026-02-28 21:53:04.873	2	2026-02-11 11:40:23.656	2026-02-28 21:53:04.874
254	39	31	20:35	f	4	0	2026-02-28 21:53:34.633	2	2026-02-11 11:40:23.656	2026-02-28 21:53:34.634
255	39	32	21:15	f	5	4	2026-02-28 21:54:20.857	2	2026-02-11 11:40:23.656	2026-02-28 21:54:20.858
256	39	33	22:05	f	3	5	2026-02-28 21:55:19.195	2	2026-02-11 11:40:23.656	2026-02-28 21:55:19.196
252	39	29	22:55	f	2	0	2026-02-28 21:55:54.317	2	2026-02-11 11:40:23.656	2026-02-28 21:55:54.318
264	40	34	19:15	f	0	8	2026-02-28 22:02:14.997	2	2026-02-11 11:40:23.66	2026-02-28 22:02:14.998
260	40	30	19:55	f	0	4	2026-02-28 22:02:32.847	2	2026-02-11 11:40:23.66	2026-02-28 22:02:32.848
261	40	31	20:35	f	2	1	2026-02-28 22:03:00.243	2	2026-02-11 11:40:23.66	2026-02-28 22:03:00.244
262	40	32	21:15	f	6	2	2026-02-28 22:03:44.534	2	2026-02-11 11:40:23.66	2026-02-28 22:03:44.535
263	40	33	22:05	f	2	4	2026-02-28 22:04:23.816	2	2026-02-11 11:40:23.66	2026-02-28 22:04:23.817
259	40	29	22:55	f	11	1	2026-02-28 22:05:17.195	2	2026-02-11 11:40:23.66	2026-02-28 22:05:17.196
258	40	28	23:45	f	7	3	2026-02-28 22:06:02.347	2	2026-02-11 11:40:23.66	2026-02-28 22:06:02.347
266	41	29	22:55	f	1	9	2026-02-28 22:20:48.782	2	2026-02-11 11:40:23.663	2026-02-28 22:20:48.783
270	41	33	22:05	f	1	4	2026-02-28 22:21:42.949	2	2026-02-11 11:40:23.663	2026-02-28 22:21:42.949
269	41	32	21:15	f	3	1	2026-02-28 22:22:12.96	2	2026-02-11 11:40:23.663	2026-02-28 22:22:12.961
268	41	31	20:35	f	2	2	2026-02-28 22:23:40.798	2	2026-02-11 11:40:23.663	2026-02-28 22:23:40.799
267	41	30	19:55	f	0	4	2026-02-28 22:24:39.165	2	2026-02-11 11:40:23.663	2026-02-28 22:24:39.166
271	41	34	19:15	f	1	2	2026-02-28 22:25:10.738	2	2026-02-11 11:40:23.663	2026-02-28 22:25:10.739
188	30	25	20:00	f	0	1	2026-03-10 10:50:04.95	2	2026-02-02 14:57:25.964	2026-03-10 10:50:04.951
281	43	30	19:55	f	5	0	2026-03-12 12:30:50.432	2	2026-02-11 11:40:23.67	2026-03-12 12:30:50.433
282	43	31	20:35	f	0	4	2026-03-12 12:31:09.664	2	2026-02-11 11:40:23.67	2026-03-12 12:31:09.665
283	43	32	21:15	f	4	8	2026-03-12 12:32:01.923	2	2026-02-11 11:40:23.67	2026-03-12 12:32:01.924
284	43	33	22:05	f	1	3	2026-03-12 12:32:57.428	2	2026-02-11 11:40:23.67	2026-03-12 12:32:57.429
280	43	29	22:55	f	3	9	2026-03-12 12:33:38.334	2	2026-02-11 11:40:23.67	2026-03-12 12:33:38.335
279	43	28	23:45	f	2	0	2026-03-12 12:33:54.214	2	2026-02-11 11:40:23.67	2026-03-12 12:33:54.215
272	42	28	23:45	f	2	7	2026-04-03 19:53:33.655	2	2026-02-11 11:40:23.667	2026-04-03 19:53:33.656
273	42	29	22:55	f	0	5	2026-04-03 19:54:05.215	2	2026-02-11 11:40:23.667	2026-04-03 19:54:05.216
277	42	33	22:05	f	7	1	2026-04-03 19:54:39.221	2	2026-02-11 11:40:23.667	2026-04-03 19:54:39.222
276	42	32	21:15	f	1	3	2026-04-03 19:55:03.819	2	2026-02-11 11:40:23.667	2026-04-03 19:55:03.82
275	42	31	20:35	f	1	6	2026-04-03 19:55:37.381	2	2026-02-11 11:40:23.667	2026-04-03 19:55:37.382
274	42	30	19:55	f	2	4	2026-04-03 19:56:12.197	2	2026-02-11 11:40:23.667	2026-04-03 19:56:12.198
278	42	34	19:15	f	0	6	2026-04-03 19:56:34.836	2	2026-02-11 11:40:23.667	2026-04-03 19:56:34.837
287	44	29	22:55	f	9	0	2026-03-10 10:39:50.232	2	2026-02-11 11:40:23.674	2026-03-10 10:39:50.233
288	44	30	19:55	f	1	6	2026-03-10 10:41:17.927	2	2026-02-11 11:40:23.674	2026-03-10 10:41:17.928
291	44	33	22:05	f	9	4	2026-03-10 10:44:51.662	2	2026-02-11 11:40:23.674	2026-03-10 10:44:51.663
290	44	32	21:15	f	7	3	2026-03-10 10:45:34.028	2	2026-02-11 11:40:23.674	2026-03-10 10:45:34.029
289	44	31	20:35	f	2	0	2026-03-10 10:45:53.43	2	2026-02-11 11:40:23.674	2026-03-10 10:45:53.431
285	43	34	19:15	f	3	0	2026-03-12 12:30:06.834	2	2026-02-11 11:40:23.67	2026-03-12 12:30:06.835
299	45	34	19:15	f	4	0	2026-03-18 12:47:36.677	2	2026-02-11 11:40:23.677	2026-03-18 12:47:36.678
295	45	30	19:55	f	2	1	2026-03-18 12:47:55.006	2	2026-02-11 11:40:23.677	2026-03-18 12:47:55.007
298	45	33	22:05	f	1	6	2026-03-18 12:49:42.777	2	2026-02-11 11:40:23.677	2026-03-18 12:49:42.777
294	45	29	22:55	f	1	1	2026-03-18 12:50:09.376	2	2026-02-11 11:40:23.677	2026-03-18 12:50:09.377
293	45	28	23:45	f	3	1	2026-03-18 12:50:35.953	2	2026-02-11 11:40:23.677	2026-03-18 12:50:35.954
308	47	29	22:55	f	0	0	2026-03-25 16:46:43.794	2	2026-02-11 11:40:23.684	2026-03-25 16:46:43.795
304	46	32	21:15	f	0	3	2026-03-18 12:51:57.312	2	2026-02-11 11:40:23.68	2026-03-18 12:51:57.313
306	46	34	19:15	f	2	1	2026-03-18 12:52:22.715	2	2026-02-11 11:40:23.68	2026-03-18 12:52:22.716
303	46	31	20:35	f	1	0	2026-03-18 12:52:35.563	2	2026-02-11 11:40:23.68	2026-03-18 12:52:35.563
301	46	29	22:55	f	3	1	2026-03-18 12:53:27.003	2	2026-02-11 11:40:23.68	2026-03-18 12:53:27.004
305	46	33	22:05	f	3	3	2026-03-18 12:53:53.991	2	2026-02-11 11:40:23.68	2026-03-18 12:53:53.992
313	47	34	19:15	f	1	0	2026-03-18 13:28:05.301	2	2026-02-11 11:40:23.684	2026-03-18 13:28:05.302
309	47	30	19:55	f	3	1	2026-03-18 13:28:33.067	2	2026-02-11 11:40:23.684	2026-03-18 13:28:33.068
310	47	31	20:35	f	1	2	2026-03-18 13:28:58.607	2	2026-02-11 11:40:23.684	2026-03-18 13:28:58.608
311	47	32	21:15	f	5	2	2026-03-18 13:30:57.814	2	2026-02-11 11:40:23.684	2026-03-18 13:30:57.815
320	48	34	19:15	f	3	0	2026-03-25 10:40:34.323	2	2026-02-11 11:40:23.687	2026-03-25 10:40:34.324
316	48	30	19:55	f	3	0	2026-03-25 10:41:00.018	2	2026-02-11 11:40:23.687	2026-03-25 10:41:00.019
317	48	31	20:35	f	2	0	2026-03-25 10:41:14.574	2	2026-02-11 11:40:23.687	2026-03-25 10:41:14.575
318	48	32	21:15	f	1	0	2026-03-25 10:41:28.514	2	2026-02-11 11:40:23.687	2026-03-25 10:41:28.515
319	48	33	22:05	f	3	3	2026-03-25 10:42:22.938	2	2026-02-11 11:40:23.687	2026-03-25 10:42:22.939
314	48	28	23:45	f	2	4	2026-03-25 10:43:57.279	2	2026-02-11 11:40:23.687	2026-03-25 10:43:57.28
315	48	29	22:55	f	3	5	2026-03-25 10:45:43.687	2	2026-02-11 11:40:23.687	2026-03-25 10:45:43.688
326	49	33	22:05	f	3	3	2026-03-25 10:47:31.078	2	2026-02-11 11:40:23.691	2026-03-25 10:47:31.079
325	49	32	21:15	f	3	0	2026-03-25 10:48:25.748	2	2026-02-11 11:40:23.691	2026-03-25 10:48:25.749
323	49	30	19:55	f	4	2	2026-03-25 10:49:07.377	2	2026-02-11 11:40:23.691	2026-03-25 10:49:07.378
327	49	34	19:15	f	4	0	2026-03-25 10:49:59.969	2	2026-02-11 11:40:23.691	2026-03-25 10:49:59.97
324	49	31	20:35	f	1	1	2026-03-25 10:50:31.791	2	2026-02-11 11:40:23.691	2026-03-25 10:50:31.792
322	49	29	22:55	f	2	0	2026-03-25 10:50:37.345	2	2026-02-11 11:40:23.691	2026-03-25 10:50:37.346
300	46	28	23:45	f	2	2	2026-03-25 16:45:20.746	2	2026-02-11 11:40:23.68	2026-03-25 16:45:20.747
297	45	32	21:15	f	0	0	2026-03-25 16:47:50.432	2	2026-02-11 11:40:23.677	2026-03-25 16:47:50.433
341	51	34	19:15	f	2	5	2026-03-31 12:06:59.707	2	2026-02-11 11:40:23.698	2026-03-31 12:06:59.708
337	51	30	19:55	f	0	5	2026-03-31 12:09:13.815	2	2026-02-11 11:40:23.698	2026-03-31 12:09:13.816
338	51	31	20:35	f	6	0	2026-03-31 12:09:39.429	2	2026-02-11 11:40:23.698	2026-03-31 12:09:39.43
339	51	32	21:15	f	1	5	2026-03-31 12:10:37.773	2	2026-02-11 11:40:23.698	2026-03-31 12:10:37.774
340	51	33	22:05	f	1	10	2026-03-31 12:11:09.873	2	2026-02-11 11:40:23.698	2026-03-31 12:11:09.874
335	51	28	23:45	f	8	2	2026-03-31 12:12:22.833	2	2026-02-11 11:40:23.698	2026-03-31 12:12:22.834
346	52	32	21:15	f	1	2	2026-04-03 21:14:16.378	2	2026-02-11 11:40:23.702	2026-04-03 21:14:16.379
345	52	31	20:35	f	2	1	2026-04-03 21:15:21.652	2	2026-02-11 11:40:23.702	2026-04-03 21:15:21.653
347	52	33	22:05	f	1	3	2026-04-03 21:15:50.749	2	2026-02-11 11:40:23.702	2026-04-03 21:15:50.75
344	52	30	19:55	f	0	2	2026-04-03 21:16:27.761	2	2026-02-11 11:40:23.702	2026-04-03 21:16:27.762
348	52	34	19:15	f	0	2	2026-04-03 21:16:49.228	2	2026-02-11 11:40:23.702	2026-04-03 21:16:49.229
342	52	28	23:45	f	4	1	2026-04-03 21:17:47.404	2	2026-02-11 11:40:23.702	2026-04-03 21:17:47.405
361	54	33	22:05	f	2	0	2026-04-23 19:12:53.598	2	2026-02-11 11:40:23.708	2026-04-23 19:12:53.599
362	54	34	19:15	f	2	0	2026-04-23 19:13:34.932	2	2026-02-11 11:40:23.708	2026-04-23 19:13:34.933
378	57	29	22:55	f	3	1	2026-04-25 13:32:33.046	2	2026-02-11 11:40:23.717	2026-04-25 13:32:33.047
360	54	32	21:15	f	2	0	2026-04-23 19:13:21.039	2	2026-02-11 11:40:23.708	2026-04-23 19:13:21.04
356	54	28	23:45	f	2	0	2026-04-23 19:12:59.18	2	2026-02-11 11:40:23.708	2026-04-23 19:12:59.181
359	54	31	20:35	f	2	0	2026-04-23 19:13:24.978	2	2026-02-11 11:40:23.708	2026-04-23 19:13:24.979
357	54	29	22:55	f	2	0	2026-04-14 14:07:19.874	2	2026-02-11 11:40:23.708	2026-04-14 14:07:19.875
373	56	31	20:35	f	2	0	2026-04-16 23:05:27.422	2	2026-02-11 11:40:23.714	2026-04-16 23:05:27.423
374	56	32	21:15	f	1	1	2026-04-16 23:05:45.918	2	2026-02-11 11:40:23.714	2026-04-16 23:05:45.919
375	56	33	22:05	f	5	0	2026-04-16 23:06:19.078	2	2026-02-11 11:40:23.714	2026-04-16 23:06:19.079
371	56	29	22:55	f	8	4	2026-04-16 23:07:03.97	2	2026-02-11 11:40:23.714	2026-04-16 23:07:03.971
370	56	28	23:45	f	4	1	2026-04-16 23:07:24.363	2	2026-02-11 11:40:23.714	2026-04-16 23:07:24.364
372	56	30	19:55	f	2	0	2026-04-16 23:44:22.754	2	2026-02-11 11:40:23.714	2026-04-16 23:44:22.755
329	50	29	22:55	f	0	2	2026-04-23 19:11:22.302	2	2026-02-11 11:40:23.694	2026-04-23 19:11:22.303
333	50	33	22:05	f	0	2	2026-04-23 19:11:26.146	2	2026-02-11 11:40:23.694	2026-04-23 19:11:26.147
332	50	32	21:15	f	0	2	2026-04-23 19:11:29.56	2	2026-02-11 11:40:23.694	2026-04-23 19:11:29.561
331	50	31	20:35	f	0	2	2026-04-23 19:11:32.429	2	2026-02-11 11:40:23.694	2026-04-23 19:11:32.43
330	50	30	19:55	f	0	2	2026-04-23 19:11:35.448	2	2026-02-11 11:40:23.694	2026-04-23 19:11:35.449
334	50	34	19:15	f	0	2	2026-04-23 19:11:39.32	2	2026-02-11 11:40:23.694	2026-04-23 19:11:39.321
349	53	28	23:45	f	0	2	2026-04-23 19:11:50.256	2	2026-02-11 11:40:23.705	2026-04-23 19:11:50.257
354	53	33	22:05	f	0	2	2026-04-23 19:11:57.14	2	2026-02-11 11:40:23.705	2026-04-23 19:11:57.141
353	53	32	21:15	f	0	2	2026-04-23 19:12:00.042	2	2026-02-11 11:40:23.705	2026-04-23 19:12:00.043
352	53	31	20:35	f	0	2	2026-04-23 19:12:02.595	2	2026-02-11 11:40:23.705	2026-04-23 19:12:02.596
351	53	30	19:55	f	0	2	2026-04-23 19:12:05.332	2	2026-02-11 11:40:23.705	2026-04-23 19:12:05.333
355	53	34	19:15	f	0	2	2026-04-23 19:12:08.851	2	2026-02-11 11:40:23.705	2026-04-23 19:12:08.852
358	54	30	19:55	f	2	0	2026-04-23 19:13:30.619	2	2026-02-11 11:40:23.708	2026-04-23 19:13:30.62
381	57	32	21:15	f	2	2	2026-04-25 13:31:22.226	2	2026-02-11 11:40:23.717	2026-04-25 13:31:22.227
380	57	31	20:35	f	4	1	2026-04-25 13:33:09.927	2	2026-02-11 11:40:23.717	2026-04-25 13:33:09.928
377	57	28	23:45	f	2	1	2026-04-25 13:33:34.279	2	2026-02-11 11:40:23.717	2026-04-25 13:33:34.28
368	55	33	22:05	f	3	2	2026-04-28 12:14:09.037	2	2026-02-11 11:40:23.711	2026-04-28 12:14:09.038
367	55	32	21:15	f	3	1	2026-04-28 12:14:40.978	2	2026-02-11 11:40:23.711	2026-04-28 12:14:40.979
366	55	31	20:35	f	1	2	2026-04-28 12:15:11.142	2	2026-02-11 11:40:23.711	2026-04-28 12:15:11.142
365	55	30	19:55	f	2	0	2026-04-28 12:15:27.421	2	2026-02-11 11:40:23.711	2026-04-28 12:15:27.422
369	55	34	19:15	f	6	2	2026-04-28 12:17:51.308	2	2026-02-11 11:40:23.711	2026-04-28 12:17:51.309
364	55	29	22:55	f	2	0	2026-04-28 12:19:03.868	2	2026-02-11 11:40:23.711	2026-04-28 12:19:03.869
398	60	28	23:45	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
399	60	29	22:55	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
400	60	30	19:55	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
401	60	31	20:35	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
402	60	32	21:15	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
403	60	33	22:05	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
404	60	34	19:15	f	0	0	\N	\N	2026-02-11 11:40:23.725	2026-02-11 11:40:23.725
219	34	31	20:35	f	0	4	2026-02-14 14:16:19.926	2	2026-02-11 11:40:23.638	2026-02-14 14:16:19.927
217	34	29	22:55	f	3	1	2026-02-14 14:18:08.075	2	2026-02-11 11:40:23.638	2026-02-14 14:18:08.076
213	33	32	21:15	f	2	3	2026-02-14 16:46:20.914	2	2026-02-11 11:40:23.629	2026-02-14 16:46:20.915
224	35	29	22:55	f	2	6	2026-02-14 19:24:28.363	2	2026-02-11 11:40:23.642	2026-02-14 19:24:28.364
108	21	26	20:40	f	2	1	2026-02-18 10:39:09.461	2	2026-02-02 14:57:25.929	2026-02-18 10:39:09.462
114	22	23	22:00	f	5	3	2026-02-18 10:42:03.663	2	2026-02-02 14:57:25.937	2026-02-18 10:42:03.664
121	23	21	18:00	f	1	4	2026-02-18 11:16:23.004	2	2026-02-02 14:57:25.941	2026-02-18 11:16:23.005
134	24	25	20:00	f	2	0	2026-02-20 10:26:09.905	2	2026-02-02 14:57:25.944	2026-02-20 10:26:09.906
233	36	31	20:35	f	1	5	2026-02-21 13:42:08.831	2	2026-02-11 11:40:23.646	2026-02-21 13:42:08.832
245	38	29	22:55	f	1	3	2026-02-21 17:11:08.693	2	2026-02-11 11:40:23.653	2026-02-21 17:11:08.694
138	25	20	22:40	f	6	4	2026-02-25 16:23:50.327	2	2026-02-02 14:57:25.948	2026-02-25 16:23:50.328
151	26	24	21:20	f	3	1	2026-02-25 16:25:36.389	2	2026-02-02 14:57:25.951	2026-02-25 16:25:36.39
143	25	25	20:00	f	3	4	2026-02-25 17:34:19.062	2	2026-02-02 14:57:25.948	2026-02-25 17:34:19.063
237	37	28	23:45	f	1	1	2026-02-26 11:46:48.665	2	2026-02-11 11:40:23.649	2026-02-26 11:46:48.666
251	39	28	23:45	f	5	2	2026-02-28 21:56:55.395	2	2026-02-11 11:40:23.656	2026-02-28 21:56:55.396
265	41	28	23:45	f	0	7	2026-02-28 22:19:48.497	2	2026-02-11 11:40:23.663	2026-02-28 22:19:48.498
286	44	28	23:45	f	6	2	2026-03-10 10:39:05.644	2	2026-02-11 11:40:23.674	2026-03-10 10:39:05.645
292	44	34	19:15	f	4	2	2026-03-10 10:40:35.67	2	2026-02-11 11:40:23.674	2026-03-10 10:40:35.671
156	27	20	22:40	f	3	1	2026-03-10 10:47:50.778	2	2026-02-02 14:57:25.955	2026-03-10 10:47:50.779
187	30	24	21:20	f	2	6	2026-03-10 10:49:53.018	2	2026-02-02 14:57:25.964	2026-03-10 10:49:53.019
189	30	26	20:40	f	1	2	2026-03-10 10:50:15.93	2	2026-02-02 14:57:25.964	2026-03-10 10:50:15.931
180	29	26	20:40	f	1	1	2026-03-12 12:25:06.894	2	2026-02-02 14:57:25.961	2026-03-12 12:25:06.895
170	28	25	20:00	f	1	0	2026-03-12 12:37:48.269	2	2026-02-02 14:57:25.958	2026-03-12 12:37:48.27
190	30	27	19:20	f	0	0	2026-03-12 18:10:03.454	2	2026-02-02 14:57:25.964	2026-03-12 18:10:03.455
296	45	31	20:35	f	7	0	2026-03-18 12:48:47.883	2	2026-02-11 11:40:23.677	2026-03-18 12:48:47.884
302	46	30	19:55	f	1	2	2026-03-18 12:52:55.813	2	2026-02-11 11:40:23.68	2026-03-18 12:52:55.814
312	47	33	22:05	f	2	0	2026-03-18 13:31:27.914	2	2026-02-11 11:40:23.684	2026-03-18 13:31:27.915
321	49	28	23:45	f	1	5	2026-03-25 16:45:00.645	2	2026-02-11 11:40:23.691	2026-03-25 16:45:00.646
307	47	28	23:45	f	0	0	2026-03-25 16:46:39.708	2	2026-02-11 11:40:23.684	2026-03-25 16:46:39.709
336	51	29	22:55	f	0	2	2026-03-31 12:11:19.752	2	2026-02-11 11:40:23.698	2026-03-31 12:11:19.753
343	52	29	22:55	f	2	0	2026-04-03 21:18:14.561	2	2026-02-11 11:40:23.702	2026-04-03 21:18:14.561
376	56	34	19:15	f	5	0	2026-04-16 23:04:43.941	2	2026-02-11 11:40:23.714	2026-04-16 23:04:43.942
328	50	28	23:45	f	0	2	2026-04-23 19:11:19.025	2	2026-02-11 11:40:23.694	2026-04-23 19:11:19.026
350	53	29	22:55	f	0	2	2026-04-23 19:11:54.007	2	2026-02-11 11:40:23.705	2026-04-23 19:11:54.008
384	58	28	23:45	f	0	2	2026-04-23 19:13:53.236	2	2026-02-11 11:40:23.72	2026-04-23 19:13:53.236
385	58	29	22:55	f	0	2	2026-04-23 19:13:56.756	2	2026-02-11 11:40:23.72	2026-04-23 19:13:56.757
389	58	33	22:05	f	0	2	2026-04-23 19:14:00.157	2	2026-02-11 11:40:23.72	2026-04-23 19:14:00.158
388	58	32	21:15	f	0	2	2026-04-23 19:14:02.762	2	2026-02-11 11:40:23.72	2026-04-23 19:14:02.763
387	58	31	20:35	f	0	2	2026-04-23 19:14:05.78	2	2026-02-11 11:40:23.72	2026-04-23 19:14:05.781
386	58	30	19:55	f	0	2	2026-04-23 19:14:08.984	2	2026-02-11 11:40:23.72	2026-04-23 19:14:08.985
390	58	34	19:15	f	0	2	2026-04-23 19:14:12.471	2	2026-02-11 11:40:23.72	2026-04-23 19:14:12.472
412	62	28	23:45	f	2	0	2026-04-23 19:14:33.095	2	2026-02-11 11:40:23.731	2026-04-23 19:14:33.096
413	62	29	22:55	f	2	0	2026-04-23 19:14:35.994	2	2026-02-11 11:40:23.731	2026-04-23 19:14:35.995
417	62	33	22:05	f	2	0	2026-04-23 19:14:39.28	2	2026-02-11 11:40:23.731	2026-04-23 19:14:39.281
416	62	32	21:15	f	2	0	2026-04-23 19:14:42.584	2	2026-02-11 11:40:23.731	2026-04-23 19:14:42.585
415	62	31	20:35	f	2	0	2026-04-23 19:14:45.607	2	2026-02-11 11:40:23.731	2026-04-23 19:14:45.608
414	62	30	19:55	f	2	0	2026-04-23 19:14:48.521	2	2026-02-11 11:40:23.731	2026-04-23 19:14:48.522
418	62	34	19:15	f	2	0	2026-04-23 19:14:52.16	2	2026-02-11 11:40:23.731	2026-04-23 19:14:52.161
383	57	34	19:15	f	1	0	2026-04-25 12:16:28.798	2	2026-02-11 11:40:23.717	2026-04-25 12:16:28.799
379	57	30	19:55	f	5	2	2026-04-25 13:31:58.69	2	2026-02-11 11:40:23.717	2026-04-25 13:31:58.691
382	57	33	22:05	f	0	2	2026-04-25 13:33:51.608	2	2026-02-11 11:40:23.717	2026-04-25 13:33:51.609
391	59	28	23:45	f	2	5	2026-04-25 13:38:11.312	2	2026-02-11 11:40:23.722	2026-04-25 13:38:11.313
392	59	29	22:55	f	2	0	2026-04-25 13:38:29.521	2	2026-02-11 11:40:23.722	2026-04-25 13:38:29.521
393	59	30	19:55	f	3	0	2026-04-25 13:39:04.247	2	2026-02-11 11:40:23.722	2026-04-25 13:39:04.248
397	59	34	19:15	f	1	2	2026-04-25 13:39:29.714	2	2026-02-11 11:40:23.722	2026-04-25 13:39:29.715
395	59	32	21:15	f	1	0	2026-04-25 13:39:43.424	2	2026-02-11 11:40:23.722	2026-04-25 13:39:43.425
394	59	31	20:35	f	0	1	2026-04-25 13:39:58.666	2	2026-02-11 11:40:23.722	2026-04-25 13:39:58.667
396	59	33	22:05	f	3	1	2026-04-25 13:40:33.923	2	2026-02-11 11:40:23.722	2026-04-25 13:40:33.923
363	55	28	23:45	f	3	5	2026-04-28 12:16:10.653	2	2026-02-11 11:40:23.711	2026-04-28 12:16:10.653
409	61	32	21:15	f	3	0	2026-05-04 22:56:44.001	2	2026-02-11 11:40:23.729	2026-05-04 22:56:44.002
407	61	30	19:55	f	1	0	2026-05-04 22:56:10.86	2	2026-02-11 11:40:23.729	2026-05-04 22:56:10.862
411	61	34	19:15	f	3	1	2026-05-04 22:56:15.507	2	2026-02-11 11:40:23.729	2026-05-04 22:56:15.507
408	61	31	20:35	f	1	2	2026-05-04 22:56:35.461	2	2026-02-11 11:40:23.729	2026-05-04 22:56:35.462
410	61	33	22:05	f	3	1	2026-05-04 22:56:58.502	2	2026-02-11 11:40:23.729	2026-05-04 22:56:58.504
406	61	29	22:55	f	1	6	2026-05-04 22:57:09.254	2	2026-02-11 11:40:23.729	2026-05-04 22:57:09.255
405	61	28	23:45	f	1	0	2026-05-04 22:57:15.812	2	2026-02-11 11:40:23.729	2026-05-04 22:57:15.814
\.


--
-- Data for Name: MatchLog; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MatchLog" (id, "matchId", "userId", action, "createdAt") FROM stdin;
1	1	2	RESULT_UPDATED	2026-01-16 11:28:51.657
2	1	2	RESULT_UPDATED	2026-01-20 11:23:02.16
3	1	2	RESULT_UPDATED	2026-01-20 11:23:07.294
4	1	2	RESULT_UPDATED	2026-01-20 11:23:15.16
5	1	2	RESULT_UPDATED	2026-01-20 11:23:19.881
6	1	2	RESULT_UPDATED	2026-01-20 11:23:29.209
7	1	2	RESULT_UPDATED	2026-01-20 11:23:43.408
8	1	2	RESULT_UPDATED	2026-01-20 11:23:49.936
9	2	2	RESULT_UPDATED	2026-01-20 11:24:21.092
10	2	2	RESULT_UPDATED	2026-01-20 11:24:24.222
11	2	2	RESULT_UPDATED	2026-01-20 11:24:28.732
12	2	2	RESULT_UPDATED	2026-01-20 11:24:34.18
13	2	2	RESULT_UPDATED	2026-01-20 11:24:43.14
14	3	2	RESULT_UPDATED	2026-01-20 11:25:23.046
15	3	2	RESULT_UPDATED	2026-01-20 11:25:27.501
16	3	2	RESULT_UPDATED	2026-01-20 11:25:31.306
17	3	2	RESULT_UPDATED	2026-01-20 11:25:36.152
18	4	2	RESULT_UPDATED	2026-01-20 11:25:50.137
19	4	2	RESULT_UPDATED	2026-01-20 11:25:54.256
20	4	2	RESULT_UPDATED	2026-01-20 11:25:59.687
21	4	2	RESULT_UPDATED	2026-01-20 11:26:03.822
22	4	2	RESULT_UPDATED	2026-01-20 11:26:08.696
23	3	2	RESULT_UPDATED	2026-01-20 11:26:59.265
24	5	2	RESULT_UPDATED	2026-01-20 11:27:21.759
25	5	2	RESULT_UPDATED	2026-01-20 11:27:26.641
26	5	2	RESULT_UPDATED	2026-01-20 11:27:32.975
27	5	2	RESULT_UPDATED	2026-01-20 11:27:38.384
28	5	2	RESULT_UPDATED	2026-01-20 11:27:41.208
29	5	2	RESULT_UPDATED	2026-01-20 11:27:45.776
30	6	2	RESULT_UPDATED	2026-01-20 11:27:55.098
31	6	2	RESULT_UPDATED	2026-01-20 11:28:00.139
32	6	2	RESULT_UPDATED	2026-01-20 11:28:03.753
33	6	2	RESULT_UPDATED	2026-01-20 11:28:07.972
34	6	2	RESULT_UPDATED	2026-01-20 11:28:11.296
35	6	2	RESULT_UPDATED	2026-01-20 11:28:16.01
36	34	2	RESULT_UPDATED	2026-02-14 14:16:19.932
37	34	2	RESULT_UPDATED	2026-02-14 14:17:38.939
38	34	2	RESULT_UPDATED	2026-02-14 14:18:08.079
39	34	2	RESULT_UPDATED	2026-02-14 14:18:35.29
40	34	2	RESULT_UPDATED	2026-02-14 14:19:37.348
41	34	2	RESULT_UPDATED	2026-02-14 14:20:28.036
42	34	2	RESULT_UPDATED	2026-02-14 14:27:59.368
43	33	2	RESULT_UPDATED	2026-02-14 16:43:52.437
44	33	2	RESULT_UPDATED	2026-02-14 16:45:15.163
45	33	2	RESULT_UPDATED	2026-02-14 16:45:46.542
46	33	2	RESULT_UPDATED	2026-02-14 16:46:20.918
47	33	2	RESULT_UPDATED	2026-02-14 16:47:03.941
48	33	2	RESULT_UPDATED	2026-02-14 16:47:29.614
49	34	2	RESULT_UPDATED	2026-02-14 16:49:16.079
50	35	2	RESULT_UPDATED	2026-02-14 19:21:38.996
51	35	2	RESULT_UPDATED	2026-02-14 19:22:00.194
52	35	2	RESULT_UPDATED	2026-02-14 19:22:27.767
53	35	2	RESULT_UPDATED	2026-02-14 19:22:55.164
54	35	2	RESULT_UPDATED	2026-02-14 19:23:52.585
55	35	2	RESULT_UPDATED	2026-02-14 19:24:28.366
56	35	2	RESULT_UPDATED	2026-02-14 19:24:57.35
57	33	2	RESULT_UPDATED	2026-02-14 19:32:12.983
58	21	2	RESULT_UPDATED	2026-02-18 10:34:30.035
59	21	2	RESULT_UPDATED	2026-02-18 10:35:20.993
60	21	2	RESULT_UPDATED	2026-02-18 10:36:33.884
61	21	2	RESULT_UPDATED	2026-02-18 10:37:42.851
62	21	2	RESULT_UPDATED	2026-02-18 10:38:41.472
63	21	2	RESULT_UPDATED	2026-02-18 10:39:09.465
64	21	2	RESULT_UPDATED	2026-02-18 10:39:49.019
65	21	2	RESULT_UPDATED	2026-02-18 10:40:23.237
66	21	2	RESULT_UPDATED	2026-02-18 10:40:36.484
67	22	2	RESULT_UPDATED	2026-02-18 10:41:34.52
68	22	2	RESULT_UPDATED	2026-02-18 10:41:39.296
69	22	2	RESULT_UPDATED	2026-02-18 10:41:47.433
70	22	2	RESULT_UPDATED	2026-02-18 10:41:56.595
71	22	2	RESULT_UPDATED	2026-02-18 10:42:03.667
72	22	2	RESULT_UPDATED	2026-02-18 10:42:11.152
73	22	2	RESULT_UPDATED	2026-02-18 10:42:18.192
74	22	2	RESULT_UPDATED	2026-02-18 10:42:47.154
75	22	2	RESULT_UPDATED	2026-02-18 10:42:55.496
76	23	2	RESULT_UPDATED	2026-02-18 11:15:41.217
77	23	2	RESULT_UPDATED	2026-02-18 11:16:09.83
78	23	2	RESULT_UPDATED	2026-02-18 11:16:23.008
79	23	2	RESULT_UPDATED	2026-02-18 11:16:38.062
80	23	2	RESULT_UPDATED	2026-02-18 11:16:50.429
81	23	2	RESULT_UPDATED	2026-02-18 11:17:01.567
82	23	2	RESULT_UPDATED	2026-02-18 11:17:22.628
83	23	2	RESULT_UPDATED	2026-02-18 11:17:37.565
84	24	2	RESULT_UPDATED	2026-02-20 10:25:42.494
85	24	2	RESULT_UPDATED	2026-02-20 10:25:57.717
86	24	2	RESULT_UPDATED	2026-02-20 10:26:09.908
87	24	2	RESULT_UPDATED	2026-02-20 10:26:25.432
88	24	2	RESULT_UPDATED	2026-02-20 10:26:40.14
89	24	2	RESULT_UPDATED	2026-02-20 10:26:50.263
90	24	2	RESULT_UPDATED	2026-02-20 10:26:57.506
91	24	2	RESULT_UPDATED	2026-02-20 10:27:06.907
92	24	2	RESULT_UPDATED	2026-02-20 10:27:18.927
93	23	2	RESULT_UPDATED	2026-02-20 10:27:41.902
94	36	2	RESULT_UPDATED	2026-02-21 13:39:34.397
95	36	2	RESULT_UPDATED	2026-02-21 13:40:37.71
96	36	2	RESULT_UPDATED	2026-02-21 13:41:05.061
97	36	2	RESULT_UPDATED	2026-02-21 13:41:27.351
98	36	2	RESULT_UPDATED	2026-02-21 13:42:08.835
99	36	2	RESULT_UPDATED	2026-02-21 13:42:57.471
100	36	2	RESULT_UPDATED	2026-02-21 13:43:34.466
101	38	2	RESULT_UPDATED	2026-02-21 17:08:35.844
102	38	2	RESULT_UPDATED	2026-02-21 17:08:58.538
103	38	2	RESULT_UPDATED	2026-02-21 17:09:26.519
104	38	2	RESULT_UPDATED	2026-02-21 17:09:57.648
105	38	2	RESULT_UPDATED	2026-02-21 17:10:33.758
106	38	2	RESULT_UPDATED	2026-02-21 17:11:08.696
107	38	2	RESULT_UPDATED	2026-02-21 17:11:38.65
108	25	2	RESULT_UPDATED	2026-02-25 16:23:50.332
109	25	2	RESULT_UPDATED	2026-02-25 16:24:00.682
110	25	2	RESULT_UPDATED	2026-02-25 16:24:09.752
111	26	2	RESULT_UPDATED	2026-02-25 16:24:49.618
112	26	2	RESULT_UPDATED	2026-02-25 16:25:02.348
113	26	2	RESULT_UPDATED	2026-02-25 16:25:13.179
114	26	2	RESULT_UPDATED	2026-02-25 16:25:23.193
115	26	2	RESULT_UPDATED	2026-02-25 16:25:36.394
116	26	2	RESULT_UPDATED	2026-02-25 16:25:45.264
117	26	2	RESULT_UPDATED	2026-02-25 16:25:55.275
118	26	2	RESULT_UPDATED	2026-02-25 16:26:03.706
119	25	2	RESULT_UPDATED	2026-02-25 16:48:54.556
120	25	2	RESULT_UPDATED	2026-02-25 16:49:02.04
121	25	2	RESULT_UPDATED	2026-02-25 17:12:23.307
122	25	2	RESULT_UPDATED	2026-02-25 17:13:48.328
123	25	2	RESULT_UPDATED	2026-02-25 17:34:19.066
124	25	2	RESULT_UPDATED	2026-02-25 17:43:22.6
125	37	2	RESULT_UPDATED	2026-02-26 11:42:47.889
126	37	2	RESULT_UPDATED	2026-02-26 11:43:28.108
127	37	2	RESULT_UPDATED	2026-02-26 11:44:10.231
128	37	2	RESULT_UPDATED	2026-02-26 11:45:00.069
129	37	2	RESULT_UPDATED	2026-02-26 11:45:40.645
130	37	2	RESULT_UPDATED	2026-02-26 11:46:30.131
131	37	2	RESULT_UPDATED	2026-02-26 11:46:48.67
132	25	2	RESULT_UPDATED	2026-02-27 10:16:29.457
133	39	2	RESULT_UPDATED	2026-02-28 21:52:45.659
134	39	2	RESULT_UPDATED	2026-02-28 21:53:04.876
135	39	2	RESULT_UPDATED	2026-02-28 21:53:34.637
136	39	2	RESULT_UPDATED	2026-02-28 21:54:20.86
137	39	2	RESULT_UPDATED	2026-02-28 21:55:19.199
138	39	2	RESULT_UPDATED	2026-02-28 21:55:54.32
139	39	2	RESULT_UPDATED	2026-02-28 21:56:55.401
140	40	2	RESULT_UPDATED	2026-02-28 22:02:15.002
141	40	2	RESULT_UPDATED	2026-02-28 22:02:32.851
142	40	2	RESULT_UPDATED	2026-02-28 22:03:00.247
143	40	2	RESULT_UPDATED	2026-02-28 22:03:44.537
144	40	2	RESULT_UPDATED	2026-02-28 22:04:23.819
145	40	2	RESULT_UPDATED	2026-02-28 22:05:17.199
146	40	2	RESULT_UPDATED	2026-02-28 22:06:02.353
147	41	2	RESULT_UPDATED	2026-02-28 22:19:48.501
148	41	2	RESULT_UPDATED	2026-02-28 22:20:48.785
149	41	2	RESULT_UPDATED	2026-02-28 22:21:42.952
150	41	2	RESULT_UPDATED	2026-02-28 22:22:12.964
151	41	2	RESULT_UPDATED	2026-02-28 22:23:40.802
152	41	2	RESULT_UPDATED	2026-02-28 22:24:39.169
153	41	2	RESULT_UPDATED	2026-02-28 22:25:10.743
154	44	2	RESULT_UPDATED	2026-03-10 10:39:05.648
155	44	2	RESULT_UPDATED	2026-03-10 10:39:50.236
156	44	2	RESULT_UPDATED	2026-03-10 10:40:35.674
157	44	2	RESULT_UPDATED	2026-03-10 10:41:17.93
158	44	2	RESULT_UPDATED	2026-03-10 10:44:51.666
159	44	2	RESULT_UPDATED	2026-03-10 10:45:34.031
160	44	2	RESULT_UPDATED	2026-03-10 10:45:53.435
161	27	2	RESULT_UPDATED	2026-03-10 10:46:43.327
162	27	2	RESULT_UPDATED	2026-03-10 10:46:50.822
163	27	2	RESULT_UPDATED	2026-03-10 10:47:01.134
164	27	2	RESULT_UPDATED	2026-03-10 10:47:10.073
165	27	2	RESULT_UPDATED	2026-03-10 10:47:30.85
166	27	2	RESULT_UPDATED	2026-03-10 10:47:41.598
167	27	2	RESULT_UPDATED	2026-03-10 10:47:50.781
168	27	2	RESULT_UPDATED	2026-03-10 10:48:04.384
169	30	2	RESULT_UPDATED	2026-03-10 10:48:36.624
170	30	2	RESULT_UPDATED	2026-03-10 10:48:42.596
171	30	2	RESULT_UPDATED	2026-03-10 10:49:07.003
172	30	2	RESULT_UPDATED	2026-03-10 10:49:15.782
173	30	2	RESULT_UPDATED	2026-03-10 10:49:30.262
174	30	2	RESULT_UPDATED	2026-03-10 10:49:41.935
175	30	2	RESULT_UPDATED	2026-03-10 10:49:53.021
176	30	2	RESULT_UPDATED	2026-03-10 10:50:04.953
177	30	2	RESULT_UPDATED	2026-03-10 10:50:15.933
178	29	2	RESULT_UPDATED	2026-03-12 12:24:20.577
179	29	2	RESULT_UPDATED	2026-03-12 12:24:31.376
180	29	2	RESULT_UPDATED	2026-03-12 12:24:36.811
181	29	2	RESULT_UPDATED	2026-03-12 12:24:41.168
182	29	2	RESULT_UPDATED	2026-03-12 12:24:48.398
183	29	2	RESULT_UPDATED	2026-03-12 12:24:52.546
184	29	2	RESULT_UPDATED	2026-03-12 12:25:01.278
185	29	2	RESULT_UPDATED	2026-03-12 12:25:06.897
186	29	2	RESULT_UPDATED	2026-03-12 12:25:12.576
187	43	2	RESULT_UPDATED	2026-03-12 12:30:06.838
188	43	2	RESULT_UPDATED	2026-03-12 12:30:50.436
189	43	2	RESULT_UPDATED	2026-03-12 12:31:09.667
190	43	2	RESULT_UPDATED	2026-03-12 12:32:01.927
191	43	2	RESULT_UPDATED	2026-03-12 12:32:57.431
192	43	2	RESULT_UPDATED	2026-03-12 12:33:38.337
193	43	2	RESULT_UPDATED	2026-03-12 12:33:54.219
194	28	2	RESULT_UPDATED	2026-03-12 12:37:22.555
195	28	2	RESULT_UPDATED	2026-03-12 12:37:26.142
196	28	2	RESULT_UPDATED	2026-03-12 12:37:29.449
197	28	2	RESULT_UPDATED	2026-03-12 12:37:32.42
198	28	2	RESULT_UPDATED	2026-03-12 12:37:36.434
199	28	2	RESULT_UPDATED	2026-03-12 12:37:40.216
200	28	2	RESULT_UPDATED	2026-03-12 12:37:43.919
201	28	2	RESULT_UPDATED	2026-03-12 12:37:48.273
202	28	2	RESULT_UPDATED	2026-03-12 12:37:51.524
203	28	2	RESULT_UPDATED	2026-03-12 12:37:54.487
204	23	2	RESULT_UPDATED	2026-03-12 18:09:26.156
205	26	2	RESULT_UPDATED	2026-03-12 18:09:41.459
206	27	2	RESULT_UPDATED	2026-03-12 18:09:49.928
207	30	2	RESULT_UPDATED	2026-03-12 18:10:03.459
208	45	2	RESULT_UPDATED	2026-03-18 12:47:36.681
209	45	2	RESULT_UPDATED	2026-03-18 12:47:55.009
210	45	2	RESULT_UPDATED	2026-03-18 12:48:47.886
211	45	2	RESULT_UPDATED	2026-03-18 12:49:42.78
212	45	2	RESULT_UPDATED	2026-03-18 12:50:09.379
213	45	2	RESULT_UPDATED	2026-03-18 12:50:35.956
214	46	2	RESULT_UPDATED	2026-03-18 12:51:39.07
215	46	2	RESULT_UPDATED	2026-03-18 12:51:57.316
216	46	2	RESULT_UPDATED	2026-03-18 12:52:22.719
217	46	2	RESULT_UPDATED	2026-03-18 12:52:35.566
218	46	2	RESULT_UPDATED	2026-03-18 12:52:55.817
219	46	2	RESULT_UPDATED	2026-03-18 12:53:27.006
220	46	2	RESULT_UPDATED	2026-03-18 12:53:53.996
221	47	2	RESULT_UPDATED	2026-03-18 13:28:05.305
222	47	2	RESULT_UPDATED	2026-03-18 13:28:33.07
223	47	2	RESULT_UPDATED	2026-03-18 13:28:58.611
224	47	2	RESULT_UPDATED	2026-03-18 13:30:57.819
225	47	2	RESULT_UPDATED	2026-03-18 13:31:27.917
226	48	2	RESULT_UPDATED	2026-03-25 10:40:34.327
227	48	2	RESULT_UPDATED	2026-03-25 10:41:00.021
228	48	2	RESULT_UPDATED	2026-03-25 10:41:14.577
229	48	2	RESULT_UPDATED	2026-03-25 10:41:28.517
230	48	2	RESULT_UPDATED	2026-03-25 10:42:22.942
231	48	2	RESULT_UPDATED	2026-03-25 10:43:57.282
232	48	2	RESULT_UPDATED	2026-03-25 10:45:43.692
233	49	2	RESULT_UPDATED	2026-03-25 10:46:37.759
234	49	2	RESULT_UPDATED	2026-03-25 10:47:31.081
235	49	2	RESULT_UPDATED	2026-03-25 10:48:25.751
236	49	2	RESULT_UPDATED	2026-03-25 10:49:07.38
237	49	2	RESULT_UPDATED	2026-03-25 10:49:59.974
238	49	2	RESULT_UPDATED	2026-03-25 10:50:31.795
239	49	2	RESULT_UPDATED	2026-03-25 10:50:37.349
240	49	2	RESULT_UPDATED	2026-03-25 16:45:00.656
241	46	2	RESULT_UPDATED	2026-03-25 16:45:20.755
242	47	2	RESULT_UPDATED	2026-03-25 16:46:39.712
243	47	2	RESULT_UPDATED	2026-03-25 16:46:43.799
244	45	2	RESULT_UPDATED	2026-03-25 16:47:50.438
245	51	2	RESULT_UPDATED	2026-03-31 12:06:59.714
246	51	2	RESULT_UPDATED	2026-03-31 12:09:13.821
247	51	2	RESULT_UPDATED	2026-03-31 12:09:39.434
248	51	2	RESULT_UPDATED	2026-03-31 12:10:37.778
249	51	2	RESULT_UPDATED	2026-03-31 12:11:09.877
250	51	2	RESULT_UPDATED	2026-03-31 12:11:19.756
251	51	2	RESULT_UPDATED	2026-03-31 12:12:22.839
252	42	2	RESULT_UPDATED	2026-04-03 19:53:33.661
253	42	2	RESULT_UPDATED	2026-04-03 19:54:05.221
254	42	2	RESULT_UPDATED	2026-04-03 19:54:39.225
255	42	2	RESULT_UPDATED	2026-04-03 19:55:03.824
256	42	2	RESULT_UPDATED	2026-04-03 19:55:37.385
257	42	2	RESULT_UPDATED	2026-04-03 19:56:12.201
258	42	2	RESULT_UPDATED	2026-04-03 19:56:34.844
259	52	2	RESULT_UPDATED	2026-04-03 21:14:16.384
260	52	2	RESULT_UPDATED	2026-04-03 21:15:21.658
261	52	2	RESULT_UPDATED	2026-04-03 21:15:50.753
262	52	2	RESULT_UPDATED	2026-04-03 21:16:27.765
263	52	2	RESULT_UPDATED	2026-04-03 21:16:49.232
264	52	2	RESULT_UPDATED	2026-04-03 21:17:47.408
265	52	2	RESULT_UPDATED	2026-04-03 21:18:14.566
266	54	2	RESULT_UPDATED	2026-04-14 14:03:06.93
267	54	2	RESULT_UPDATED	2026-04-14 14:03:25.048
268	54	2	RESULT_UPDATED	2026-04-14 14:04:00.159
269	54	2	RESULT_UPDATED	2026-04-14 14:04:43.499
270	54	2	RESULT_UPDATED	2026-04-14 14:05:20.552
271	54	2	RESULT_UPDATED	2026-04-14 14:05:45.483
272	54	2	RESULT_UPDATED	2026-04-14 14:07:19.88
273	56	2	RESULT_UPDATED	2026-04-16 23:04:43.947
274	56	2	RESULT_UPDATED	2026-04-16 23:05:27.427
275	56	2	RESULT_UPDATED	2026-04-16 23:05:45.923
276	56	2	RESULT_UPDATED	2026-04-16 23:06:19.083
277	56	2	RESULT_UPDATED	2026-04-16 23:07:03.975
278	56	2	RESULT_UPDATED	2026-04-16 23:07:24.368
279	56	2	RESULT_UPDATED	2026-04-16 23:44:22.762
280	50	2	RESULT_UPDATED	2026-04-23 19:11:19.031
281	50	2	RESULT_UPDATED	2026-04-23 19:11:22.309
282	50	2	RESULT_UPDATED	2026-04-23 19:11:26.15
283	50	2	RESULT_UPDATED	2026-04-23 19:11:29.564
284	50	2	RESULT_UPDATED	2026-04-23 19:11:32.433
285	50	2	RESULT_UPDATED	2026-04-23 19:11:35.455
286	50	2	RESULT_UPDATED	2026-04-23 19:11:39.326
287	53	2	RESULT_UPDATED	2026-04-23 19:11:50.26
288	53	2	RESULT_UPDATED	2026-04-23 19:11:54.012
289	53	2	RESULT_UPDATED	2026-04-23 19:11:57.144
290	53	2	RESULT_UPDATED	2026-04-23 19:12:00.046
291	53	2	RESULT_UPDATED	2026-04-23 19:12:02.599
292	53	2	RESULT_UPDATED	2026-04-23 19:12:05.336
293	53	2	RESULT_UPDATED	2026-04-23 19:12:08.857
294	54	2	RESULT_UPDATED	2026-04-23 19:12:33.667
295	54	2	RESULT_UPDATED	2026-04-23 19:12:40.222
296	54	2	RESULT_UPDATED	2026-04-23 19:12:53.603
297	54	2	RESULT_UPDATED	2026-04-23 19:12:59.184
298	54	2	RESULT_UPDATED	2026-04-23 19:13:15.993
299	54	2	RESULT_UPDATED	2026-04-23 19:13:21.045
300	54	2	RESULT_UPDATED	2026-04-23 19:13:24.983
301	54	2	RESULT_UPDATED	2026-04-23 19:13:30.624
302	54	2	RESULT_UPDATED	2026-04-23 19:13:34.937
303	58	2	RESULT_UPDATED	2026-04-23 19:13:53.24
304	58	2	RESULT_UPDATED	2026-04-23 19:13:56.76
305	58	2	RESULT_UPDATED	2026-04-23 19:14:00.161
306	58	2	RESULT_UPDATED	2026-04-23 19:14:02.766
307	58	2	RESULT_UPDATED	2026-04-23 19:14:05.783
308	58	2	RESULT_UPDATED	2026-04-23 19:14:08.988
309	58	2	RESULT_UPDATED	2026-04-23 19:14:12.476
310	62	2	RESULT_UPDATED	2026-04-23 19:14:33.101
311	62	2	RESULT_UPDATED	2026-04-23 19:14:35.998
312	62	2	RESULT_UPDATED	2026-04-23 19:14:39.284
313	62	2	RESULT_UPDATED	2026-04-23 19:14:42.587
314	62	2	RESULT_UPDATED	2026-04-23 19:14:45.611
315	62	2	RESULT_UPDATED	2026-04-23 19:14:48.525
316	62	2	RESULT_UPDATED	2026-04-23 19:14:52.165
317	57	2	RESULT_UPDATED	2026-04-25 12:16:28.805
318	57	2	RESULT_UPDATED	2026-04-25 12:17:48.57
319	57	2	RESULT_UPDATED	2026-04-25 13:31:22.232
320	57	2	RESULT_UPDATED	2026-04-25 13:31:58.696
321	57	2	RESULT_UPDATED	2026-04-25 13:32:33.051
322	57	2	RESULT_UPDATED	2026-04-25 13:33:09.932
323	57	2	RESULT_UPDATED	2026-04-25 13:33:34.285
324	57	2	RESULT_UPDATED	2026-04-25 13:33:51.615
325	59	2	RESULT_UPDATED	2026-04-25 13:38:11.317
326	59	2	RESULT_UPDATED	2026-04-25 13:38:29.527
327	59	2	RESULT_UPDATED	2026-04-25 13:39:04.251
328	59	2	RESULT_UPDATED	2026-04-25 13:39:29.719
329	59	2	RESULT_UPDATED	2026-04-25 13:39:43.428
330	59	2	RESULT_UPDATED	2026-04-25 13:39:58.672
331	59	2	RESULT_UPDATED	2026-04-25 13:40:33.928
332	55	2	RESULT_UPDATED	2026-04-28 12:14:09.043
333	55	2	RESULT_UPDATED	2026-04-28 12:14:40.982
334	55	2	RESULT_UPDATED	2026-04-28 12:15:11.145
335	55	2	RESULT_UPDATED	2026-04-28 12:15:27.425
336	55	2	RESULT_UPDATED	2026-04-28 12:16:10.657
337	55	2	RESULT_UPDATED	2026-04-28 12:17:51.314
338	55	2	RESULT_UPDATED	2026-04-28 12:19:03.873
339	61	2	RESULT_UPDATED	2026-05-04 22:56:02.89
340	61	2	RESULT_UPDATED	2026-05-04 22:56:10.867
341	61	2	RESULT_UPDATED	2026-05-04 22:56:15.512
342	61	2	RESULT_UPDATED	2026-05-04 22:56:35.465
343	61	2	RESULT_UPDATED	2026-05-04 22:56:44.005
344	61	2	RESULT_UPDATED	2026-05-04 22:56:58.507
345	61	2	RESULT_UPDATED	2026-05-04 22:57:09.265
346	61	2	RESULT_UPDATED	2026-05-04 22:57:15.831
\.


--
-- Data for Name: MatchPosterCache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MatchPosterCache" (id, "matchId", "templateVersion", hash, "storageKey", "generatedAt") FROM stdin;
40	26	12	f820d6ab25371e932fcf3097b0efd1be1558d753e038fdbf78804a4c3f54eb75	uploads/posters/26-12-f820d6ab-edbb3c79-8b02-4525-9be0-a02e5f833b43.png	2026-02-19 13:59:23.03
37	25	12	327e90d5570a2e1ca740916a862ae7593cb69c6f598eef5aff95393b74efb309	uploads/posters/25-12-327e90d5-3f08a91f-f3a8-41a4-bc9c-8e9c03edf94e.png	2026-02-20 12:35:44.09
1	2	5	ce77dd9af967080b1a6386f36b36b67a5cbaab1b895a5bae26b6ac7d5ffacf60	uploads/posters/2-5-ce77dd9a-68b59e67-e15e-40f7-ba2c-0c0c4ca4ad02.png	2026-01-20 23:31:06.227
44	40	8	d502a81594c884d6ec4e409c300f827c0dfcdbaa48f31961a46f49a32a7714fb	uploads/posters/40-8-d502a815-c5ed136e-3c61-4762-aedf-868a7b41a16c.png	2026-02-25 15:23:44.557
45	41	8	f9c30796aa15d9bfb5a59c7cc6e15085148b54d008f7072c21af0e3553290750	uploads/posters/41-8-f9c30796-a4209dfb-5f70-4414-ba0c-86cb4104fcd5.png	2026-02-25 15:23:52.712
46	39	8	8f50cd3adc63cad037376b2afdb823b16256c91bf5edeaae5cd2230f5a4ac43b	uploads/posters/39-8-8f50cd3a-83d728b6-6e3d-4ab2-8556-f4fc6184e459.png	2026-02-25 15:23:59.902
47	28	12	fcc966e6d5e25ce37f614e4dd49a325b5bed1fb62262f5f3936a1e8b68cad019	uploads/posters/28-12-fcc966e6-a1b8c35d-f3e7-486d-b200-e90f52d561ee.png	2026-02-27 10:16:54.608
48	27	12	2a6c10a876e02f303a9cf85337e8479cb8317749c2c4f303ab4e01a32e66b954	uploads/posters/27-12-2a6c10a8-d4b52578-f210-4ccf-a344-f82aaa0e9c72.png	2026-02-27 10:19:07.451
51	44	8	4d88a16f871f58d9c43e3a2a7709d612245555b2652e6ef1ac120b5b9602bc4b	uploads/posters/44-8-4d88a16f-7c20980b-8e65-4c5b-ad1b-da5e7d04024a.png	2026-03-05 01:35:22.132
49	30	12	6a4fd22df2541c614a6b124f8712d2f4c45fb26665bbe668e96e5405e6fb87a0	uploads/posters/30-12-6a4fd22d-8714dfbb-d0df-4ac4-b6a7-b35ffeba3bab.png	2026-03-05 14:27:32.486
28	35	8	d55dc88c9e7f32a9f39a84dbf23d084f68e7934107a046e61ad985ff42e45db4	uploads/posters/35-8-d55dc88c-f262073f-33a2-453e-b0be-47bac2d18f2e.png	2026-03-10 17:12:19.224
13	22	12	6c488e2a7f90dc5b00f3e90c2c4eda9dd586f6e492f69feb959b270633ac0f87	uploads/posters/22-12-6c488e2a-4d64110b-91c8-4a6b-a93b-eaf073f8f792.png	2026-02-06 13:53:21.401
19	24	12	c96e42d6a90ce52ac62a3c42cffadff3c3ac7b6a016f728b733d14037aaef543	uploads/posters/24-12-c96e42d6-060226fb-c51d-463e-b574-7c371fefdeff.png	2026-02-08 19:17:13.735
50	43	8	2032a88fc127f9f58bd85fc9900205a7739a74d653cc41b64d05ae9aee920c89	uploads/posters/43-8-2032a88f-2240f69c-a150-4aa6-bc70-383352367603.png	2026-03-10 17:49:58.148
56	46	8	240955bd5216dfbbcfcc2db92108dfd9e0a78039984b880b24508f42d379d370	uploads/posters/46-8-240955bd-3973e653-e270-4465-86fc-8f27b37d0e1e.png	2026-03-12 12:34:52.538
57	47	8	ac205c487983143c189a1e59260477a0b7d741315818c3f8b7a062d0be718ed5	uploads/posters/47-8-ac205c48-ea5e5765-7f7f-4b7e-a045-1bb7c2cbdf2e.png	2026-03-12 12:35:03.745
58	45	8	64b7d9fd6b36627f5824ecdb33667fceb78ef9793bba007330f0001ff7a50214	uploads/posters/45-8-64b7d9fd-38d71728-447d-458c-b2dd-fded0dbfaf04.png	2026-03-12 12:35:15.083
59	49	8	f1c2ef601c46621453986dbafe9ce116a352f21a3d9aef71ac857e3b939ddb84	uploads/posters/49-8-f1c2ef60-3aa96123-ee88-410e-a6da-516ea243c737.png	2026-03-18 13:51:39.371
20	34	8	f1a15e294118caf0d3b6a2001fcefad50e04a2ee3aa2c977a6035160741c08d3	uploads/posters/34-8-f1a15e29-d6ff6422-70a3-4b81-8746-e957737c1928.png	2026-02-11 12:12:01.445
29	33	8	d67b917f4b5926966d20bdcb6426542918dd9232ff105f74c93395962733f448	uploads/posters/33-8-d67b917f-bfc5b7a7-890c-4f2d-8440-0a5fa609dc5c.png	2026-02-11 12:12:47.826
60	50	8	7d059b57b733e6657bf9e28779d753562f7d8ca170b9da2d4ae54103249a1882	uploads/posters/50-8-7d059b57-af4b3dc6-c1e7-4c31-b883-bc1c3a065228.png	2026-03-18 13:52:08.165
61	48	8	46c0bad057185fa9c0ae1a78328d84abe631b7203123a2c0410a3a763dc704be	uploads/posters/48-8-46c0bad0-e842b22b-33ba-45a2-a3ef-2014075d7f3d.png	2026-03-18 13:52:21.904
6	21	12	f1a4fc9ed29e2400b420beeb6b025593bb99f3870c96e9fbe9cc30be2f04c86d	uploads/posters/21-12-f1a4fc9e-dad46e35-94c1-491d-a400-ae4e1647a7ab.png	2026-02-13 12:12:00.26
33	23	12	91450acb63a3162890f5314bb1f1fa5db2809f22e07811282a1eb51992700b7f	uploads/posters/23-12-91450acb-e41acf45-2fc6-47d2-9f43-df9c57349961.png	2026-02-14 20:56:18.639
34	38	8	20c6d7794d21bc38c29966bf92cc46ce9f7ced264190569e293bdda35fa170f0	uploads/posters/38-8-20c6d779-ceea1102-cbd1-4e22-b18a-8258ece07229.png	2026-02-17 14:21:32.207
35	36	8	14f5b4760e4efa883d4aa01817da2447c19c4c97366a2321f39773f990982c6d	uploads/posters/36-8-14f5b476-dea95c06-a726-43b7-b077-009b5caac91b.png	2026-02-17 14:21:36.82
36	37	8	7cd56df9c79601ea92d7d6162a2b6846d8ea79237d3c1a0d6a08e913b7a4d4a6	uploads/posters/37-8-7cd56df9-284ed406-c079-453e-bdce-b83a6169c73a.png	2026-02-17 14:21:42.423
63	53	8	decfeb8f38bd311d479a2c46f2f3f00fa9bd2d5422074cc210235632543a0efc	uploads/posters/53-8-decfeb8f-a182527b-c8a1-47be-bf4d-a5ecd1290f6b.png	2026-03-25 17:28:58.184
64	52	8	1f1a3c6b7c8f64e1c370621f769cfde9d4779fdc69e2585d0df25d61748a1aed	uploads/posters/52-8-1f1a3c6b-62c88313-538d-47eb-b365-1663a889b1c0.png	2026-03-25 17:29:09.756
65	51	8	a21bcfee9167f42c3df91d6c5726e2dd217f7a08616bd637ae89eaa1f10388c3	uploads/posters/51-8-a21bcfee-46257c18-51fc-489a-8374-cc861c8852ff.png	2026-03-25 17:29:17.485
54	42	8	b33aea01a85727f23c57921c4d7f7ffdc75e522592679564ed6afd57d3a96a88	uploads/posters/42-8-b33aea01-3433ef0e-94d6-46ee-871a-900ddca6cd77.png	2026-03-25 17:31:51.937
69	56	8	9021911391f9a6339f108ab373aa17fe0903149633455e6f41a613c665a8da80	uploads/posters/56-8-90219113-7edd8469-b261-442a-8330-0edb1ea2f83a.png	2026-04-10 10:34:39.957
67	54	8	458ded0f5c9db0fd59ac3a6d3b4663749a3c85b55da02977d98ec7c483a55684	uploads/posters/54-8-458ded0f-069cd70e-50cf-4308-8ca9-03531a8e3579.png	2026-04-12 16:27:35.684
72	57	8	ad60ce140b7a1b51501b90acb539624df67d80b53cf1c93cfef72a3bff18daa6	uploads/posters/57-8-ad60ce14-ae85ee17-ecd1-4e79-b6dc-e0ad78fe5295.png	2026-04-23 12:23:33.92
73	61	8	5fe89a25d37c6227d2118a180a66084f1fa26da58d03bab52e14ed98e8ad0d3e	uploads/posters/61-8-5fe89a25-81c2aba1-d510-4853-9bdc-e62d4f3a5df4.png	2026-04-28 15:08:33.138
74	60	8	5006734cdf911edf3d8758f6334b571e2dc467d3282c78314fa074e29e09f267	uploads/posters/60-8-5006734c-0f6ccdc5-aa31-4206-83b6-4d811961a878.png	2026-04-28 15:29:50.143
\.


--
-- Data for Name: OtherGoal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."OtherGoal" (id, "matchCategoryId", "clubId", goals, "createdAt") FROM stdin;
1	5	3	1	2026-01-16 11:28:51.651
3	1	3	1	2026-01-20 11:23:49.931
5	218	11	2	2026-02-14 14:19:37.344
6	102	6	5	2026-02-18 10:36:33.88
7	107	1	1	2026-02-18 10:37:42.847
8	108	1	2	2026-02-18 10:39:09.46
9	104	1	2	2026-02-18 10:39:49.014
10	104	6	1	2026-02-18 10:39:49.014
11	105	1	3	2026-02-18 10:40:23.233
12	105	6	1	2026-02-18 10:40:23.233
13	101	1	1	2026-02-18 10:40:36.48
14	118	7	2	2026-02-18 10:41:34.517
15	117	8	2	2026-02-18 10:41:39.293
16	116	7	3	2026-02-18 10:41:47.429
17	116	8	2	2026-02-18 10:41:47.429
18	115	7	3	2026-02-18 10:41:56.592
19	115	8	4	2026-02-18 10:41:56.592
20	114	7	5	2026-02-18 10:42:03.662
21	114	8	3	2026-02-18 10:42:03.662
22	113	7	2	2026-02-18 10:42:11.149
23	113	8	4	2026-02-18 10:42:11.149
24	112	7	2	2026-02-18 10:42:18.187
25	111	7	7	2026-02-18 10:42:47.15
26	111	8	5	2026-02-18 10:42:47.15
27	110	7	6	2026-02-18 10:42:55.488
28	110	8	5	2026-02-18 10:42:55.488
29	119	6	8	2026-02-18 11:15:41.212
30	119	7	11	2026-02-18 11:15:41.212
31	120	6	4	2026-02-18 11:16:09.825
32	120	7	2	2026-02-18 11:16:09.825
33	121	6	1	2026-02-18 11:16:23.003
34	121	7	4	2026-02-18 11:16:23.003
35	122	6	4	2026-02-18 11:16:38.059
36	122	7	4	2026-02-18 11:16:38.059
37	123	6	1	2026-02-18 11:16:50.425
38	123	7	1	2026-02-18 11:16:50.425
39	124	6	2	2026-02-18 11:17:01.564
40	126	7	1	2026-02-18 11:17:22.625
41	127	6	1	2026-02-18 11:17:37.561
42	127	7	2	2026-02-18 11:17:37.561
43	136	8	2	2026-02-20 10:25:42.489
44	135	8	5	2026-02-20 10:25:57.712
45	135	1	1	2026-02-20 10:25:57.712
46	134	8	2	2026-02-20 10:26:09.905
47	133	8	5	2026-02-20 10:26:25.427
48	133	1	1	2026-02-20 10:26:25.427
49	132	8	1	2026-02-20 10:26:40.136
50	132	1	3	2026-02-20 10:26:40.136
51	131	8	5	2026-02-20 10:26:50.26
52	131	1	1	2026-02-20 10:26:50.26
53	130	8	1	2026-02-20 10:26:57.502
54	129	8	3	2026-02-20 10:27:06.902
55	129	1	2	2026-02-20 10:27:06.902
56	128	1	1	2026-02-20 10:27:18.922
57	234	11	1	2026-02-21 13:41:05.057
58	233	11	2	2026-02-21 13:42:08.831
59	138	1	6	2026-02-25 16:23:50.324
60	138	7	4	2026-02-25 16:23:50.324
61	144	1	1	2026-02-25 16:24:00.677
62	144	7	2	2026-02-25 16:24:00.677
63	139	1	2	2026-02-25 16:24:09.748
64	139	7	4	2026-02-25 16:24:09.748
65	148	8	4	2026-02-25 16:24:49.611
66	148	6	3	2026-02-25 16:24:49.611
67	149	8	4	2026-02-25 16:25:02.342
68	149	6	3	2026-02-25 16:25:02.342
69	152	6	3	2026-02-25 16:25:13.175
70	153	8	1	2026-02-25 16:25:23.189
71	153	6	1	2026-02-25 16:25:23.189
72	151	8	3	2026-02-25 16:25:36.388
73	151	6	1	2026-02-25 16:25:36.388
74	150	8	1	2026-02-25 16:25:45.26
75	150	6	2	2026-02-25 16:25:45.26
76	147	8	4	2026-02-25 16:25:55.271
77	147	6	4	2026-02-25 16:25:55.271
78	146	8	2	2026-02-25 16:26:03.703
79	146	6	2	2026-02-25 16:26:03.703
80	141	1	1	2026-02-25 16:48:54.55
81	141	7	2	2026-02-25 16:48:54.55
82	137	1	3	2026-02-25 16:49:02.035
83	137	7	2	2026-02-25 16:49:02.035
84	142	1	1	2026-02-25 17:12:23.301
85	142	7	4	2026-02-25 17:12:23.301
87	143	1	3	2026-02-25 17:34:19.061
88	143	7	4	2026-02-25 17:34:19.061
89	145	1	1	2026-02-25 17:43:22.594
90	140	1	1	2026-02-27 10:16:29.449
91	140	7	4	2026-02-27 10:16:29.449
92	253	13	2	2026-02-28 21:53:04.872
93	262	11	3	2026-02-28 22:03:44.533
94	269	1	1	2026-02-28 22:22:12.958
95	290	11	2	2026-03-10 10:45:34.027
96	163	6	2	2026-03-10 10:46:43.323
97	162	6	1	2026-03-10 10:46:50.817
98	162	8	1	2026-03-10 10:46:50.817
99	161	8	5	2026-03-10 10:47:01.131
100	160	6	1	2026-03-10 10:47:10.068
101	160	8	1	2026-03-10 10:47:10.068
102	158	6	2	2026-03-10 10:47:30.846
103	158	8	4	2026-03-10 10:47:30.846
104	157	6	2	2026-03-10 10:47:41.594
105	157	8	4	2026-03-10 10:47:41.594
106	156	6	3	2026-03-10 10:47:50.777
107	156	8	1	2026-03-10 10:47:50.777
108	155	6	2	2026-03-10 10:48:04.381
109	155	8	3	2026-03-10 10:48:04.381
112	182	1	1	2026-03-10 10:48:42.593
113	182	8	1	2026-03-10 10:48:42.593
114	183	1	2	2026-03-10 10:49:06.999
115	183	8	3	2026-03-10 10:49:06.999
116	184	1	4	2026-03-10 10:49:15.779
117	184	8	5	2026-03-10 10:49:15.779
118	185	1	3	2026-03-10 10:49:30.259
119	185	8	5	2026-03-10 10:49:30.259
120	186	1	3	2026-03-10 10:49:41.931
121	186	8	3	2026-03-10 10:49:41.931
122	187	1	2	2026-03-10 10:49:53.018
123	187	8	6	2026-03-10 10:49:53.018
124	188	8	1	2026-03-10 10:50:04.949
125	189	1	1	2026-03-10 10:50:15.93
126	189	8	2	2026-03-10 10:50:15.93
127	173	7	1	2026-03-12 12:24:20.572
128	174	7	1	2026-03-12 12:24:31.371
129	174	6	1	2026-03-12 12:24:31.371
130	175	7	1	2026-03-12 12:24:36.806
131	176	7	1	2026-03-12 12:24:41.165
132	177	7	1	2026-03-12 12:24:48.395
133	178	7	1	2026-03-12 12:24:52.543
134	179	7	1	2026-03-12 12:25:01.274
135	179	6	1	2026-03-12 12:25:01.274
136	180	7	1	2026-03-12 12:25:06.893
137	180	6	1	2026-03-12 12:25:06.893
138	181	6	1	2026-03-12 12:25:12.57
139	164	7	1	2026-03-12 12:37:22.55
140	165	7	1	2026-03-12 12:37:26.137
141	166	7	1	2026-03-12 12:37:29.446
142	167	7	1	2026-03-12 12:37:36.431
143	168	7	1	2026-03-12 12:37:40.209
144	169	7	1	2026-03-12 12:37:43.916
145	170	7	1	2026-03-12 12:37:48.269
146	171	7	1	2026-03-12 12:37:51.521
147	172	7	1	2026-03-12 12:37:54.482
148	296	12	3	2026-03-18 12:48:47.882
149	311	11	2	2026-03-18 13:30:57.814
150	322	1	2	2026-03-25 10:50:37.344
151	357	9	2	2026-04-14 14:07:19.873
152	372	1	2	2026-04-16 23:44:22.752
153	328	12	2	2026-04-23 19:11:19.025
154	329	12	2	2026-04-23 19:11:22.302
155	333	12	2	2026-04-23 19:11:26.145
156	332	12	2	2026-04-23 19:11:29.56
157	331	12	2	2026-04-23 19:11:32.429
158	330	12	2	2026-04-23 19:11:35.447
159	334	12	2	2026-04-23 19:11:39.319
160	349	1	2	2026-04-23 19:11:50.256
161	350	1	2	2026-04-23 19:11:54.007
162	354	1	2	2026-04-23 19:11:57.139
164	352	1	2	2026-04-23 19:12:02.595
163	353	1	2	2026-04-23 19:12:00.042
165	351	1	2	2026-04-23 19:12:05.331
166	355	1	2	2026-04-23 19:12:08.851
169	361	9	2	2026-04-23 19:12:53.598
170	356	9	2	2026-04-23 19:12:59.18
172	360	9	2	2026-04-23 19:13:21.039
173	359	9	2	2026-04-23 19:13:24.978
174	358	9	2	2026-04-23 19:13:30.619
175	362	9	2	2026-04-23 19:13:34.932
176	384	10	2	2026-04-23 19:13:53.236
177	385	10	2	2026-04-23 19:13:56.756
178	389	10	2	2026-04-23 19:14:00.157
179	388	10	2	2026-04-23 19:14:02.762
180	387	10	2	2026-04-23 19:14:05.779
181	386	10	2	2026-04-23 19:14:08.984
182	390	10	2	2026-04-23 19:14:12.471
183	412	11	2	2026-04-23 19:14:33.094
184	413	11	2	2026-04-23 19:14:35.994
185	417	11	2	2026-04-23 19:14:39.28
186	416	11	2	2026-04-23 19:14:42.584
187	415	11	2	2026-04-23 19:14:45.606
188	414	11	2	2026-04-23 19:14:48.521
189	418	11	2	2026-04-23 19:14:52.16
190	380	9	1	2026-04-25 13:33:09.927
191	391	12	1	2026-04-25 13:38:11.311
192	392	12	2	2026-04-25 13:38:29.519
193	364	10	2	2026-04-28 12:19:03.867
196	407	10	1	2026-05-04 22:56:10.859
197	411	10	3	2026-05-04 22:56:15.505
198	411	1	1	2026-05-04 22:56:15.505
199	408	10	1	2026-05-04 22:56:35.461
200	408	1	2	2026-05-04 22:56:35.461
201	409	10	3	2026-05-04 22:56:44
202	410	10	3	2026-05-04 22:56:58.501
203	410	1	1	2026-05-04 22:56:58.501
204	406	10	1	2026-05-04 22:57:09.246
205	406	1	6	2026-05-04 22:57:09.246
206	405	10	1	2026-05-04 22:57:15.809
\.


--
-- Data for Name: PasswordChangeRequest; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PasswordChangeRequest" (id, "userId", token, "newPassword", "expiresAt", "confirmedAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: PasswordResetToken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PasswordResetToken" (id, "userId", token, "expiresAt", "usedAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: Permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Permission" (id, module, action, scope, description, "createdAt", "updatedAt") FROM stdin;
1	TORNEOS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.742	2026-01-12 15:23:38.742
2	PARTIDOS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
3	PLANTELES	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
4	JUGADORES	VIEW	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
5	LIGAS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.742	2026-01-12 15:23:38.742
6	ZONAS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
7	RESULTADOS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
8	PLANTELES	VIEW	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
9	TABLAS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
10	CLUBES	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
11	CATEGORIAS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
12	CONFIGURACION	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
13	FIXTURE	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
14	FIXTURE	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
15	USUARIOS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
16	ROLES	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
17	ZONAS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
18	CATEGORIAS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
19	JUGADORES	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
20	PERMISOS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
21	REPORTES	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
22	PARTIDOS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
23	RESULTADOS	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
24	FIXTURE	VIEW	LIGA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
25	USUARIOS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
26	PARTIDOS	VIEW	LIGA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
27	FIXTURE	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
28	PARTIDOS	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
29	ROLES	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
30	PERMISOS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
31	PARTIDOS	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
32	TABLAS	VIEW	LIGA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
33	TABLAS	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
34	RESULTADOS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
35	FIXTURE	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
36	JUGADORES	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
37	TABLAS	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
38	TABLAS	VIEW	GLOBAL	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
39	PLANTELES	VIEW	CATEGORIA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
40	CONFIGURACION	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
41	RESULTADOS	VIEW	LIGA	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
42	JUGADORES	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
43	PLANTELES	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
44	TORNEOS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.745	2026-01-12 15:23:38.745
45	LIGAS	MANAGE	GLOBAL	\N	2026-01-12 15:23:38.745	2026-01-12 15:23:38.745
46	RESULTADOS	VIEW	CLUB	\N	2026-01-12 15:23:38.744	2026-01-12 15:23:38.744
47	REPORTES	VIEW	GLOBAL	\N	2026-01-12 15:23:38.745	2026-01-12 15:23:38.745
48	CLUBES	VIEW	GLOBAL	\N	2026-01-12 15:23:38.743	2026-01-12 15:23:38.743
\.


--
-- Data for Name: Player; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Player" (id, "firstName", "lastName", "birthDate", dni, gender, active, "addressStreet", "addressNumber", "addressCity", "emergencyName", "emergencyRelationship", "emergencyPhone", "createdAt", "updatedAt") FROM stdin;
2	asf	jug05	2012-01-01 00:00:00	12123124	MASCULINO	f	falsa	132	GB	\N	\N	\N	2026-01-12 17:38:38.328	2026-02-12 15:59:32.007
10	a	jug10	2012-12-12 00:00:00	45568744	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:10.841	2026-02-12 15:59:35.336
7	as	Jug07	2012-01-01 00:00:00	4477477	MASCULINO	f	a	77	as	\N	\N	\N	2026-01-14 18:06:03.496	2026-02-12 15:58:12.554
8	a	Jug08	2012-01-01 00:00:00	234234234234	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:10.436	2026-02-12 15:58:15.75
21	s	Jug21	2014-01-01 00:00:00	564564564	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:01.09	2026-02-12 15:58:54.633
20	a	Jug20	2013-01-01 00:00:00	456547568	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:12.84	2026-02-12 15:58:51.896
19	a	Jug19	2013-01-01 00:00:00	45756834	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:12.642	2026-02-12 15:58:48.839
18	a	Jug18	2013-01-01 00:00:00	23523537	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:12.442	2026-02-12 15:58:45.781
17	a	Jug17	2013-01-01 00:00:00	34678474	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:12.242	2026-02-12 15:58:42.018
16	a	Jug16	2013-01-01 00:00:00	3457885	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:12.041	2026-02-12 15:58:38.232
15	a	Jug15	2013-01-01 00:00:00	4578342	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:11.841	2026-02-12 15:58:35.399
14	a	Jug14	2013-01-01 00:00:00	2353647	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:11.64	2026-02-12 15:58:31.749
13	a	Jug13	2013-01-01 00:00:00	3455772	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:11.438	2026-02-12 15:58:28.601
12	a	Jug12	2013-01-01 00:00:00	565656343	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:11.241	2026-02-12 15:58:25.261
27	s	Jug27	2014-01-01 00:00:00	2345644	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:02.999	2026-02-12 15:59:58.933
11	a	Jug11	2013-01-01 00:00:00	33456474	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:11.038	2026-02-12 15:58:22.351
9	a	Jug09	2012-12-01 00:00:00	234212355	MASCULINO	f	as	3	d	\N	\N	\N	2026-01-14 23:45:10.641	2026-02-12 15:58:19.415
34	asd	Jug42	2016-01-01 00:00:00	4354644	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:53.447	2026-02-12 16:00:49.666
43	a	Jug43	2016-01-01 00:00:00	77451465	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:00.562	2026-02-12 16:00:52.531
22	s	Jug22	2014-01-01 00:00:00	45676745	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:01.459	2026-02-12 15:58:57.52
23	s	Jug23	2014-01-01 00:00:00	34534562	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:01.769	2026-02-12 15:59:01.446
24	s	Jug24	2014-01-01 00:00:00	234674	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:02.014	2026-02-12 15:59:04.849
25	s	Jug25	2014-01-01 00:00:00	2346733	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:02.384	2026-02-12 15:59:08.97
26	s	Jug26	2014-01-01 00:00:00	2353467	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:02.689	2026-02-12 15:59:12.537
3	a	jug01	2012-01-01 00:00:00	4777777	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-14 12:42:12.737	2026-02-12 15:59:19.095
4	a	jug02	2012-01-01 00:00:00	4444444	MASCULINO	f	4	1	1	\N	\N	\N	2026-01-14 12:42:39.708	2026-02-12 15:59:22.366
5	a	jug03	2012-01-01 00:00:00	44444444	MASCULINO	f	q	4	q	\N	\N	\N	2026-01-14 12:42:59.933	2026-02-12 15:59:25.904
1	asd	jug04	2012-01-01 00:00:00	12123132	MASCULINO	f	falsa	123	GB	\N	\N	\N	2026-01-12 17:38:14.165	2026-02-12 15:59:28.987
28	s	Jug28	2014-01-01 00:00:00	56866334	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:03.325	2026-02-12 16:00:01.706
29	s	Jug29	2014-01-01 00:00:00	345789008	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:03.728	2026-02-12 16:00:04.401
30	s	Jug30	2014-01-01 00:00:00	3456788	MASCULINO	f	s	5	fg	\N	\N	\N	2026-01-14 23:55:04.025	2026-02-12 16:00:07.42
31	asd	Jug31	2015-01-01 00:00:00	568734	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:11.621	2026-02-12 16:00:10.864
32	asd	Jug32	2015-01-01 00:00:00	435464	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:11.81	2026-02-12 16:00:14.202
35	asd	Jug33	2015-01-01 00:00:00	423124	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:53.626	2026-02-12 16:00:17.411
37	asd	Jug35	2015-01-01 00:00:00	67486344	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:53.993	2026-02-12 16:00:23.519
38	asd	Jug36	2015-01-01 00:00:00	43789644	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:54.176	2026-02-12 16:00:27.064
39	asd	Jug37	2015-01-01 00:00:00	45378964	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:54.36	2026-02-12 16:00:35.93
40	asd	Jug38	2015-01-01 00:00:00	65671264	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:54.542	2026-02-12 16:00:38.566
41	asd	Jug39	2015-01-01 00:00:00	66475564	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:54.726	2026-02-12 16:00:41.318
42	asd	Jug40	2015-01-01 00:00:00	78945344	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:54.908	2026-02-12 16:00:43.947
33	asd	Jug41	2016-01-01 00:00:00	5687344	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:53.257	2026-02-12 16:00:46.906
44	a	Jug44	2016-01-01 00:00:00	77451581	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:00.745	2026-02-12 16:00:55.344
45	a	Jug45	2016-01-01 00:00:00	7795412	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:00.928	2026-02-12 16:00:58.118
46	a	Jug46	2016-01-01 00:00:00	776841	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:01.115	2026-02-12 16:01:03.054
47	a	Jug47	2016-01-01 00:00:00	7713548	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:01.294	2026-02-12 16:01:06.147
48	a	Jug48	2016-01-01 00:00:00	77564841	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:01.476	2026-02-12 16:01:11.416
49	a	Jug49	2016-01-01 00:00:00	7741258	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:01.677	2026-02-12 16:01:14.78
50	a	Jug50	2016-01-01 00:00:00	77985412	MASCULINO	f	a	1	a	\N	\N	\N	2026-01-15 11:08:01.863	2026-02-12 16:01:17.784
51	asd	jug80	2017-01-01 00:00:00	99874214	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.06	2026-02-12 16:01:20.754
52	asd	jug81	2017-01-01 00:00:00	1878754	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.26	2026-02-12 16:01:23.968
53	asd	jug82	2017-01-01 00:00:00	156748	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.447	2026-02-12 16:01:27.621
54	asd	jug83	2017-01-01 00:00:00	1878845	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.63	2026-02-12 16:01:30.902
55	asd	jug84	2017-01-01 00:00:00	8754168	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.811	2026-02-12 16:01:35.02
56	asd	jug85	2017-01-01 00:00:00	8764189	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:57.996	2026-02-12 16:01:38.646
57	asd	jug86	2017-01-01 00:00:00	874131674	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:58.182	2026-02-12 16:01:42.066
58	asd	jug87	2017-01-01 00:00:00	498746	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:01:58.362	2026-02-12 16:01:45.331
72	asd	jug90	2019-01-01 00:00:00	1254878	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:37.881	2026-02-12 16:01:52.517
64	asd	jug90	2018-01-01 00:00:00	58325136541	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:40.845	2026-02-12 16:01:56.468
60	asd	jug91	2018-01-01 00:00:00	98325148	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:16.699	2026-02-12 16:01:59.298
65	asd	jug91	2018-01-01 00:00:00	9832514811	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:41.027	2026-02-12 16:02:02.524
73	asd	jug91	2019-01-01 00:00:00	6874314	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:38.079	2026-02-12 16:02:06.311
61	asd	jug92	2018-01-01 00:00:00	247486	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:16.882	2026-02-12 16:02:09.62
74	asd	jug92	2019-01-01 00:00:00	3419887	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:38.265	2026-02-12 16:02:12.753
66	asd	jug92	2018-01-01 00:00:00	2474861	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:41.21	2026-02-12 16:02:16.122
75	asd	jug93	2019-01-01 00:00:00	436873	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:38.452	2026-02-12 16:02:19.301
67	asd	jug93	2018-01-01 00:00:00	354864111	MASCULINO	f	asd	1	as	\N	\N	\N	2026-02-02 14:07:41.405	2026-02-12 16:02:22.782
62	asd	jug93	2018-01-01 00:00:00	35486411	MASCULINO	f	asd	1	as	\N	\N	\N	2026-02-02 14:07:17.065	2026-02-12 16:02:26.9
76	asd	jug94	2019-01-01 00:00:00	71384641	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:38.663	2026-02-12 16:02:29.995
63	asd	jug94	2018-01-01 00:00:00	7443587431	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:17.244	2026-02-12 16:02:33.239
68	asd	jug94	2018-01-01 00:00:00	74435874311	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:41.591	2026-02-12 16:02:37.24
69	asd	jug95	2018-01-01 00:00:00	1347811	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:41.784	2026-02-12 16:02:41.466
77	asd	jug95	2019-01-01 00:00:00	2174876	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:38.856	2026-02-12 16:02:45.123
70	asd	jug96	2018-01-01 00:00:00	4784311	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:41.964	2026-02-12 16:02:49.036
78	asd	jug96	2019-01-01 00:00:00	1478741886	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:39.043	2026-02-12 16:02:52.535
71	asd	jug97	2018-01-01 00:00:00	48612861	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:42.167	2026-02-12 16:02:55.485
79	asd	jug97	2019-01-01 00:00:00	7484364	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:11:39.228	2026-02-12 16:02:58.675
99	S11	Jugadora11	2015-01-01 00:00:00	77987844	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:17.937	2026-02-12 15:34:32.778
143	Mia	Duport	2012-07-07 00:00:00	52655072	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:16.89	2026-02-11 23:42:16.89
91	S13	Jugadora24	2013-01-01 00:00:00	7657343	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:39.979	2026-02-12 15:35:10.763
90	S13	Jugadora23	2013-01-01 00:00:00	1246733	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:39.796	2026-02-12 15:35:07.206
94	S13	Jugadora22	2013-01-01 00:00:00	34567341	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55.189	2026-02-12 15:35:03.057
106	S13	Jugadora25	2013-01-01 00:00:00	4541582	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:23:11.545	2026-02-12 15:35:14.629
137	Lourdes	Dominguez	2011-04-20 00:00:00	50960483	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:15.72	2026-02-11 23:42:15.72
138	Luisana	Lizarraga	2011-09-02 00:00:00	51256844	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:15.93	2026-02-11 23:42:15.93
139	Luz	Villalba	2012-07-17 00:00:00	52623580	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:16.142	2026-02-11 23:42:16.142
140	Sofia	Velazquez	2011-05-24 00:00:00	51144665	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:16.326	2026-02-11 23:42:16.326
141	Lourdes	Diago	2012-01-30 00:00:00	52025370	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:16.51	2026-02-11 23:42:16.51
142	Alma	Baginay	2012-12-18 00:00:00	52915989	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:16.707	2026-02-11 23:42:16.707
144	Zaira	Coria	2012-01-17 00:00:00	52029075	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:42:17.089	2026-02-11 23:42:17.089
145	Evelyn	Ruffini	1993-08-23 00:00:00	37863181	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:16.607	2026-02-11 23:58:16.607
146	Carolin	Salina	1992-10-08 00:00:00	37123644	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:16.813	2026-02-11 23:58:16.813
147	Elena	Tobares	1986-08-20 00:00:00	32872367	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:17.002	2026-02-11 23:58:17.002
148	Adriana	Basoalto	1991-08-31 00:00:00	38634134	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:17.2	2026-02-11 23:58:17.2
149	Gisela	Zelame	1987-08-24 00:00:00	33202365	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:17.401	2026-02-11 23:58:17.401
150	Brenda	Lopez	1993-01-20 00:00:00	37279986	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-11 23:58:17.6	2026-02-11 23:58:17.6
151	Mariana	Carrizo	2018-12-11 00:00:00	57394643	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:04:32.269	2026-02-12 00:04:32.269
152	Mora	Menendez	2017-05-03 00:00:00	56260944	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:04:32.471	2026-02-12 00:04:32.471
153	Aitana	Martinez	2017-06-03 00:00:00	56354007	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:04:32.681	2026-02-12 00:04:32.681
88	S9	Jugadora01	2017-01-01 00:00:00	456565	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:39.429	2026-02-12 15:34:06.002
89	S9	Jugadora02	2017-01-01 00:00:00	3456734	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:39.614	2026-02-12 15:34:10.217
95	S9	Jugadora03	2017-01-01 00:00:00	12467331	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55.369	2026-02-12 15:34:13.861
96	S9	Jugadora04	2017-01-01 00:00:00	76573431	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55.55	2026-02-12 15:34:17.613
97	S9	Jugadora05	2017-01-01 00:00:00	236774531	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55.734	2026-02-12 15:34:21.243
98	S9	Jugadora06	2017-01-01 00:00:00	23566111	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55.916	2026-02-12 15:34:24.747
92	S9	Jugadora07	2017-01-01 00:00:00	23677453	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:40.162	2026-02-12 15:34:28.358
100	S11	Jugadora12	2015-01-01 00:00:00	5415168	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:18.119	2026-02-12 15:34:36.255
101	S11	Jugadora13	2015-01-01 00:00:00	0541513	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:18.301	2026-02-12 15:34:39.482
102	S11	Jugadora14	2015-01-01 00:00:00	4784515	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:18.5	2026-02-12 15:34:42.942
103	S11	Jugadora15	2015-01-01 00:00:00	01515130	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:18.699	2026-02-12 15:34:46.327
104	S11	Jugadora16	2015-01-01 00:00:00	32411822	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:18.897	2026-02-12 15:34:49.727
105	S11	Jugadora17	2015-01-01 00:00:00	87451844	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:19:19.076	2026-02-12 15:34:52.995
93	S13	Jugadora21	2013-01-01 00:00:00	4565651	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:16:55	2026-02-12 15:34:59.677
107	S13	Jugadora26	2013-01-01 00:00:00	2649841	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:23:11.728	2026-02-12 15:35:18.314
108	S13	Jugadora27	2013-01-01 00:00:00	6587412	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:23:11.91	2026-02-12 15:35:22.247
109	S15	Jugadora31	2011-01-01 00:00:00	91124141	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:40.063	2026-02-12 15:35:26.038
110	S15	Jugadora32	2011-01-01 00:00:00	6574154	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:40.248	2026-02-12 15:35:30.048
111	S15	Jugadora33	2011-01-01 00:00:00	48747118	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:40.431	2026-02-12 15:35:33.465
112	S15	Jugadora34	2011-01-01 00:00:00	17818114	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:40.631	2026-02-12 15:35:36.902
113	S15	Jugadora35	2011-01-01 00:00:00	65874142	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:40.811	2026-02-12 15:35:49.749
114	S15	Jugadora36	2011-01-01 00:00:00	98745874	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:41.001	2026-02-12 15:35:54.169
116	S17	Jugadora41	2009-01-01 00:00:00	78748122	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:26.438	2026-02-12 15:35:59.735
117	S17	Jugadora42	2009-01-01 00:00:00	84523687	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:26.651	2026-02-12 15:36:02.655
118	S17	Jugadora43	2009-01-01 00:00:00	1584681	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:26.833	2026-02-12 15:36:05.595
119	S17	Jugadora44	2009-01-01 00:00:00	987987456	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:27.013	2026-02-12 15:36:08.517
120	S17	Jugadora45	2009-01-01 00:00:00	126587487	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:27.192	2026-02-12 15:36:11.395
121	S17	Jugadora46	2009-01-01 00:00:00	496846314	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:27.377	2026-02-12 15:36:14.942
122	S17	Jugadora47	2009-01-01 00:00:00	4987462	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:29:27.561	2026-02-12 15:36:19.395
123	P	Jugadora51	1997-01-01 00:00:00	24584553	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:05.245	2026-02-12 15:36:23.111
124	P	Jugadora52	1997-01-01 00:00:00	425684141	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:05.428	2026-02-12 15:36:27.568
125	P	Jugadora53	1997-01-01 00:00:00	32114478	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:05.612	2026-02-12 15:36:31.602
126	P	Jugadora54	1997-01-01 00:00:00	41815447	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:05.797	2026-02-12 15:36:35.009
127	P	Jugadora55	1997-01-01 00:00:00	87421453	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:05.978	2026-02-12 15:36:38.827
128	P	Jugadora56	1997-01-01 00:00:00	15171244	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:06.162	2026-02-12 15:36:43.766
129	P	Jugadora57	1997-01-01 00:00:00	874585214	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:32:06.382	2026-02-12 15:36:47.448
130	D	Jugadora61	1990-01-01 00:00:00	5741287414	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:58.972	2026-02-12 15:36:51.984
131	D	Jugadora62	1990-01-01 00:00:00	523698415	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:59.161	2026-02-12 15:36:55.766
132	D	Jugadora63	1990-01-01 00:00:00	51247851	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:59.348	2026-02-12 15:36:59.559
133	D	Jugadora64	1990-01-01 00:00:00	536987444	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:59.538	2026-02-12 15:37:02.814
134	D	Jugadora65	1990-01-01 00:00:00	587426985	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:59.737	2026-02-12 15:37:06.544
135	D	Jugadora66	1990-01-01 00:00:00	5971058784	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:34:59.952	2026-02-12 15:37:09.825
136	D	Jugadora67	1990-01-01 00:00:00	50475844	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:35:00.133	2026-02-12 15:37:13.202
87	asd	jug	2020-01-01 00:00:00	487415668	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:15.527	2026-02-12 15:59:15.73
80	asd	jug100	2020-01-01 00:00:00	546454548	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:14.12	2026-02-12 15:59:38.539
81	asd	jug101	2020-01-01 00:00:00	1486547874	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:14.317	2026-02-12 15:59:41.436
82	asd	jug102	2020-01-01 00:00:00	6548111	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:14.52	2026-02-12 15:59:44.814
83	asd	jug103	2020-01-01 00:00:00	4848136	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:14.72	2026-02-12 15:59:47.57
85	asd	jug105	2020-01-01 00:00:00	4481444	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:15.129	2026-02-12 15:59:53.335
86	asd	jug106	2020-01-01 00:00:00	487425154	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:15.317	2026-02-12 15:59:55.75
155	Mia Valentina	Serna	2019-07-12 00:00:00	57830224	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:04:33.08	2026-02-12 00:04:33.08
156	Barbara	Ojeda	2005-07-07 00:00:00	46894497	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:36.409	2026-02-12 00:10:36.409
157	Daira	Barrientos	2005-02-20 00:00:00	46431291	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:36.597	2026-02-12 00:10:36.597
158	Sheila	Benitez	2007-12-27 00:00:00	48439698	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:36.865	2026-02-12 00:10:36.865
159	Fiorella	Paredes	2005-10-12 00:00:00	47053850	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:37.05	2026-02-12 00:10:37.05
160	Milagros	Villalba	2004-08-09 00:00:00	46088079	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:37.233	2026-02-12 00:10:37.233
161	Julieta	Busca	2006-05-19 00:00:00	47235964	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:37.419	2026-02-12 00:10:37.419
162	Ivana	Ojeda	1998-03-04 00:00:00	41100847	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:37.615	2026-02-12 00:10:37.615
163	Micaela	Ayala	2002-03-15 00:00:00	45892583	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:10:37.798	2026-02-12 00:10:37.798
164	Maria	Franco	1996-01-26 00:00:00	94407421	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:12:02.65	2026-02-12 00:12:02.65
165	Nicole	Pereyra	2009-04-16 00:00:00	49357467	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:41.566	2026-02-12 00:17:41.566
166	Fatima	Diaz	2009-01-23 00:00:00	49312241	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:41.767	2026-02-12 00:17:41.767
167	Esmeralda	Sena	2010-04-17 00:00:00	50246135	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:41.965	2026-02-12 00:17:41.965
168	Camila	Menendez	2010-01-15 00:00:00	50099823	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:42.153	2026-02-12 00:17:42.153
169	Nazarena	Perez	2009-01-20 00:00:00	49312255	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:42.334	2026-02-12 00:17:42.334
170	Julieta	Orlando	2010-01-06 00:00:00	50014279	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:42.521	2026-02-12 00:17:42.521
171	Dahiara	Alegre	2010-05-01 00:00:00	50246250	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:42.702	2026-02-12 00:17:42.702
172	Dulce	Gonzalez	2010-04-06 00:00:00	50098273	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:17:42.886	2026-02-12 00:17:42.886
173	Hannah	Sandoval	2015-08-20 00:00:00	54967032	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:05.164	2026-02-12 01:19:05.164
174	Milagros	Carrizo	2014-10-09 00:00:00	54347043	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:05.36	2026-02-12 01:19:05.36
175	Malena	Blanco	2014-10-21 00:00:00	54664746	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:05.576	2026-02-12 01:19:05.576
176	Pamela	Farias	2013-09-08 00:00:00	53458405	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:05.78	2026-02-12 01:19:05.78
177	Mariana	Villa	2013-03-15 00:00:00	53137520	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:05.977	2026-02-12 01:19:05.977
178	More Martina	Ayala	2014-06-28 00:00:00	53996028	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:06.176	2026-02-12 01:19:06.176
179	Mia	Ruiz	2016-09-20 00:00:00	55816758	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:06.38	2026-02-12 01:19:06.38
180	Valentina	Godoy	2016-10-03 00:00:00	55740780	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:06.576	2026-02-12 01:19:06.576
181	Isabella	Salamida	2015-02-18 00:00:00	54664710	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 01:19:06.788	2026-02-12 01:19:06.788
182	Maria	Galarza	1988-07-20 00:00:00	18894839	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 10:03:47.719	2026-02-12 10:03:47.719
183	Luna	Soler	2013-04-13 00:00:00	53061158	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 10:03:47.904	2026-02-12 10:03:47.904
184	Kiara	Robledo	2009-10-08 00:00:00	50864222	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 11:49:19.855	2026-02-12 11:49:19.855
185	Alicia	Gonzalez	1974-12-27 00:00:00	24231567	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 11:49:20.043	2026-02-12 11:49:20.043
154	Mara	Rodriguez	2018-01-29 00:00:00	56815436	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 00:04:32.87	2026-02-12 15:07:00.841
186	Trinidad	Bravo	2017-06-19 00:00:00	56353906	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:26:03.13	2026-02-12 15:26:03.13
187	Nahomi Jazmin	Corvalan	2017-10-28 00:00:00	56642211	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:30:56.827	2026-02-12 15:30:56.827
188	Quimey Milena	Corvalan	2018-12-28 00:00:00	57475791	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:30:57.017	2026-02-12 15:30:57.017
189	Zoe Yazmin	Vargas	2018-01-22 00:00:00	56809200	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:30:57.212	2026-02-12 15:30:57.212
190	Damari	Silva	2017-11-09 00:00:00	56642352	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:30:57.402	2026-02-12 15:30:57.402
191	Yuliana	Silva	2016-09-22 00:00:00	55816766	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:30:57.594	2026-02-12 15:30:57.594
193	Belinda	Araujo	2018-01-11 00:00:00	56858005	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:32:19.962	2026-02-12 15:32:19.962
194	Damaris	Herrera	2017-03-07 00:00:00	000000	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:32:53.033	2026-02-12 15:32:53.033
115	S15	Jugadora37	2011-01-01 00:00:00	96312587	FEMENINO	f	A	1	A	\N	\N	\N	2026-02-11 11:25:41.182	2026-02-12 15:35:56.919
195	Candela	Roldan	2014-07-07 00:00:00	54146661	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:26.54	2026-02-12 15:55:26.54
196	Ana Francesca	Benitez	2014-06-19 00:00:00	54063144	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:26.73	2026-02-12 15:55:26.73
197	Nahiara	Ayala	2014-12-13 00:00:00	54815626	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:26.916	2026-02-12 15:55:26.916
198	Valentina	Moyano	2016-02-10 00:00:00	55338516	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:27.101	2026-02-12 15:55:27.101
199	Milagros	Villalba	2014-08-29 00:00:00	54057080	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:27.287	2026-02-12 15:55:27.287
200	Aldana	Trinidad	2014-06-12 00:00:00	54049092	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:27.478	2026-02-12 15:55:27.478
201	Rosario	Vega	2015-11-07 00:00:00	55260837	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 15:55:27.665	2026-02-12 15:55:27.665
6	a	Jug06	2012-01-01 00:00:00	47474714	MASCULINO	f	a	44	as	\N	\N	\N	2026-01-14 18:06:03.286	2026-02-12 15:58:05.221
84	asd	jug104	2020-01-01 00:00:00	54654123	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:14:14.911	2026-02-12 15:59:50.689
36	asd	Jug34	2015-01-01 00:00:00	453789644	MASCULINO	f	a	1	s	\N	\N	\N	2026-01-15 10:47:53.809	2026-02-12 16:00:20.453
59	asd	jug90	2018-01-01 00:00:00	5832513654	MASCULINO	f	as	1	as	\N	\N	\N	2026-02-02 14:07:16.491	2026-02-12 16:01:49.35
202	Uma Analia	Marin	2013-01-31 00:00:00	52984146	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:07:50.295	2026-02-12 16:07:50.295
203	Nahiara	Sanchez	2013-11-09 00:00:00	53604828	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:07:50.483	2026-02-12 16:07:50.483
204	Delfina	Mansilla	2013-03-01 00:00:00	53047644	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:07:50.666	2026-02-12 16:07:50.666
205	Martina	Sanchez	2012-08-30 00:00:00	52676774	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:07:50.846	2026-02-12 16:07:50.846
206	Xiomara	Sanchez	2012-07-03 00:00:00	52426538	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:07:51.033	2026-02-12 16:07:51.033
207	Daiara	Ferreira	2013-02-02 00:00:00	52996695	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:12:41.632	2026-02-12 16:12:41.632
208	Ludmila	Bugliolo	2012-09-16 00:00:00	52713046	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:12:41.824	2026-02-12 16:12:41.824
209	Bianca	Sequeira	2011-09-24 00:00:00	51262829	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:14:28.179	2026-02-12 16:14:28.179
210	Bianca	Vielma	2011-03-31 00:00:00	50961788	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:14:28.368	2026-02-12 16:14:28.368
211	Nahiara	Vielma	2011-03-31 00:00:00	50961775	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:14:28.548	2026-02-12 16:14:28.548
212	Candela	Bravo	2009-08-11 00:00:00	49813771	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:41.893	2026-02-12 16:25:41.893
213	Lola Jazmin	Marfil	2010-10-08 00:00:00	50399282	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:42.089	2026-02-12 16:25:42.089
214	Morena	Ramirez	2010-05-09 00:00:00	50723911	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:42.293	2026-02-12 16:25:42.293
215	Umma	La Palma	2009-12-04 00:00:00	49920477	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:42.488	2026-02-12 16:25:42.488
216	Nayla	Santa Cruz	2009-02-27 00:00:00	49427303	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:42.675	2026-02-12 16:25:42.675
217	Ludmila	Torrez	2010-06-26 00:00:00	50648367	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:42.866	2026-02-12 16:25:42.866
218	Luna Naiara	Sena	2009-09-22 00:00:00	49833310	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:43.053	2026-02-12 16:25:43.053
219	Melany	Galvan	2010-02-23 00:00:00	50138984	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:43.282	2026-02-12 16:25:43.282
220	Antonella	Gomez	2009-04-06 00:00:00	52113200	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:25:43.472	2026-02-12 16:25:43.472
221	Kiara	Ramirez	2006-02-20 00:00:00	47120967	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:29:11.69	2026-02-12 16:29:11.69
222	Brisa	Rojas	2000-06-04 00:00:00	42682316	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:29:11.884	2026-02-12 16:29:11.884
223	Abigail	Zelaya	1997-10-03 00:00:00	43088987	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:29:12.075	2026-02-12 16:29:12.075
224	Leila	Allende	2003-10-26 00:00:00	45427253	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:29:12.276	2026-02-12 16:29:12.276
225	Rocio	Ayala	1986-06-21 00:00:00	94942215	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:12.986	2026-02-12 16:33:12.986
226	Johana	Jara	1991-07-17 00:00:00	95264303	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:13.174	2026-02-12 16:33:13.174
227	Natalia	Gonzalez	1992-05-07 00:00:00	36646808	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:13.359	2026-02-12 16:33:13.359
228	Cintia	Gaona	1994-07-24 00:00:00	40431538	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:13.539	2026-02-12 16:33:13.539
229	Mara	Romero	1995-02-28 00:00:00	38678278	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:13.719	2026-02-12 16:33:13.719
230	Mayra	Ibañez	1986-07-22 00:00:00	36426656	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:13.904	2026-02-12 16:33:13.904
231	Silvina	Maldonado	1986-05-18 00:00:00	32446019	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:14.087	2026-02-12 16:33:14.087
232	Juliana	Campos	1993-05-27 00:00:00	40663932	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:14.269	2026-02-12 16:33:14.269
233	Nancy	Alemandi	1987-11-25 00:00:00	33226599	FEMENINO	t	A	1	A	\N	\N	\N	2026-02-12 16:33:14.454	2026-02-12 16:33:14.454
234	Valentino Agustn	Orviz	2016-09-26 00:00:00	55805179	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 01:29:33.569	2026-02-13 01:29:33.569
235	Luz	Caceres	2019-09-08 00:00:00	57901643	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:51.619	2026-02-13 10:18:51.619
236	Alma Lucia	Blanco	2018-01-17 00:00:00	56781655	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:51.815	2026-02-13 10:18:51.815
237	Malena	Caudevila	2017-01-11 00:00:00	56076416	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.006	2026-02-13 10:18:52.006
238	Antonela	Blanco	2017-01-10 00:00:00	56048392	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.193	2026-02-13 10:18:52.193
239	Lola	Caudevila	2018-12-04 00:00:00	57394642	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.381	2026-02-13 10:18:52.381
240	Gianna	Merlo	2018-05-06 00:00:00	57080510	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.576	2026-02-13 10:18:52.576
241	Mora	Alsina	2020-06-27 00:00:00	58214634	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.764	2026-02-13 10:18:52.764
242	Oriana	Lucero	2018-03-21 00:00:00	56192387	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:52.958	2026-02-13 10:18:52.958
243	Elena	Blanco	2018-07-23 00:00:00	57242293	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:18:53.146	2026-02-13 10:18:53.146
244	Geraldine	Gonzalez	2015-07-27 00:00:00	54958676	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:22:27.542	2026-02-13 10:22:27.542
245	Abigail	Gorosito	2015-05-26 00:00:00	54822644	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:22:27.74	2026-02-13 10:22:27.74
246	Mia	Quintana	2015-07-03 00:00:00	54896892	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:22:27.93	2026-02-13 10:22:27.93
247	Natasha	Ojeda	2016-12-01 00:00:00	55953593	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:22:28.161	2026-02-13 10:22:28.161
248	Cielo	Camejo	2013-01-03 00:00:00	52918190	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:57.189	2026-02-13 10:28:57.189
249	Zoe	Rodriguez	2014-05-08 00:00:00	53994026	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:57.393	2026-02-13 10:28:57.393
250	Ambar	Silva	2014-07-11 00:00:00	54128560	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:57.592	2026-02-13 10:28:57.592
251	Maitena	Leguizamon	2014-01-23 00:00:00	53884794	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:57.773	2026-02-13 10:28:57.773
252	Samira	Saldivia	2014-09-07 00:00:00	54352091	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:57.954	2026-02-13 10:28:57.954
253	Milena	Gomez	2013-06-20 00:00:00	53283607	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:58.136	2026-02-13 10:28:58.136
254	Sofia	Oviedo	2013-02-18 00:00:00	52996653	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:58.321	2026-02-13 10:28:58.321
255	Francesca	Kovinchich	2014-10-23 00:00:00	54352034	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:58.508	2026-02-13 10:28:58.508
256	Mailen	Diamela	2013-03-11 00:00:00	53137868	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:58.738	2026-02-13 10:28:58.738
257	Sofia	Medina	2014-12-05 00:00:00	54346269	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:58.923	2026-02-13 10:28:58.923
259	Luana Luz	Aliano	2013-10-02 00:00:00	53532876	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:59.343	2026-02-13 10:28:59.343
260	Iara	Bustamante	2013-04-04 00:00:00	53131211	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:59.558	2026-02-13 10:28:59.558
258	Mia	Rodriguez	2014-05-01 00:00:00	53897051	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:28:59.124	2026-02-13 10:31:09.024
261	Milena	Cardozo	2008-09-15 00:00:00	49057750	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.033	2026-02-13 10:34:37.033
262	Daniela	Martinez	1997-09-29 00:00:00	40652703	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.228	2026-02-13 10:34:37.228
263	Gabriela	Martinez	2002-02-17 00:00:00	23900804	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.408	2026-02-13 10:34:37.408
264	Luciana	Juarez	2005-12-14 00:00:00	47184105	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.589	2026-02-13 10:34:37.589
265	Beatriz	Juarez	2004-09-09 00:00:00	46087529	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.789	2026-02-13 10:34:37.789
266	Juliana	Gria	2008-06-18 00:00:00	48850172	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:37.97	2026-02-13 10:34:37.97
267	Julieta	Morales	1999-05-15 00:00:00	19087984	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:38.151	2026-02-13 10:34:38.151
268	Brisa	Gallegos	2000-04-07 00:00:00	43671475	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:34:38.328	2026-02-13 10:34:38.328
269	Rosario	Socci	2014-06-06 00:00:00	53986116	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:57.315	2026-02-13 10:45:57.315
272	Morena Samantha	Zacarias	2014-03-05 00:00:00	53896407	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:57.893	2026-02-13 10:45:57.893
273	Mia Eugenia	Juarez	2013-02-24 00:00:00	53457265	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:58.075	2026-02-13 10:45:58.075
274	Keila	Rodriguez	2014-03-25 00:00:00	54127008	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:58.278	2026-02-13 10:45:58.278
275	Jazmin	Ramirez	2014-11-21 00:00:00	54420779	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:58.46	2026-02-13 10:45:58.46
276	Bianca	Lopez	2016-04-03 00:00:00	55439870	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:58.646	2026-02-13 10:45:58.646
277	Sofia	Nuñez	2016-01-01 00:00:00	55278426	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:58.827	2026-02-13 10:45:58.827
278	Mia Bianca	Cisterna	2015-06-30 00:00:00	54915262	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:59.013	2026-02-13 10:45:59.013
279	Luz	Luque	2015-05-21 00:00:00	54818829	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:59.206	2026-02-13 10:45:59.206
280	Geraldine	Jara	2015-07-10 00:00:00	54877097	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:59.389	2026-02-13 10:45:59.389
281	Hector Hugo	Orviz	1988-01-28 00:00:00	33717766	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 11:42:58.775	2026-02-13 11:42:58.775
282	Luana	Magallanes	2009-05-12 00:00:00	50486502	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:31:36.354	2026-02-13 14:31:36.354
283	Morena	Ochoa	2009-09-10 00:00:00	49730118	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:31:36.542	2026-02-13 14:31:36.542
284	Ayelen	Cabezas	2009-07-06 00:00:00	46667818	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:31:36.721	2026-02-13 14:31:36.721
285	Iris Camila	Orviz	2009-03-04 00:00:00	49427368	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:35:44.444	2026-02-13 14:35:44.444
286	Zamira	Montecinos	2009-07-15 00:00:00	49671726	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:42:09.577	2026-02-13 14:42:09.577
287	Ambar	Consillas	2019-11-04 00:00:00	57977120	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:47.351	2026-02-13 14:46:47.351
288	Bianca	Diarte	2017-04-18 00:00:00	56341713	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:47.537	2026-02-13 14:46:47.537
289	Emma	Acosta	2017-06-06 00:00:00	56354049	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:47.719	2026-02-13 14:46:47.719
290	Isabella	Bornia	2017-05-06 00:00:00	56248882	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:47.921	2026-02-13 14:46:47.921
291	Nadia	Gamarra	2020-09-07 00:00:00	58519709	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:48.108	2026-02-13 14:46:48.108
293	Valentina	Correa	2020-02-08 00:00:00	58717241	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:48.47	2026-02-13 14:46:48.47
294	Alma	Padilla	2019-11-25 00:00:00	57981205	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:48.656	2026-02-13 14:46:48.656
295	Sofia	Calderone	2015-01-08 00:00:00	54517244	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:12.822	2026-02-13 14:51:12.822
296	Morena	Aguilar	2015-01-31 00:00:00	54531272	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.005	2026-02-13 14:51:13.005
297	Giuliana	Sosa	2015-03-29 00:00:00	54729548	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.187	2026-02-13 14:51:13.187
298	Nahiara	Faccio	2015-01-12 00:00:00	54531229	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.372	2026-02-13 14:51:13.372
299	Zoe	Mancuello	2015-09-22 00:00:00	55038884	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.554	2026-02-13 14:51:13.554
270	Aylen	Coronel	2013-07-23 00:00:00	53291089	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:57.503	2026-02-14 12:39:53.035
300	Maitena	Diarte	2015-02-14 00:00:00	54729521	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.737	2026-02-13 14:51:13.737
301	Reyna	Rodriguez	2015-01-20 00:00:00	54604613	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:13.92	2026-02-13 14:51:13.92
302	Mia	Nuñez	2016-09-09 00:00:00	55680588	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:14.104	2026-02-13 14:51:14.104
303	Renata	Fernandez	2016-07-21 00:00:00	55666589	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:14.286	2026-02-13 14:51:14.286
304	Fiorelle	Gamarra	2016-08-17 00:00:00	55727483	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:14.47	2026-02-13 14:51:14.47
305	Alma	Rodriguez	2016-07-22 00:00:00	55740571	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:51:14.654	2026-02-13 14:51:14.654
292	Victoria	Rodriguez	2018-08-25 00:00:00	57288810	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 14:46:48.288	2026-02-13 14:55:39.548
306	Paloma	Ibarra	2013-12-14 00:00:00	53718508	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:22.567	2026-02-13 15:03:22.567
307	Jazmin	Sosa	2013-08-11 00:00:00	53436732	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:22.755	2026-02-13 15:03:22.755
308	Zoe	Romero	2014-04-05 00:00:00	53880904	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:22.937	2026-02-13 15:03:22.937
309	Milena	Montes	2014-03-21 00:00:00	53876549	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:23.121	2026-02-13 15:03:23.121
310	Luciana	Fantasia	2013-01-20 00:00:00	52929499	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:23.303	2026-02-13 15:03:23.303
311	Steffi	Sosa	2013-05-25 00:00:00	53213239	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:23.491	2026-02-13 15:03:23.491
312	Agostina	Isla	2014-10-16 00:00:00	54343678	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:23.671	2026-02-13 15:03:23.671
313	Francia Elena	Glock	2013-06-29 00:00:00	53199700	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:03:23.861	2026-02-13 15:03:23.861
314	Aylen	Soliño	2011-06-08 00:00:00	50971902	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:51.032	2026-02-13 15:08:51.032
315	Malena	Arevalo	2011-02-16 00:00:00	50879383	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:51.237	2026-02-13 15:08:51.237
316	Alma	Vega	2011-02-18 00:00:00	50961563	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:51.43	2026-02-13 15:08:51.43
317	Tamara	Figueroa	2011-11-29 00:00:00	51494685	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:51.624	2026-02-13 15:08:51.624
318	Briana	Ponce	2012-11-08 00:00:00	50961629	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:51.811	2026-02-13 15:08:51.811
319	Damaris	Ponce	2012-11-08 00:00:00	53334261	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:52.003	2026-02-13 15:08:52.003
320	Nahiara	Ibarra	2012-03-27 00:00:00	52421477	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:52.188	2026-02-13 15:08:52.188
321	Maria Sol	Paez	2012-03-15 00:00:00	52392831	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:52.375	2026-02-13 15:08:52.375
322	Bianca	Carrizo	2011-04-05 00:00:00	50264116	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:52.564	2026-02-13 15:08:52.564
323	Isis Agustina	Serpa	2011-12-29 00:00:00	52393915	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:08:52.755	2026-02-13 15:08:52.755
324	Nicole	Arrieta	2009-04-30 00:00:00	50265531	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.032	2026-02-13 15:17:00.032
325	Morena	Coronel	2009-10-04 00:00:00	49811940	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.225	2026-02-13 15:17:00.225
326	Angela	Fantasia	2010-06-06 00:00:00	50356022	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.412	2026-02-13 15:17:00.412
327	Danqe	Martinez	2010-07-08 00:00:00	50356107	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.605	2026-02-13 15:17:00.605
328	Zaira	Segovia	2009-10-22 00:00:00	49893500	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.798	2026-02-13 15:17:00.798
329	Sashara	Segovia	2010-01-10 00:00:00	51253209	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:17:00.988	2026-02-13 15:17:00.988
330	Sol	Arkuszyn	2008-01-16 00:00:00	48232147	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:52.962	2026-02-13 15:22:52.962
331	Antonella	Isla	2003-11-20 00:00:00	45307704	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:53.16	2026-02-13 15:22:53.16
332	Brenda	Miranda	2007-08-27 00:00:00	48307606	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:53.378	2026-02-13 15:22:53.378
333	Natalia	Miño	1998-03-11 00:00:00	41569969	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:53.577	2026-02-13 15:22:53.577
334	Ruth	Salcedo	1998-06-23 00:00:00	41292601	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:53.766	2026-02-13 15:22:53.766
335	Karen	Aquino	2000-08-16 00:00:00	42589275	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:53.974	2026-02-13 15:22:53.974
336	Camila	Fernandez	1999-01-01 00:00:00	41685931	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:54.193	2026-02-13 15:22:54.193
337	Araceli	Heredia	2007-01-26 00:00:00	47864925	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:54.396	2026-02-13 15:22:54.396
338	Evelyn	Gimenez	1998-02-01 00:00:00	45307849	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:54.587	2026-02-13 15:22:54.587
339	Micaela	Sosa	1997-06-21 00:00:00	40567288	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:54.777	2026-02-13 15:22:54.777
340	Anabelen	Paz	2007-06-04 00:00:00	49940749	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:54.972	2026-02-13 15:22:54.972
341	Milagros	Saliño	2000-11-15 00:00:00	43021686	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:55.194	2026-02-13 15:22:55.194
342	Oriana	Contrera	2006-03-25 00:00:00	47183313	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:22:55.381	2026-02-13 15:22:55.381
343	Analia	Maza	1991-09-01 00:00:00	37688580	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:37.264	2026-02-13 15:38:37.264
344	Debora	Mansilla	1991-12-17 00:00:00	36646015	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:37.45	2026-02-13 15:38:37.45
345	Nadia	Aquino	1988-05-31 00:00:00	33862195	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:37.627	2026-02-13 15:38:37.627
346	Melany	Nuñez	1994-05-10 00:00:00	46641882	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:37.813	2026-02-13 15:38:37.813
347	Roxana	Aquino	1994-07-06 00:00:00	38301890	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:37.991	2026-02-13 15:38:37.991
348	Jimena	Ibarra	1988-06-23 00:00:00	33873514	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:38.175	2026-02-13 15:38:38.175
349	Julia	Fernandez	1983-08-24 00:00:00	30413310	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:38.357	2026-02-13 15:38:38.357
350	Estefania	Francia	1994-10-16 00:00:00	38554248	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:38.582	2026-02-13 15:38:38.582
351	Claudia	Lespade	1975-04-26 00:00:00	24698071	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:38.758	2026-02-13 15:38:38.758
352	Viviana	Huanca	1978-12-02 00:00:00	94541443	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:38.977	2026-02-13 15:38:38.977
353	Tamara	Ramirez	1996-12-11 00:00:00	40884401	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:39.161	2026-02-13 15:38:39.161
354	Angela	Bravo	1978-05-07 00:00:00	26599458	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:39.341	2026-02-13 15:38:39.341
355	Rocio	Coronel	1990-08-16 00:00:00	35539105	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:39.534	2026-02-13 15:38:39.534
356	Liliana	Ortiz	1983-08-23 00:00:00	30443612	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 15:38:39.712	2026-02-13 15:38:39.712
357	Priscila	Mozon	2010-01-27 00:00:00	50684454	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 16:03:12.004	2026-02-13 16:03:12.004
271	Micaela	Martinez	2013-04-05 00:00:00	53050986	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-13 10:45:57.687	2026-02-14 12:40:03.005
358	Nicole	Martinez	2013-10-28 00:00:00	53521382	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:39:17.78	2026-02-14 13:39:17.78
359	Milagors	Estigariba	2014-04-07 00:00:00	53888221	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:41:05.399	2026-02-14 13:41:05.399
360	Julieta	Lemos	2014-08-16 00:00:00	54269250	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:41:05.705	2026-02-14 13:41:05.705
361	Tani	Dominguez	2014-07-06 00:00:00	54006226	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:41:05.896	2026-02-14 13:41:05.896
362	Angela	Fantasia	2010-06-06 00:00:00	50354022	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:48.632	2026-02-14 13:44:48.632
363	Xiomara	Coria	2010-12-30 00:00:00	50776086	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:48.831	2026-02-14 13:44:48.831
365	Abril	Alfonso	2009-11-09 00:00:00	49890252	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:49.248	2026-02-14 13:44:49.248
366	Malena	Gonzalez	2010-05-24 00:00:00	50304125	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:49.446	2026-02-14 13:44:49.446
367	Milena	Mazzuca	2010-09-24 00:00:00	50761723	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:49.648	2026-02-14 13:44:49.648
368	Silvina	Toledo	2006-04-23 00:00:00	47256869	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:14.194	2026-02-14 13:54:14.194
369	Brenda	Luque	2003-01-17 00:00:00	44669513	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:14.392	2026-02-14 13:54:14.392
370	Gladys	Sacaca	1997-12-28 00:00:00	95051239	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:14.578	2026-02-14 13:54:14.578
371	Brisa	Garcia	1999-01-20 00:00:00	41671851	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:14.884	2026-02-14 13:54:14.884
372	Nahiara	Magallanes	2007-03-06 00:00:00	48286574	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:15.241	2026-02-14 13:54:15.241
373	Xiomara	Caceres	2008-07-10 00:00:00	48848109	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:15.442	2026-02-14 13:54:15.442
374	Nahiara	Gutierrez	2005-07-03 00:00:00	46894595	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:54:15.624	2026-02-14 13:54:15.624
375	Milena	Tevez	2011-07-08 00:00:00	51157809	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:07.896	2026-02-14 14:00:07.896
376	Julieta	Britez	2011-08-01 00:00:00	51225857	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:08.182	2026-02-14 14:00:08.182
377	Priscila	Santillan	2011-11-22 00:00:00	51457829	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:08.52	2026-02-14 14:00:08.52
378	Martina	Frias	2012-01-28 00:00:00	52088359	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:08.875	2026-02-14 14:00:08.875
380	Julieta	Benitez	2011-03-10 00:00:00	50961598	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:09.296	2026-02-14 14:00:09.296
381	Micaela	Ramirez	2012-06-17 00:00:00	52604691	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:09.492	2026-02-14 14:00:09.492
382	Melina	Caran	2012-03-25 00:00:00	52592584	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:02:33.178	2026-02-14 14:02:33.178
383	Francesca	Rodriguez	2015-11-19 00:00:00	55195412	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:05:48.479	2026-02-14 14:05:48.479
384	Madelen	Ibarra	2010-04-05 00:00:00	55505220	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:05:48.663	2026-02-14 14:05:48.663
385	Daiana	Aguirre	2016-07-17 00:00:00	56041094	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:05:48.844	2026-02-14 14:05:48.844
386	Renata	Almiron	2016-11-04 00:00:00	55884557	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:05:49.044	2026-02-14 14:05:49.044
387	Francesca	Fuch	2014-04-14 00:00:00	57626942	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:57.972	2026-02-14 14:12:57.972
389	Andelina	Lencina	2017-07-05 00:00:00	56402151	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:58.366	2026-02-14 14:12:58.366
390	Delfina	Lauria Lopez	2017-08-28 00:00:00	56507206	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:58.559	2026-02-14 14:12:58.559
391	Lara	Astrada	2017-07-15 00:00:00	56493607	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:58.749	2026-02-14 14:12:58.749
392	Maia	Saldivia	2017-07-01 00:00:00	56499351	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:58.933	2026-02-14 14:12:58.933
393	Francesca	Hidalgo	2017-04-03 00:00:00	56341607	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:59.128	2026-02-14 14:12:59.128
394	Sol Milagros	Perina	2017-02-23 00:00:00	56186029	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:59.316	2026-02-14 14:12:59.316
395	Athenea	Reinozo	2019-04-04 00:00:00	57667402	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:59.499	2026-02-14 14:12:59.499
396	Constanza	Reinozo	2019-04-04 00:00:00	57667403	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:59.698	2026-02-14 14:12:59.698
397	Martina	Olmedo	2018-06-15 00:00:00	57089379	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:59.981	2026-02-14 14:12:59.981
398	Keila	Jara	2017-04-14 00:00:00	56250154	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:13:00.182	2026-02-14 14:13:00.182
399	Yanina	Estigarribiar	1994-06-15 00:00:00	38192728	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:26:19.349	2026-02-14 14:26:19.349
400	Daiana	Ibañez	1995-11-22 00:00:00	39283906	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:26:19.679	2026-02-14 14:26:19.679
401	Cecilia	Mereno	1996-09-12 00:00:00	40340662	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:26:19.971	2026-02-14 14:26:19.971
402	Raquel	Sanchez	1978-08-16 00:00:00	26773338	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:26:20.263	2026-02-14 14:26:20.263
403	Isabella	Romero	2017-01-18 00:00:00	56048408	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:51.765	2026-02-14 15:14:51.765
404	Paula	Croceth	2017-07-05 00:00:00	56405096	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:51.949	2026-02-14 15:14:51.949
405	Morena	Soria	2017-12-05 00:00:00	56712314	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:52.13	2026-02-14 15:14:52.13
406	Zoe	Villafañe	2017-10-28 00:00:00	56626734	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:52.314	2026-02-14 15:14:52.314
407	Lucia	Castro	2017-01-29 00:00:00	56121401	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:52.496	2026-02-14 15:14:52.496
408	Ambar	Farias	2017-02-12 00:00:00	56858080	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:52.68	2026-02-14 15:14:52.68
409	Morena	Gimenez	2019-11-18 00:00:00	57981473	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:14:52.862	2026-02-14 15:14:52.862
410	Priscila	Rodriguez	2014-07-11 00:00:00	54128548	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:45.981	2026-02-14 15:25:45.981
411	Pilar	Da Silva	2015-11-09 00:00:00	55262814	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:46.181	2026-02-14 15:25:46.181
412	Isabella	Figueroa	2015-06-17 00:00:00	54898627	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:46.379	2026-02-14 15:25:46.379
413	Maria	Crocetti	2015-04-24 00:00:00	54942297	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:46.565	2026-02-14 15:25:46.565
414	Lucia	Rodriguez	2015-02-27 00:00:00	54657441	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:46.96	2026-02-14 15:25:46.96
415	Sofia	Rodriguez	2015-08-24 00:00:00	54968183	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:47.272	2026-02-14 15:25:47.272
416	Nayla	Ordoñez	2015-04-17 00:00:00	54729669	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:47.63	2026-02-14 15:25:47.63
417	Renata	Rivero	2016-02-05 00:00:00	55338458	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:47.998	2026-02-14 15:25:47.998
418	Lola	Vargas	2015-08-30 00:00:00	55038706	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:48.309	2026-02-14 15:25:48.309
419	Ahinara	Ruiz	2016-04-11 00:00:00	55505266	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:25:48.606	2026-02-14 15:25:48.606
420	Thais	Sosa	2013-05-29 00:00:00	53213290	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:25.683	2026-02-14 15:28:25.683
421	Alma	Avendaño	2014-06-17 00:00:00	54063132	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:26.014	2026-02-14 15:28:26.014
422	Martina	Chavez	2013-04-08 00:00:00	53131258	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:26.318	2026-02-14 15:28:26.318
423	Martina	Da Silva	2013-01-02 00:00:00	52981035	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:26.628	2026-02-14 15:28:26.628
424	Dana	Chavez	2014-01-20 00:00:00	53748123	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:26.936	2026-02-14 15:28:26.936
425	Florencia	Perez	2014-09-23 00:00:00	54275621	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:28:27.256	2026-02-14 15:28:27.256
426	Ariana	Juarez	2011-01-21 00:00:00	50784156	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:26.543	2026-02-14 15:32:26.543
427	Zaida	Fromiwisz	2011-06-23 00:00:00	51158113	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:26.867	2026-02-14 15:32:26.867
428	Valentina	Bravo	2012-09-20 00:00:00	52823319	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:27.194	2026-02-14 15:32:27.194
429	Nerea	Ortiz	2012-04-26 00:00:00	52288208	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:27.542	2026-02-14 15:32:27.542
430	Cielo	Rodriguez	2012-02-19 00:00:00	52163157	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:27.836	2026-02-14 15:32:27.836
431	Florencia	Cacerez	2011-06-08 00:00:00	51160621	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:32:28.173	2026-02-14 15:32:28.173
432	Abigail	Gonzalez	2006-06-19 00:00:00	55264871	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:19.665	2026-02-14 15:39:19.665
434	Jennifer	Marquez	1999-04-14 00:00:00	41722575	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.048	2026-02-14 15:39:20.048
435	Leila	Posada	2007-11-01 00:00:00	47789763	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.233	2026-02-14 15:39:20.233
436	Diega	Gonzalez	2005-07-14 00:00:00	46894419	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.43	2026-02-14 15:39:20.43
437	Julieta	Rodriguez	2004-12-24 00:00:00	46089474	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.614	2026-02-14 15:39:20.614
438	Magali	Garay	2007-07-27 00:00:00	48161675	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.8	2026-02-14 15:39:20.8
439	Yazmin	Cabeza	1998-05-10 00:00:00	42493772	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:20.982	2026-02-14 15:39:20.982
440	Adriana	Ledesma	1989-01-21 00:00:00	34227681	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:49.793	2026-02-14 16:17:49.793
441	Gabriela	Perello	1989-01-23 00:00:00	34227646	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:50.125	2026-02-14 16:17:50.125
442	Taria	Baltaceda	1981-03-16 00:00:00	28150697	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:50.31	2026-02-14 16:17:50.31
443	Gisela	Oroñez	1988-06-28 00:00:00	33909689	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:50.636	2026-02-14 16:17:50.636
444	Jesica	Baltaceda	1988-07-31 00:00:00	34760123	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:50.925	2026-02-14 16:17:50.925
445	Gisela	Lucero	1993-04-30 00:00:00	37605713	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 16:17:51.295	2026-02-14 16:17:51.295
446	Renata	Sanchez	2019-02-05 00:00:00	57548768	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:56.572	2026-02-14 17:06:56.572
447	Mia	Escobar	2016-08-30 00:00:00	55801730	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:56.919	2026-02-14 17:06:56.919
448	Yazmin	Sosa	2015-06-17 00:00:00	54832673	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:57.196	2026-02-14 17:06:57.196
449	Ludmila	Sosa	2015-06-17 00:00:00	54832674	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:57.395	2026-02-14 17:06:57.395
379	Maites	Ochoa	2011-12-10 00:00:00	50889329	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:00:09.095	2026-02-28 22:17:35.845
388	Emma	Rubin	2017-02-13 00:00:00	56112350	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 14:12:58.18	2026-03-22 19:19:58.511
450	Zoe	Sosa	2015-10-11 00:00:00	55034576	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:57.589	2026-02-14 17:06:57.589
451	Brianna	Martinez	2015-11-28 00:00:00	54420755	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:57.79	2026-02-14 17:06:57.79
452	Luzmila	Bianco	2015-12-24 00:00:00	55325289	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:06:57.974	2026-02-14 17:06:57.974
453	Kiara	Acuña	2013-06-13 00:00:00	53284863	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:04.967	2026-02-14 17:12:04.967
454	Jocelyn	Peralta	2013-06-13 00:00:00	53284871	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:05.18	2026-02-14 17:12:05.18
455	Maia	Larrosa	2013-06-28 00:00:00	53376406	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:05.382	2026-02-14 17:12:05.382
456	Julieta	Mansilla	2012-02-16 00:00:00	52113193	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:05.582	2026-02-14 17:12:05.582
457	Denise	Mansilla	2011-04-14 00:00:00	50961991	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:05.779	2026-02-14 17:12:05.779
458	Deni	Villagra	2011-09-05 00:00:00	51271877	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:05.964	2026-02-14 17:12:05.964
459	Salma	Ponte	2012-03-13 00:00:00	52392881	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:06.162	2026-02-14 17:12:06.162
460	Dulce	Garcia	2012-07-14 00:00:00	52481794	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:06.345	2026-02-14 17:12:06.345
462	Nahiara	Rodriguez	2011-06-18 00:00:00	52591901	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:06.731	2026-02-14 17:12:06.731
463	Valentina	Mendoza	2011-10-23 00:00:00	51453547	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:06.93	2026-02-14 17:12:06.93
464	Antonela	Ramirez	2010-06-01 00:00:00	50364679	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:46.983	2026-02-14 17:18:46.983
465	Mayte	Herrera	2009-10-17 00:00:00	49920343	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:48.939	2026-02-14 17:18:48.939
466	Zaira	Lauzovitch	2009-08-27 00:00:00	49826952	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:49.858	2026-02-14 17:18:49.858
467	Maitena	Espinola	2009-04-17 00:00:00	49517949	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:50.699	2026-02-14 17:18:50.699
468	Debora	Batista	2009-10-27 00:00:00	49878526	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:51.921	2026-02-14 17:18:51.921
469	Nicole	Ibañez	2010-09-09 00:00:00	50648217	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:52.217	2026-02-14 17:18:52.217
470	Sharon	Portillo	2010-08-04 00:00:00	50356117	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:52.635	2026-02-14 17:18:52.635
471	Maia	Viviane	2009-12-10 00:00:00	49936038	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:53.561	2026-02-14 17:18:53.561
472	Antonela	Pereyra	2010-02-05 00:00:00	50011986	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:53.793	2026-02-14 17:18:53.793
473	Keila	Escarlon	2010-10-03 00:00:00	50648329	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:54.582	2026-02-14 17:18:54.582
474	Geraldine	Prieto	2010-11-27 00:00:00	50673179	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:54.937	2026-02-14 17:18:54.937
475	Candela	Paz	2010-03-04 00:00:00	55513726	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:55.899	2026-02-14 17:18:55.899
476	Alma	Gomez	2010-08-16 00:00:00	50228531	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:18:56.134	2026-02-14 17:18:56.134
477	Enriqueta	Rodriguez	2001-06-05 00:00:00	43350809	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.048	2026-02-14 17:23:45.048
478	Magali	Gerez	2002-05-20 00:00:00	44171459	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.231	2026-02-14 17:23:45.231
479	Antonella	Lobo	2007-12-18 00:00:00	50736882	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.416	2026-02-14 17:23:45.416
480	Yamila	Paifer	1997-09-28 00:00:00	40671742	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.596	2026-02-14 17:23:45.596
481	Veronica	Giri	1978-03-04 00:00:00	26532752	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.782	2026-02-14 17:23:45.782
482	Rocio	Nuñez	1995-05-14 00:00:00	38845861	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:45.964	2026-02-14 17:23:45.964
483	Karina	Pereyra	1994-09-25 00:00:00	38526388	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:46.146	2026-02-14 17:23:46.146
485	Valeria	Vielma	1992-08-21 00:00:00	36770837	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:46.531	2026-02-14 17:23:46.531
486	Jimena	Alegre	1986-04-07 00:00:00	34251298	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:46.716	2026-02-14 17:23:46.716
487	Nicol	Decima	2009-04-23 00:00:00	54532341	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:12.211	2026-02-14 19:29:12.211
488	Luana	Quintero	2009-06-01 00:00:00	50784041	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:12.608	2026-02-14 19:29:12.608
489	Zoe	Rodriguez	2009-01-28 00:00:00	49230977	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:12.971	2026-02-14 19:29:12.971
490	Bianca	Godoy	2010-05-30 00:00:00	54876673	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:13.281	2026-02-14 19:29:13.281
491	Guadalupe	Martinez	2010-07-08 00:00:00	50856069	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:13.586	2026-02-14 19:29:13.586
492	Nerea	Martinez	2010-07-08 00:00:00	50356068	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:13.909	2026-02-14 19:29:13.909
493	Magali	Fretes	2009-08-22 00:00:00	49724844	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 19:29:14.125	2026-02-14 19:29:14.125
494	Nereo	Gomez	2017-09-28 00:00:00	56558671	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:18.766	2026-02-14 23:43:18.766
495	Benicio	Perez	2017-03-10 00:00:00	56261257	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:18.981	2026-02-14 23:43:18.981
496	Gustavo	Ojeda	2017-04-13 00:00:00	56255283	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:19.309	2026-02-14 23:43:19.309
497	Timoteo	Paez	2017-07-12 00:00:00	56405163	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:19.532	2026-02-14 23:43:19.532
498	Julian	Diaz	2017-02-05 00:00:00	56121459	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:19.748	2026-02-14 23:43:19.748
499	Benicio	Rodriguez	2017-01-13 00:00:00	56029188	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:19.982	2026-02-14 23:43:19.982
500	Gian	Jimenez	2017-05-05 00:00:00	56349637	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:20.374	2026-02-14 23:43:20.374
501	Amadeo	Oliva	2017-01-10 00:00:00	56041045	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:20.847	2026-02-14 23:43:20.847
502	Isaac	Arriola	2017-01-09 00:00:00	56033998	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:21.311	2026-02-14 23:43:21.311
503	Mariano	Gomez	2017-04-06 00:00:00	56255022	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:21.601	2026-02-14 23:43:21.601
504	Daniel	Lopez	2017-09-10 00:00:00	56508095	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 23:43:22.027	2026-02-14 23:43:22.027
505	Blass	Osuna	2017-05-13 00:00:00	56261363	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.038	2026-02-15 00:53:05.038
506	Giovannni	Perez	2017-10-30 00:00:00	56000001	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.24	2026-02-15 00:53:05.24
507	Benjamin	Noah	2017-02-06 00:00:00	56000002	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.425	2026-02-15 00:53:05.425
508	Lian	Romero	2017-01-14 00:00:00	56000003	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.607	2026-02-15 00:53:05.607
509	Ulises	Videla	2017-04-17 00:00:00	56000004	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.789	2026-02-15 00:53:05.789
510	Joaquin	Suarez	2017-03-04 00:00:00	56000005	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:05.986	2026-02-15 00:53:05.986
511	Santino	Diaz	2017-01-01 00:00:00	56000006	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 00:53:06.174	2026-02-15 00:53:06.174
512	Elian	Cardozo	2014-10-23 00:00:00	54270351	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:42.777	2026-02-15 01:03:42.777
513	Uriel	Paredes	2014-10-16 00:00:00	54343525	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:43.08	2026-02-15 01:03:43.08
514	Thiago	Alderete	2014-02-02 00:00:00	53593742	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:43.371	2026-02-15 01:03:43.371
515	Ayrton	Cusi	2014-11-26 00:00:00	54270240	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:43.656	2026-02-15 01:03:43.656
516	Bastian	Chacoma	2014-08-25 00:00:00	54269217	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:43.936	2026-02-15 01:03:43.936
517	Santino	Dias	2014-05-11 00:00:00	53884796	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:44.224	2026-02-15 01:03:44.224
518	Tiziano	Andino	2014-01-06 00:00:00	53740685	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:44.509	2026-02-15 01:03:44.509
519	Tahiel	Jaita	2014-01-04 00:00:00	53694941	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:44.834	2026-02-15 01:03:44.834
520	Ezequiel	Silvera	2014-03-21 00:00:00	53763179	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:45.021	2026-02-15 01:03:45.021
521	Bautista	Costa	2014-09-10 00:00:00	54222157	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:45.229	2026-02-15 01:03:45.229
522	Dylan	Acuña	2014-05-17 00:00:00	53994140	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:45.557	2026-02-15 01:03:45.557
523	Facundo	Melo	2014-01-13 00:00:00	53748020	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:45.975	2026-02-15 01:03:45.975
524	Dias	Ruis	2014-06-26 00:00:00	54224604	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:46.361	2026-02-15 01:03:46.361
525	Gonzalo	Frias	2014-05-25 00:00:00	54096388	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:46.726	2026-02-15 01:03:46.726
484	Andrea	Tarroza	1993-08-20 00:00:00	37281869	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:23:46.345	2026-02-28 21:57:28.91
526	Ignacio	Vallejos	2014-03-17 00:00:00	53676512	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:03:47.106	2026-02-15 01:03:47.106
527	Ignacio	Gimenez	2013-10-21 00:00:00	53523615	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:32.823	2026-02-15 01:12:32.823
528	Ciro	Gonzalez	2013-06-27 00:00:00	53294553	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:33.141	2026-02-15 01:12:33.141
529	Bautista	Urquiza	2013-10-15 00:00:00	53521289	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:33.363	2026-02-15 01:12:33.363
530	Ciro	Benitez	2013-10-20 00:00:00	53521321	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:33.559	2026-02-15 01:12:33.559
531	Brandon	Maidana	2013-09-05 00:00:00	53446472	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:33.758	2026-02-15 01:12:33.758
532	Francesco	Ocho	2013-02-20 00:00:00	53049825	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 01:12:33.96	2026-02-15 01:12:33.96
533	Francesco	Ochoa	2013-02-20 00:00:00	53059825	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:17.242	2026-02-15 23:16:17.242
534	Eitan	Gutierrez	2013-11-04 00:00:00	53588336	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:17.455	2026-02-15 23:16:17.455
535	Alex	Carballo	2014-07-07 00:00:00	54135507	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:17.655	2026-02-15 23:16:17.655
536	Alejandro	Luna	2013-03-05 00:00:00	52994814	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:17.839	2026-02-15 23:16:17.839
537	Matias	Cabrera	2013-09-19 00:00:00	53515994	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:18.022	2026-02-15 23:16:18.022
538	Franco	Arzamendia	2013-06-11 00:00:00	53369167	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:18.205	2026-02-15 23:16:18.205
539	Ian	Garcia	2013-09-26 00:00:00	53457434	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:16:18.388	2026-02-15 23:16:18.388
540	Bruno	De Moraiz	2018-09-30 00:00:00	57397456	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:20.79	2026-02-15 23:21:20.79
541	Luciano	Aguirrez	2018-01-25 00:00:00	56792333	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:20.985	2026-02-15 23:21:20.985
542	Aaron	Romero	2018-01-04 00:00:00	56851563	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:21.171	2026-02-15 23:21:21.171
543	Tiziano	Velazquez	2018-03-26 00:00:00	56935425	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:21.355	2026-02-15 23:21:21.355
544	Matheo	Ponce	2018-04-16 00:00:00	56938565	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:21.54	2026-02-15 23:21:21.54
545	Felipe	Duarte	2018-09-05 00:00:00	57254622	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:21.853	2026-02-15 23:21:21.853
546	Bautista	Gutierrez	2018-11-07 00:00:00	57316113	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:21:22.103	2026-02-15 23:21:22.103
547	Giovanni	Perez	2021-01-11 00:00:00	58657027	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:33.877	2026-02-15 23:26:33.877
548	Valentino	Cejas	2021-10-22 00:00:00	58625917	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:34.208	2026-02-15 23:26:34.208
549	Nahiel	Monzon	2020-07-10 00:00:00	58372149	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:34.393	2026-02-15 23:26:34.393
550	Enzo	Juarez	2020-05-27 00:00:00	58214679	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:34.589	2026-02-15 23:26:34.589
551	Tobias	Aguilar	2020-07-10 00:00:00	58215218	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:34.773	2026-02-15 23:26:34.773
552	Ramon	Equiles	2020-11-06 00:00:00	58513236	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:35.135	2026-02-15 23:26:35.135
553	Eithan	Figueroa	2020-04-27 00:00:00	58302151	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:26:35.325	2026-02-15 23:26:35.325
554	Thiago	Zurita	2020-01-28 00:00:00	58110916	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:28:09.592	2026-02-15 23:28:09.592
555	Lionel	Gonzalez	2021-06-14 00:00:00	58899102	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:28:09.777	2026-02-15 23:28:09.777
556	Aaron	Sequeira	2021-07-06 00:00:00	59010367	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:28:09.981	2026-02-15 23:28:09.981
557	Giovanni	Arias	2020-06-12 00:00:00	58452910	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:28:10.181	2026-02-15 23:28:10.181
558	Cristian	Hidalgo	2020-02-18 00:00:00	58199600	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:28:10.375	2026-02-15 23:28:10.375
559	Lehian	Gomez	2019-01-21 00:00:00	57544237	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:07.311	2026-02-15 23:35:07.311
560	Maximo	Biandayoli	2019-01-22 00:00:00	57548679	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:07.561	2026-02-15 23:35:07.561
561	Giovanni	Bernal	2019-05-01 00:00:00	57662096	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:07.741	2026-02-15 23:35:07.741
562	Santino	Nuñez	2019-12-02 00:00:00	58135099	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:07.927	2026-02-15 23:35:07.927
563	Ramiro	Aguirrez	2019-04-28 00:00:00	57668677	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:08.112	2026-02-15 23:35:08.112
564	Jeronimo	Goncebatt	2019-01-30 00:00:00	57551508	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:08.294	2026-02-15 23:35:08.294
565	Joaquin	Montenegro	2019-08-19 00:00:00	57849714	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-15 23:35:08.475	2026-02-15 23:35:08.475
566	Aron	Tejeda	2016-06-30 00:00:00	55668186	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:17.832	2026-02-18 10:18:17.832
567	Facundo	Perez	2015-03-29 00:00:00	54670263	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:18.024	2026-02-18 10:18:18.024
568	Benjamin	Perez	2015-06-22 00:00:00	54896708	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:18.212	2026-02-18 10:18:18.212
569	Mateo	Rodriguez	2015-10-26 00:00:00	55148549	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:18.435	2026-02-18 10:18:18.435
570	Thiago	Sayago	2015-07-16 00:00:00	54910498	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:18.638	2026-02-18 10:18:18.638
571	Jeremi	Heredia	2015-08-01 00:00:00	54970841	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:18.866	2026-02-18 10:18:18.866
572	Javier	Melo	2015-09-08 00:00:00	55034549	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:19.054	2026-02-18 10:18:19.054
573	Tihago	Montenegro	2016-02-13 00:00:00	55338535	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:19.246	2026-02-18 10:18:19.246
574	Ciro	Dominguez	2016-10-05 00:00:00	55565539	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:19.43	2026-02-18 10:18:19.43
575	Joan	Romero	2015-02-07 00:00:00	54958651	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:18:19.615	2026-02-18 10:18:19.615
576	Stefano	Reinoso	2016-07-10 00:00:00	55580826	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:36.834	2026-02-18 10:22:36.834
577	Tahiel	Lamas	2016-04-16 00:00:00	55488524	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.02	2026-02-18 10:22:37.02
578	Leonardo	Sosa	2016-03-06 00:00:00	55342708	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.206	2026-02-18 10:22:37.206
579	Ian	Cardozo	2016-05-01 00:00:00	55498249	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.399	2026-02-18 10:22:37.399
580	Dahiel	Aguilar	2016-08-02 00:00:00	55742230	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.586	2026-02-18 10:22:37.586
581	Christopher	Luque	2016-12-20 00:00:00	56041444	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.78	2026-02-18 10:22:37.78
582	Thobias	Cabezas	2016-07-22 00:00:00	55740545	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:22:37.967	2026-02-18 10:22:37.967
583	Enzo	Gutierrez	2016-02-07 00:00:00	55341013	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:25:06.142	2026-02-18 10:25:06.142
584	Jonas	Goncebatt	2016-02-29 00:00:00	55439725	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:25:06.334	2026-02-18 10:25:06.334
585	Joaquin	Suarez	2017-03-04 00:00:00	56199911	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:25:06.519	2026-02-18 10:25:06.519
586	Ulises	Videla	2017-04-17 00:00:00	56121095	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:25:06.705	2026-02-18 10:25:06.705
587	Alex	Vargas	2012-02-12 00:00:00	52125621	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:36.135	2026-02-18 10:31:36.135
588	Alexander	Gomez	2012-11-16 00:00:00	52608577	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:36.327	2026-02-18 10:31:36.327
589	Lian	Lencina	2012-04-06 00:00:00	52421402	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:36.512	2026-02-18 10:31:36.512
590	Thiago	Chacoma	2012-06-19 00:00:00	52621113	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:36.689	2026-02-18 10:31:36.689
591	Juan Pablo	Torija	2012-02-10 00:00:00	52791314	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:36.888	2026-02-18 10:31:36.888
592	Fabricio	Soto	2012-06-03 00:00:00	52426405	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:37.09	2026-02-18 10:31:37.09
593	Erik	Encina	2012-03-18 00:00:00	52418117	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:37.302	2026-02-18 10:31:37.302
594	Gonzalo	Cabrera	2012-03-01 00:00:00	52412589	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:37.484	2026-02-18 10:31:37.484
595	Lautaro	Benitez	2012-10-29 00:00:00	52823453	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:37.705	2026-02-18 10:31:37.705
596	Lionel	Vazquez	2012-12-15 00:00:00	52929367	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:37.901	2026-02-18 10:31:37.901
597	Felipe	Flores	2012-03-02 00:00:00	52131161	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:38.091	2026-02-18 10:31:38.091
598	Benjamin	Valdebenito	2012-05-21 00:00:00	52595408	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:31:38.288	2026-02-18 10:31:38.288
599	Romeo	Davico	2013-03-28 00:00:00	53881085	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:55.08	2026-02-18 10:52:55.08
600	Ignacio	Vallejos	2014-03-19 00:00:00	53241512	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:55.283	2026-02-18 10:52:55.283
601	Benicio	Sequeira	2013-05-03 00:00:00	53145524	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:55.477	2026-02-18 10:52:55.477
602	Santino	Lobos	2013-11-15 00:00:00	53604134	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:55.661	2026-02-18 10:52:55.661
603	Nehuen	Ramirez	2013-05-31 00:00:00	53295531	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:55.844	2026-02-18 10:52:55.844
604	Enzo	Rodriguez	2013-11-15 00:00:00	53604485	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:56.029	2026-02-18 10:52:56.029
605	Axel	Avila	2013-07-18 00:00:00	53216835	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:56.245	2026-02-18 10:52:56.245
606	Thiago	Guzman	2013-05-25 00:00:00	53063648	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:56.429	2026-02-18 10:52:56.429
607	Mateo	Mansilla	2013-10-12 00:00:00	53602405	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 10:52:56.613	2026-02-18 10:52:56.613
608	Juan	Valdez	2014-02-25 00:00:00	54145780	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:42.913	2026-02-18 11:05:42.913
609	Brandon	Urquiza	2014-08-29 00:00:00	53888139	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:43.09	2026-02-18 11:05:43.09
610	Mijael	Guevara	2014-02-24 00:00:00	53829893	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:43.267	2026-02-18 11:05:43.267
611	Galo	Goitica	2014-06-16 00:00:00	53881461	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:43.445	2026-02-18 11:05:43.445
612	Martino	Seque	2015-07-13 00:00:00	54961002	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:43.631	2026-02-18 11:05:43.631
613	Johann	Gimenez	2015-09-21 00:00:00	55058760	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-18 11:05:43.83	2026-02-18 11:05:43.83
614	Selene	Redionigi	2018-09-20 00:00:00	57294728	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:33.222	2026-02-20 17:19:33.222
615	Tiziano	Mansilla	2018-01-25 00:00:00	56781754	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:33.405	2026-02-20 17:19:33.405
616	Loan	Torres	2018-01-04 00:00:00	56725890	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:33.622	2026-02-20 17:19:33.622
617	Enzo	Garoia	2018-07-20 00:00:00	57095294	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:33.831	2026-02-20 17:19:33.831
618	Mateo	Gonzalez	2018-09-19 00:00:00	57946884	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:34.029	2026-02-20 17:19:34.029
619	Bastian	Villareal	2018-10-01 00:00:00	57254985	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:34.255	2026-02-20 17:19:34.255
620	Roman	Garro	2018-02-15 00:00:00	56864791	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:34.437	2026-02-20 17:19:34.437
622	Teo	Bustos	2019-08-07 00:00:00	57465894	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:34.794	2026-02-20 17:19:34.794
623	Francisco	Cuenca	2018-01-11 00:00:00	56935404	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:21:57.703	2026-02-20 17:21:57.703
624	Lihuen	Baigorria	2018-06-03 00:00:00	57087797	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:21:57.883	2026-02-20 17:21:57.883
625	Leon	Zacarias	2018-04-16 00:00:00	56950411	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:21:58.059	2026-02-20 17:21:58.059
626	Tiziano	Sandoval	2018-05-05 00:00:00	57034864	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:21:58.237	2026-02-20 17:21:58.237
627	Azael	Ramos	2018-05-16 00:00:00	57032303	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:21:58.421	2026-02-20 17:21:58.421
621	Felipe	Gonzalez	2019-11-29 00:00:00	57982258	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:19:34.616	2026-02-20 17:22:22.313
628	Cesar	Paredes	2017-01-19 00:00:00	56107325	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:45.969	2026-02-20 17:27:45.969
629	Tahiel	Juarez	2017-05-29 00:00:00	56339113	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:46.153	2026-02-20 17:27:46.153
630	Juan	Suarez	2017-06-10 00:00:00	56340011	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:46.335	2026-02-20 17:27:46.335
631	Genaro	Heredia	2017-06-23 00:00:00	56354194	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:46.52	2026-02-20 17:27:46.52
632	Ciro	Arriola	2017-04-05 00:00:00	56255024	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:46.703	2026-02-20 17:27:46.703
633	Gianluca	Sandoval	2017-11-30 00:00:00	56714620	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:46.886	2026-02-20 17:27:46.886
634	Tobias	Herebia	2017-01-25 00:00:00	56071091	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:47.108	2026-02-20 17:27:47.108
635	Tiziano	Schenhaiter	2017-01-12 00:00:00	56048430	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:47.297	2026-02-20 17:27:47.297
636	Mirko	Ojeda	2017-11-06 00:00:00	56641866	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:47.476	2026-02-20 17:27:47.476
637	Samuel	Montenegro	2017-08-24 00:00:00	56507175	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:27:47.66	2026-02-20 17:27:47.66
638	Dominik	Enriquez	2016-09-22 00:00:00	55816762	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:32:29.923	2026-02-20 17:32:29.923
639	Bastian	Santillan	2016-05-27 00:00:00	55498290	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:32:30.106	2026-02-20 17:32:30.106
640	Nahuel	Echenique	2016-01-08 00:00:00	55325224	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:32:30.299	2026-02-20 17:32:30.299
641	Stefano	Reinoso	2016-07-10 00:00:00	55580820	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:32:30.479	2026-02-20 17:32:30.479
642	Cristian	Ferreira	2015-03-23 00:00:00	54664198	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.007	2026-02-20 17:37:58.007
643	Milan	Jimenez	2015-06-05 00:00:00	54892560	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.226	2026-02-20 17:37:58.226
644	Mikeas	Mendez	2015-07-08 00:00:00	54896879	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.404	2026-02-20 17:37:58.404
645	Brandond	Patoteli	2015-07-31 00:00:00	54972824	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.597	2026-02-20 17:37:58.597
646	Roman	Servoli	2015-02-05 00:00:00	54532385	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.793	2026-02-20 17:37:58.793
647	Lautaro	Servoli	2015-02-05 00:00:00	54532384	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:37:58.999	2026-02-20 17:37:58.999
648	Ramiro	Avalos	2012-07-10 00:00:00	52614612	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:38.043	2026-02-20 17:48:38.043
649	Donato	Herrera	2012-08-03 00:00:00	52655144	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:38.241	2026-02-20 17:48:38.241
650	Elias	Paredes	2012-08-26 00:00:00	52525967	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:38.44	2026-02-20 17:48:38.44
651	Lautaro	Marrero	2012-06-14 00:00:00	52655042	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:38.644	2026-02-20 17:48:38.644
652	Benicio	Ruiz	2013-03-08 00:00:00	52997739	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:38.858	2026-02-20 17:48:38.858
653	Nadir	Medina	2012-09-05 00:00:00	54712919	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:48:39.053	2026-02-20 17:48:39.053
654	Juan Pablo	Torija	2012-02-10 00:00:00	52791134	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:50:53.93	2026-02-20 17:50:53.93
655	Dominick	Luque	2012-02-17 00:00:00	52125784	MASCULINO	t	\N	\N	\N	\N	\N	\N	2026-02-20 17:50:54.14	2026-02-20 17:50:54.14
656	Milena	Martinez	2007-02-11 00:00:00	57667829	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:15.735	2026-02-21 13:29:15.735
657	Yanina	Campo	2007-02-15 00:00:00	51163600	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:15.933	2026-02-21 13:29:15.933
658	Marcela	Paz	2011-01-09 00:00:00	52170063	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:16.132	2026-02-21 13:29:16.132
659	Maitena	Fernandez	2015-03-26 00:00:00	54669284	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:16.319	2026-02-21 13:29:16.319
660	Morena	Moreno	2016-08-13 00:00:00	55742306	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:16.515	2026-02-21 13:29:16.515
661	Francesca	Veron	2020-02-25 00:00:00	58199635	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:16.712	2026-02-21 13:29:16.712
662	Renata	Perez	2018-12-29 00:00:00	57468972	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 13:29:16.9	2026-02-21 13:29:16.9
663	Maitena	Gomez	2016-04-06 00:00:00	55505229	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:30:12.045	2026-02-21 15:30:12.045
664	Morena	Gomez	2015-02-19 00:00:00	54655610	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:30:12.419	2026-02-21 15:30:12.419
665	Valentina	Ramirez	2016-07-29 00:00:00	55748352	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:30:12.64	2026-02-21 15:30:12.64
666	Agustina	Losardo	2016-06-23 00:00:00	55668127	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:30:13.011	2026-02-21 15:30:13.011
667	Julieta	Herrera	2014-09-16 00:00:00	54659350	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:33.549	2026-02-21 15:35:33.549
668	Daira	Herrera	2014-01-01 00:00:00	52633509	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:33.881	2026-02-21 15:35:33.881
669	Alma	Palacios	2014-11-19 00:00:00	54353490	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:34.253	2026-02-21 15:35:34.253
670	Isabella	Espinosa	2012-08-23 00:00:00	52712416	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:34.627	2026-02-21 15:35:34.627
671	Zoe	Romero	2011-12-05 00:00:00	51478273	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:34.923	2026-02-21 15:35:34.923
672	Yandira	Obregon	2010-02-27 00:00:00	50138955	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:35.238	2026-02-21 15:35:35.238
673	Maia	Nuñez	2009-05-11 00:00:00	51253400	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:35.582	2026-02-21 15:35:35.582
674	Ailen	Aguirre	2011-09-01 00:00:00	51335157	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:35:35.934	2026-02-21 15:35:35.934
675	Brisa	Aguirre	2003-08-08 00:00:00	45149324	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:37:55.948	2026-02-21 15:37:55.948
676	Araceli	Ledezma	2005-07-25 00:00:00	47648207	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:37:56.146	2026-02-21 15:37:56.146
677	Luciana	Carrizo	2001-03-31 00:00:00	44079296	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:37:56.345	2026-02-21 15:37:56.345
678	Briana	Hidalgo	2008-07-05 00:00:00	48834090	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 15:37:56.546	2026-02-21 15:37:56.546
679	Florencia	Ibañez	1992-06-22 00:00:00	37020816	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 17:03:58.569	2026-02-21 17:03:58.569
680	Micaela	Moreno	1991-11-09 00:00:00	36649135	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-21 17:03:58.784	2026-02-21 17:03:58.784
681	Melody	Perez	2009-09-13 00:00:00	49736745	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-25 16:50:10.896	2026-02-25 16:50:10.896
682	Zoe	Marquez	2017-09-08 00:00:00	56559584	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:33.849	2026-02-26 11:12:33.849
683	Victoria	Minarik	2019-02-01 00:00:00	57551541	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.037	2026-02-26 11:12:34.037
684	Aitana	Torres	2018-01-10 00:00:00	58112136	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.223	2026-02-26 11:12:34.223
685	Alma Melina	Albornoz	2018-02-02 00:00:00	56727060	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.4	2026-02-26 11:12:34.4
686	Barbara	Penayo	2018-01-10 00:00:00	56048317	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.611	2026-02-26 11:12:34.611
687	Valentina	Galeano	2018-05-07 00:00:00	57031155	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.794	2026-02-26 11:12:34.794
688	Noah	Florentin	2016-07-08 00:00:00	55682771	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:34.997	2026-02-26 11:12:34.997
689	Angeles	Lucero	2013-03-26 00:00:00	53131109	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:35.187	2026-02-26 11:12:35.187
690	Emily	Reinoso	2013-11-05 00:00:00	53590309	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:35.369	2026-02-26 11:12:35.369
691	Charo	Paz	2012-12-06 00:00:00	52910930	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:35.545	2026-02-26 11:12:35.545
692	Ailen	Milagros	2011-09-08 00:00:00	51330054	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:35.735	2026-02-26 11:12:35.735
693	Mia Morena	Herrera	2012-07-10 00:00:00	52589695	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:12:35.91	2026-02-26 11:12:35.91
694	Zahira	Rivera	2010-03-05 00:00:00	50065483	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:15:15.972	2026-02-26 11:15:15.972
695	Abril	Gonzalez	2009-04-22 00:00:00	49523034	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:15:16.15	2026-02-26 11:15:16.15
696	Brunella	Cejas	2010-04-11 00:00:00	50222880	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:15:16.333	2026-02-26 11:15:16.333
697	Tatiana	Zaka	2009-09-02 00:00:00	49624416	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:15:16.51	2026-02-26 11:15:16.51
698	Rosa	Gonzales	1980-07-03 00:00:00	28152595	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:15:16.685	2026-02-26 11:18:09.02
192	Morena	Vella	2008-02-25 00:00:00	48764925	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-12 15:30:57.78	2026-02-26 11:26:32.1
699	Morena	Cardozo	2008-01-04 00:00:00	48628073	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:37:08.798	2026-02-26 11:37:08.798
700	Zunilda	Chavez	1992-01-26 00:00:00	95865751	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:37:08.981	2026-02-26 11:37:08.981
701	Liz Elena	Estigarriba	2003-01-01 00:00:00	95169016	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:37:09.161	2026-02-26 11:37:09.161
702	Melani	Alfonzo	2006-12-27 00:00:00	47942944	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-26 11:37:09.368	2026-02-26 11:37:09.368
433	Romina	Britos	2006-05-19 00:00:00	47294714	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 15:39:19.863	2026-02-26 11:51:03.282
703	Mahia	Stuan	2016-05-27 00:00:00	55579585	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:01.26	2026-02-28 21:29:01.26
704	Aitana	Gonzalez	2016-03-14 00:00:00	55501939	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:01.454	2026-02-28 21:29:01.454
705	Morena	Sanchez	2013-08-05 00:00:00	52655118	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:01.667	2026-02-28 21:29:01.667
706	Antonella	Ruiz Diaz	2012-01-23 00:00:00	52033892	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:01.87	2026-02-28 21:29:01.87
707	Melani	Gorosito	2011-06-09 00:00:00	52484019	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:02.084	2026-02-28 21:29:02.084
709	Macarena	Quevedo	2010-01-16 00:00:00	49812842	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:02.551	2026-02-28 21:29:02.551
710	Selena	Brites	2003-09-21 00:00:00	46279144	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:02.77	2026-02-28 21:29:02.77
711	Antonella	Vargas	2008-03-04 00:00:00	53610919	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:02.984	2026-02-28 21:29:02.984
712	Laura	Vielma	1989-03-14 00:00:00	34478975	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:03.221	2026-02-28 21:29:03.221
713	Mabel	Jarc	1975-10-24 00:00:00	24851401	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:03.452	2026-02-28 21:29:03.452
714	Gabriela	Roldan	1976-08-20 00:00:00	25337487	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:03.67	2026-02-28 21:29:03.67
461	Vida	Ocaño	2011-10-21 00:00:00	50846060	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 17:12:06.533	2026-02-28 21:29:47.827
715	Morena	Godoy	2011-07-13 00:00:00	51121250	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:47:32.834	2026-02-28 21:47:32.834
708	Martina	Paz	2011-09-16 00:00:00	51387304	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 21:29:02.284	2026-02-28 21:48:56.812
716	Ainara	Martinez	2017-10-09 00:00:00	56571469	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:00:42.876	2026-02-28 22:00:42.876
717	Martina	Aragon	2013-03-22 00:00:00	53131115	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:00:43.26	2026-02-28 22:00:43.26
718	Mayra	Diez	1989-08-23 00:00:00	34514827	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:00:43.649	2026-02-28 22:00:43.649
719	Rocio	Pereira	1994-08-04 00:00:00	38350861	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:08.836	2026-02-28 22:11:08.836
720	Debora	Diaz	1990-02-12 00:00:00	35351055	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:09.04	2026-02-28 22:11:09.04
721	Vanina	Sosa	1993-05-29 00:00:00	37606330	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:09.402	2026-02-28 22:11:09.402
722	Maite	Cabezas	1986-11-22 00:00:00	32825695	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:09.591	2026-02-28 22:11:09.591
723	Silvia	Zeballos	1989-12-20 00:00:00	34963139	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:09.787	2026-02-28 22:11:09.787
724	Aldana	Lucero	1994-08-11 00:00:00	40623629	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:09.975	2026-02-28 22:11:09.975
725	Zunilda	Chavez	1997-08-26 00:00:00	95863751	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:10.182	2026-02-28 22:11:10.182
726	Julieta	Zelaya	2010-10-10 00:00:00	50366431	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:10.371	2026-02-28 22:11:10.371
728	Ludmila	Romero	2012-07-04 00:00:00	52619598	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:13:24.637	2026-02-28 22:13:24.637
729	Tiziana	Valdes	2012-11-01 00:00:00	53047640	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:13:25.027	2026-02-28 22:13:25.027
730	Ambar Zoe	Zelaya	2018-06-13 00:00:00	57032487	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-28 22:13:25.363	2026-02-28 22:13:25.363
740	Anahi	Yanevich	1996-03-18 00:00:00	39618202	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:18:14.075	2026-03-19 18:18:14.075
727	Maite	Ochoa	2011-04-12 00:00:00	5999999	FEMENINO	f	\N	\N	\N	\N	\N	\N	2026-02-28 22:11:10.556	2026-02-28 22:17:24.677
731	Veronica	Campos	1991-11-01 00:00:00	37020632	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:36:31.914	2026-03-10 10:36:31.914
732	Elisabeth	Campos	1988-06-11 00:00:00	34102859	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:36:32.095	2026-03-10 10:36:32.095
733	Virginia	Sandoval	1988-04-16 00:00:00	39339963	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:36:32.273	2026-03-10 10:36:32.273
734	Erica	Espindola	1987-11-19 00:00:00	95178028	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:36:32.454	2026-03-10 10:36:32.454
735	Clara	Grcia	1984-02-01 00:00:00	30714749	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:36:32.638	2026-03-10 10:36:32.638
736	Luciana	Pavon	2010-06-15 00:00:00	49644316	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-10 10:42:55.625	2026-03-10 10:42:55.625
737	Delfina	Dure	2011-05-17 00:00:00	51050753	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-18 13:29:55.074	2026-03-18 13:29:55.074
738	Yanil	Zeballos	2015-07-14 00:00:00	54997217	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:18:13.702	2026-03-19 18:18:13.702
739	Macarena	Soto	2016-02-16 00:00:00	55272156	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:18:13.89	2026-03-19 18:18:13.89
741	Cecilia	Valdez	1995-07-24 00:00:00	38840298	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:18:14.26	2026-03-19 18:18:14.26
742	Victoria	Epremian	2013-08-04 00:00:00	53436849	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:24:43.599	2026-03-19 18:24:43.599
743	Cielo	Romero	2014-08-20 00:00:00	54063186	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:24:43.796	2026-03-19 18:24:43.796
744	Aylin	Almeda	2015-05-27 00:00:00	54832645	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:24:43.989	2026-03-19 18:24:43.989
745	Mia	Romero	2013-06-18 00:00:00	53283636	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:24:44.175	2026-03-19 18:24:44.175
746	Zoe	Besatetti	2007-05-21 00:00:00	19144993	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:32:31.807	2026-03-19 18:32:31.807
747	Caren	Escalada	1999-11-10 00:00:00	42297600	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:32:31.99	2026-03-19 18:32:31.99
748	Wendy	Muñoz	2004-06-04 00:00:00	45814763	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:32:32.177	2026-03-19 18:32:32.177
749	Maite	Gonzalez	2008-08-07 00:00:00	48925994	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:32:32.357	2026-03-19 18:32:32.357
750	Zoe	Paredes	2008-10-01 00:00:00	48483578	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:38:41.441	2026-03-19 18:38:41.441
751	-	Britez	2006-12-03 00:00:00	47746005	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:38:41.623	2026-03-19 18:38:41.623
752	Valentina	Perez	2006-05-20 00:00:00	46350523	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-19 18:38:41.825	2026-03-19 18:38:41.825
753	Romina	Di Zinno	1985-10-11 00:00:00	32172146	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-20 01:28:14.178	2026-03-20 01:28:14.178
754	Rocio Belen	Bidera	1982-02-28 00:00:00	37020772	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-20 16:21:42.267	2026-03-20 16:21:42.267
755	Xiomara	Sayavedra	2011-07-28 00:00:00	51158467	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-20 16:34:42.421	2026-03-20 16:34:42.421
756	Nataly Mailen	Ojeda	2014-04-03 00:00:00	54038825	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-20 18:02:13.123	2026-03-20 18:02:13.123
757	Andrea	Almiron	1979-03-07 00:00:00	27251142	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-23 21:28:19.683	2026-03-23 21:28:19.683
758	Judit	Chayle	1991-03-06 00:00:00	35757154	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-23 21:30:02.807	2026-03-23 21:35:37.519
759	Kiara Morena	Rodriguez	2008-12-12 00:00:00	48932261	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-27 14:09:21.627	2026-03-27 14:14:48.962
760	Milagros	Ormeño	2010-12-10 00:00:00	50777508	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-27 15:03:12.629	2026-03-27 15:03:12.629
761	sabella victoria	Lizarraga	2017-02-18 00:00:00	56255082	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-27 15:11:25.129	2026-03-27 15:11:25.129
762	Isabella	Cardozo	2016-09-09 00:00:00	55816750	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-03-27 15:17:44.668	2026-03-27 15:17:44.668
763	Ana	Barrieto	1978-05-09 00:00:00	26640690	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 19:50:18.083	2026-04-03 19:50:18.083
764	Luana	Sanchez	2015-12-26 00:00:00	55500732	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 19:50:18.409	2026-04-03 19:50:18.409
765	Tiziana	Sanchez	2015-12-26 00:00:00	55500731	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 19:50:18.607	2026-04-03 19:50:18.607
766	Ema Renata	Tea	2020-08-15 00:00:00	58453058	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 19:50:18.79	2026-04-03 19:50:18.79
767	Anahi Lovera	Zafira	2013-03-02 00:00:00	52998542	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 20:44:03.88	2026-04-03 20:44:03.88
768	Nicole Celeste	Acevedo	2011-08-10 00:00:00	55555555	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-04-03 20:44:04.076	2026-04-03 20:44:04.076
364	Samira	Ozan	2012-12-02 00:00:00	52929387	FEMENINO	t	\N	\N	\N	\N	\N	\N	2026-02-14 13:44:49.054	2026-04-24 18:17:24.26
\.


--
-- Data for Name: PlayerTournamentClub; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PlayerTournamentClub" (id, "playerId", "clubId", "tournamentId", "createdAt") FROM stdin;
3	1	4	2	2026-01-14 12:33:58.809
4	2	1	2	2026-01-14 12:34:00.991
6	3	1	1	2026-01-14 15:42:17.202
7	4	1	1	2026-01-14 15:42:18.908
8	5	4	1	2026-01-14 15:42:21.429
9	1	4	1	2026-01-14 15:42:23.579
11	7	2	1	2026-01-15 10:51:54.297
12	8	3	1	2026-01-15 10:51:57.322
13	9	3	1	2026-01-15 10:51:59.713
14	2	5	1	2026-01-15 10:52:12.507
15	10	5	1	2026-01-15 10:52:14.268
16	11	4	1	2026-01-15 10:52:55.114
17	12	4	1	2026-01-15 10:52:56.668
18	13	2	1	2026-01-15 10:52:58.292
19	14	2	1	2026-01-15 10:53:00.221
20	15	3	1	2026-01-15 10:53:02.998
21	16	3	1	2026-01-15 10:53:04.714
22	17	1	1	2026-01-15 10:53:06.539
23	18	1	1	2026-01-15 10:53:08.287
24	19	5	1	2026-01-15 10:53:11.673
25	20	5	1	2026-01-15 10:53:13.552
26	21	4	1	2026-01-15 10:53:21.887
27	22	4	1	2026-01-15 10:53:23.228
28	23	2	1	2026-01-15 10:53:24.955
29	24	2	1	2026-01-15 10:53:26.909
30	25	3	1	2026-01-15 10:53:29.356
31	26	3	1	2026-01-15 10:53:31.006
32	27	1	1	2026-01-15 10:53:32.48
33	28	1	1	2026-01-15 10:53:34.155
34	29	5	1	2026-01-15 10:53:38.234
35	30	5	1	2026-01-15 10:53:39.767
36	31	4	1	2026-01-15 10:53:47.336
40	35	3	1	2026-01-15 10:53:54.205
41	36	3	1	2026-01-15 10:53:56.063
38	32	4	1	2026-01-15 10:53:50.722
42	37	2	1	2026-01-15 10:53:57.72
43	38	2	1	2026-01-15 10:53:59.531
47	33	4	1	2026-01-15 11:08:33.604
48	34	4	1	2026-01-15 11:08:35.147
49	43	2	1	2026-01-15 11:08:36.84
50	44	2	1	2026-01-15 11:08:39.437
51	45	3	1	2026-01-15 11:08:41.505
52	46	3	1	2026-01-15 11:08:48.238
53	47	1	1	2026-01-15 11:08:52.33
54	48	1	1	2026-01-15 11:08:54.454
55	49	5	1	2026-01-15 11:09:32.885
56	50	5	1	2026-01-15 11:09:34.872
57	39	1	1	2026-01-15 11:57:50.035
58	40	1	1	2026-01-15 11:57:51.948
59	41	5	1	2026-01-15 11:57:54.136
60	42	5	1	2026-01-15 11:57:55.684
61	6	4	2	2026-01-30 22:31:54.166
62	7	4	2	2026-01-30 22:31:56.656
63	8	2	2	2026-01-30 22:31:58.701
64	9	2	2	2026-01-30 22:32:00.461
65	3	3	2	2026-01-30 22:32:02.5
66	4	3	2	2026-01-30 22:32:04.268
67	5	1	2	2026-01-30 22:32:06.323
68	11	4	2	2026-01-30 22:37:56.088
69	12	4	2	2026-01-30 22:37:57.033
70	13	2	2	2026-01-30 22:37:58.846
71	14	2	2	2026-01-30 22:38:00.747
72	15	3	2	2026-01-30 22:38:02.973
73	16	3	2	2026-01-30 22:38:04.818
74	17	1	2	2026-01-30 22:38:06.537
75	18	1	2	2026-01-30 22:38:08.375
76	21	4	2	2026-01-30 22:38:15.11
77	22	4	2	2026-01-30 22:38:16.454
78	23	2	2	2026-01-30 22:38:18.021
79	24	2	2	2026-01-30 22:38:19.815
80	25	3	2	2026-01-30 22:38:21.886
81	26	3	2	2026-01-30 22:38:24.414
82	27	1	2	2026-01-30 22:38:27.689
83	28	1	2	2026-01-30 22:38:29.762
84	31	4	2	2026-01-30 22:38:35.986
85	32	4	2	2026-01-30 22:38:37.386
86	35	2	2	2026-01-30 22:38:39.056
87	36	2	2	2026-01-30 22:38:40.796
88	37	3	2	2026-01-30 22:38:42.685
89	38	3	2	2026-01-30 22:38:44.436
90	39	1	2	2026-01-30 22:38:46.177
91	40	1	2	2026-01-30 22:38:48.166
92	33	4	2	2026-01-30 22:38:57.04
93	34	4	2	2026-01-30 22:38:58.57
94	43	2	2	2026-01-30 22:39:00.084
95	44	2	2	2026-01-30 22:39:02.224
96	45	3	2	2026-01-30 22:39:04.04
97	46	3	2	2026-01-30 22:39:05.629
98	47	1	2	2026-01-30 22:39:07.289
99	48	1	2	2026-01-30 22:39:08.974
100	6	1	3	2026-02-02 13:56:09.217
101	7	1	3	2026-02-02 13:56:10.769
102	8	7	3	2026-02-02 13:56:12.562
103	9	7	3	2026-02-02 13:56:14.567
104	3	8	3	2026-02-02 13:56:16.253
105	4	8	3	2026-02-02 13:56:17.895
106	5	6	3	2026-02-02 13:56:19.516
107	1	6	3	2026-02-02 13:56:21.163
108	11	1	3	2026-02-02 13:56:28.291
109	12	1	3	2026-02-02 13:56:30.965
110	13	7	3	2026-02-02 13:56:32.6
111	14	7	3	2026-02-02 13:56:34.223
112	15	8	3	2026-02-02 13:56:36.409
113	16	8	3	2026-02-02 13:56:38.4
114	17	6	3	2026-02-02 13:56:41.07
115	18	6	3	2026-02-02 13:56:42.746
116	21	1	3	2026-02-02 13:56:49.568
117	22	1	3	2026-02-02 13:56:50.949
119	23	7	3	2026-02-02 13:56:57.15
120	24	7	3	2026-02-02 13:56:59.102
121	25	8	3	2026-02-02 13:57:01.492
122	26	8	3	2026-02-02 13:57:03.577
123	27	6	3	2026-02-02 13:57:05.547
124	28	6	3	2026-02-02 13:57:07.343
125	31	1	3	2026-02-02 13:57:18.416
126	32	1	3	2026-02-02 13:57:20.588
127	35	7	3	2026-02-02 13:57:22.279
128	36	7	3	2026-02-02 13:57:24.247
129	37	8	3	2026-02-02 13:57:26.272
130	38	8	3	2026-02-02 13:57:28.184
131	39	6	3	2026-02-02 13:57:30.182
132	40	6	3	2026-02-02 13:57:32.082
133	33	1	3	2026-02-02 13:57:42.652
134	34	1	3	2026-02-02 13:57:43.982
135	43	7	3	2026-02-02 13:57:45.767
136	44	7	3	2026-02-02 13:57:47.767
137	45	8	3	2026-02-02 13:57:49.85
138	46	8	3	2026-02-02 13:57:53.383
139	47	6	3	2026-02-02 13:57:55.415
140	48	6	3	2026-02-02 13:57:57.231
141	51	1	3	2026-02-02 14:02:19.814
142	52	1	3	2026-02-02 14:02:21.466
143	53	7	3	2026-02-02 14:02:24.501
144	54	7	3	2026-02-02 14:02:26.286
145	55	8	3	2026-02-02 14:02:28.491
146	56	8	3	2026-02-02 14:02:30.366
147	57	6	3	2026-02-02 14:02:33.083
148	58	6	3	2026-02-02 14:02:34.585
149	59	1	3	2026-02-02 14:08:10.957
150	64	1	3	2026-02-02 14:08:12.187
151	65	7	3	2026-02-02 14:08:13.639
152	60	7	3	2026-02-02 14:08:15.283
153	61	8	3	2026-02-02 14:08:17.069
154	66	8	3	2026-02-02 14:08:18.634
155	67	6	3	2026-02-02 14:08:22.85
156	62	6	3	2026-02-02 14:08:24.805
157	72	1	3	2026-02-02 14:14:42.381
158	73	1	3	2026-02-02 14:14:43.79
159	74	7	3	2026-02-02 14:14:45.567
160	75	7	3	2026-02-02 14:14:47.536
161	76	8	3	2026-02-02 14:14:49.919
162	77	8	3	2026-02-02 14:14:51.883
163	78	6	3	2026-02-02 14:14:53.884
164	79	6	3	2026-02-02 14:14:55.545
165	87	1	3	2026-02-02 14:15:01.923
166	80	1	3	2026-02-02 14:15:03.3
167	81	7	3	2026-02-02 14:15:05.018
171	85	6	3	2026-02-02 14:15:13.474
168	82	7	3	2026-02-02 14:15:06.976
170	84	8	3	2026-02-02 14:15:11.565
172	86	6	3	2026-02-02 14:15:15.55
169	83	8	3	2026-02-02 14:15:09.367
215	142	11	4	2026-02-11 23:43:05.456
216	144	11	4	2026-02-11 23:43:07.698
217	141	11	4	2026-02-11 23:43:09.65
218	137	11	4	2026-02-11 23:43:11.761
219	143	11	4	2026-02-11 23:43:13.929
220	138	11	4	2026-02-11 23:43:16.578
221	140	11	4	2026-02-11 23:43:19.214
222	139	11	4	2026-02-11 23:43:21.082
223	148	11	4	2026-02-11 23:58:45.983
225	150	11	4	2026-02-11 23:58:55.274
226	145	11	4	2026-02-11 23:58:57.292
227	146	11	4	2026-02-11 23:58:59.724
228	147	11	4	2026-02-11 23:59:01.339
229	149	11	4	2026-02-11 23:59:03.17
230	151	11	4	2026-02-12 00:05:07.604
231	153	11	4	2026-02-12 00:05:11.569
232	152	11	4	2026-02-12 00:05:13.47
233	154	11	4	2026-02-12 00:05:15.019
234	155	11	4	2026-02-12 00:05:16.805
235	163	11	4	2026-02-12 00:11:03.384
236	157	11	4	2026-02-12 00:11:05.489
237	158	11	4	2026-02-12 00:11:07.469
238	161	11	4	2026-02-12 00:11:09.751
239	156	11	4	2026-02-12 00:11:13.888
240	162	11	4	2026-02-12 00:11:15.837
241	159	11	4	2026-02-12 00:11:17.682
242	160	11	4	2026-02-12 00:11:19.517
243	164	11	4	2026-02-12 00:12:40.422
244	171	11	4	2026-02-12 00:18:15.836
246	172	11	4	2026-02-12 00:18:19.785
247	168	11	4	2026-02-12 00:18:23.373
248	170	11	4	2026-02-12 00:18:25.089
249	165	11	4	2026-02-12 00:18:27.294
250	169	11	4	2026-02-12 00:18:28.85
251	167	11	4	2026-02-12 00:18:30.585
252	178	11	4	2026-02-12 01:19:47.6
253	175	11	4	2026-02-12 01:19:49.31
254	174	11	4	2026-02-12 01:19:51.379
255	176	11	4	2026-02-12 01:19:54.194
256	177	11	4	2026-02-12 01:19:58.592
257	180	11	4	2026-02-12 01:20:10.365
258	179	11	4	2026-02-12 01:20:12.896
259	181	11	4	2026-02-12 01:20:14.692
260	173	11	4	2026-02-12 01:20:16.459
261	182	11	4	2026-02-12 10:04:06.853
262	183	11	4	2026-02-12 10:04:22.301
263	185	11	4	2026-02-12 11:50:42.526
265	186	11	4	2026-02-12 15:26:19.944
266	193	12	4	2026-02-12 15:40:38.056
267	187	12	4	2026-02-12 15:40:39.804
268	188	12	4	2026-02-12 15:40:41.537
269	194	12	4	2026-02-12 15:40:44.051
270	190	12	4	2026-02-12 15:40:45.84
271	189	12	4	2026-02-12 15:40:47.614
272	191	12	4	2026-02-12 15:45:29.21
273	195	12	4	2026-02-12 16:03:38.811
274	196	12	4	2026-02-12 16:04:00.78
275	197	12	4	2026-02-12 16:04:06.179
276	198	12	4	2026-02-12 16:04:12.627
277	199	12	4	2026-02-12 16:04:18.455
278	200	12	4	2026-02-12 16:04:24.309
279	201	12	4	2026-02-12 16:04:29.621
280	202	12	4	2026-02-12 16:08:11.208
281	203	12	4	2026-02-12 16:08:20.544
282	204	12	4	2026-02-12 16:08:31.376
283	205	12	4	2026-02-12 16:08:48.724
284	206	12	4	2026-02-12 16:09:10.994
285	207	12	4	2026-02-12 16:12:52.609
286	208	12	4	2026-02-12 16:13:01.228
287	209	12	4	2026-02-12 16:14:37.515
288	210	12	4	2026-02-12 16:14:43.946
289	211	12	4	2026-02-12 16:14:45.64
290	220	12	4	2026-02-12 16:25:59.61
291	219	12	4	2026-02-12 16:26:08.677
292	218	12	4	2026-02-12 16:26:21.586
294	216	12	4	2026-02-12 16:26:47.129
295	215	12	4	2026-02-12 16:27:00.882
296	214	12	4	2026-02-12 16:27:12.175
297	213	12	4	2026-02-12 16:27:20.843
298	212	12	4	2026-02-12 16:27:29.023
299	233	12	4	2026-02-12 16:33:26.296
300	232	12	4	2026-02-12 16:33:33.527
306	226	12	4	2026-02-12 16:34:29.409
307	225	12	4	2026-02-12 16:34:39.788
308	221	12	4	2026-02-12 16:34:51.372
309	222	12	4	2026-02-12 16:34:59.888
310	223	12	4	2026-02-12 16:35:11.811
311	224	12	4	2026-02-12 16:35:19.374
312	235	13	4	2026-02-13 10:19:42.924
313	236	13	4	2026-02-13 10:19:51.882
314	237	13	4	2026-02-13 10:20:00.406
315	238	13	4	2026-02-13 10:20:11.388
316	239	13	4	2026-02-13 10:20:20.779
317	240	13	4	2026-02-13 10:20:27.717
318	242	13	4	2026-02-13 10:20:41.922
319	243	13	4	2026-02-13 10:20:46.649
320	244	13	4	2026-02-13 10:22:46.115
321	245	13	4	2026-02-13 10:22:50.459
322	246	13	4	2026-02-13 10:22:56.411
323	247	13	4	2026-02-13 10:23:09.839
324	248	13	4	2026-02-13 10:29:24.254
325	249	13	4	2026-02-13 10:29:37.868
327	251	13	4	2026-02-13 10:29:52.012
328	252	13	4	2026-02-13 10:29:56.632
329	253	13	4	2026-02-13 10:30:04.003
330	254	13	4	2026-02-13 10:30:11.016
331	255	13	4	2026-02-13 10:30:16.773
332	256	13	4	2026-02-13 10:30:20.929
333	257	13	4	2026-02-13 10:30:28.265
334	258	13	4	2026-02-13 10:30:40.601
335	259	13	4	2026-02-13 10:30:45.101
336	260	13	4	2026-02-13 10:30:49.748
337	261	13	4	2026-02-13 10:35:00.4
338	262	13	4	2026-02-13 10:35:07.776
339	263	13	4	2026-02-13 10:35:09.482
340	264	13	4	2026-02-13 10:35:18.569
341	265	13	4	2026-02-13 10:35:29.729
342	266	13	4	2026-02-13 10:35:34.763
343	267	13	4	2026-02-13 10:35:38.433
344	268	13	4	2026-02-13 10:35:44.41
345	270	1	4	2026-02-13 10:46:16.204
346	271	1	4	2026-02-13 10:46:18.082
347	272	1	4	2026-02-13 10:47:01.814
348	269	1	4	2026-02-13 10:47:08.181
349	273	1	4	2026-02-13 10:47:20.136
351	275	1	4	2026-02-13 10:47:34.882
352	278	1	4	2026-02-13 10:48:02.255
353	280	1	4	2026-02-13 10:48:03.698
354	276	1	4	2026-02-13 10:48:05.295
355	279	1	4	2026-02-13 10:48:07.166
356	277	1	4	2026-02-13 10:48:08.629
357	284	1	4	2026-02-13 14:36:10.483
358	282	1	4	2026-02-13 14:36:13.649
359	283	1	4	2026-02-13 14:36:19.221
360	285	1	4	2026-02-13 14:36:23.199
245	166	1	4	2026-02-12 00:18:17.566
362	286	1	4	2026-02-13 14:42:35.838
363	287	9	4	2026-02-13 14:54:00.457
364	288	9	4	2026-02-13 14:54:05.144
365	289	9	4	2026-02-13 14:54:09.833
366	290	9	4	2026-02-13 14:54:15.232
369	295	9	4	2026-02-13 14:56:36.136
371	297	9	4	2026-02-13 14:56:50.182
374	300	9	4	2026-02-13 14:57:09.774
378	304	9	4	2026-02-13 14:57:52.047
370	296	9	4	2026-02-13 14:56:41.084
372	298	9	4	2026-02-13 14:56:53.999
373	299	9	4	2026-02-13 14:57:00.3
377	303	9	4	2026-02-13 14:57:32.338
380	306	9	4	2026-02-13 15:09:24.066
381	307	9	4	2026-02-13 15:09:30.096
382	308	9	4	2026-02-13 15:09:36.165
383	309	9	4	2026-02-13 15:09:42.235
384	310	9	4	2026-02-13 15:09:47.714
385	311	9	4	2026-02-13 15:09:52.683
386	312	9	4	2026-02-13 15:09:58.988
387	313	9	4	2026-02-13 15:10:02.567
388	314	9	4	2026-02-13 15:10:28.143
389	315	9	4	2026-02-13 15:10:34.766
390	316	9	4	2026-02-13 15:10:42.617
391	317	9	4	2026-02-13 15:10:55.918
392	318	9	4	2026-02-13 15:11:04.437
393	319	9	4	2026-02-13 15:11:09.55
394	320	9	4	2026-02-13 15:11:15.369
397	323	9	4	2026-02-13 15:11:36.583
398	324	9	4	2026-02-13 15:23:10.575
399	325	9	4	2026-02-13 15:23:20.255
401	327	9	4	2026-02-13 15:23:28.844
402	329	9	4	2026-02-13 15:23:32.416
403	328	9	4	2026-02-13 15:23:34.164
404	330	9	4	2026-02-13 15:23:51.571
405	331	9	4	2026-02-13 15:23:57.187
406	332	9	4	2026-02-13 15:24:08.999
407	333	9	4	2026-02-13 15:24:11.789
408	334	9	4	2026-02-13 15:24:19.922
409	335	9	4	2026-02-13 15:24:24.685
410	336	9	4	2026-02-13 15:24:28.682
411	337	9	4	2026-02-13 15:24:32.748
413	339	9	4	2026-02-13 15:24:46.036
414	340	9	4	2026-02-13 15:24:50.61
416	342	9	4	2026-02-13 15:24:57.019
417	291	9	4	2026-02-13 15:25:13.185
418	293	9	4	2026-02-13 15:25:25.269
419	241	13	4	2026-02-13 15:26:42.763
420	343	9	4	2026-02-13 15:39:04.641
421	344	9	4	2026-02-13 15:39:13.238
422	345	9	4	2026-02-13 15:39:18.22
423	346	9	4	2026-02-13 15:39:36.538
424	347	9	4	2026-02-13 15:39:58.169
425	348	9	4	2026-02-13 15:40:07.144
426	349	9	4	2026-02-13 15:40:12.782
427	350	9	4	2026-02-13 15:40:40.243
428	351	9	4	2026-02-13 15:40:49.702
429	352	9	4	2026-02-13 15:40:56.32
430	353	9	4	2026-02-13 15:41:03.102
434	357	9	4	2026-02-13 16:03:34.692
435	358	11	4	2026-02-14 13:39:30.458
436	359	1	4	2026-02-14 13:41:17.383
437	360	1	4	2026-02-14 13:41:26.091
438	361	1	4	2026-02-14 13:41:33.614
439	365	1	4	2026-02-14 13:45:03.358
440	366	1	4	2026-02-14 13:45:10.886
441	367	1	4	2026-02-14 13:45:19.57
443	362	11	4	2026-02-14 13:48:12.019
444	363	11	4	2026-02-14 13:48:26.083
445	369	1	4	2026-02-14 13:54:35.286
446	370	1	4	2026-02-14 13:54:42.613
447	371	1	4	2026-02-14 13:54:50.863
448	372	1	4	2026-02-14 13:54:59.08
449	373	1	4	2026-02-14 13:55:13.72
450	374	1	4	2026-02-14 13:55:25.301
451	368	11	4	2026-02-14 13:55:37.526
452	375	1	4	2026-02-14 14:00:26.849
453	376	1	4	2026-02-14 14:00:36.873
454	377	1	4	2026-02-14 14:00:46.252
455	378	1	4	2026-02-14 14:00:53.799
456	379	1	4	2026-02-14 14:01:01.381
457	380	1	4	2026-02-14 14:01:18.48
458	381	1	4	2026-02-14 14:01:59.955
459	382	1	4	2026-02-14 14:02:43.47
460	383	11	4	2026-02-14 14:06:06.501
461	384	11	4	2026-02-14 14:06:28.168
462	385	1	4	2026-02-14 14:06:38.599
463	386	1	4	2026-02-14 14:06:48.28
464	387	11	4	2026-02-14 14:13:24.739
465	388	1	4	2026-02-14 14:13:35.992
466	389	1	4	2026-02-14 14:13:43.667
467	390	1	4	2026-02-14 14:13:52.473
468	391	1	4	2026-02-14 14:14:00.868
469	392	1	4	2026-02-14 14:14:11.771
470	393	1	4	2026-02-14 14:14:21.752
471	394	1	4	2026-02-14 14:14:35.585
472	395	1	4	2026-02-14 14:14:48.202
473	396	1	4	2026-02-14 14:14:49.534
474	397	1	4	2026-02-14 14:14:58.901
475	398	1	4	2026-02-14 14:15:11.022
476	399	1	4	2026-02-14 14:26:37.496
477	400	1	4	2026-02-14 14:26:47.174
478	401	1	4	2026-02-14 14:26:55.777
479	402	1	4	2026-02-14 14:27:21.745
480	403	10	4	2026-02-14 16:18:46.473
481	404	10	4	2026-02-14 16:18:54.768
482	405	10	4	2026-02-14 16:19:10.481
483	406	10	4	2026-02-14 16:19:18.881
484	407	10	4	2026-02-14 16:19:30.932
485	408	10	4	2026-02-14 16:19:40.201
486	409	10	4	2026-02-14 16:19:50.515
487	410	9	4	2026-02-14 16:20:19.035
489	411	10	4	2026-02-14 16:20:32.782
490	412	10	4	2026-02-14 16:20:42.951
491	413	10	4	2026-02-14 16:21:00.183
492	414	10	4	2026-02-14 16:21:17.135
493	415	10	4	2026-02-14 16:21:28.198
494	416	10	4	2026-02-14 16:21:37.813
495	417	10	4	2026-02-14 16:21:52.202
496	418	10	4	2026-02-14 16:22:03.885
497	419	10	4	2026-02-14 16:22:17.745
498	420	10	4	2026-02-14 16:22:46.26
499	421	10	4	2026-02-14 16:22:56.91
500	422	10	4	2026-02-14 16:23:04.3
501	423	10	4	2026-02-14 16:23:11.866
502	424	10	4	2026-02-14 16:23:19.132
503	425	10	4	2026-02-14 16:23:28.52
504	426	9	4	2026-02-14 16:23:59.213
505	427	9	4	2026-02-14 16:24:18.25
506	428	10	4	2026-02-14 16:25:23.262
507	429	10	4	2026-02-14 16:25:37.415
508	430	10	4	2026-02-14 16:25:59.265
509	431	10	4	2026-02-14 16:26:09.382
510	432	10	4	2026-02-14 16:26:30.97
511	433	10	4	2026-02-14 16:26:39.355
512	434	10	4	2026-02-14 16:26:53.639
513	435	10	4	2026-02-14 16:27:01.14
514	436	10	4	2026-02-14 16:27:09.758
515	437	10	4	2026-02-14 16:40:51.712
516	438	10	4	2026-02-14 16:41:03.86
517	439	10	4	2026-02-14 16:41:12.904
518	440	10	4	2026-02-14 16:42:02.229
519	441	10	4	2026-02-14 16:42:07.621
520	442	10	4	2026-02-14 16:42:22.356
521	443	10	4	2026-02-14 16:42:32.544
522	444	10	4	2026-02-14 16:42:41.27
523	445	10	4	2026-02-14 16:43:19.934
524	481	13	4	2026-02-14 17:24:11.289
525	482	13	4	2026-02-14 17:24:18.635
526	483	13	4	2026-02-14 17:24:27.757
527	484	13	4	2026-02-14 17:24:45.233
528	485	13	4	2026-02-14 17:24:56.688
529	486	13	4	2026-02-14 17:25:09.793
530	477	12	4	2026-02-14 17:25:30.435
531	478	12	4	2026-02-14 17:25:43.082
532	479	12	4	2026-02-14 17:25:52.033
533	480	12	4	2026-02-14 17:25:59.948
534	464	12	4	2026-02-14 17:26:25.125
535	465	12	4	2026-02-14 17:26:38.495
536	466	13	4	2026-02-14 17:26:57.876
537	467	13	4	2026-02-14 17:27:10.755
539	469	13	4	2026-02-14 17:28:06.574
540	470	13	4	2026-02-14 17:28:28.458
541	471	13	4	2026-02-14 17:28:38.11
542	472	13	4	2026-02-14 17:28:48.151
543	473	13	4	2026-02-14 17:29:16.681
544	474	13	4	2026-02-14 17:29:26.746
545	475	13	4	2026-02-14 17:29:42.504
546	476	13	4	2026-02-14 17:30:01.758
547	456	12	4	2026-02-14 17:30:21.21
548	457	12	4	2026-02-14 17:30:28.945
550	459	13	4	2026-02-14 17:30:49.823
549	458	13	4	2026-02-14 17:30:37.974
552	460	13	4	2026-02-14 17:31:14.537
553	461	13	4	2026-02-14 17:31:25.846
554	462	13	4	2026-02-14 17:31:48.031
555	463	13	4	2026-02-14 17:31:59.11
556	453	12	4	2026-02-14 17:32:21.958
557	454	12	4	2026-02-14 17:32:41.56
559	447	12	4	2026-02-14 19:18:50.828
560	449	12	4	2026-02-14 19:19:30.946
561	448	12	4	2026-02-14 19:19:33.743
562	450	12	4	2026-02-14 19:19:46.36
563	452	13	4	2026-02-14 19:19:59.992
564	451	13	4	2026-02-14 19:20:16.425
565	446	12	4	2026-02-14 19:21:06.826
566	493	10	4	2026-02-14 19:29:32.961
567	491	10	4	2026-02-14 19:30:28.719
568	492	10	4	2026-02-14 19:30:31.707
569	490	10	4	2026-02-14 19:30:45.142
570	487	9	4	2026-02-14 19:30:59.766
571	488	9	4	2026-02-14 19:31:20.676
572	489	9	4	2026-02-14 19:31:29.324
573	511	6	3	2026-02-15 00:53:28.334
574	507	6	3	2026-02-15 00:53:29.946
575	506	6	3	2026-02-15 00:53:31.583
576	508	6	3	2026-02-15 00:53:33.33
577	510	6	3	2026-02-15 00:53:34.981
578	509	6	3	2026-02-15 00:53:36.614
579	505	6	3	2026-02-15 00:54:03.965
580	494	1	3	2026-02-15 00:54:17.248
581	495	1	3	2026-02-15 00:54:25.96
582	496	1	3	2026-02-15 00:54:35.027
583	497	1	3	2026-02-15 00:54:54.08
584	498	1	3	2026-02-15 00:55:03.121
585	499	1	3	2026-02-15 00:55:15.491
586	500	1	3	2026-02-15 00:55:36.828
587	501	1	3	2026-02-15 00:55:50.091
588	502	1	3	2026-02-15 00:55:59.912
589	503	1	3	2026-02-15 00:56:10.556
590	504	1	3	2026-02-15 00:56:20.358
591	517	6	3	2026-02-15 01:05:13.089
592	518	6	3	2026-02-15 01:05:21.505
593	519	6	3	2026-02-15 01:05:48.19
594	520	6	3	2026-02-15 01:05:58.44
595	521	6	3	2026-02-15 01:06:14.206
596	522	6	3	2026-02-15 01:06:24.986
597	523	6	3	2026-02-15 01:06:34.307
598	524	6	3	2026-02-15 01:06:42.42
599	525	6	3	2026-02-15 01:06:51.256
600	526	6	3	2026-02-15 01:07:12.394
601	512	1	3	2026-02-15 01:07:46.464
602	515	1	3	2026-02-15 01:07:48.271
603	513	1	3	2026-02-15 01:07:55.488
604	514	1	3	2026-02-15 01:08:02.014
605	269	1	3	2026-02-15 01:09:34.078
606	516	1	3	2026-02-15 01:09:43.345
607	534	6	3	2026-02-15 23:16:36.312
608	535	6	3	2026-02-15 23:16:46.213
609	536	6	3	2026-02-15 23:16:54.174
610	537	6	3	2026-02-15 23:17:01.13
611	538	6	3	2026-02-15 23:17:14.994
612	539	6	3	2026-02-15 23:17:26.153
613	527	1	3	2026-02-15 23:17:37.44
614	528	1	3	2026-02-15 23:17:45.789
615	530	1	3	2026-02-15 23:17:58.012
616	529	1	3	2026-02-15 23:18:10.413
617	531	1	3	2026-02-15 23:18:31.808
618	532	1	3	2026-02-15 23:18:41.376
619	541	6	3	2026-02-15 23:21:59.487
620	540	6	3	2026-02-15 23:22:00.75
621	545	6	3	2026-02-15 23:22:02.329
622	546	6	3	2026-02-15 23:22:03.875
623	544	6	3	2026-02-15 23:22:05.646
624	542	6	3	2026-02-15 23:22:07.014
625	543	6	3	2026-02-15 23:22:08.36
626	554	1	3	2026-02-15 23:28:23.895
627	555	1	3	2026-02-15 23:28:29.581
628	556	1	3	2026-02-15 23:28:41.575
629	557	1	3	2026-02-15 23:28:48.617
630	558	1	3	2026-02-15 23:28:54.093
631	547	6	3	2026-02-15 23:29:06.736
632	548	6	3	2026-02-15 23:29:14.492
633	549	6	3	2026-02-15 23:29:22.727
634	550	6	3	2026-02-15 23:29:47.76
635	551	6	3	2026-02-15 23:30:04.891
636	552	6	3	2026-02-15 23:30:11.896
637	553	6	3	2026-02-15 23:30:20.764
638	563	6	3	2026-02-15 23:35:42.849
639	561	6	3	2026-02-15 23:35:44.464
640	560	6	3	2026-02-15 23:35:46.016
641	559	6	3	2026-02-15 23:35:47.681
642	564	6	3	2026-02-15 23:35:49.261
643	565	6	3	2026-02-15 23:35:50.649
644	562	6	3	2026-02-15 23:35:52.122
645	568	6	3	2026-02-18 10:18:51.462
646	567	6	3	2026-02-18 10:18:53.579
647	569	6	3	2026-02-18 10:18:59.569
648	570	6	3	2026-02-18 10:19:03.972
649	571	6	3	2026-02-18 10:19:08.619
650	572	6	3	2026-02-18 10:19:17.291
651	575	6	3	2026-02-18 10:19:23.509
652	580	1	3	2026-02-18 10:25:29.949
653	576	1	3	2026-02-18 10:25:39.876
654	577	1	3	2026-02-18 10:25:47.491
655	578	1	3	2026-02-18 10:25:50.714
656	579	1	3	2026-02-18 10:25:57.005
657	581	1	3	2026-02-18 10:26:31.031
658	582	1	3	2026-02-18 10:26:36.587
659	566	1	3	2026-02-18 10:26:41.308
660	583	6	3	2026-02-18 10:26:54.799
661	584	6	3	2026-02-18 10:26:59.409
662	574	6	3	2026-02-18 10:27:01.976
663	573	6	3	2026-02-18 10:27:06.129
664	587	1	3	2026-02-18 10:32:07.945
665	588	1	3	2026-02-18 10:32:16.914
666	589	1	3	2026-02-18 10:32:22.437
667	590	1	3	2026-02-18 10:32:25.629
668	591	1	3	2026-02-18 10:32:28.907
669	592	1	3	2026-02-18 10:32:32.56
670	593	1	3	2026-02-18 10:32:36.575
671	594	6	3	2026-02-18 10:32:45.598
672	595	6	3	2026-02-18 10:33:06.465
673	596	6	3	2026-02-18 10:33:12.143
674	597	6	3	2026-02-18 10:33:23.679
675	598	6	3	2026-02-18 10:33:28.356
676	599	6	3	2026-02-18 10:54:06.984
677	601	7	3	2026-02-18 10:55:07.08
678	602	7	3	2026-02-18 10:55:18.207
679	603	7	3	2026-02-18 10:55:25.915
680	604	7	3	2026-02-18 10:55:47.171
681	605	7	3	2026-02-18 10:56:00.383
682	606	7	3	2026-02-18 10:56:10.7
683	607	7	3	2026-02-18 10:56:22.628
684	608	7	3	2026-02-18 11:06:02.37
685	609	7	3	2026-02-18 11:06:13.832
686	610	7	3	2026-02-18 11:06:44.197
687	611	7	3	2026-02-18 11:06:51.981
688	612	7	3	2026-02-18 11:07:02.977
689	613	7	3	2026-02-18 11:07:10.496
690	614	8	3	2026-02-20 17:22:45.252
691	615	8	3	2026-02-20 17:22:49.987
692	616	8	3	2026-02-20 17:22:54.195
693	617	8	3	2026-02-20 17:23:07.851
694	618	8	3	2026-02-20 17:23:13.494
695	619	8	3	2026-02-20 17:23:19.742
696	620	8	3	2026-02-20 17:23:25.36
697	623	1	3	2026-02-20 17:23:39.032
698	624	1	3	2026-02-20 17:23:43.967
699	625	1	3	2026-02-20 17:23:49.129
700	626	1	3	2026-02-20 17:23:54.775
701	627	1	3	2026-02-20 17:23:59.246
702	622	8	3	2026-02-20 17:24:05.714
703	621	8	3	2026-02-20 17:24:07.698
704	628	8	3	2026-02-20 17:28:10.13
705	629	8	3	2026-02-20 17:28:13.4
706	630	8	3	2026-02-20 17:28:26.995
707	631	8	3	2026-02-20 17:28:33.397
708	632	8	3	2026-02-20 17:28:37.514
709	633	8	3	2026-02-20 17:28:45.346
710	634	8	3	2026-02-20 17:28:53.092
711	635	8	3	2026-02-20 17:29:00.084
712	636	8	3	2026-02-20 17:29:03.335
713	637	8	3	2026-02-20 17:29:07.043
714	638	8	3	2026-02-20 17:32:49.265
715	639	8	3	2026-02-20 17:32:54.607
716	640	1	3	2026-02-20 17:33:00.479
717	641	1	3	2026-02-20 17:33:07.851
718	642	1	3	2026-02-20 17:38:42.065
719	643	1	3	2026-02-20 17:38:45.24
720	644	1	3	2026-02-20 17:38:48.881
721	645	1	3	2026-02-20 17:38:52.572
722	647	1	3	2026-02-20 17:38:54.167
723	646	1	3	2026-02-20 17:38:55.811
724	648	8	3	2026-02-20 17:51:17.77
725	649	8	3	2026-02-20 17:51:26.181
726	650	8	3	2026-02-20 17:51:32.781
727	651	8	3	2026-02-20 17:51:40.113
728	653	8	3	2026-02-20 17:51:55.615
729	655	1	3	2026-02-20 17:52:04.349
730	654	1	3	2026-02-20 17:52:06.032
731	657	9	4	2026-02-21 13:29:47.576
732	656	11	4	2026-02-21 13:30:01.307
733	658	9	4	2026-02-21 13:30:34.011
735	659	9	4	2026-02-21 13:37:33.417
736	660	11	4	2026-02-21 13:37:46.794
737	661	9	4	2026-02-21 13:38:12.525
738	662	11	4	2026-02-21 13:38:25.982
739	679	1	4	2026-02-21 17:04:18.186
740	680	1	4	2026-02-21 17:04:19.655
741	675	1	4	2026-02-21 17:04:35.469
742	677	1	4	2026-02-21 17:04:39.152
743	678	13	4	2026-02-21 17:04:46.037
744	676	1	4	2026-02-21 17:04:54.294
745	673	13	4	2026-02-21 17:05:28.422
746	672	13	4	2026-02-21 17:05:31.057
747	674	13	4	2026-02-21 17:06:06.857
748	670	13	4	2026-02-21 17:06:08.557
749	671	13	4	2026-02-21 17:06:10.388
750	668	1	4	2026-02-21 17:07:24.76
751	667	1	4	2026-02-21 17:07:26.35
752	669	1	4	2026-02-21 17:07:27.869
753	663	1	4	2026-02-21 17:07:54.458
754	664	1	4	2026-02-21 17:07:55.832
755	666	1	4	2026-02-21 17:07:57.307
756	665	1	4	2026-02-21 17:07:59.135
757	681	13	4	2026-02-25 16:50:26.241
759	694	10	4	2026-02-26 11:19:00.052
760	695	10	4	2026-02-26 11:19:07.253
761	696	10	4	2026-02-26 11:19:50.594
762	697	10	4	2026-02-26 11:19:58.174
763	691	10	4	2026-02-26 11:20:17.086
764	692	10	4	2026-02-26 11:20:19.422
765	693	12	4	2026-02-26 11:20:25.161
766	689	10	4	2026-02-26 11:23:22.421
767	690	10	4	2026-02-26 11:23:23.996
768	688	12	4	2026-02-26 11:23:48.673
769	682	10	4	2026-02-26 11:24:06.728
770	683	10	4	2026-02-26 11:24:11.105
771	684	12	4	2026-02-26 11:24:36.909
772	685	12	4	2026-02-26 11:25:07.695
773	686	12	4	2026-02-26 11:25:15.538
774	687	12	4	2026-02-26 11:25:27.431
775	702	12	4	2026-02-26 11:37:26.702
776	699	10	4	2026-02-26 11:37:34.122
777	701	12	4	2026-02-26 11:37:41.118
778	192	10	4	2026-02-26 11:37:53.369
779	703	13	4	2026-02-28 21:30:45.99
780	704	13	4	2026-02-28 21:30:53.94
781	705	9	4	2026-02-28 21:31:15.251
782	706	13	4	2026-02-28 21:31:35.487
783	707	13	4	2026-02-28 21:31:42.438
784	715	13	4	2026-02-28 21:49:16.83
785	708	13	4	2026-02-28 21:49:23.87
786	709	9	4	2026-02-28 21:50:30.239
787	710	13	4	2026-02-28 21:51:33.288
788	711	13	4	2026-02-28 21:51:37.619
789	712	13	4	2026-02-28 21:51:57.761
790	713	9	4	2026-02-28 21:52:03.363
791	714	9	4	2026-02-28 21:52:08.778
792	718	10	4	2026-02-28 22:01:03.613
793	717	11	4	2026-02-28 22:01:23.127
794	716	11	4	2026-02-28 22:01:40.173
795	730	12	4	2026-02-28 22:13:44.77
796	729	12	4	2026-02-28 22:14:05.861
797	728	1	4	2026-02-28 22:14:21.195
798	726	12	4	2026-02-28 22:15:39.068
799	725	12	4	2026-02-28 22:17:54.128
800	719	12	4	2026-02-28 22:18:19.462
802	721	1	4	2026-02-28 22:18:30.438
803	722	1	4	2026-02-28 22:18:35.581
804	723	1	4	2026-02-28 22:18:40.812
805	724	1	4	2026-02-28 22:18:45.985
806	732	12	4	2026-03-10 10:36:47.753
807	731	12	4	2026-03-10 10:36:50.587
808	733	12	4	2026-03-10 10:37:00.109
809	734	12	4	2026-03-10 10:37:06.48
810	735	12	4	2026-03-10 10:37:12.699
842	766	9	4	2026-04-03 19:50:38.032
812	736	12	4	2026-03-10 10:43:11.264
813	737	13	4	2026-03-18 13:30:38.667
814	738	13	4	2026-03-19 18:19:33.074
815	739	13	4	2026-03-19 18:19:43.054
816	740	13	4	2026-03-19 18:20:51.868
817	741	13	4	2026-03-19 18:20:58.337
818	742	12	4	2026-03-19 18:25:10.883
819	743	12	4	2026-03-19 18:25:26.97
820	744	9	4	2026-03-19 18:25:37.853
821	745	9	4	2026-03-19 18:25:44.633
822	746	12	4	2026-03-19 18:33:03.675
823	747	12	4	2026-03-19 18:33:13.415
824	748	9	4	2026-03-19 18:33:31.999
825	749	9	4	2026-03-19 18:33:44.317
826	750	1	4	2026-03-19 18:39:05.509
827	751	1	4	2026-03-19 18:39:16.859
828	752	1	4	2026-03-19 18:39:23.867
829	302	9	4	2026-03-20 01:17:41.133
830	354	9	4	2026-03-20 01:18:30.893
831	753	10	4	2026-03-20 01:28:42.234
832	754	1	4	2026-03-20 16:21:53.802
833	755	9	4	2026-03-20 16:35:11.156
834	756	1	4	2026-03-20 18:02:27.178
835	757	1	4	2026-03-23 21:30:58.776
836	758	1	4	2026-03-23 21:32:05.14
837	759	1	4	2026-03-27 14:09:48.702
838	760	12	4	2026-03-27 15:03:32.35
839	761	11	4	2026-03-27 15:11:37.434
840	762	1	4	2026-03-27 15:17:52.438
264	184	11	4	2026-02-12 11:51:03.56
843	764	9	4	2026-04-03 19:50:49.899
844	765	9	4	2026-04-03 19:50:51.428
845	763	1	4	2026-04-03 19:51:13.118
846	767	1	4	2026-04-03 20:45:51.905
847	768	1	4	2026-04-03 20:46:01.793
848	364	11	4	2026-04-24 18:19:35.109
\.


--
-- Data for Name: Role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Role" (id, key, name, description, "createdAt", "updatedAt") FROM stdin;
1	COACH	DT	\N	2026-01-12 15:23:38.832	2026-01-12 15:23:38.832
3	ADMIN	Administrador	\N	2026-01-12 15:23:38.832	2026-01-12 15:23:38.832
4	DELEGATE	Delegado	\N	2026-01-12 15:23:38.832	2026-01-12 15:23:38.832
5	COLLABORATOR	Colaborador	\N	2026-01-12 15:23:38.832	2026-01-12 15:23:38.832
2	USER	Usuario	\N	2026-01-12 15:23:38.832	2026-01-12 15:23:38.832
\.


--
-- Data for Name: RolePermission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."RolePermission" ("roleId", "permissionId", "createdAt") FROM stdin;
3	5	2026-05-07 20:12:42.481
3	1	2026-05-07 20:12:42.481
3	6	2026-05-07 20:12:42.481
3	13	2026-05-07 20:12:42.481
3	22	2026-05-07 20:12:42.481
3	34	2026-05-07 20:12:42.481
3	38	2026-05-07 20:12:42.481
3	48	2026-05-07 20:12:42.481
3	18	2026-05-07 20:12:42.481
3	4	2026-05-07 20:12:42.481
3	8	2026-05-07 20:12:42.481
3	12	2026-05-07 20:12:42.481
3	25	2026-05-07 20:12:42.481
3	29	2026-05-07 20:12:42.481
3	30	2026-05-07 20:12:42.481
3	47	2026-05-07 20:12:42.481
3	45	2026-05-07 20:12:42.481
3	44	2026-05-07 20:12:42.481
3	17	2026-05-07 20:12:42.481
3	14	2026-05-07 20:12:42.481
3	2	2026-05-07 20:12:42.481
3	7	2026-05-07 20:12:42.481
3	9	2026-05-07 20:12:42.481
3	10	2026-05-07 20:12:42.481
3	11	2026-05-07 20:12:42.481
3	19	2026-05-07 20:12:42.481
3	3	2026-05-07 20:12:42.481
3	40	2026-05-07 20:12:42.481
3	15	2026-05-07 20:12:42.481
3	16	2026-05-07 20:12:42.481
3	20	2026-05-07 20:12:42.481
3	21	2026-05-07 20:12:42.481
3	24	2026-05-07 20:12:42.481
3	27	2026-05-07 20:12:42.481
3	35	2026-05-07 20:12:42.481
3	41	2026-05-07 20:12:42.481
3	46	2026-05-07 20:12:42.481
3	23	2026-05-07 20:12:42.481
3	26	2026-05-07 20:12:42.481
3	28	2026-05-07 20:12:42.481
3	31	2026-05-07 20:12:42.481
3	32	2026-05-07 20:12:42.481
3	37	2026-05-07 20:12:42.481
3	33	2026-05-07 20:12:42.481
3	36	2026-05-07 20:12:42.481
3	39	2026-05-07 20:12:42.481
3	42	2026-05-07 20:12:42.481
3	43	2026-05-07 20:12:42.481
5	7	2026-05-07 20:12:42.489
5	2	2026-05-07 20:12:42.489
5	14	2026-05-07 20:12:42.489
5	3	2026-05-07 20:12:42.489
5	5	2026-05-07 20:12:42.489
5	1	2026-05-07 20:12:42.489
5	6	2026-05-07 20:12:42.489
5	48	2026-05-07 20:12:42.489
5	18	2026-05-07 20:12:42.489
5	4	2026-05-07 20:12:42.489
5	13	2026-05-07 20:12:42.489
5	22	2026-05-07 20:12:42.489
5	34	2026-05-07 20:12:42.489
5	38	2026-05-07 20:12:42.489
4	48	2026-05-07 20:12:42.494
4	18	2026-05-07 20:12:42.494
4	1	2026-05-07 20:12:42.494
4	6	2026-05-07 20:12:42.494
4	13	2026-05-07 20:12:42.494
4	22	2026-05-07 20:12:42.494
4	34	2026-05-07 20:12:42.494
4	38	2026-05-07 20:12:42.494
4	42	2026-05-07 20:12:42.494
4	43	2026-05-07 20:12:42.494
1	48	2026-05-07 20:12:42.497
1	18	2026-05-07 20:12:42.497
1	1	2026-05-07 20:12:42.497
1	6	2026-05-07 20:12:42.497
1	13	2026-05-07 20:12:42.497
1	22	2026-05-07 20:12:42.497
1	34	2026-05-07 20:12:42.497
1	38	2026-05-07 20:12:42.497
1	42	2026-05-07 20:12:42.497
1	43	2026-05-07 20:12:42.497
2	48	2026-05-07 20:12:42.502
2	13	2026-05-07 20:12:42.502
2	22	2026-05-07 20:12:42.502
2	34	2026-05-07 20:12:42.502
2	38	2026-05-07 20:12:42.502
\.


--
-- Data for Name: Roster; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Roster" (id, "clubId", "tournamentCategoryId", "lockedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: RosterPlayer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."RosterPlayer" (id, "rosterId", "playerId", jersey, "createdAt") FROM stdin;
\.


--
-- Data for Name: SiteIdentity; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SiteIdentity" (id, title, "iconKey", "faviconHash", "flyerKey", "backgroundImage", "layoutSvg", "tokenConfig", "createdAt", "updatedAt") FROM stdin;
1	Ligas Deportivas	uploads/87745d4d-8ebb-45e7-9647-a5cb69137925.png	e3ece884fef56c98ee02ad3acda1a5581303207d8f3225cdd7e500c604d05ccc	uploads/ca33a0c0-df68-4021-8695-321c0ec4911f.jpg	\N	\N	\N	2026-01-12 15:23:38.861	2026-02-03 14:04:13.938
\.


--
-- Data for Name: Team; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Team" (id, "clubId", "tournamentCategoryId", "publicName", active, "createdAt", "updatedAt") FROM stdin;
1	1	1	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
2	1	2	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
3	1	3	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
4	1	4	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
5	1	5	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
6	1	6	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
7	1	7	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
8	1	8	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
9	1	9	CSD Soler	t	2026-01-14 12:07:48.549	2026-01-14 12:07:48.549
10	4	1	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
11	4	2	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
12	4	3	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
13	4	4	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
14	4	5	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
15	4	6	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
16	4	7	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
17	4	8	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
18	4	9	Deportivo Nogues	t	2026-01-14 12:11:40.7	2026-01-14 12:11:40.7
19	4	10	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
20	4	11	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
21	4	12	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
22	4	13	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
23	4	14	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
24	4	15	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
25	4	16	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
26	4	17	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
27	4	18	Deportivo Nogues	t	2026-01-14 12:33:28.124	2026-01-14 12:33:28.124
28	1	10	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
29	1	11	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
30	1	12	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
31	1	13	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
32	1	14	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
33	1	15	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
34	1	16	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
35	1	17	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
36	1	18	CSD Soler	t	2026-01-14 12:33:38.823	2026-01-14 12:33:38.823
37	5	1	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
38	5	2	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
39	5	3	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
40	5	4	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
41	5	5	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
42	5	6	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
43	5	7	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
44	5	8	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
45	5	9	Barça	t	2026-01-14 17:03:59.19	2026-01-14 17:03:59.19
46	3	1	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
47	3	2	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
48	3	3	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
49	3	4	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
50	3	5	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
51	3	6	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
52	3	7	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
53	3	8	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
54	3	9	CSD San Antonio	t	2026-01-14 17:04:00.148	2026-01-14 17:04:00.148
55	2	1	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
56	2	2	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
57	2	3	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
58	2	4	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
59	2	5	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
60	2	6	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
61	2	7	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
62	2	8	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
63	2	9	Real Polvorines	t	2026-01-14 17:04:00.837	2026-01-14 17:04:00.837
64	3	10	CSD San Antonio	t	2026-01-30 22:30:57.978	2026-01-30 22:30:57.978
65	3	11	CSD San Antonio	t	2026-01-30 22:30:57.978	2026-01-30 22:30:57.978
66	3	12	CSD San Antonio	t	2026-01-30 22:30:57.978	2026-01-30 22:30:57.978
67	3	13	CSD San Antonio	t	2026-01-30 22:30:57.978	2026-01-30 22:30:57.978
68	3	14	CSD San Antonio	t	2026-01-30 22:30:57.978	2026-01-30 22:30:57.978
69	2	10	Real Polvorines	t	2026-01-30 22:30:58.571	2026-01-30 22:30:58.571
70	2	11	Real Polvorines	t	2026-01-30 22:30:58.571	2026-01-30 22:30:58.571
71	2	12	Real Polvorines	t	2026-01-30 22:30:58.571	2026-01-30 22:30:58.571
72	2	13	Real Polvorines	t	2026-01-30 22:30:58.571	2026-01-30 22:30:58.571
73	2	14	Real Polvorines	t	2026-01-30 22:30:58.571	2026-01-30 22:30:58.571
74	1	19	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
75	1	20	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
76	1	21	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
77	1	22	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
78	1	23	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
79	1	24	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
80	1	25	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
81	1	26	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
82	1	27	CSD Soler	t	2026-02-02 13:51:59.538	2026-02-02 13:51:59.538
83	8	19	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
84	8	20	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
85	8	21	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
86	8	22	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
87	8	23	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
88	8	24	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
89	8	25	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
90	8	26	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
91	8	27	El Lucero	t	2026-02-02 13:52:12.944	2026-02-02 13:52:12.944
92	6	19	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
93	6	20	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
94	6	21	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
95	6	22	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
96	6	23	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
97	6	24	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
98	6	25	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
99	6	26	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
100	6	27	Torino	t	2026-02-02 13:52:19.728	2026-02-02 13:52:19.728
101	7	19	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
102	7	20	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
103	7	21	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
104	7	22	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
105	7	23	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
106	7	24	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
107	7	25	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
108	7	26	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
109	7	27	Wilson	t	2026-02-02 13:52:20.185	2026-02-02 13:52:20.185
110	9	28	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
111	9	29	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
112	9	30	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
113	9	31	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
114	9	32	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
115	9	33	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
116	9	34	Magdalena	t	2026-02-11 11:12:47.311	2026-02-11 11:12:47.311
117	10	28	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
118	10	29	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
119	10	30	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
120	10	31	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
121	10	32	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
122	10	33	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
123	10	34	Mariano Moreno	t	2026-02-11 11:12:50.679	2026-02-11 11:12:50.679
124	11	28	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
125	11	29	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
126	11	30	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
127	11	31	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
128	11	32	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
129	11	33	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
130	11	34	S.F. San Martin	t	2026-02-11 11:12:54.112	2026-02-11 11:12:54.112
131	1	28	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
132	1	29	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
133	1	30	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
134	1	31	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
135	1	32	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
136	1	33	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
137	1	34	CSD Soler	t	2026-02-11 11:13:01.468	2026-02-11 11:13:01.468
138	12	28	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
139	12	29	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
140	12	30	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
141	12	31	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
142	12	32	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
143	12	33	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
144	12	34	Malvinense	t	2026-02-11 11:13:04.513	2026-02-11 11:13:04.513
145	13	28	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
146	13	29	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
147	13	30	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
148	13	31	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
149	13	32	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
150	13	33	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
151	13	34	Deportivo Polvorines	t	2026-02-11 11:13:06.887	2026-02-11 11:13:06.887
\.


--
-- Data for Name: TournamentCategory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TournamentCategory" (id, "tournamentId", "categoryId", enabled, "kickoffTime", "countsForGeneral", "createdAt", "updatedAt") FROM stdin;
2	1	6	t	10:00	t	2026-01-12 17:34:32.295	2026-01-15 11:15:51.467
3	1	5	t	10:40	t	2026-01-12 17:34:32.298	2026-01-15 11:15:51.469
4	1	4	t	11:20	t	2026-01-12 17:34:32.299	2026-01-15 11:15:51.469
5	1	3	t	12:00	t	2026-01-12 17:34:32.3	2026-01-15 11:15:51.47
6	1	2	t	12:40	t	2026-01-12 17:34:32.302	2026-01-15 11:15:51.472
1	1	1	f	\N	t	2026-01-12 16:29:13.382	2026-01-15 11:15:51.473
7	1	7	f	\N	t	2026-01-12 17:34:32.304	2026-01-15 11:15:51.474
8	1	8	f	\N	t	2026-01-12 17:34:32.306	2026-01-15 11:15:51.475
9	1	9	f	\N	t	2026-01-12 17:34:32.307	2026-01-15 11:15:51.476
10	2	6	t	11:00	t	2026-01-14 12:14:14.809	2026-01-30 22:39:19.644
11	2	5	t	12:00	t	2026-01-14 12:14:15.009	2026-01-30 22:39:19.646
12	2	4	t	13:00	t	2026-01-14 12:14:15.217	2026-01-30 22:39:19.647
13	2	3	t	14:00	t	2026-01-14 12:14:15.41	2026-01-30 22:39:19.649
14	2	2	t	15:00	t	2026-01-14 12:14:15.624	2026-01-30 22:39:19.65
15	2	1	f	\N	t	2026-01-14 12:14:15.811	2026-01-30 22:39:19.651
16	2	7	f	\N	t	2026-01-14 12:14:15.997	2026-01-30 22:39:19.653
17	2	8	f	\N	t	2026-01-14 12:14:16.183	2026-01-30 22:39:19.654
18	2	9	f	\N	t	2026-01-14 12:14:16.381	2026-01-30 22:39:19.655
28	4	16	t	23:45	t	2026-02-11 11:12:24.218	2026-02-11 11:12:24.218
29	4	15	t	22:55	t	2026-02-11 11:12:24.221	2026-02-11 11:12:24.221
30	4	11	t	19:55	t	2026-02-11 11:12:24.222	2026-02-11 11:12:24.222
31	4	12	t	20:35	t	2026-02-11 11:12:24.223	2026-02-11 11:12:24.223
32	4	13	t	21:15	t	2026-02-11 11:12:24.224	2026-02-11 11:12:24.224
33	4	14	t	22:05	t	2026-02-11 11:12:24.225	2026-02-11 11:12:24.225
34	4	10	t	19:15	t	2026-02-11 11:12:24.227	2026-02-11 11:12:24.227
19	3	6	t	17:20	t	2026-02-02 13:51:34.611	2026-03-05 14:27:22.183
20	3	5	t	16:30	t	2026-02-02 13:51:34.614	2026-03-05 14:27:22.185
21	3	4	t	18:00	t	2026-02-02 13:51:34.615	2026-03-05 14:27:22.186
22	3	3	t	18:50	t	2026-02-02 13:51:34.616	2026-03-05 14:27:22.187
23	3	2	t	21:50	t	2026-02-02 13:51:34.617	2026-03-05 14:27:22.188
24	3	1	t	21:00	t	2026-02-02 13:51:34.62	2026-03-05 14:27:22.189
25	3	7	t	19:30	t	2026-02-02 13:51:34.621	2026-03-05 14:27:22.19
26	3	8	t	20:10	t	2026-02-02 13:51:34.622	2026-03-05 14:27:22.191
27	3	9	t	23:00	t	2026-02-02 13:51:34.623	2026-03-05 14:27:22.192
\.


--
-- Data for Name: TournamentPosterTemplate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."TournamentPosterTemplate" (id, "tournamentId", template, version, "backgroundKey", "createdAt", "updatedAt") FROM stdin;
6	3	{"layers": [{"x": 0, "y": 0, "id": "background-1770081793190-2019", "fit": "cover", "src": "", "type": "image", "width": 1080, "height": 1920, "locked": true, "zIndex": 0, "opacity": 1, "rotation": 0, "isBackground": true}, {"x": 104.8834019204393, "y": 433.71742112483, "id": "home-logo-1770081793190-5409", "fit": "contain", "src": "{{homeClub.logoUrl}}", "type": "image", "width": 400, "height": 400, "locked": false, "zIndex": 1, "opacity": 1, "rotation": 0}, {"x": 587.3251028806591, "y": 433.7174211248285, "id": "away-logo-1770081793190-8054", "fit": "contain", "src": "{{awayClub.logoUrl}}", "type": "image", "width": 400, "height": 400, "locked": false, "zIndex": 2, "opacity": 1, "rotation": 0}, {"x": 0, "y": 938, "id": "shape-1770082325495-4841", "fill": "#000000", "type": "shape", "shape": "rect", "width": 1080, "height": 100, "locked": false, "zIndex": 3, "opacity": 0.6, "rotation": 0}, {"x": 0, "y": 965, "id": "matchday-1770081793190-5276", "text": "Fecha {{match.matchday}} · {{match.dayName}} · {{match.date}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1080, "height": 120, "locked": false, "zIndex": 4, "opacity": 1, "fontSize": 48, "rotation": 0}, {"x": 137.5582990397797, "y": 1100, "id": "text-1770081898300-7238", "text": "{{tournament.timeSlots}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 840, "height": 900, "locked": false, "zIndex": 5, "opacity": 1, "fontSize": 72, "rotation": 0, "fontWeight": "bold"}, {"x": 49.76680384087795, "y": 875, "id": "text-1770082445844-3480", "text": "{{homeClub.name}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 500, "height": 140, "locked": false, "zIndex": 6, "opacity": 1, "fontSize": 48, "rotation": 0, "fontFamily": "Lato", "fontWeight": "bold"}, {"x": 541.3991769547332, "y": 875, "id": "text-1770082511960-6533", "text": "{{awayClub.name}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 500, "height": 140, "locked": false, "zIndex": 7, "opacity": 1, "fontSize": 48, "rotation": 0, "fontFamily": "Lato", "fontWeight": "bold"}, {"x": 0, "y": 1860, "id": "shape-1770120310218-8104", "fill": "#000000", "type": "shape", "shape": "rect", "width": 1080, "height": 240, "locked": false, "zIndex": 8, "opacity": 0.6, "rotation": 0}, {"x": 0, "y": 1880, "id": "text-1770120218366-3688", "text": "{{homeClub.address}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1080, "height": 80, "locked": false, "zIndex": 9, "opacity": 1, "fontSize": 32, "rotation": 0}]}	12	uploads/b219dace-94b1-41cd-ae71-eb903985502a.png	2026-02-03 01:24:13.624	2026-02-03 12:06:31.279
1	1	{"layers": [{"x": 0, "y": 0, "id": "background-1768565997389-8280", "fit": "cover", "src": "", "type": "image", "width": 1080, "height": 1920, "locked": false, "zIndex": 0, "opacity": 1, "rotation": 0, "isBackground": true}, {"x": 100, "y": 220, "id": "home-logo-1768565997389-5654", "fit": "contain", "src": "{{homeClub.logoUrl}}", "type": "image", "width": 400, "height": 400, "locked": false, "zIndex": 1, "opacity": 1, "rotation": 0}, {"x": 580, "y": 220, "id": "away-logo-1768565997389-441", "fit": "contain", "src": "{{awayClub.logoUrl}}", "type": "image", "width": 400, "height": 400, "locked": false, "zIndex": 2, "opacity": 1, "rotation": 0}, {"x": 40, "y": 50, "id": "tournament-1768565997389-565", "text": "{{league.name}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1000, "height": 120, "locked": false, "zIndex": 3, "opacity": 1, "fontSize": 64, "rotation": 0, "fontFamily": "Roboto", "fontWeight": "bold"}, {"x": -61.48834019204379, "y": 859.1906721536353, "id": "shape-1768567006236-922", "fill": "#000000", "type": "shape", "shape": "rect", "width": 1400, "height": 120, "locked": false, "zIndex": 4, "opacity": 0.6, "rotation": 0}, {"x": 40, "y": 913.5390946502065, "id": "matchday-1768565997389-9524", "text": "{{match.round}} - F {{match.matchday}} · {{match.dayName}} {{match.date}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1000, "height": 120, "locked": false, "zIndex": 5, "opacity": 1, "fontSize": 48, "rotation": 0}, {"x": 80, "y": 1035.768175582991, "id": "text-1768566043617-2659", "text": "{{tournament.timeSlots}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 920, "height": 140, "locked": false, "zIndex": 6, "opacity": 1, "fontSize": 94, "rotation": 0, "fontStyle": "normal", "fontWeight": "normal"}, {"x": 46.23456790123448, "y": 610, "id": "text-1768568190928-669", "text": "{{homeClub.name}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 500, "height": 140, "locked": false, "zIndex": 7, "opacity": 1, "fontSize": 60, "rotation": 0, "fontFamily": "Oswald"}, {"x": 525.6241426611797, "y": 610, "id": "text-1768568209325-2637", "text": "{{awayClub.name}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 500, "height": 140, "locked": false, "zIndex": 8, "opacity": 1, "fontSize": 60, "rotation": 0, "fontFamily": "Oswald"}]}	5	uploads/cbbc554b-8f43-42ad-bcec-b61a8469da5f.jpg	2026-01-16 12:22:56.61	2026-01-20 23:30:51.157
18	4	{"layers": [{"x": 0, "y": 0, "id": "background-1770810280600-188", "fit": "cover", "src": "", "type": "image", "width": 1080, "height": 1920, "locked": false, "zIndex": 0, "opacity": 1, "rotation": 0, "isBackground": true}, {"x": 25, "y": 400, "id": "home-logo-1770810280600-5912", "fit": "contain", "src": "{{homeClub.logoUrl}}", "type": "image", "width": 500, "height": 500, "locked": false, "zIndex": 1, "opacity": 1, "rotation": 0}, {"x": 555, "y": 400, "id": "away-logo-1770810280600-5055", "fit": "contain", "src": "{{awayClub.logoUrl}}", "type": "image", "width": 500, "height": 500, "locked": false, "zIndex": 2, "opacity": 1, "rotation": 0}, {"x": 100, "y": 1000, "id": "shape-1770811378938-937", "fill": "#000000", "type": "shape", "shape": "rect", "width": 880, "height": 700, "locked": false, "zIndex": 3, "opacity": 0.4, "rotation": 0}, {"x": 92.27709190672141, "y": 1050, "id": "tournament-1770810280600-6406", "text": "{{tournament.timeSlots}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 920, "height": 800, "locked": false, "zIndex": 4, "opacity": 1, "fontSize": 72, "rotation": 0, "fontFamily": "Roboto", "fontWeight": "bold"}, {"x": 0, "y": 920, "id": "matchday-1770810280600-4585", "text": "Fecha {{match.matchday}} · {{match.dayName}} · {{match.date}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1080, "height": 120, "locked": false, "zIndex": 5, "opacity": 1, "fontSize": 42, "rotation": 0, "fontFamily": "Roboto", "fontWeight": "bold"}, {"x": 0, "y": 1850, "id": "text-1770811583970-8314", "text": "{{homeClub.address}}", "type": "text", "align": "center", "color": "#FFFFFF", "width": 1080, "height": 70, "locked": false, "zIndex": 6, "opacity": 1, "fontSize": 32, "rotation": 0}]}	8	uploads/85d398ef-6884-4843-b377-b94ab5b1c99c.png	2026-02-11 11:46:06.801	2026-02-11 12:11:28.826
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."User" (id, email, "passwordHash", "firstName", "lastName", "emailVerifiedAt", language, "avatarHash", "avatarUpdatedAt", "avatarMime", "clubId", "createdAt", "updatedAt") FROM stdin;
1	admin@ligas.local	$argon2id$v=19$m=65536,t=3,p=4$jfVUUpJb2zoLo7tWIuAvog$hOhajvcXhMKOv3gizMQBH5rnPYNwQMSZfN2ZPHaKE7s	Admin	General	2026-01-12 15:23:38.947	\N	\N	\N	\N	\N	2026-01-12 15:23:38.949	2026-01-12 15:23:38.949
2	hector.h.orviz@gmail.com	$argon2id$v=19$m=65536,t=3,p=4$as5ZlhczfHTu8Y81uQZ4Jg$chXzsH9fcc3PAeqAfFgLrKB3GqfnFWvWTr/FeyZ22EA	Hector	Orviz	2026-01-12 16:13:30.387	\N	\N	\N	\N	\N	2026-01-12 16:13:10.824	2026-01-12 16:13:30.389
4	orviz.test@gmail.com	$argon2id$v=19$m=65536,t=3,p=4$qYB5EGy2BrXhUD93XrWUSA$LP3Ek/h2/2j9bX/xXvLNRZ8tQyTBi3mURTh0WoebMnU	Victor	Vera	2026-02-09 13:08:21.024	\N	\N	\N	\N	1	2026-02-09 13:06:36.403	2026-02-09 13:11:43.513
\.


--
-- Data for Name: UserRole; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserRole" (id, "userId", "roleId", "leagueId", "clubId", "categoryId", "createdAt") FROM stdin;
1	1	3	\N	\N	\N	2026-01-12 15:23:38.955
3	2	3	\N	\N	\N	2026-01-12 16:14:21.71
6	4	4	\N	\N	\N	2026-02-09 13:16:16.786
\.


--
-- Data for Name: UserToken; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."UserToken" (id, "userId", token, "expiresAt", "createdAt") FROM stdin;
4497	2	$argon2id$v=19$m=65536,t=3,p=4$Ba6nvun2kb+V8XIL6SG5qA$XDBt66JK4KTldGrtKfT6A4w5yXujp+t1MHIaDao/94w	2026-02-19 22:36:21.927	2026-02-12 22:36:21.929
4383	2	$argon2id$v=19$m=65536,t=3,p=4$Ow96ABaGAjssj07UG66LXg$7cwclbK4NNuR41KB49lGulCUPfNsCoMm3CxIfXr+Nb0	2026-02-10 13:14:05.355	2026-02-03 13:14:05.356
3	2	$argon2id$v=19$m=65536,t=3,p=4$XnZtvHKXnDtot9ff0hLjrg$HJpoydpiflfnWBpyB5LKjzLIRbjoJ4ZahFAbEJNd8Wg	2026-01-19 16:13:11.451	2026-01-12 16:13:11.452
4498	2	$argon2id$v=19$m=65536,t=3,p=4$9SYEQMSq8Isi93SM7mAEXA$mNj7zzz8hNUngOWnJe4CZA7hGI7gC83X8JEndWCtQYo	2026-02-19 23:02:12.198	2026-02-12 23:02:12.203
4385	2	$argon2id$v=19$m=65536,t=3,p=4$SvKUihzh/9KHxA8htgYDxg$02+yG5D50CDPuXzEf+IADqzrUSJVb6pjnhaiTzopwD8	2026-02-10 13:33:24.675	2026-02-03 13:33:24.676
6	2	$argon2id$v=19$m=65536,t=3,p=4$YPLLqf7ZfIeJZ1AsRby7Ow$d11xSsELRuur1Wu1Smb0ZIWDyNDvNkBMOCNImiwydt4	2026-01-19 16:14:55.694	2026-01-12 16:14:55.695
4386	2	$argon2id$v=19$m=65536,t=3,p=4$cmjAeGXtTyH/jlRQEn3Mmg$2tcDMBuzKLpRH9JiKCboZtZWL37//lb7w6E79Rlqu5w	2026-02-10 13:34:27.838	2026-02-03 13:34:27.839
8	2	$argon2id$v=19$m=65536,t=3,p=4$Gz+SZAaTAt2ycPxyFjtdJw$HkxNfR5OSpFedO1rMbMGNdRNZJhYi/fXVwHVYPHe45M	2026-01-19 17:30:52.134	2026-01-12 17:30:52.135
9	2	$argon2id$v=19$m=65536,t=3,p=4$jOf6aMtDHTZpvg8jNalLAg$Bn8hGNgujpB30gg7ozjD9fXP4ncDuRdlxIXGDh2iqeU	2026-01-19 17:51:03.701	2026-01-12 17:51:03.703
10	2	$argon2id$v=19$m=65536,t=3,p=4$8AkPmLqTEZR+o0a8IzldYA$ooOAQJ4sN4nP5L7NqgRFO8A1BqTi6ByF61Q1WrwdTDw	2026-01-19 18:04:16.377	2026-01-12 18:04:16.378
451	2	$argon2id$v=19$m=65536,t=3,p=4$LIY4i7EXc83e9AMkZESTwg$30QLSpIIqorZPrUXJEUbsJhoCstVdq/UpHrG4sGsEUo	2026-01-21 12:10:09.985	2026-01-14 12:10:09.986
4387	2	$argon2id$v=19$m=65536,t=3,p=4$jiRKGWYh9WaAF2jpB291zQ$N6NAjvRq2TU3W8lmgAAR6ynR83BcXErmuko6NNwfnw0	2026-02-10 13:35:07.199	2026-02-03 13:35:07.2
4499	2	$argon2id$v=19$m=65536,t=3,p=4$Re3KIeFatZ0XImsHGJt4CQ$iGCt3daoC8mynOmrSZ3RL2qmmpa6WtBsBxU/gFd4H20	2026-02-19 23:12:26.372	2026-02-12 23:12:26.374
4394	2	$argon2id$v=19$m=65536,t=3,p=4$b1SDOdlKNMhDb0Og18/yiA$6aW41BjAcr1FgEAzL7S7obcyHruJ6CW65z/VLl+3U5k	2026-02-13 13:46:47.646	2026-02-06 13:46:47.648
4403	4	$argon2id$v=19$m=65536,t=3,p=4$4Qfm3gg4MHXXpLHqlPjO9A$yGONMPkujAQq9q0pxbiI0UipNDjwcIpbFA/git4ltA8	2026-02-16 13:12:02.544	2026-02-09 13:12:02.545
4408	4	$argon2id$v=19$m=65536,t=3,p=4$rCAdv9Q2X+mLbkOeizsUbg$Vxwk6LmzKBEKQ9sIzPwYM6BD/v1W3yj3NL0Z6ZRHJO0	2026-02-16 13:19:51.158	2026-02-09 13:19:51.159
4409	4	$argon2id$v=19$m=65536,t=3,p=4$v7wo1+FYl+HFux1tmxDZbA$k3qMFoZt6dDcmLXPA9yETuosmLxuxXzoMeSfS1wGN2U	2026-02-16 13:36:09.733	2026-02-09 13:36:09.734
4411	2	$argon2id$v=19$m=65536,t=3,p=4$QB51SRLZRdKQ22d7nkU79w$OBoTH4UV0RwTi6HIVRmDJn4ZAAxYs7Oev9ijBLS0678	2026-02-16 13:51:33.727	2026-02-09 13:51:33.728
4417	2	$argon2id$v=19$m=65536,t=3,p=4$TiSJbVpXXDRUaKtMlZKoig$sSfLLefODv3DZxecdjLc3V+eMdvSjkQ5Jt4pGIjc4yE	2026-02-18 12:11:49.217	2026-02-11 12:11:49.218
1059	2	$argon2id$v=19$m=65536,t=3,p=4$su9M16DXbNVB0heW0xd0rQ$q5RJCnDIl28mtTh9fdJbLQK76zUf9DnoKH0UzGmMHDk	2026-01-21 12:32:32.263	2026-01-14 12:32:32.264
1060	2	$argon2id$v=19$m=65536,t=3,p=4$h8ootrkgQxe6u+A9zauP2Q$3GgC86AO7hsn7CyVsNnLWqk8rEhd9EW3RPw9PBwgHQo	2026-01-21 15:38:57.928	2026-01-14 15:38:57.929
1061	2	$argon2id$v=19$m=65536,t=3,p=4$/bnHg55UD+ewKhm9M2sqJA$O5pvKKaVpOnsbjmt8FkxXdflAgLbKmzBn8GXVDVvlvo	2026-01-21 16:10:15.447	2026-01-14 16:10:15.448
1062	2	$argon2id$v=19$m=65536,t=3,p=4$sUH1Bf/LEPwZPcq/P0quCw$s7pt88HlaFdR55+16nnckyoknVrvJ7ZoTCy+3EHbsd4	2026-01-21 16:21:53.494	2026-01-14 16:21:53.496
1064	2	$argon2id$v=19$m=65536,t=3,p=4$hux9fOJwMm56tK8TBLjjwg$qF1l25MNc0N7nChsbD9gUDyDuNI2wYuhT2eWchxWWbc	2026-01-21 17:15:59.766	2026-01-14 17:15:59.767
1065	2	$argon2id$v=19$m=65536,t=3,p=4$wopo25vHARPtCQbICT6ruQ$kRTp/ux+841WMoggnu+H+6UTeikz3GzUJreMbJknCC4	2026-01-21 17:16:45.258	2026-01-14 17:16:45.259
1066	2	$argon2id$v=19$m=65536,t=3,p=4$+6ou6luYzYjlgwp0bHzb9w$DGwt606JvOWwhN6YXgNHf7wGZ++e0DbXkCHy4VsUHlU	2026-01-21 17:18:50.976	2026-01-14 17:18:50.977
1067	2	$argon2id$v=19$m=65536,t=3,p=4$2GpP7WIqsPK13chbdvLEdw$kP1gtFYlme0v+VWTjfyzwsYqRapGd25+0zGbbLBhloM	2026-01-21 17:23:23.311	2026-01-14 17:23:23.312
1068	2	$argon2id$v=19$m=65536,t=3,p=4$BZXuZxfCYhS+fT3U+73vYQ$gFEDlFNlwKvIfJL2RC02G8eSp1TERmR/HO/PKX2TjAY	2026-01-21 17:26:23.652	2026-01-14 17:26:23.654
1069	2	$argon2id$v=19$m=65536,t=3,p=4$cAx/zNMsdbnq/UvBf4FHlA$g8jUG2FqgKp2ltKx4LX5QHBeqXMasOojMDlZyQCzYHU	2026-01-21 17:36:02.752	2026-01-14 17:36:02.753
1070	2	$argon2id$v=19$m=65536,t=3,p=4$n2Y4bZ9MGddS9KzYamGGuA$i+ClGI1oiAUTU6YxN2gs9QfBCtBxQ+A8Be1/pKxt1t4	2026-01-21 18:03:52.377	2026-01-14 18:03:52.378
1071	2	$argon2id$v=19$m=65536,t=3,p=4$mOuF6zNPFNgp6/0AxLzIlw$rzsH8z19vH9NlvuNRmWCCJHnlnyLlz9lJuhvW/BUu6U	2026-01-21 18:27:14.76	2026-01-14 18:27:14.762
1072	2	$argon2id$v=19$m=65536,t=3,p=4$CPy+wjwpx0vJ8NrZ8xO78w$ZIORFwgMRqSPHM0Pfu1YmsxU4Ww3QloSOTUTTNfNyUY	2026-01-21 18:30:01.154	2026-01-14 18:30:01.155
1074	2	$argon2id$v=19$m=65536,t=3,p=4$X15f18Ti/8hl3K+7/Li+pQ$+nQBIvSOctzqZnGVq2YgVFw4yx4ear/o99DGhnBvj2k	2026-01-21 20:22:38.086	2026-01-14 20:22:38.088
1077	2	$argon2id$v=19$m=65536,t=3,p=4$aI+v/sHF3ng7w9zMMJJgLQ$DQoFW4Dp5pQUzuOgvW5fHOa3sKTLKjOSBnHaPwj1hCM	2026-01-21 23:55:00.287	2026-01-14 23:55:00.288
1081	2	$argon2id$v=19$m=65536,t=3,p=4$G1ZgBKvzE5NeH0j93WQ93g$f1pa29gPkWMDTvn/NR7wlXL+QQqbzUylMN0Sz9VmNbA	2026-01-22 11:40:14.96	2026-01-15 11:40:14.961
1082	2	$argon2id$v=19$m=65536,t=3,p=4$Oei6qD5hiGNUD//iltXlkw$pplYi7WB3+6L2tIxxWQOjmJtnOTEj55zqO8MFruk44U	2026-01-22 11:57:01.405	2026-01-15 11:57:01.406
1084	2	$argon2id$v=19$m=65536,t=3,p=4$aPTEJBAAzSbX2QDv43uCbg$aB2kBlwC+Tm30JamgH2Y/ITceNa1cOFXC5V1P7yTFH0	2026-01-22 12:31:17.884	2026-01-15 12:31:17.885
1086	2	$argon2id$v=19$m=65536,t=3,p=4$rPgXvBC4RNhJ6TmR1sM7zQ$XnCwOpnJ+tARN86RqEfnTd4R0hvr6ZBsSqN/X3Jyje4	2026-01-23 11:03:49.594	2026-01-16 11:03:49.595
1087	2	$argon2id$v=19$m=65536,t=3,p=4$khQcU9pA6D7m7lNk6eFqUg$8+Zy9DKh/6LQq4DQszVCbqkaL28f3X50EWrR0OVn7VE	2026-01-23 11:25:43.315	2026-01-16 11:25:43.317
1088	2	$argon2id$v=19$m=65536,t=3,p=4$fqP1wH9lBkz4Nm78LWYaEg$A9RVoiWmfxCUhFrqdvjNMynjDInZtUaWQvCC3D1JI+c	2026-01-23 12:16:36.84	2026-01-16 12:16:36.841
1092	2	$argon2id$v=19$m=65536,t=3,p=4$cYWH15AlNhoQIB/LV4Yf/w$aLuXmZzDbg3zPllzylncerbnDMlamon9I/ntwhZBexs	2026-01-23 13:11:57.834	2026-01-16 13:11:57.835
1094	2	$argon2id$v=19$m=65536,t=3,p=4$KWH6TA9HBAwKGG21Bced2Q$WcsVASyHC6CZXiQzy+dMTudrge5Etq6FFfm9L6qQM4s	2026-01-27 11:22:41.484	2026-01-20 11:22:41.485
1095	2	$argon2id$v=19$m=65536,t=3,p=4$CW1k8tVSz1jd9OSkWOt51w$aLzUvzaX9PYruyeqLK0noYlFwX+BZguU0p2tO0ecXSQ	2026-01-27 11:31:05.176	2026-01-20 11:31:05.177
1096	2	$argon2id$v=19$m=65536,t=3,p=4$KoZk1L9QzFsTickGJhyoKQ$5lBmEdMwHk/Z8xET3TX6WYjCQiwvOGmR8NY0giTfeLM	2026-01-27 23:28:21.968	2026-01-20 23:28:21.97
1097	2	$argon2id$v=19$m=65536,t=3,p=4$AGkh9Er45xZ8wkXJY6MKiw$CS3M/gFXsbHR0NWL/cMMaWnl/Nd5Yp2bjRhi2qpRPQs	2026-01-28 01:02:45.219	2026-01-21 01:02:45.22
1100	2	$argon2id$v=19$m=65536,t=3,p=4$2eGXZ+AAHcGROZ9TV3VgsA$NgZKJWmhj7HTEAEpcgenOJWTTneDSSz5WkVH/Sj5xEk	2026-02-06 22:27:44.911	2026-01-30 22:27:44.913
4371	2	$argon2id$v=19$m=65536,t=3,p=4$A0AOOKVhPb2/y0YzNA9chA$umiPy1VtaNlFg2NbGeZJFqOpCfUpkbhiXwi4WY6ScvA	2026-02-09 14:21:33.917	2026-02-02 14:21:33.918
4373	2	$argon2id$v=19$m=65536,t=3,p=4$0IewQXriwTrMsAvz2hJgww$57hpQKpC2m79qImuGK0Bovg1DOnq4Xer4VdPwTuWd1g	2026-02-09 14:54:04.3	2026-02-02 14:54:04.301
4377	2	$argon2id$v=19$m=65536,t=3,p=4$sam2G5+Uk2mZ0gMtEV86Mg$n6emG0m8HobCqoizScR3/b5Jx2JfCEoe6A0AJqnMLH0	2026-02-10 10:47:35.928	2026-02-03 10:47:35.929
4378	2	$argon2id$v=19$m=65536,t=3,p=4$P8Kw5AI8Cs26OKKtHiokrQ$0ElKou8cbsOuYpkpmviZT0Cm2ZXOvayZoPIqCX+BGQs	2026-02-10 11:02:38.292	2026-02-03 11:02:38.293
4381	2	$argon2id$v=19$m=65536,t=3,p=4$IjmKCysnZtT2j633S5VV0Q$XfF3hT5QJpsNz1cv0P3Q0SxKdQooNHa6foYGznesyuE	2026-02-10 12:02:14.001	2026-02-03 12:02:14.002
4420	2	$argon2id$v=19$m=65536,t=3,p=4$yuQM9VsNtvSsxAtTnWjaQw$MmDh/OfPOZR0gywZUVcZb5MyyXMvUI9XntjgNgeCFoQ	2026-02-18 15:32:32.889	2026-02-11 15:32:32.89
4421	2	$argon2id$v=19$m=65536,t=3,p=4$3kjNia5S8y7eC8qcjpQG8Q$PxulSHmL9aBnkkclMLYjUhGBXq+pH3xEGttCpFQgD04	2026-02-18 16:19:20.088	2026-02-11 16:19:20.089
4422	2	$argon2id$v=19$m=65536,t=3,p=4$ZyVBOj0bFpL0PHbxzrxEJQ$oSB7pLv5CFJr0wp3fgEdUjPM50NaRQFGz3/iJ1duzro	2026-02-18 16:32:45.54	2026-02-11 16:32:45.542
4423	2	$argon2id$v=19$m=65536,t=3,p=4$mKACDBVlsnzIDR8oTuhisg$DAbxxFARgB1Anx70q/+HKaeethaJnQJo0ezXwIAL/7I	2026-02-18 16:40:35.724	2026-02-11 16:40:35.726
4424	2	$argon2id$v=19$m=65536,t=3,p=4$l8uqMwR92NS9QqtdxCnyyA$0P1yK6LVTjm8URy1EtXG8dYYfG98Yq0afeKLN3qOAbY	2026-02-18 16:54:33.153	2026-02-11 16:54:33.154
4425	2	$argon2id$v=19$m=65536,t=3,p=4$d9ILAZpmj7EB3BMi0Albpg$TDe+bPQ26D5wcFT4uJEqGi0INRfXXIM7gLP3Ru/5W5U	2026-02-18 21:52:13.099	2026-02-11 21:52:13.101
4500	2	$argon2id$v=19$m=65536,t=3,p=4$zgrpUaafurTJAIEE4/MamQ$x3MiqZZPc8FAVQvyOFAoD2PpR29HlTqMf70XNY/n9xo	2026-02-19 23:34:50.613	2026-02-12 23:34:50.614
4506	2	$argon2id$v=19$m=65536,t=3,p=4$VB6i9aZVlcBZ/mF2yScg5w$KXgzx4vT2nXMbWTa9coXzG4T3/iiLrFvIhDBG7RAtY4	2026-02-20 01:18:37.674	2026-02-13 01:18:37.675
4509	2	$argon2id$v=19$m=65536,t=3,p=4$66H4WpEhHlTbrILJV280QA$4nJVxFbZjj5amwv61SXFl/pOnpsJUiDo/5w/3EHVdpI	2026-02-20 10:03:00.263	2026-02-13 10:03:00.265
4510	2	$argon2id$v=19$m=65536,t=3,p=4$9hUV1TZEnArsGhKV89MmXA$ucM5le2CvCVnrRHgEwQTLjN2c+IMSfJOcQLSg9YdGHU	2026-02-20 10:03:39.721	2026-02-13 10:03:39.723
5370	2	$argon2id$v=19$m=65536,t=3,p=4$BoShBhFea/biYJE27PY0lA$T05Kx+yAMxHfMfg8NTe2X0dMurpAzTZezkhTHDi+oVk	2026-02-20 17:59:50.938	2026-02-13 17:59:50.939
5542	2	$argon2id$v=19$m=65536,t=3,p=4$d4iZX5g4hLXOd/bV6u+B2g$UP5TPztTZQHcxukD3Q5ry5qSk/x12/oTTUp+5F7p2jc	2026-03-11 22:24:10.74	2026-03-04 22:24:10.742
4524	2	$argon2id$v=19$m=65536,t=3,p=4$ZlhiSOfJu3y8QFbxouXZHA$XiVgfIpSw4/5lBwUe5OJwbql/ZAKSFSh74dgrI3zy/8	2026-02-20 14:25:59.329	2026-02-13 14:25:59.33
4526	2	$argon2id$v=19$m=65536,t=3,p=4$G9uq1eSA3A/tmg4wCx9hew$GkBG8OL5f1k+6dzv+bCpAhH/Gb1geojtWdjfE/B82ik	2026-02-20 14:31:58.867	2026-02-13 14:31:58.868
4527	2	$argon2id$v=19$m=65536,t=3,p=4$NPfTB9eGqOfG5mlUUolMWA$vQZYFBO4IpUmzgQ5oMjIh3UhlltCfJdJcHzvgaLuUEc	2026-02-20 14:32:18.241	2026-02-13 14:32:18.242
5543	2	$argon2id$v=19$m=65536,t=3,p=4$OgPDA88mSvDDXyM3379mdQ$1hTpqG4sJayYF68pTNiwE6ta2g3pF9lFEJkhqujpBQU	2026-03-11 22:31:59.778	2026-03-04 22:31:59.78
5384	2	$argon2id$v=19$m=65536,t=3,p=4$UvD9NxbK5B/2A3yIA5LO9A$OJcoFHwT6WNrkMRxvOfMuW37Y6sa72hRFK8sSDYU1b0	2026-02-21 16:40:12.748	2026-02-14 16:40:12.75
7563	2	$argon2id$v=19$m=65536,t=3,p=4$5iW6mYXEqG3Dm/RWvZz1+g$eGOS+9GCGGVcvYKaRs2B3+wxA3ZTcoy6nRfN1BDBbbA	2026-05-01 13:14:13.536	2026-04-24 13:14:13.537
7883	2	$argon2id$v=19$m=65536,t=3,p=4$4z9EwQJQM5inCf6ffr8IPg$KFKjGOiovw7Xr8AILgl3AZK1vTGrNZawqLMpYyjPaO0	2026-05-14 20:19:19.494	2026-05-07 20:19:19.496
4451	2	$argon2id$v=19$m=65536,t=3,p=4$MLR6RrvqMhUzkX+OpSMDdA$cqcY0Bh6hgvIEp6tiML62rD1ytZOqII4MuxsuBfUuEY	2026-02-18 23:34:56.174	2026-02-11 23:34:56.176
4452	2	$argon2id$v=19$m=65536,t=3,p=4$KEU5yVh45QmBqWsLmAWenA$vqKK9yPR2gU1q7rxkXAlLUpOSxW9Tp6Q0dJ+XwMaadE	2026-02-18 23:35:38.948	2026-02-11 23:35:38.95
5496	2	$argon2id$v=19$m=65536,t=3,p=4$x0QUUYgve0maaspF4cDwIw$888YW1Sul88fEOBXiZQj3d8bnpMiBh6/JyEB2e252Gw	2026-02-28 21:24:37.565	2026-02-21 21:24:37.566
5569	2	$argon2id$v=19$m=65536,t=3,p=4$sDkh+1Y9FN98ZNagOryD0Q$ocHebkjDuzT6Ds7Cttj1w0N2nGT4ow2uBYWDvT5pnVc	2026-03-19 17:48:53.057	2026-03-12 17:48:53.058
5408	2	$argon2id$v=19$m=65536,t=3,p=4$zSwY3ykn2Eh8wppJ/f71PQ$lNrl0tV7OrpUvy/Pwe3cvgmh61lp3+2oWhWi1eYg2g4	2026-02-27 14:11:20.202	2026-02-20 14:11:20.204
5498	2	$argon2id$v=19$m=65536,t=3,p=4$f+3MsPBqxr84aU2aly1gfw$NPcU2Uv8aNApS+ea+DPVRCDhAOArQpS4mejpArssaPY	2026-02-28 23:25:05.311	2026-02-21 23:25:05.314
5570	2	$argon2id$v=19$m=65536,t=3,p=4$gXqezKg8XN9dcnhmlaYo9Q$oFX/2OUgh+9nxAV6H/smWyfoQRW5eqazA3ZbSYvMHu8	2026-03-19 17:59:12.407	2026-03-12 17:59:12.409
5502	2	$argon2id$v=19$m=65536,t=3,p=4$oNioGlhO8N/D2Pqezpe7vg$TRiR4nAbWAEOnMTgfq6sXXr0bDeGWnhULlK8E0zlx+w	2026-03-04 15:23:17.943	2026-02-25 15:23:17.944
4459	2	$argon2id$v=19$m=65536,t=3,p=4$bPKvWGVapZc6fY75fe7Fmg$jNWWdIY2eJcugs83g8QgYPakU4MZ9nmHAqqzcZd87xo	2026-02-19 10:43:27.546	2026-02-12 10:43:27.548
4460	2	$argon2id$v=19$m=65536,t=3,p=4$ZsYObSyaVOa9382cTsblLQ$F1emEJfbrnNCn32gog6xVeZO17/nN6kgo9LC0Id/nGE	2026-02-19 10:59:15.63	2026-02-12 10:59:15.631
4461	2	$argon2id$v=19$m=65536,t=3,p=4$M2eiEhl/ortVwjnWBxdBFQ$Rpv+KNiZkjxKxzg8vh3W62WfdNrd7fimVnvpZT7kdI4	2026-02-19 11:08:15.055	2026-02-12 11:08:15.056
4462	2	$argon2id$v=19$m=65536,t=3,p=4$mX5V32eRvmrAR6Qke5ot2g$6HXP5mKwt8AOv6oSFtFW1Y92DFmc1CVLS7s0P7VZ/Ew	2026-02-19 11:16:48.545	2026-02-12 11:16:48.546
4464	2	$argon2id$v=19$m=65536,t=3,p=4$VoSCoOij49J9ZWct6pFEtA$ytBuD6OYjp5eoCYGniTPd9Byr50l7FbQ5s+Mi9t+c7I	2026-02-19 12:08:16.12	2026-02-12 12:08:16.122
4465	2	$argon2id$v=19$m=65536,t=3,p=4$3K1fZwcwklzJCjqQ1CgG8w$xG8WG+h/WVTtYWFRWhzNEwnFZRwHK/W7fp27uVSwOWI	2026-02-19 12:09:12.065	2026-02-12 12:09:12.066
4466	2	$argon2id$v=19$m=65536,t=3,p=4$hQ1JfxEF+sx8STZ6a43Iuw$IIRWAZpBJumtRjS+LeTGUuY306Omzdek+JrMzY/HGJg	2026-02-19 13:07:01.054	2026-02-12 13:07:01.056
4467	2	$argon2id$v=19$m=65536,t=3,p=4$u2Yo8hk2l8gZ85djVP0m2w$O2ehuwIYc6dgxU2KdkwZ1WqELvGpauTwwv8ibVoEzSE	2026-02-19 13:25:03.718	2026-02-12 13:25:03.72
4468	2	$argon2id$v=19$m=65536,t=3,p=4$ZOiIoW9otfSMiVsMZIvg7A$CUqPgD5qt9vpYABTp/ZpBsqTjHeIPsYUY2lf1ohovoM	2026-02-19 13:36:33.455	2026-02-12 13:36:33.456
4469	2	$argon2id$v=19$m=65536,t=3,p=4$o3krI4J2tUmK3jbLX/4H0w$rgn9oLiNiYHMzS8h4mOGInRlUfuIuVaCqGUK64gACto	2026-02-19 13:38:21.658	2026-02-12 13:38:21.659
4470	2	$argon2id$v=19$m=65536,t=3,p=4$L8fcgNjXkhWzzCu78wXvBQ$CFRmdYk6sF0bd2ch9itJt1AutB50Z6i5OG0UbeXo+lA	2026-02-19 13:47:09.902	2026-02-12 13:47:09.903
4471	2	$argon2id$v=19$m=65536,t=3,p=4$OJqrP2DLRLkMMphwYb/26Q$rHvp/atGlanwyiRT5Rs/oD/+23/NPyWWXmKi0aUgeKE	2026-02-19 13:49:17.627	2026-02-12 13:49:17.629
7314	2	$argon2id$v=19$m=65536,t=3,p=4$u2nPU5/VL8Q7F+Llp1snQA$6nLwweedKPLTyGuAa/CUwFt3LotEPnUuxIk2V7y5uwQ	2026-04-10 21:12:38.906	2026-04-03 21:12:38.907
5520	2	$argon2id$v=19$m=65536,t=3,p=4$1ZAF0a6R1Cy3Z3fJCp0MaQ$VrIkcj4tEvVi06ynsCThNuJbrZMEqz7f8oPXUJnchYE	2026-03-06 11:14:03.845	2026-02-27 11:14:03.847
7318	2	$argon2id$v=19$m=65536,t=3,p=4$Wrrpg7cf+oHplGfztGX7+g$/1Wm+XOuw4CInUfPoNeuUX0nZM/SVopLWmnQ7oxQb/s	2026-04-14 15:41:39.615	2026-04-07 15:41:39.616
5534	2	$argon2id$v=19$m=65536,t=3,p=4$sUMbp/AV1h2YafVF+vaweA$PHQiG4yACw8dPYTJCe0SL4Bz01+NC57iOEXcarfRDag	2026-03-11 16:05:53.343	2026-03-04 16:05:53.345
5535	2	$argon2id$v=19$m=65536,t=3,p=4$XLeZ9hquJHYGFb6vlZty1w$ji5j4TPpv1njim/Je0OC7xT3A7SwsP0jojJeKZxLVoU	2026-03-11 16:18:22.642	2026-03-04 16:18:22.644
5536	2	$argon2id$v=19$m=65536,t=3,p=4$89uNydzYFH1zHxAWvi0m1g$bb8IghpK7/kvzr8O71VCh9ZP6zmGtmRCmgLD1Xc6/mk	2026-03-11 18:13:05.821	2026-03-04 18:13:05.823
5537	2	$argon2id$v=19$m=65536,t=3,p=4$6e/CVqtwhT2fZrh3aZLUcA$nxOqisygJL0Xgax3I/KmA60FG9ETphSZAwSGqz9KfxY	2026-03-11 18:22:33.694	2026-03-04 18:22:33.695
5538	2	$argon2id$v=19$m=65536,t=3,p=4$0oQc6SWndDHHrlZDI3SRkg$lA2vCXdt/YxRgWvm+6/aelIQxioiVRCeoyT5mDBYxlQ	2026-03-11 18:37:16.838	2026-03-04 18:37:16.84
5539	2	$argon2id$v=19$m=65536,t=3,p=4$TQXvRFoekdy7BfbYegGWFQ$oQmbqVGKxGmohhJMiLBGf4MQT36YUftvEECfBqs5Myc	2026-03-11 18:46:09.629	2026-03-04 18:46:09.63
4683	2	$argon2id$v=19$m=65536,t=3,p=4$LHL/PAbP9ViOGtjsBy33uQ$YhVg7GM4qJQ2teqUOfWJvARnWeAYn+VdWQFdvI3T3Ic	2026-02-20 16:55:37.206	2026-02-13 16:55:37.207
4685	2	$argon2id$v=19$m=65536,t=3,p=4$xGKvnY1+NJ+UnPjWMYCFTA$9vharxWgkP6XaN2+GPsTWm25QH7pshIcSww8iLuOHl4	2026-02-20 16:56:52.201	2026-02-13 16:56:52.203
4472	2	$argon2id$v=19$m=65536,t=3,p=4$FQ+7x1YYTNJ8RCOFTNTUyQ$Ogp1CECrx3Nw9POnMh4STTO1DmAkU9ekh3wD7gBLbTA	2026-02-19 14:01:28.287	2026-02-12 14:01:28.288
4473	2	$argon2id$v=19$m=65536,t=3,p=4$+2knnQip4xDyzpWQycbkVw$Q4Xwy+BKLmw3uQpBlCasYCvaCe8gixW9Oscfl778i5M	2026-02-19 14:14:41.522	2026-02-12 14:14:41.524
4474	2	$argon2id$v=19$m=65536,t=3,p=4$FJGv3szZv21x+t85y3e2hg$kBq8XDh/bwBbGCbevRI/daJ98zi2LfEZ0bK6zO3IgJI	2026-02-19 14:25:47.533	2026-02-12 14:25:47.535
4475	2	$argon2id$v=19$m=65536,t=3,p=4$ea6iMAvnp8KXpIMPzcdZkA$7eb9Ih4ZpSPDWinnTkxTRaR9D5adjzb6vphWHMLpy5c	2026-02-19 14:43:01.159	2026-02-12 14:43:01.16
4476	2	$argon2id$v=19$m=65536,t=3,p=4$bDTiwwK7/euQ2KlP7chMmw$qEQweRbBSHG1kc/xES4Du114W2Gnhd4EdOHDHNGKOSM	2026-02-19 15:02:35.126	2026-02-12 15:02:35.127
4501	2	$argon2id$v=19$m=65536,t=3,p=4$lEH8N0VLkzPqv4N3e4omNA$DZ8FTl9tb6YE71UqiiB0h8qAhAux8P91PHiaaXVgcC8	2026-02-20 00:30:36.009	2026-02-13 00:30:36.012
4502	2	$argon2id$v=19$m=65536,t=3,p=4$2YSKYWDob5HtQBvr/5Wnsg$sHTlzMLz59pEM12/uHnDmH+SXt3X89i7679oeAAltl4	2026-02-20 00:49:12.587	2026-02-13 00:49:12.588
4503	2	$argon2id$v=19$m=65536,t=3,p=4$xqZ4I4N6j9hu0W4QN+0PXg$V/AqKPfaE70voAB51mAHeY37fygHA90n1LxTptv6y9k	2026-02-20 00:59:29.987	2026-02-13 00:59:29.988
4504	2	$argon2id$v=19$m=65536,t=3,p=4$yvBhVE+ykLCGFHRhJoMQqQ$DphCgQuFa/tPQPpKtNLyBmQuN5HqSuTCr6bHIJLIHcs	2026-02-20 01:07:05.927	2026-02-13 01:07:05.928
4481	2	$argon2id$v=19$m=65536,t=3,p=4$btDBJe+/aV10P31rJfSeaA$bOv5cGSfbaqZl0daKX25jYUFPZ4w4CZISlJspA5ZY00	2026-02-19 16:25:41.462	2026-02-12 16:25:41.463
4482	2	$argon2id$v=19$m=65536,t=3,p=4$4KQVwNnWYRrQ9WB0dmzIJA$ODi6qpqHdE5fXbS9eJnc65klcOnWc6FAvwvVq2ACSKU	2026-02-19 16:49:34.134	2026-02-12 16:49:34.136
4483	2	$argon2id$v=19$m=65536,t=3,p=4$M3y8v+EqytbRoxMnyCrHUA$MBgdiEV7ttBpuEGjo6rJr+zfE+t5gDTRyIaPnMDcht4	2026-02-19 16:53:09.274	2026-02-12 16:53:09.276
4484	2	$argon2id$v=19$m=65536,t=3,p=4$nk3xa+obwtUNqWlR6qzqQw$P1uIYf0FXNeEpy6i3LIOMDcOghNw2lv1ex2MhP4s1MA	2026-02-19 17:04:44.151	2026-02-12 17:04:44.156
4485	2	$argon2id$v=19$m=65536,t=3,p=4$nJjRUbm1a2wbgsE4Aow7DA$HZDEj5odnBQFd1RgMr6ZNVHk7qWtoR9mZG9jWU107nU	2026-02-19 17:29:12.868	2026-02-12 17:29:12.869
4486	2	$argon2id$v=19$m=65536,t=3,p=4$99ChSU0I9QMg6zKcj7q8xg$l44DPc9dkPAtzN2kXHV4jx0ivuaiICN7A2Y67wXN0UY	2026-02-19 17:29:58.889	2026-02-12 17:29:58.89
4487	2	$argon2id$v=19$m=65536,t=3,p=4$FyrtwRDBiH64vG9Asu6A5Q$ogWvdJDCdLbG+uB+a6BXe3TjefLV1yZ6fuqzqINIekU	2026-02-19 17:30:28.256	2026-02-12 17:30:28.257
4488	2	$argon2id$v=19$m=65536,t=3,p=4$XXgmXXmUMnrfCi0NWsx1Qg$WUGQbTRm5KpdGKGd8ZJkmd+JpQ1S9YyG90XRY+8N3ts	2026-02-19 17:43:18.021	2026-02-12 17:43:18.022
4489	2	$argon2id$v=19$m=65536,t=3,p=4$ctnAGrSl4BUxZYdsFe3epA$ekVg1NCBbj2tF1AulTWv8eLG9tt41VnRNEwRLau+Rho	2026-02-19 18:05:59.695	2026-02-12 18:05:59.696
4490	2	$argon2id$v=19$m=65536,t=3,p=4$YunAqeE3I6jH46zQfn/FSA$xk9pZdxbyrGzpo7PE0EsNbvJygjp253xSrwkFqDsoIY	2026-02-19 18:14:52.963	2026-02-12 18:14:52.964
4491	2	$argon2id$v=19$m=65536,t=3,p=4$Tb/7O2sbAeE1Qyh12t3aQA$u+APL8JoWAC6o6iOl5unFfO9uJDF7SwGMo73HsMQrtQ	2026-02-19 18:18:57.099	2026-02-12 18:18:57.1
4492	2	$argon2id$v=19$m=65536,t=3,p=4$5k+vUUCcaKzYhiRdoySUOA$/Yx83Umal4qkfsASmAZHaKoVDvvnYizVgCxLIRssFMQ	2026-02-19 18:39:59.573	2026-02-12 18:39:59.575
4493	2	$argon2id$v=19$m=65536,t=3,p=4$B8fJpk8LYCiBRMUNcSiGLQ$YckJW10/3rP6/j7X0FCrFVw9C+L4PK6ZpEQwu2PDwxg	2026-02-19 18:52:19.325	2026-02-12 18:52:19.327
4494	2	$argon2id$v=19$m=65536,t=3,p=4$8gwvzI4z+ssfXZe6/9+eMA$MTKwjUqdy+g+iMTQ8paOyVBFZ6zkSGEE/37Sz+H+5kY	2026-02-19 19:00:46.27	2026-02-12 19:00:46.272
4495	2	$argon2id$v=19$m=65536,t=3,p=4$HYMSnYY7A7eD3Si+wVteUw$b2Str1U4VV3NHDnTY0Um2qNkh1x+L21wdthx9Bt2VQg	2026-02-19 21:04:43.707	2026-02-12 21:04:43.708
4505	2	$argon2id$v=19$m=65536,t=3,p=4$tYSxWgb98bc/UyIF3WTRpQ$g4Kzc9HgsWREP+woewRAs8SWuAJsi9/x0kyhEnllpIU	2026-02-20 01:15:55.481	2026-02-13 01:15:55.482
4507	2	$argon2id$v=19$m=65536,t=3,p=4$OJNQQ3NB2rGPOz1UvOlzyw$Kf2+GIS7hPIqXRTcIsNUtBXuqrWJ7cccb9bn9BFkInI	2026-02-20 01:20:24.4	2026-02-13 01:20:24.401
4508	2	$argon2id$v=19$m=65536,t=3,p=4$l/ImglqI7BAsZPizpiqFQw$VTErng79QtacrC63qYJ6RIV/1UA3k9V0WYFvFnPr5e4	2026-02-20 01:28:12.634	2026-02-13 01:28:12.635
4684	2	$argon2id$v=19$m=65536,t=3,p=4$KZQfyZ+iqwOSW8iTFav5Zg$G9itKjxHOGdMAX/ljmP4SWVcU/t3rBxZr2nhYrZAOB0	2026-02-20 16:56:21.978	2026-02-13 16:56:21.979
4686	2	$argon2id$v=19$m=65536,t=3,p=4$0/fLJep/Mcy38eeHe8lLZQ$4pM1OmZejs6USgAZieTUEY734K7K0e+cpAwpPrS9VV0	2026-02-20 16:57:57.467	2026-02-13 16:57:57.469
4514	2	$argon2id$v=19$m=65536,t=3,p=4$XbLlr/to+Akm3sVlc7032w$H/s+En60doCpHNu3rtLXTT12InjeIv7I76LVZXtft2I	2026-02-20 10:59:29.257	2026-02-13 10:59:29.258
4515	2	$argon2id$v=19$m=65536,t=3,p=4$7wUudRUeEhw7sf410Ig7oQ$09wc6p5F7A+zdEZXO+BOXlE+oSUH68WgQSP73fsxvhk	2026-02-20 11:03:42.6	2026-02-13 11:03:42.601
4516	2	$argon2id$v=19$m=65536,t=3,p=4$soADpT2HYWJKmFG92BDhQQ$bo9JS6f1RszLUinVTFiielOVf2qOfuFo48lOlcM4F3Q	2026-02-20 11:22:09.712	2026-02-13 11:22:09.713
4517	2	$argon2id$v=19$m=65536,t=3,p=4$u+7/FVRj34wuILvndk+fBA$qWNp/Aup8Hc1ko0DI7ilwJJvnQ7ktZ6ZQsGU24yDgFo	2026-02-20 11:29:32.348	2026-02-13 11:29:32.35
4518	2	$argon2id$v=19$m=65536,t=3,p=4$1mnT6PIvidecIVX/WTgltw$AIjTfs9H8c2EpDHwaj9zeiW/XaTUChTEsEqnojdCSc8	2026-02-20 11:39:09.978	2026-02-13 11:39:09.979
4519	2	$argon2id$v=19$m=65536,t=3,p=4$mDOiSyid7ntsloC2jv7Abw$gV8BpSeVN1k0I9ecOz/eeDxsUtr67yZLT/6piJzqCyE	2026-02-20 11:59:48.9	2026-02-13 11:59:48.901
4520	2	$argon2id$v=19$m=65536,t=3,p=4$luSkM572NNI+LB7YYue26A$qhDIMHk+FgPU6XT2q30+5Rb6So+9X49OCQxMI/JewKE	2026-02-20 12:06:42.953	2026-02-13 12:06:42.956
4521	2	$argon2id$v=19$m=65536,t=3,p=4$/9d7eqOIbvnDpmYnFS9p9A$zU6FmOkZAMfqTrS4ZvxfeYVMkfIGDnKgzIE2ULSpIf0	2026-02-20 13:26:56.223	2026-02-13 13:26:56.225
5548	2	$argon2id$v=19$m=65536,t=3,p=4$6ecpTJ43/D6v4cIOL2AyOQ$T+qnuWXL/bFQmcVMqXwVb70LK6XwRZl2iusGglReDvY	2026-03-12 01:34:46.168	2026-03-05 01:34:46.169
5373	2	$argon2id$v=19$m=65536,t=3,p=4$6TDHzsqYJgL9MMR4N8r64w$BwzBnWQxmYf2XgJBQZCUkDM6CbF1L+j8GV1mhHpXNG4	2026-02-21 12:24:19.513	2026-02-14 12:24:19.514
4528	2	$argon2id$v=19$m=65536,t=3,p=4$jl8PI64GA4tCknexSYPb9w$tQQ9HsEyr70s9/hq34ExwKQW+d0FY4K/3Azn3lFVeyU	2026-02-20 14:32:40.323	2026-02-13 14:32:40.324
4535	2	$argon2id$v=19$m=65536,t=3,p=4$Yie/RWkDi/7jKgITbR1AKw$mNYxn8vav0PcUaIAdiYWFXMi8r6YZnZ1/3AG08Bdh4w	2026-02-20 15:56:18.637	2026-02-13 15:56:18.638
6562	2	$argon2id$v=19$m=65536,t=3,p=4$uIAzM8f1MsuqwEQAFKgY1g$i19sOP5mH+/FClcDjPBXsV6idAmlMM40zaE/sAvotB8	2026-03-30 21:27:00.314	2026-03-23 21:27:00.316
4538	2	$argon2id$v=19$m=65536,t=3,p=4$dkFEWgUMAqY2lKPCqpAgMw$JV8UPY4hRlA0NLZyIRuUXCDzaewCrnUyY8bchxBg6tA	2026-02-20 16:26:55.785	2026-02-13 16:26:55.786
6572	2	$argon2id$v=19$m=65536,t=3,p=4$16fMGEg90aCTaUMV4W3OoQ$tR2PvHXh+joG2kImbMhM7oHfHmk9Wi7kr28X1l2JbSI	2026-04-03 14:08:29.515	2026-03-27 14:08:29.517
5395	2	$argon2id$v=19$m=65536,t=3,p=4$llOrfysuN+2T2D4pRHlmeg$4pgE8QViLmt6uvUDKsL0tUmSLUKNvusoc63g1Hvtyq8	2026-02-23 13:46:24.033	2026-02-16 13:46:24.035
5576	2	$argon2id$v=19$m=65536,t=3,p=4$0jdhMLAbwh8x5gMJEwyE0g$mrtkcGZZvdx729zqNaPBLxtawA5ah3MCPtDaJnBWu7Y	2026-03-25 13:28:04.857	2026-03-18 13:28:04.859
5490	2	$argon2id$v=19$m=65536,t=3,p=4$6mKFAVvtxl7adN9LBe2fTg$EGkr8UZr/LtYAgqPnM3zQEkovQ9RdipVF4guipNJyM4	2026-02-28 01:07:26.532	2026-02-21 01:07:26.533
5511	2	$argon2id$v=19$m=65536,t=3,p=4$yosJcY5dlXzQK/e4Dh//Fg$jg48QhUUg15p1iZLx/8/2wwIlcUJ5ECWC1nfIaCI+tw	2026-03-05 11:37:08.417	2026-02-26 11:37:08.418
5515	2	$argon2id$v=19$m=65536,t=3,p=4$g/pXbNCfob5PpW0+/crmWQ$lEVxSFyTqpM1GXw2sxX13Njwfw7znmSUhB0ZvqJfj+k	2026-03-05 17:18:07.89	2026-02-26 17:18:07.891
7317	2	$argon2id$v=19$m=65536,t=3,p=4$dj1TGE2s08N8ngozHV/LMw$zU4wZT/Wou19eID9JeNaVt3YKpVJAS9xZdZyV+rBtDo	2026-04-10 23:29:23.407	2026-04-03 23:29:23.409
7323	2	$argon2id$v=19$m=65536,t=3,p=4$o+NqxI1MJ1Fm7b8xNOXBgQ$UD5YIKIz7Sr+alTiAFW5MAzdvaDusl/Esfw2QlfIS5Q	2026-04-21 14:02:22.085	2026-04-14 14:02:22.087
7884	2	$argon2id$v=19$m=65536,t=3,p=4$KShWPG94xAPKC+cnvhR37Q$1RuTnUcnuLgv3tXSBL/cn+JTV4Y+zk9ZsEpCawdsWUg	2026-05-14 20:22:03.913	2026-05-07 20:22:03.914
7329	2	$argon2id$v=19$m=65536,t=3,p=4$17qLx4SrdM15PztdW5b7fg$v4pDA6v8bEc1A9bamB1oDC6MaYhO61c97i4VudDgr4c	2026-04-30 12:16:42.235	2026-04-23 12:16:42.236
7787	2	$argon2id$v=19$m=65536,t=3,p=4$K9Kw1IQKwRhdHPiVQwIPBw$fIsmwm7bH81zcll6I8o04p/ZwuYW8LOzWus974KklTU	2026-05-01 18:18:57.753	2026-04-24 18:18:57.754
7335	2	$argon2id$v=19$m=65536,t=3,p=4$HIgSSV6BIOEJtEr3aAipyQ$hHXUdcabkfdas739tTZlqJzYI8jDmT2Hx4CdF4QhQ8E	2026-05-01 00:47:05.579	2026-04-24 00:47:05.58
7796	2	$argon2id$v=19$m=65536,t=3,p=4$cbRpqrdU65B4CD2eOt41+w$Hjl4dwjyjyAE3r04/Yld6uUQb/tmjEFV7+5E7BrByY8	2026-05-05 15:00:01.556	2026-04-28 15:00:01.558
7803	2	$argon2id$v=19$m=65536,t=3,p=4$zi8iwzGl0zz5WS9VEqkLGg$hc/b1MKK4m7Igd/MzX4zKH+wW8aVIPSiVSRU+6/8i/U	2026-05-08 22:12:03.258	2026-05-01 22:12:03.259
7804	2	$argon2id$v=19$m=65536,t=3,p=4$IFidDzCLQ5BTO7TZRY41gw$ESj0Nh5hnQhS0OOn2k623aoAtTVzgaVPJhtY6BzfdVw	2026-05-11 22:55:38.183	2026-05-04 22:55:38.185
\.


--
-- Data for Name: Zone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Zone" (id, "tournamentId", name, status, "lockedAt", "fixtureSeed", "createdAt", "updatedAt") FROM stdin;
1	1	Superliga	PLAYING	2026-01-15 12:11:40.829	840816152	2026-01-14 18:33:11.428	2026-01-15 12:23:14.306
2	2	A	IN_PROGRESS	2026-01-30 22:39:57.794	\N	2026-01-30 22:39:39.617	2026-01-30 22:39:57.795
3	3	Unica	PLAYING	2026-02-02 14:15:41.544	\N	2026-02-02 13:53:17.733	2026-02-02 14:57:25.979
4	4	Unica	PLAYING	2026-02-11 11:37:35.338	\N	2026-02-11 11:13:38.3	2026-02-11 11:40:23.74
\.


--
-- Data for Name: ZoneMatchday; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ZoneMatchday" (id, "zoneId", matchday, status, date, "createdAt", "updatedAt") FROM stdin;
5	1	5	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
6	1	6	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
7	1	7	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
8	1	8	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
9	1	9	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
10	1	10	PENDING	\N	2026-01-15 12:23:14.303	2026-01-15 12:23:14.303
1	1	1	PLAYED	2026-01-11 00:00:00	2026-01-15 12:23:14.303	2026-01-20 11:24:56.611
20	4	4	PLAYED	2026-03-06 00:00:00	2026-02-11 11:40:23.736	2026-04-03 19:56:43.432
21	4	5	PLAYED	2026-03-13 00:00:00	2026-02-11 11:40:23.736	2026-04-03 19:57:03.898
2	1	2	PLAYED	2026-01-18 00:00:00	2026-01-15 12:23:14.303	2026-01-20 11:27:05.216
3	1	3	PLAYED	2026-01-25 00:00:00	2026-01-15 12:23:14.303	2026-01-20 11:28:21.237
4	1	4	IN_PROGRESS	2026-02-01 00:00:00	2026-01-15 12:23:14.303	2026-01-20 11:28:21.237
17	4	1	PLAYED	2026-02-13 00:00:00	2026-02-11 11:40:23.736	2026-02-14 19:32:36.692
22	4	6	PLAYED	2026-03-20 00:00:00	2026-02-11 11:40:23.736	2026-04-24 13:11:29.32
23	4	7	PLAYED	2026-03-27 00:00:00	2026-02-11 11:40:23.736	2026-04-24 13:11:33.389
11	3	1	PLAYED	2026-02-14 00:00:00	2026-02-02 14:57:25.975	2026-02-20 10:27:23.367
25	4	9	PLAYED	2026-04-24 00:00:00	2026-02-11 11:40:23.736	2026-04-25 13:40:39.627
24	4	8	PLAYED	2026-04-10 00:00:00	2026-02-11 11:40:23.736	2026-04-28 12:19:10.796
26	4	10	IN_PROGRESS	2026-04-30 00:00:00	2026-02-11 11:40:23.736	2026-04-28 15:29:45.344
18	4	2	PLAYED	2026-02-20 00:00:00	2026-02-11 11:40:23.736	2026-02-26 11:46:57.561
19	4	3	PLAYED	2026-02-27 00:00:00	2026-02-11 11:40:23.736	2026-02-28 22:25:33.129
16	3	6	IN_PROGRESS	\N	2026-02-02 14:57:25.975	2026-03-12 12:38:12.001
12	3	2	PLAYED	2026-02-16 00:00:00	2026-02-02 14:57:25.975	2026-03-12 17:59:24.014
13	3	3	PLAYED	2026-02-21 00:00:00	2026-02-02 14:57:25.975	2026-03-12 17:59:26.099
14	3	4	PLAYED	2026-02-28 00:00:00	2026-02-02 14:57:25.975	2026-03-12 17:59:27.725
15	3	5	PLAYED	2026-03-07 00:00:00	2026-02-02 14:57:25.975	2026-03-12 17:59:29.973
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
47b6d37a-3422-4173-a101-bd9782eecd4c	109c454ef9a9aa06dca0895f95a7b9a04128cff5538d08cd5d7618864fce89a5	2026-01-12 15:10:16.077238+00	20250101000000_baseline_init	\N	\N	2026-01-12 15:10:15.794307+00	1
b847bd7e-52d5-427e-a5d5-97ccf72210ab	27aa59d1de058fa16910332e52ed7b96aa0f65a7669b9e94e759929644edfb63	2026-01-12 15:10:16.082122+00	20250609120000_site_identity_flyer_assets	\N	\N	2026-01-12 15:10:16.07836+00	1
3a3952e9-5fd8-4f27-a78e-bd142a355d79	963192b0311e9a3555a67e458ac4b236d96a3506c4ee694210fdcab58524b865	2026-01-12 15:10:16.098712+00	20250615123000_flyer_templates	\N	\N	2026-01-12 15:10:16.082823+00	1
9879389b-ca1e-4a89-ab3f-6eec9807073d	2188b8779db9eb4a473271b9135549bde9e04d319aa41303adfec31b07247909	2026-01-12 15:10:16.101727+00	20250616090000_add_site_identity_flyer_key	\N	\N	2026-01-12 15:10:16.099474+00	1
1f2e2007-0717-4aa0-b606-418d0d3d8847	4227b27d8730d79b285335f670b93589ae7c4a13776bec262e13b318019f744b	2026-01-12 15:10:16.12319+00	20250620120000_poster_templates	\N	\N	2026-01-12 15:10:16.103275+00	1
55583d3c-164c-4eca-9166-27ce2133e95c	9fa472da23e810356f683248ad8c26abf03c4daddc59e63779a435edb7ebf935	2026-01-12 15:10:16.126409+00	20250906120000_add_site_identity_favicon_key	\N	\N	2026-01-12 15:10:16.123919+00	1
1325a3fe-979f-436c-8299-919a0e0f3535	6e372420c968759c27199d990429d00443f8203b835eacbc13a7dcd6fe168aaa	2026-01-12 15:10:16.131021+00	20250914120000_add_site_identity_favicon_hash	\N	\N	2026-01-12 15:10:16.127138+00	1
dd2f506d-f89c-42fc-b6c0-0cba21283bde	5bb3fa5b08bcd1ca8ad667ab5fe6c73332b11ae77ff4d88e19ed3f00582756f5	2026-02-03 11:51:50.11259+00	20250915090000_add_club_home_address	\N	\N	2026-02-03 11:51:50.096695+00	1
5e693204-2779-4225-904e-32dccab4ca0b	4e20efff7c38ea7869f561eb255c40d89d3380fce3aa65092f6c92981b80bf9a	2026-02-03 13:11:53.738515+00	20260203130140_add_tournament_status	\N	\N	2026-02-03 13:11:53.720145+00	1
\.


--
-- Data for Name: tournament; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tournament (id, "leagueId", name, year, gender, "pointsWin", "pointsDraw", "pointsLoss", "championMode", "startDate", "endDate", "fixtureLockedAt", "createdAt", "updatedAt", status) FROM stdin;
3	3	Infantil Sabados	2026	MIXTO	3	1	0	GLOBAL	\N	\N	\N	2026-02-02 13:51:34.406	2026-02-02 13:51:34.606	ACTIVE
2	2	Torneo 2025	2026	MIXTO	3	1	0	GLOBAL	\N	\N	\N	2026-01-14 12:14:14.602	2026-02-03 13:34:40.934	INACTIVE
1	1	Torneo	2026	MASCULINO	3	1	0	GLOBAL	\N	\N	\N	2026-01-12 16:29:13.18	2026-02-09 13:51:52.013	INACTIVE
4	3	Femenino	2026	FEMENINO	3	1	0	GLOBAL	\N	\N	\N	2026-02-11 11:12:24.006	2026-02-11 11:12:24.213	ACTIVE
\.


--
-- Name: AuditLog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."AuditLog_id_seq"', 1, false);


--
-- Name: CategoryStanding_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."CategoryStanding_id_seq"', 13625, true);


--
-- Name: Category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Category_id_seq"', 16, true);


--
-- Name: ClubZone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ClubZone_id_seq"', 19, true);


--
-- Name: Club_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Club_id_seq"', 13, true);


--
-- Name: EmailChangeRequest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."EmailChangeRequest_id_seq"', 1, false);


--
-- Name: EmailVerificationToken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."EmailVerificationToken_id_seq"', 3, true);


--
-- Name: FlyerTemplate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."FlyerTemplate_id_seq"', 1, false);


--
-- Name: Goal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Goal_id_seq"', 883, true);


--
-- Name: League_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."League_id_seq"', 3, true);


--
-- Name: MatchAttachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."MatchAttachment_id_seq"', 1, false);


--
-- Name: MatchCategory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."MatchCategory_id_seq"', 418, true);


--
-- Name: MatchLog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."MatchLog_id_seq"', 346, true);


--
-- Name: MatchPosterCache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."MatchPosterCache_id_seq"', 74, true);


--
-- Name: Match_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Match_id_seq"', 62, true);


--
-- Name: OtherGoal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."OtherGoal_id_seq"', 206, true);


--
-- Name: PasswordChangeRequest_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."PasswordChangeRequest_id_seq"', 1, false);


--
-- Name: PasswordResetToken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."PasswordResetToken_id_seq"', 2, true);


--
-- Name: Permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Permission_id_seq"', 48, true);


--
-- Name: PlayerTournamentClub_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."PlayerTournamentClub_id_seq"', 848, true);


--
-- Name: Player_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Player_id_seq"', 768, true);


--
-- Name: Role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Role_id_seq"', 5, true);


--
-- Name: RosterPlayer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."RosterPlayer_id_seq"', 1, false);


--
-- Name: Roster_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Roster_id_seq"', 1, false);


--
-- Name: Team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Team_id_seq"', 151, true);


--
-- Name: TournamentCategory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."TournamentCategory_id_seq"', 34, true);


--
-- Name: TournamentPosterTemplate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."TournamentPosterTemplate_id_seq"', 25, true);


--
-- Name: UserRole_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."UserRole_id_seq"', 6, true);


--
-- Name: UserToken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."UserToken_id_seq"', 7884, true);


--
-- Name: User_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."User_id_seq"', 4, true);


--
-- Name: ZoneMatchday_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."ZoneMatchday_id_seq"', 26, true);


--
-- Name: Zone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public."Zone_id_seq"', 4, true);


--
-- Name: tournament_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tournament_id_seq', 4, true);


--
-- Name: AuditLog AuditLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY (id);


--
-- Name: CategoryStanding CategoryStanding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CategoryStanding"
    ADD CONSTRAINT "CategoryStanding_pkey" PRIMARY KEY (id);


--
-- Name: Category Category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Category"
    ADD CONSTRAINT "Category_pkey" PRIMARY KEY (id);


--
-- Name: ClubZone ClubZone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ClubZone"
    ADD CONSTRAINT "ClubZone_pkey" PRIMARY KEY (id);


--
-- Name: Club Club_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Club"
    ADD CONSTRAINT "Club_pkey" PRIMARY KEY (id);


--
-- Name: EmailChangeRequest EmailChangeRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailChangeRequest"
    ADD CONSTRAINT "EmailChangeRequest_pkey" PRIMARY KEY (id);


--
-- Name: EmailVerificationToken EmailVerificationToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailVerificationToken"
    ADD CONSTRAINT "EmailVerificationToken_pkey" PRIMARY KEY (id);


--
-- Name: FlyerTemplate FlyerTemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FlyerTemplate"
    ADD CONSTRAINT "FlyerTemplate_pkey" PRIMARY KEY (id);


--
-- Name: Goal Goal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_pkey" PRIMARY KEY (id);


--
-- Name: League League_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."League"
    ADD CONSTRAINT "League_pkey" PRIMARY KEY (id);


--
-- Name: MatchAttachment MatchAttachment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchAttachment"
    ADD CONSTRAINT "MatchAttachment_pkey" PRIMARY KEY (id);


--
-- Name: MatchCategory MatchCategory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchCategory"
    ADD CONSTRAINT "MatchCategory_pkey" PRIMARY KEY (id);


--
-- Name: MatchLog MatchLog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchLog"
    ADD CONSTRAINT "MatchLog_pkey" PRIMARY KEY (id);


--
-- Name: MatchPosterCache MatchPosterCache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchPosterCache"
    ADD CONSTRAINT "MatchPosterCache_pkey" PRIMARY KEY (id);


--
-- Name: Match Match_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match"
    ADD CONSTRAINT "Match_pkey" PRIMARY KEY (id);


--
-- Name: OtherGoal OtherGoal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OtherGoal"
    ADD CONSTRAINT "OtherGoal_pkey" PRIMARY KEY (id);


--
-- Name: PasswordChangeRequest PasswordChangeRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordChangeRequest"
    ADD CONSTRAINT "PasswordChangeRequest_pkey" PRIMARY KEY (id);


--
-- Name: PasswordResetToken PasswordResetToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordResetToken"
    ADD CONSTRAINT "PasswordResetToken_pkey" PRIMARY KEY (id);


--
-- Name: Permission Permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Permission"
    ADD CONSTRAINT "Permission_pkey" PRIMARY KEY (id);


--
-- Name: PlayerTournamentClub PlayerTournamentClub_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PlayerTournamentClub"
    ADD CONSTRAINT "PlayerTournamentClub_pkey" PRIMARY KEY (id);


--
-- Name: Player Player_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Player"
    ADD CONSTRAINT "Player_pkey" PRIMARY KEY (id);


--
-- Name: RolePermission RolePermission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("roleId", "permissionId");


--
-- Name: Role Role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT "Role_pkey" PRIMARY KEY (id);


--
-- Name: RosterPlayer RosterPlayer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RosterPlayer"
    ADD CONSTRAINT "RosterPlayer_pkey" PRIMARY KEY (id);


--
-- Name: Roster Roster_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Roster"
    ADD CONSTRAINT "Roster_pkey" PRIMARY KEY (id);


--
-- Name: SiteIdentity SiteIdentity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SiteIdentity"
    ADD CONSTRAINT "SiteIdentity_pkey" PRIMARY KEY (id);


--
-- Name: Team Team_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_pkey" PRIMARY KEY (id);


--
-- Name: TournamentCategory TournamentCategory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentCategory"
    ADD CONSTRAINT "TournamentCategory_pkey" PRIMARY KEY (id);


--
-- Name: TournamentPosterTemplate TournamentPosterTemplate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentPosterTemplate"
    ADD CONSTRAINT "TournamentPosterTemplate_pkey" PRIMARY KEY (id);


--
-- Name: UserRole UserRole_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_pkey" PRIMARY KEY (id);


--
-- Name: UserToken UserToken_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserToken"
    ADD CONSTRAINT "UserToken_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: ZoneMatchday ZoneMatchday_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ZoneMatchday"
    ADD CONSTRAINT "ZoneMatchday_pkey" PRIMARY KEY (id);


--
-- Name: Zone Zone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Zone"
    ADD CONSTRAINT "Zone_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: tournament tournament_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament
    ADD CONSTRAINT tournament_pkey PRIMARY KEY (id);


--
-- Name: CategoryStanding_zoneId_tournamentCategoryId_clubId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "CategoryStanding_zoneId_tournamentCategoryId_clubId_key" ON public."CategoryStanding" USING btree ("zoneId", "tournamentCategoryId", "clubId");


--
-- Name: Category_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Category_name_key" ON public."Category" USING btree (name);


--
-- Name: ClubZone_clubId_zoneId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ClubZone_clubId_zoneId_key" ON public."ClubZone" USING btree ("clubId", "zoneId");


--
-- Name: ClubZone_zoneId_clubId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ClubZone_zoneId_clubId_key" ON public."ClubZone" USING btree ("zoneId", "clubId");


--
-- Name: Club_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Club_slug_key" ON public."Club" USING btree (slug);


--
-- Name: EmailChangeRequest_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "EmailChangeRequest_token_key" ON public."EmailChangeRequest" USING btree (token);


--
-- Name: EmailVerificationToken_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "EmailVerificationToken_token_key" ON public."EmailVerificationToken" USING btree (token);


--
-- Name: FlyerTemplate_competitionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "FlyerTemplate_competitionId_key" ON public."FlyerTemplate" USING btree ("competitionId");


--
-- Name: League_slug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "League_slug_key" ON public."League" USING btree (slug);


--
-- Name: MatchPosterCache_matchId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "MatchPosterCache_matchId_key" ON public."MatchPosterCache" USING btree ("matchId");


--
-- Name: PasswordChangeRequest_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PasswordChangeRequest_token_key" ON public."PasswordChangeRequest" USING btree (token);


--
-- Name: PasswordResetToken_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PasswordResetToken_token_key" ON public."PasswordResetToken" USING btree (token);


--
-- Name: Permission_module_action_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Permission_module_action_scope_key" ON public."Permission" USING btree (module, action, scope);


--
-- Name: PlayerTournamentClub_playerId_tournamentId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "PlayerTournamentClub_playerId_tournamentId_key" ON public."PlayerTournamentClub" USING btree ("playerId", "tournamentId");


--
-- Name: Player_dni_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Player_dni_key" ON public."Player" USING btree (dni);


--
-- Name: Role_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Role_key_key" ON public."Role" USING btree (key);


--
-- Name: RosterPlayer_rosterId_playerId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "RosterPlayer_rosterId_playerId_key" ON public."RosterPlayer" USING btree ("rosterId", "playerId");


--
-- Name: Roster_clubId_tournamentCategoryId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Roster_clubId_tournamentCategoryId_key" ON public."Roster" USING btree ("clubId", "tournamentCategoryId");


--
-- Name: Team_clubId_tournamentCategoryId_publicName_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Team_clubId_tournamentCategoryId_publicName_key" ON public."Team" USING btree ("clubId", "tournamentCategoryId", "publicName");


--
-- Name: TournamentCategory_tournamentId_categoryId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TournamentCategory_tournamentId_categoryId_key" ON public."TournamentCategory" USING btree ("tournamentId", "categoryId");


--
-- Name: TournamentPosterTemplate_tournamentId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "TournamentPosterTemplate_tournamentId_key" ON public."TournamentPosterTemplate" USING btree ("tournamentId");


--
-- Name: UserRole_userId_roleId_leagueId_clubId_categoryId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "UserRole_userId_roleId_leagueId_clubId_categoryId_key" ON public."UserRole" USING btree ("userId", "roleId", "leagueId", "clubId", "categoryId");


--
-- Name: UserToken_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "UserToken_token_key" ON public."UserToken" USING btree (token);


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: ZoneMatchday_zoneId_matchday_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ZoneMatchday_zoneId_matchday_key" ON public."ZoneMatchday" USING btree ("zoneId", matchday);


--
-- Name: Zone_tournamentId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "Zone_tournamentId_name_key" ON public."Zone" USING btree ("tournamentId", name);


--
-- Name: AuditLog AuditLog_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLog"
    ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: CategoryStanding CategoryStanding_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CategoryStanding"
    ADD CONSTRAINT "CategoryStanding_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: CategoryStanding CategoryStanding_tournamentCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CategoryStanding"
    ADD CONSTRAINT "CategoryStanding_tournamentCategoryId_fkey" FOREIGN KEY ("tournamentCategoryId") REFERENCES public."TournamentCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: CategoryStanding CategoryStanding_zoneId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CategoryStanding"
    ADD CONSTRAINT "CategoryStanding_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES public."Zone"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ClubZone ClubZone_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ClubZone"
    ADD CONSTRAINT "ClubZone_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ClubZone ClubZone_zoneId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ClubZone"
    ADD CONSTRAINT "ClubZone_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES public."Zone"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Club Club_leagueId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Club"
    ADD CONSTRAINT "Club_leagueId_fkey" FOREIGN KEY ("leagueId") REFERENCES public."League"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: EmailChangeRequest EmailChangeRequest_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailChangeRequest"
    ADD CONSTRAINT "EmailChangeRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: EmailVerificationToken EmailVerificationToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmailVerificationToken"
    ADD CONSTRAINT "EmailVerificationToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: FlyerTemplate FlyerTemplate_competitionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."FlyerTemplate"
    ADD CONSTRAINT "FlyerTemplate_competitionId_fkey" FOREIGN KEY ("competitionId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Goal Goal_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Goal Goal_matchCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_matchCategoryId_fkey" FOREIGN KEY ("matchCategoryId") REFERENCES public."MatchCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Goal Goal_playerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Goal"
    ADD CONSTRAINT "Goal_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES public."Player"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchAttachment MatchAttachment_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchAttachment"
    ADD CONSTRAINT "MatchAttachment_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public."Match"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchAttachment MatchAttachment_uploadedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchAttachment"
    ADD CONSTRAINT "MatchAttachment_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchCategory MatchCategory_closedById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchCategory"
    ADD CONSTRAINT "MatchCategory_closedById_fkey" FOREIGN KEY ("closedById") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: MatchCategory MatchCategory_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchCategory"
    ADD CONSTRAINT "MatchCategory_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public."Match"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchCategory MatchCategory_tournamentCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchCategory"
    ADD CONSTRAINT "MatchCategory_tournamentCategoryId_fkey" FOREIGN KEY ("tournamentCategoryId") REFERENCES public."TournamentCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchLog MatchLog_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchLog"
    ADD CONSTRAINT "MatchLog_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public."Match"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MatchLog MatchLog_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchLog"
    ADD CONSTRAINT "MatchLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: MatchPosterCache MatchPosterCache_matchId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MatchPosterCache"
    ADD CONSTRAINT "MatchPosterCache_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES public."Match"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Match Match_awayClubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match"
    ADD CONSTRAINT "Match_awayClubId_fkey" FOREIGN KEY ("awayClubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Match Match_homeClubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match"
    ADD CONSTRAINT "Match_homeClubId_fkey" FOREIGN KEY ("homeClubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: Match Match_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match"
    ADD CONSTRAINT "Match_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Match Match_zoneId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Match"
    ADD CONSTRAINT "Match_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES public."Zone"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OtherGoal OtherGoal_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OtherGoal"
    ADD CONSTRAINT "OtherGoal_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: OtherGoal OtherGoal_matchCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."OtherGoal"
    ADD CONSTRAINT "OtherGoal_matchCategoryId_fkey" FOREIGN KEY ("matchCategoryId") REFERENCES public."MatchCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PasswordChangeRequest PasswordChangeRequest_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordChangeRequest"
    ADD CONSTRAINT "PasswordChangeRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PasswordResetToken PasswordResetToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PasswordResetToken"
    ADD CONSTRAINT "PasswordResetToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PlayerTournamentClub PlayerTournamentClub_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PlayerTournamentClub"
    ADD CONSTRAINT "PlayerTournamentClub_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PlayerTournamentClub PlayerTournamentClub_playerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PlayerTournamentClub"
    ADD CONSTRAINT "PlayerTournamentClub_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES public."Player"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: PlayerTournamentClub PlayerTournamentClub_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PlayerTournamentClub"
    ADD CONSTRAINT "PlayerTournamentClub_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: RolePermission RolePermission_permissionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES public."Permission"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: RolePermission RolePermission_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RolePermission"
    ADD CONSTRAINT "RolePermission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: RosterPlayer RosterPlayer_playerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RosterPlayer"
    ADD CONSTRAINT "RosterPlayer_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES public."Player"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: RosterPlayer RosterPlayer_rosterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."RosterPlayer"
    ADD CONSTRAINT "RosterPlayer_rosterId_fkey" FOREIGN KEY ("rosterId") REFERENCES public."Roster"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Roster Roster_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Roster"
    ADD CONSTRAINT "Roster_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Roster Roster_tournamentCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Roster"
    ADD CONSTRAINT "Roster_tournamentCategoryId_fkey" FOREIGN KEY ("tournamentCategoryId") REFERENCES public."TournamentCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Team Team_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Team Team_tournamentCategoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Team"
    ADD CONSTRAINT "Team_tournamentCategoryId_fkey" FOREIGN KEY ("tournamentCategoryId") REFERENCES public."TournamentCategory"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: TournamentCategory TournamentCategory_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentCategory"
    ADD CONSTRAINT "TournamentCategory_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public."Category"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: TournamentCategory TournamentCategory_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentCategory"
    ADD CONSTRAINT "TournamentCategory_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: TournamentPosterTemplate TournamentPosterTemplate_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."TournamentPosterTemplate"
    ADD CONSTRAINT "TournamentPosterTemplate_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: UserRole UserRole_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public."Category"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: UserRole UserRole_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: UserRole UserRole_leagueId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_leagueId_fkey" FOREIGN KEY ("leagueId") REFERENCES public."League"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: UserRole UserRole_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."Role"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: UserRole UserRole_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserRole"
    ADD CONSTRAINT "UserRole_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: UserToken UserToken_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."UserToken"
    ADD CONSTRAINT "UserToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: User User_clubId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES public."Club"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ZoneMatchday ZoneMatchday_zoneId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ZoneMatchday"
    ADD CONSTRAINT "ZoneMatchday_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES public."Zone"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Zone Zone_tournamentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Zone"
    ADD CONSTRAINT "Zone_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES public.tournament(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: tournament tournament_leagueId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournament
    ADD CONSTRAINT "tournament_leagueId_fkey" FOREIGN KEY ("leagueId") REFERENCES public."League"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict lB1eU2HEIln9ptCBEu4g0VprBmCaMqZA3fMuJccMwnb7owYpLBMQygeMCXEkpIG

