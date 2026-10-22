-- kind: expand
-- Token version for fast revocation, session client, and indexes for the lookups the API actually makes.

ALTER TABLE "users" ADD COLUMN "token_version" integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE "sessions" ADD COLUMN "client" text DEFAULT 'web' NOT NULL;

CREATE INDEX "otp_challenges_user_idx" ON "otp_challenges" ("user_id");
CREATE INDEX "sessions_user_live_idx" ON "sessions" ("user_id") WHERE "revoked_at" IS NULL;
CREATE INDEX "student_guardians_guardian_idx" ON "student_guardians" ("guardian_id");
CREATE INDEX "guardians_user_idx" ON "guardians" ("user_id");
CREATE INDEX "students_user_idx" ON "students" ("user_id");
CREATE INDEX "user_roles_role_idx" ON "user_roles" ("role_id");
CREATE INDEX "homework_class_due_idx" ON "homework" ("class_id", "due_on");
CREATE INDEX "notices_status_pub_idx" ON "notices" ("status", "published_at");
CREATE INDEX "audit_entity_idx" ON "audit_log" ("entity", "entity_id");
CREATE INDEX "fee_invoices_student_due_idx" ON "fee_invoices" ("student_id", "due_on");
CREATE INDEX "substitutions_date_idx" ON "substitutions" ("date");
CREATE INDEX "users_phone_digits_idx" ON "users" (right(regexp_replace(coalesce("phone", ''), '\D', '', 'g'), 10));
