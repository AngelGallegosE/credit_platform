SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: log_credit_application_changes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_credit_application_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        event_type_value TEXT;
        metadata_value JSONB;
        changed_fields JSONB := '{}'::JSONB;
        old_record JSONB;
        new_record JSONB;
        key TEXT;
      BEGIN
        -- Determinar el tipo de evento
        IF TG_OP = 'INSERT' THEN
          event_type_value := 'created';
          new_record := to_jsonb(NEW);
          -- Guardar todos los valores nuevos
          metadata_value := jsonb_build_object(
            'new_values', new_record
          );
        ELSIF TG_OP = 'UPDATE' THEN
          event_type_value := 'updated';
          old_record := to_jsonb(OLD);
          new_record := to_jsonb(NEW);

          -- Comparar y guardar solo los campos que cambiaron
          FOR key IN SELECT jsonb_object_keys(new_record) LOOP
            IF old_record->>key IS DISTINCT FROM new_record->>key THEN
              changed_fields := changed_fields || jsonb_build_object(
                key, jsonb_build_object(
                  'old_value', old_record->key,
                  'new_value', new_record->key
                )
              );
            END IF;
          END LOOP;

          metadata_value := jsonb_build_object(
            'changed_fields', changed_fields
          );
        ELSIF TG_OP = 'DELETE' THEN
          event_type_value := 'deleted';
          old_record := to_jsonb(OLD);
          -- Guardar todos los valores antiguos
          metadata_value := jsonb_build_object(
            'old_values', old_record
          );
        END IF;

        -- Insertar el evento
        INSERT INTO credit_application_events (
          credit_application_id,
          event_type,
          metadata,
          created_at,
          updated_at
        ) VALUES (
          COALESCE(NEW.id, OLD.id),
          event_type_value,
          metadata_value,
          NOW(),
          NOW()
        );

        -- Retornar el registro apropiado
        IF TG_OP = 'DELETE' THEN
          RETURN OLD;
        ELSE
          RETURN NEW;
        END IF;
      END;
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: credit_application_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_application_events (
    id bigint NOT NULL,
    credit_application_id bigint NOT NULL,
    event_type character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: credit_application_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.credit_application_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credit_application_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.credit_application_events_id_seq OWNED BY public.credit_application_events.id;


--
-- Name: credit_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_applications (
    id bigint NOT NULL,
    country character varying NOT NULL,
    full_name character varying NOT NULL,
    requested_amount numeric(15,2) NOT NULL,
    application_date date NOT NULL,
    status character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    validation_result jsonb,
    banking_data jsonb,
    monthly_income numeric(15,2),
    user_id bigint NOT NULL
)
PARTITION BY LIST (country);


--
-- Name: credit_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.credit_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credit_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.credit_applications_id_seq OWNED BY public.credit_applications.id;


--
-- Name: credit_applications_mexico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_applications_mexico (
    id bigint DEFAULT nextval('public.credit_applications_id_seq'::regclass) CONSTRAINT credit_applications_id_not_null NOT NULL,
    country character varying CONSTRAINT credit_applications_country_not_null NOT NULL,
    full_name character varying CONSTRAINT credit_applications_full_name_not_null NOT NULL,
    requested_amount numeric(15,2) CONSTRAINT credit_applications_requested_amount_not_null NOT NULL,
    application_date date CONSTRAINT credit_applications_application_date_not_null NOT NULL,
    status character varying CONSTRAINT credit_applications_status_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT credit_applications_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT credit_applications_updated_at_not_null NOT NULL,
    validation_result jsonb,
    banking_data jsonb,
    monthly_income numeric(15,2),
    user_id bigint CONSTRAINT credit_applications_user_id_not_null NOT NULL
);


--
-- Name: credit_applications_portugal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credit_applications_portugal (
    id bigint DEFAULT nextval('public.credit_applications_id_seq'::regclass) CONSTRAINT credit_applications_id_not_null NOT NULL,
    country character varying CONSTRAINT credit_applications_country_not_null NOT NULL,
    full_name character varying CONSTRAINT credit_applications_full_name_not_null NOT NULL,
    requested_amount numeric(15,2) CONSTRAINT credit_applications_requested_amount_not_null NOT NULL,
    application_date date CONSTRAINT credit_applications_application_date_not_null NOT NULL,
    status character varying CONSTRAINT credit_applications_status_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT credit_applications_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT credit_applications_updated_at_not_null NOT NULL,
    validation_result jsonb,
    banking_data jsonb,
    monthly_income numeric(15,2),
    user_id bigint CONSTRAINT credit_applications_user_id_not_null NOT NULL
);


--
-- Name: jwt_denylists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jwt_denylists (
    id bigint NOT NULL,
    jti character varying,
    exp timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: jwt_denylists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jwt_denylists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jwt_denylists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jwt_denylists_id_seq OWNED BY public.jwt_denylists.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    full_name character varying,
    role character varying,
    jti character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: credit_applications_mexico; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications ATTACH PARTITION public.credit_applications_mexico FOR VALUES IN ('mexico');


--
-- Name: credit_applications_portugal; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications ATTACH PARTITION public.credit_applications_portugal FOR VALUES IN ('portugal');


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: credit_application_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_application_events ALTER COLUMN id SET DEFAULT nextval('public.credit_application_events_id_seq'::regclass);


--
-- Name: credit_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications ALTER COLUMN id SET DEFAULT nextval('public.credit_applications_id_seq'::regclass);


--
-- Name: jwt_denylists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_denylists ALTER COLUMN id SET DEFAULT nextval('public.jwt_denylists_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: credit_application_events credit_application_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_application_events
    ADD CONSTRAINT credit_application_events_pkey PRIMARY KEY (id);


--
-- Name: credit_applications credit_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications
    ADD CONSTRAINT credit_applications_pkey PRIMARY KEY (id, country);


--
-- Name: credit_applications_mexico credit_applications_mexico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications_mexico
    ADD CONSTRAINT credit_applications_mexico_pkey PRIMARY KEY (id, country);


--
-- Name: credit_applications_portugal credit_applications_portugal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_applications_portugal
    ADD CONSTRAINT credit_applications_portugal_pkey PRIMARY KEY (id, country);


--
-- Name: jwt_denylists jwt_denylists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_denylists
    ADD CONSTRAINT jwt_denylists_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_credit_applications_on_application_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_application_date ON ONLY public.credit_applications USING btree (application_date);


--
-- Name: credit_applications_mexico_application_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_application_date_idx ON public.credit_applications_mexico USING btree (application_date);


--
-- Name: index_credit_applications_on_country_and_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_country_and_full_name ON ONLY public.credit_applications USING btree (country, full_name);


--
-- Name: credit_applications_mexico_country_full_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_country_full_name_idx ON public.credit_applications_mexico USING btree (country, full_name);


--
-- Name: index_credit_applications_on_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_country ON ONLY public.credit_applications USING btree (country);


--
-- Name: credit_applications_mexico_country_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_country_idx ON public.credit_applications_mexico USING btree (country);


--
-- Name: index_credit_applications_on_country_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_country_and_status ON ONLY public.credit_applications USING btree (country, status);


--
-- Name: credit_applications_mexico_country_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_country_status_idx ON public.credit_applications_mexico USING btree (country, status);


--
-- Name: index_credit_applications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_status ON ONLY public.credit_applications USING btree (status);


--
-- Name: credit_applications_mexico_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_status_idx ON public.credit_applications_mexico USING btree (status);


--
-- Name: index_credit_applications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_applications_on_user_id ON ONLY public.credit_applications USING btree (user_id);


--
-- Name: credit_applications_mexico_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_mexico_user_id_idx ON public.credit_applications_mexico USING btree (user_id);


--
-- Name: credit_applications_portugal_application_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_application_date_idx ON public.credit_applications_portugal USING btree (application_date);


--
-- Name: credit_applications_portugal_country_full_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_country_full_name_idx ON public.credit_applications_portugal USING btree (country, full_name);


--
-- Name: credit_applications_portugal_country_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_country_idx ON public.credit_applications_portugal USING btree (country);


--
-- Name: credit_applications_portugal_country_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_country_status_idx ON public.credit_applications_portugal USING btree (country, status);


--
-- Name: credit_applications_portugal_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_status_idx ON public.credit_applications_portugal USING btree (status);


--
-- Name: credit_applications_portugal_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_applications_portugal_user_id_idx ON public.credit_applications_portugal USING btree (user_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_credit_application_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_application_events_on_created_at ON public.credit_application_events USING btree (created_at);


--
-- Name: index_credit_application_events_on_credit_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_application_events_on_credit_application_id ON public.credit_application_events USING btree (credit_application_id);


--
-- Name: index_credit_application_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credit_application_events_on_event_type ON public.credit_application_events USING btree (event_type);


--
-- Name: index_jwt_denylists_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jwt_denylists_on_jti ON public.jwt_denylists USING btree (jti);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_jti ON public.users USING btree (jti);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: credit_applications_mexico_application_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_application_date ATTACH PARTITION public.credit_applications_mexico_application_date_idx;


--
-- Name: credit_applications_mexico_country_full_name_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country_and_full_name ATTACH PARTITION public.credit_applications_mexico_country_full_name_idx;


--
-- Name: credit_applications_mexico_country_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country ATTACH PARTITION public.credit_applications_mexico_country_idx;


--
-- Name: credit_applications_mexico_country_status_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country_and_status ATTACH PARTITION public.credit_applications_mexico_country_status_idx;


--
-- Name: credit_applications_mexico_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.credit_applications_pkey ATTACH PARTITION public.credit_applications_mexico_pkey;


--
-- Name: credit_applications_mexico_status_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_status ATTACH PARTITION public.credit_applications_mexico_status_idx;


--
-- Name: credit_applications_mexico_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_user_id ATTACH PARTITION public.credit_applications_mexico_user_id_idx;


--
-- Name: credit_applications_portugal_application_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_application_date ATTACH PARTITION public.credit_applications_portugal_application_date_idx;


--
-- Name: credit_applications_portugal_country_full_name_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country_and_full_name ATTACH PARTITION public.credit_applications_portugal_country_full_name_idx;


--
-- Name: credit_applications_portugal_country_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country ATTACH PARTITION public.credit_applications_portugal_country_idx;


--
-- Name: credit_applications_portugal_country_status_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_country_and_status ATTACH PARTITION public.credit_applications_portugal_country_status_idx;


--
-- Name: credit_applications_portugal_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.credit_applications_pkey ATTACH PARTITION public.credit_applications_portugal_pkey;


--
-- Name: credit_applications_portugal_status_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_status ATTACH PARTITION public.credit_applications_portugal_status_idx;


--
-- Name: credit_applications_portugal_user_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_credit_applications_on_user_id ATTACH PARTITION public.credit_applications_portugal_user_id_idx;


--
-- Name: credit_applications credit_application_changes_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER credit_application_changes_trigger AFTER INSERT OR DELETE OR UPDATE ON public.credit_applications FOR EACH ROW EXECUTE FUNCTION public.log_credit_application_changes();


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: credit_applications fk_rails_fd520c267c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.credit_applications
    ADD CONSTRAINT fk_rails_fd520c267c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251216193631'),
('20251216012602'),
('20251211183116'),
('20251211181101'),
('20251211043757'),
('20251210222342'),
('20251210220942'),
('20251210220927'),
('20251210220920'),
('20251210003516');

