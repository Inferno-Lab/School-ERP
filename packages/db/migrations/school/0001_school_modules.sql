-- kind: expand
-- Homework detail, exams and marks, the admissions pipeline, the family message inbox, event detail and data requests.
-- Everything here is new columns and tables, so the code that ran before this migration keeps working.

ALTER TABLE "homework" ADD COLUMN "description" text DEFAULT '' NOT NULL;
--> statement-breakpoint
ALTER TABLE "homework" ADD COLUMN "max_marks" integer DEFAULT 20 NOT NULL;
--> statement-breakpoint
ALTER TABLE "homework" ADD COLUMN "created_by" text;
--> statement-breakpoint
ALTER TABLE "homework_submissions" ADD COLUMN "score" integer;
--> statement-breakpoint
ALTER TABLE "homework_submissions" ADD COLUMN "feedback" text DEFAULT '' NOT NULL;
--> statement-breakpoint
CREATE TABLE "exams" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"class_id" text NOT NULL REFERENCES "classes"("id") ON DELETE CASCADE,
	"starts_on" date NOT NULL,
	"ends_on" date NOT NULL,
	"status" text DEFAULT 'upcoming' NOT NULL,
	"published_at" timestamp with time zone,
	"created_by" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX "exams_class_idx" ON "exams" ("class_id");
--> statement-breakpoint
CREATE TABLE "exam_subjects" (
	"exam_id" text NOT NULL REFERENCES "exams"("id") ON DELETE CASCADE,
	"subject_id" text NOT NULL REFERENCES "subjects"("id"),
	"on_date" date,
	"max_marks" integer DEFAULT 100 NOT NULL,
	PRIMARY KEY ("exam_id", "subject_id")
);
--> statement-breakpoint
CREATE TABLE "exam_marks" (
	"exam_id" text NOT NULL REFERENCES "exams"("id") ON DELETE CASCADE,
	"student_id" text NOT NULL REFERENCES "students"("id") ON DELETE CASCADE,
	"subject_id" text NOT NULL REFERENCES "subjects"("id"),
	"score" numeric(6,2),
	"absent" boolean DEFAULT false NOT NULL,
	PRIMARY KEY ("exam_id", "student_id", "subject_id")
);
--> statement-breakpoint
CREATE TABLE "enquiries" (
	"id" text PRIMARY KEY NOT NULL,
	"child_name" text NOT NULL,
	"grade_sought" integer NOT NULL,
	"guardian_name" text NOT NULL,
	"phone" text DEFAULT '' NOT NULL,
	"email" text,
	"source" text DEFAULT 'walk-in' NOT NULL,
	"stage" text DEFAULT 'enquiry' NOT NULL,
	"test_on" date,
	"note" text DEFAULT '' NOT NULL,
	"student_id" text REFERENCES "students"("id") ON DELETE SET NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX "enquiries_stage_idx" ON "enquiries" ("stage");
--> statement-breakpoint
CREATE TABLE "threads" (
	"id" text PRIMARY KEY NOT NULL,
	"guardian_id" text REFERENCES "guardians"("id") ON DELETE SET NULL,
	"student_id" text REFERENCES "students"("id") ON DELETE SET NULL,
	"subject" text NOT NULL,
	"status" text DEFAULT 'open' NOT NULL,
	"assigned_to" text REFERENCES "users"("id") ON DELETE SET NULL,
	"last_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX "threads_last_idx" ON "threads" ("last_at");
--> statement-breakpoint
CREATE TABLE "thread_messages" (
	"id" text PRIMARY KEY NOT NULL,
	"thread_id" text NOT NULL REFERENCES "threads"("id") ON DELETE CASCADE,
	"from_kind" text NOT NULL,
	"sender_name" text NOT NULL,
	"body" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"read_at" timestamp with time zone
);
--> statement-breakpoint
CREATE INDEX "thread_messages_thread_idx" ON "thread_messages" ("thread_id", "created_at");
--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "audience" text DEFAULT 'everyone' NOT NULL;
--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "venue" text DEFAULT '' NOT NULL;
--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "created_by" text;
--> statement-breakpoint
CREATE TABLE "event_rsvps" (
	"event_id" text NOT NULL REFERENCES "events"("id") ON DELETE CASCADE,
	"student_id" text NOT NULL REFERENCES "students"("id") ON DELETE CASCADE,
	"status" text NOT NULL,
	PRIMARY KEY ("event_id", "student_id")
);
--> statement-breakpoint
CREATE TABLE "data_requests" (
	"id" text PRIMARY KEY NOT NULL,
	"kind" text NOT NULL,
	"subject_name" text NOT NULL,
	"requested_by" text DEFAULT '' NOT NULL,
	"status" text DEFAULT 'open' NOT NULL,
	"note" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"resolved_at" timestamp with time zone,
	"resolved_by" text
);
