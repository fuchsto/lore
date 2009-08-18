--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE asset (
    asset_id integer NOT NULL,
    folder character varying(100) NOT NULL,
    filename character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.asset OWNER TO cuba;

--
-- Name: asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.asset_id_seq OWNER TO cuba;

--
-- Name: autobot; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE autobot (
    id integer NOT NULL,
    car_id integer NOT NULL,
    robot_id integer NOT NULL,
    can_fly boolean DEFAULT false NOT NULL
);


ALTER TABLE public.autobot OWNER TO cuba;

--
-- Name: autobot_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE autobot_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.autobot_id_seq OWNER TO cuba;

--
-- Name: bike_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE bike_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.bike_id_seq OWNER TO cuba;

--
-- Name: car; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE car (
    id integer NOT NULL,
    motorized_id integer NOT NULL,
    car_type_id integer NOT NULL,
    num_doors smallint NOT NULL
);


ALTER TABLE public.car OWNER TO cuba;

--
-- Name: car_features; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE car_features (
    id integer NOT NULL,
    car_id integer NOT NULL,
    color character varying(10) NOT NULL
);


ALTER TABLE public.car_features OWNER TO cuba;

--
-- Name: car_features_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE car_features_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.car_features_id_seq OWNER TO cuba;

--
-- Name: car_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE car_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.car_id_seq OWNER TO cuba;

--
-- Name: car_type; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE car_type (
    car_type_id integer NOT NULL,
    type_name character varying(100) NOT NULL
);


ALTER TABLE public.car_type OWNER TO cuba;

--
-- Name: car_type_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE car_type_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.car_type_id_seq OWNER TO cuba;

--
-- Name: convertible; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE convertible (
    id integer NOT NULL,
    car_id integer NOT NULL
);


ALTER TABLE public.convertible OWNER TO cuba;

--
-- Name: convertible_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE convertible_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.convertible_id_seq OWNER TO cuba;

--
-- Name: document_asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE document_asset (
    id integer NOT NULL,
    asset_id integer NOT NULL,
    doctype character varying(10),
    author character varying(30)
);


ALTER TABLE public.document_asset OWNER TO cuba;

--
-- Name: document_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE document_asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.document_asset_id_seq OWNER TO cuba;

--
-- Name: garage; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE garage (
    garage_id integer NOT NULL,
    vehicle_id integer NOT NULL
);


ALTER TABLE public.garage OWNER TO cuba;

--
-- Name: garage_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE garage_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.garage_id_seq OWNER TO cuba;

--
-- Name: manuf_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE manuf_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.manuf_id_seq OWNER TO cuba;

--
-- Name: manufacturer; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE manufacturer (
    manuf_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.manufacturer OWNER TO cuba;

--
-- Name: media_asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE media_asset (
    id integer NOT NULL,
    asset_id integer NOT NULL,
    media_type character varying(10) NOT NULL
);


ALTER TABLE public.media_asset OWNER TO cuba;

--
-- Name: media_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE media_asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_asset_id_seq OWNER TO cuba;

--
-- Name: motor; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE motor (
    id integer NOT NULL,
    motor_name character varying(30) NOT NULL,
    kw integer NOT NULL
);


ALTER TABLE public.motor OWNER TO cuba;

--
-- Name: motor_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE motor_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.motor_id_seq OWNER TO cuba;

--
-- Name: motorbike; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE motorbike (
    bike_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    is_chopper boolean NOT NULL
);


ALTER TABLE public.motorbike OWNER TO cuba;

--
-- Name: motorized; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE motorized (
    vehicle_id integer NOT NULL,
    motor_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.motorized OWNER TO cuba;

--
-- Name: motorized_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE motorized_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.motorized_id_seq OWNER TO cuba;

--
-- Name: other_id_1_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE other_id_1_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.other_id_1_seq OWNER TO cuba;

--
-- Name: owner; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE owner (
    owner_id integer NOT NULL,
    name character varying(200) NOT NULL
);


ALTER TABLE public.owner OWNER TO cuba;

--
-- Name: owner_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE owner_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.owner_id_seq OWNER TO cuba;

--
-- Name: robot; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE robot (
    id integer NOT NULL,
    robot_class character varying(30) NOT NULL,
    motor_type character varying(20),
    locomotion_type character varying(40)
);


ALTER TABLE public.robot OWNER TO cuba;

--
-- Name: robot_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE robot_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.robot_id_seq OWNER TO cuba;

--
-- Name: trailer; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE trailer (
    trailer_id integer NOT NULL,
    car_id integer NOT NULL,
    maxweight integer NOT NULL
);


ALTER TABLE public.trailer OWNER TO cuba;

--
-- Name: trailer_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE trailer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.trailer_id_seq OWNER TO cuba;

--
-- Name: vehicle; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE vehicle (
    id integer NOT NULL,
    manuf_id integer,
    num_seats smallint NOT NULL,
    maxspeed integer NOT NULL,
    name character varying(100) NOT NULL,
    owner_id integer
);


ALTER TABLE public.vehicle OWNER TO cuba;

--
-- Name: vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE vehicle_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.vehicle_id_seq OWNER TO cuba;

--
-- Name: vehicle_owner; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE vehicle_owner (
    owner_id integer NOT NULL,
    vehicle_id integer NOT NULL
);


ALTER TABLE public.vehicle_owner OWNER TO cuba;

--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: asset; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE asset FROM PUBLIC;
REVOKE ALL ON TABLE asset FROM cuba;
GRANT ALL ON TABLE asset TO cuba;
GRANT ALL ON TABLE asset TO cuba;


--
-- Name: asset_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE asset_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE asset_id_seq FROM cuba;
GRANT ALL ON SEQUENCE asset_id_seq TO cuba;
GRANT ALL ON SEQUENCE asset_id_seq TO cuba;


--
-- Name: autobot; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE autobot FROM PUBLIC;
REVOKE ALL ON TABLE autobot FROM cuba;
GRANT ALL ON TABLE autobot TO cuba;
GRANT ALL ON TABLE autobot TO cuba;


--
-- Name: autobot_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE autobot_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE autobot_id_seq FROM cuba;
GRANT ALL ON SEQUENCE autobot_id_seq TO cuba;
GRANT ALL ON SEQUENCE autobot_id_seq TO cuba;


--
-- Name: bike_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE bike_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE bike_id_seq FROM cuba;
GRANT ALL ON SEQUENCE bike_id_seq TO cuba;


--
-- Name: car; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE car FROM PUBLIC;
REVOKE ALL ON TABLE car FROM cuba;
GRANT ALL ON TABLE car TO cuba;


--
-- Name: car_features; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE car_features FROM PUBLIC;
REVOKE ALL ON TABLE car_features FROM cuba;
GRANT ALL ON TABLE car_features TO cuba;
GRANT ALL ON TABLE car_features TO cuba;


--
-- Name: car_features_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE car_features_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE car_features_id_seq FROM cuba;
GRANT ALL ON SEQUENCE car_features_id_seq TO cuba;
GRANT ALL ON SEQUENCE car_features_id_seq TO cuba;


--
-- Name: car_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE car_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE car_id_seq FROM cuba;
GRANT ALL ON SEQUENCE car_id_seq TO cuba;


--
-- Name: car_type; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE car_type FROM PUBLIC;
REVOKE ALL ON TABLE car_type FROM cuba;
GRANT ALL ON TABLE car_type TO cuba;


--
-- Name: car_type_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE car_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE car_type_id_seq FROM cuba;
GRANT ALL ON SEQUENCE car_type_id_seq TO cuba;


--
-- Name: convertible; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE convertible FROM PUBLIC;
REVOKE ALL ON TABLE convertible FROM cuba;
GRANT ALL ON TABLE convertible TO cuba;


--
-- Name: convertible_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE convertible_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE convertible_id_seq FROM cuba;
GRANT ALL ON SEQUENCE convertible_id_seq TO cuba;


--
-- Name: document_asset; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE document_asset FROM PUBLIC;
REVOKE ALL ON TABLE document_asset FROM cuba;
GRANT ALL ON TABLE document_asset TO cuba;
GRANT ALL ON TABLE document_asset TO cuba;


--
-- Name: document_asset_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE document_asset_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE document_asset_id_seq FROM cuba;
GRANT ALL ON SEQUENCE document_asset_id_seq TO cuba;
GRANT ALL ON SEQUENCE document_asset_id_seq TO cuba;


--
-- Name: garage; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE garage FROM PUBLIC;
REVOKE ALL ON TABLE garage FROM cuba;
GRANT ALL ON TABLE garage TO cuba;


--
-- Name: garage_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE garage_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE garage_id_seq FROM cuba;
GRANT ALL ON SEQUENCE garage_id_seq TO cuba;


--
-- Name: manuf_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE manuf_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE manuf_id_seq FROM cuba;
GRANT ALL ON SEQUENCE manuf_id_seq TO cuba;


--
-- Name: manufacturer; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE manufacturer FROM PUBLIC;
REVOKE ALL ON TABLE manufacturer FROM cuba;
GRANT ALL ON TABLE manufacturer TO cuba;


--
-- Name: media_asset; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE media_asset FROM PUBLIC;
REVOKE ALL ON TABLE media_asset FROM cuba;
GRANT ALL ON TABLE media_asset TO cuba;
GRANT ALL ON TABLE media_asset TO cuba;


--
-- Name: media_asset_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE media_asset_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE media_asset_id_seq FROM cuba;
GRANT ALL ON SEQUENCE media_asset_id_seq TO cuba;
GRANT ALL ON SEQUENCE media_asset_id_seq TO cuba;


--
-- Name: motor; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE motor FROM PUBLIC;
REVOKE ALL ON TABLE motor FROM cuba;
GRANT ALL ON TABLE motor TO cuba;
GRANT ALL ON TABLE motor TO cuba;


--
-- Name: motor_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE motor_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE motor_id_seq FROM cuba;
GRANT ALL ON SEQUENCE motor_id_seq TO cuba;
GRANT ALL ON SEQUENCE motor_id_seq TO cuba;


--
-- Name: motorbike; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE motorbike FROM PUBLIC;
REVOKE ALL ON TABLE motorbike FROM cuba;
GRANT ALL ON TABLE motorbike TO cuba;


--
-- Name: motorized; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE motorized FROM PUBLIC;
REVOKE ALL ON TABLE motorized FROM cuba;
GRANT ALL ON TABLE motorized TO cuba;
GRANT ALL ON TABLE motorized TO cuba;


--
-- Name: motorized_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE motorized_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE motorized_id_seq FROM cuba;
GRANT ALL ON SEQUENCE motorized_id_seq TO cuba;
GRANT ALL ON SEQUENCE motorized_id_seq TO cuba;


--
-- Name: robot; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE robot FROM PUBLIC;
REVOKE ALL ON TABLE robot FROM cuba;
GRANT ALL ON TABLE robot TO cuba;
GRANT ALL ON TABLE robot TO cuba;


--
-- Name: robot_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE robot_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE robot_id_seq FROM cuba;
GRANT ALL ON SEQUENCE robot_id_seq TO cuba;
GRANT ALL ON SEQUENCE robot_id_seq TO cuba;


--
-- Name: trailer; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE trailer FROM PUBLIC;
REVOKE ALL ON TABLE trailer FROM cuba;
GRANT ALL ON TABLE trailer TO cuba;


--
-- Name: trailer_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE trailer_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE trailer_id_seq FROM cuba;
GRANT ALL ON SEQUENCE trailer_id_seq TO cuba;


--
-- Name: vehicle; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE vehicle FROM PUBLIC;
REVOKE ALL ON TABLE vehicle FROM cuba;
GRANT ALL ON TABLE vehicle TO cuba;


--
-- Name: vehicle_id_seq; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON SEQUENCE vehicle_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE vehicle_id_seq FROM cuba;
GRANT ALL ON SEQUENCE vehicle_id_seq TO cuba;


--
-- PostgreSQL database dump complete
--

