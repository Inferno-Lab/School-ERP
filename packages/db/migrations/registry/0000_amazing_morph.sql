-- kind: expand
CREATE TABLE "actions" (
	"id" text PRIMARY KEY NOT NULL,
	"action" text NOT NULL,
	"school_id" text,
	"school_name" text,
	"params" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"status" text NOT NULL,
	"requested_by" text NOT NULL,
	"approved_by" text,
	"dry_run" boolean DEFAULT false NOT NULL,
	"summary" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"finished_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "blueprints" (
	"id" text PRIMARY KEY NOT NULL,
	"key" text NOT NULL,
	"version" integer NOT NULL,
	"name" text NOT NULL,
	"target" text NOT NULL,
	"plan" text,
	"steps" jsonb NOT NULL,
	"active" boolean DEFAULT false NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "builds" (
	"id" text PRIMARY KEY NOT NULL,
	"school_id" text NOT NULL,
	"platform" text NOT NULL,
	"version" text NOT NULL,
	"status" text NOT NULL,
	"url" text,
	"note" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "cells" (
	"key" text PRIMARY KEY NOT NULL,
	"target" text NOT NULL,
	"region" text NOT NULL,
	"max_schools" integer DEFAULT 50 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "console_audit" (
	"id" text PRIMARY KEY NOT NULL,
	"at" timestamp with time zone DEFAULT now() NOT NULL,
	"actor" text NOT NULL,
	"action" text NOT NULL,
	"entity" text NOT NULL,
	"entity_id" text,
	"detail" jsonb DEFAULT '{}'::jsonb NOT NULL
);
--> statement-breakpoint
CREATE TABLE "console_otp" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"code_hash" text NOT NULL,
	"attempts" integer DEFAULT 0 NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"used_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "console_sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"refresh_hash" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "console_settings" (
	"key" text PRIMARY KEY NOT NULL,
	"value" jsonb NOT NULL,
	"updated_by" text,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "console_users" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"password_hash" text,
	"roles" jsonb NOT NULL,
	"status" text DEFAULT 'active' NOT NULL,
	"last_seen_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "flags" (
	"key" text NOT NULL,
	"school_id" text DEFAULT '*' NOT NULL,
	"label" text NOT NULL,
	"enabled" boolean DEFAULT false NOT NULL,
	"updated_by" text NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "flags_key_school_id_pk" PRIMARY KEY("key","school_id")
);
--> statement-breakpoint
CREATE TABLE "incidents" (
	"id" text PRIMARY KEY NOT NULL,
	"title" text NOT NULL,
	"state" text NOT NULL,
	"school_id" text,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"resolved_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "invoices" (
	"id" text PRIMARY KEY NOT NULL,
	"school_id" text NOT NULL,
	"school_name" text NOT NULL,
	"period" text NOT NULL,
	"amount" integer NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "metrics_minute" (
	"at" timestamp with time zone NOT NULL,
	"school_slug" text NOT NULL,
	"requests" integer DEFAULT 0 NOT NULL,
	"errors" integer DEFAULT 0 NOT NULL,
	"p95_ms" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "metrics_minute_at_school_slug_pk" PRIMARY KEY("at","school_slug")
);
--> statement-breakpoint
CREATE TABLE "migration_runs" (
	"id" text PRIMARY KEY NOT NULL,
	"tag" text NOT NULL,
	"kind" text NOT NULL,
	"school_id" text NOT NULL,
	"state" text NOT NULL,
	"ms" integer,
	"error" text,
	"at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "plans" (
	"key" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"per_student_year" integer NOT NULL,
	"modules" jsonb NOT NULL,
	"limits" jsonb NOT NULL
);
--> statement-breakpoint
CREATE TABLE "provision_runs" (
	"id" text PRIMARY KEY NOT NULL,
	"school_id" text NOT NULL,
	"school_name" text NOT NULL,
	"blueprint_key" text NOT NULL,
	"blueprint_version" integer NOT NULL,
	"target" text NOT NULL,
	"dry_run" boolean DEFAULT false NOT NULL,
	"status" text DEFAULT 'queued' NOT NULL,
	"payload" jsonb NOT NULL,
	"steps" jsonb NOT NULL,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"finished_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "releases" (
	"id" text PRIMARY KEY NOT NULL,
	"version" text NOT NULL,
	"notes" text DEFAULT '' NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"waves" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"halt_reason" text,
	"created_by" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "releases_version_unique" UNIQUE("version")
);
--> statement-breakpoint
CREATE TABLE "sandbox_messages" (
	"id" text PRIMARY KEY NOT NULL,
	"school_slug" text NOT NULL,
	"channel" text NOT NULL,
	"to_addr" text NOT NULL,
	"subject" text,
	"body" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "schools" (
	"id" text PRIMARY KEY NOT NULL,
	"slug" text NOT NULL,
	"name" text NOT NULL,
	"short_name" text NOT NULL,
	"color" text NOT NULL,
	"logo_text" text NOT NULL,
	"status" text DEFAULT 'onboarding' NOT NULL,
	"plan" text NOT NULL,
	"cell" text NOT NULL,
	"target" text NOT NULL,
	"region" text NOT NULL,
	"db_url_sealed" text,
	"db_name" text,
	"api_version" text DEFAULT '0.0.0' NOT NULL,
	"admin_version" text DEFAULT '0.0.0' NOT NULL,
	"app_version" text DEFAULT '0.0.0' NOT NULL,
	"config_version" integer DEFAULT 1 NOT NULL,
	"entitlement" jsonb NOT NULL,
	"contact" jsonb NOT NULL,
	"gstin" text DEFAULT '' NOT NULL,
	"board" text DEFAULT 'CBSE' NOT NULL,
	"address" text DEFAULT '' NOT NULL,
	"addressing" text DEFAULT 'path' NOT NULL,
	"custom_domain" text DEFAULT '' NOT NULL,
	"app_name" text DEFAULT '' NOT NULL,
	"students_count" integer DEFAULT 0 NOT NULL,
	"health" text DEFAULT 'unknown' NOT NULL,
	"health_ms" integer,
	"health_at" timestamp with time zone,
	"last_incident" text,
	"onboarding_done" integer DEFAULT 0 NOT NULL,
	"onboarding_total" integer DEFAULT 8 NOT NULL,
	"checklist" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"ring" text DEFAULT 'rest' NOT NULL,
	"profile_yaml" text,
	"created_by" text DEFAULT 'system' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "support_sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"school_id" text NOT NULL,
	"school_name" text NOT NULL,
	"reason" text NOT NULL,
	"status" text NOT NULL,
	"expires_at" timestamp with time zone,
	"started_by" text NOT NULL,
	"approved_by" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "wizard_drafts" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"step" integer DEFAULT 0 NOT NULL,
	"data" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"updated_by" text NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "console_otp" ADD CONSTRAINT "console_otp_user_id_console_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."console_users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "console_sessions" ADD CONSTRAINT "console_sessions_user_id_console_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."console_users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "schools" ADD CONSTRAINT "schools_plan_plans_key_fk" FOREIGN KEY ("plan") REFERENCES "public"."plans"("key") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "schools" ADD CONSTRAINT "schools_cell_cells_key_fk" FOREIGN KEY ("cell") REFERENCES "public"."cells"("key") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "blueprints_key_version_uq" ON "blueprints" USING btree ("key","version");--> statement-breakpoint
CREATE INDEX "console_audit_at_idx" ON "console_audit" USING btree ("at");--> statement-breakpoint
CREATE UNIQUE INDEX "console_users_email_uq" ON "console_users" USING btree ("email");--> statement-breakpoint
CREATE UNIQUE INDEX "migration_runs_uq" ON "migration_runs" USING btree ("tag","school_id");--> statement-breakpoint
CREATE INDEX "provision_runs_school_idx" ON "provision_runs" USING btree ("school_id");--> statement-breakpoint
CREATE INDEX "sandbox_created_idx" ON "sandbox_messages" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "schools_slug_uq" ON "schools" USING btree ("slug");--> statement-breakpoint
CREATE INDEX "schools_cell_idx" ON "schools" USING btree ("cell");