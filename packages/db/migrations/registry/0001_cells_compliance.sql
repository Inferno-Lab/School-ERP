-- kind: expand
-- A cell can be closed to new schools, and the compliance desk (agreements and breach notices) gets its table.

ALTER TABLE "cells" ADD COLUMN "accepting" boolean DEFAULT true NOT NULL;
--> statement-breakpoint
CREATE TABLE "compliance_items" (
	"id" text PRIMARY KEY NOT NULL,
	"school_id" text NOT NULL REFERENCES "schools"("id") ON DELETE CASCADE,
	"kind" text NOT NULL,
	"title" text NOT NULL,
	"status" text DEFAULT 'open' NOT NULL,
	"note" text DEFAULT '' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deadline_at" timestamp with time zone,
	"closed_at" timestamp with time zone
);
--> statement-breakpoint
CREATE INDEX "compliance_school_idx" ON "compliance_items" ("school_id");
