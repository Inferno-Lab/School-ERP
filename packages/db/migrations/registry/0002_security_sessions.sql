-- kind: expand
-- Console token version, session client, and indexes for session and flag lookups.

ALTER TABLE "console_users" ADD COLUMN "token_version" integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE "console_sessions" ADD COLUMN "client" text DEFAULT 'web' NOT NULL;

CREATE INDEX "console_sessions_user_idx" ON "console_sessions" ("user_id");
CREATE INDEX "console_otp_user_idx" ON "console_otp" ("user_id");
CREATE INDEX "flags_school_key_idx" ON "flags" ("school_id", "key");
