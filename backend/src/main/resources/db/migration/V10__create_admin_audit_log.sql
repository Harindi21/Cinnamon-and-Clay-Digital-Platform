CREATE TABLE admin_audit_event (
    id uuid PRIMARY KEY,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    actor_subject varchar(200) NOT NULL,
    actor_username varchar(200) NOT NULL,
    actor_roles jsonb NOT NULL DEFAULT '[]'::jsonb,
    action varchar(80) NOT NULL,
    resource_type varchar(120) NOT NULL,
    resource_id varchar(200),
    request_id varchar(80),
    trace_id varchar(64),
    before_state jsonb,
    after_state jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT admin_audit_event_action_not_blank CHECK (btrim(action) <> ''),
    CONSTRAINT admin_audit_event_resource_type_not_blank CHECK (btrim(resource_type) <> '')
);

CREATE INDEX idx_admin_audit_event_occurred_at
    ON admin_audit_event (occurred_at DESC, id DESC);

CREATE INDEX idx_admin_audit_event_actor_username
    ON admin_audit_event (actor_username, occurred_at DESC);

CREATE INDEX idx_admin_audit_event_resource
    ON admin_audit_event (resource_type, resource_id, occurred_at DESC);

CREATE INDEX idx_admin_audit_event_action
    ON admin_audit_event (action, occurred_at DESC);

CREATE INDEX idx_admin_audit_event_request_id
    ON admin_audit_event (request_id)
    WHERE request_id IS NOT NULL;

CREATE INDEX idx_admin_audit_event_trace_id
    ON admin_audit_event (trace_id)
    WHERE trace_id IS NOT NULL;

CREATE OR REPLACE FUNCTION reject_admin_audit_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'admin_audit_event is append-only'
        USING ERRCODE = '55000';
END;
$$;

CREATE TRIGGER admin_audit_event_append_only
    BEFORE UPDATE OR DELETE OR TRUNCATE ON admin_audit_event
    FOR EACH STATEMENT
    EXECUTE FUNCTION reject_admin_audit_event_mutation();
