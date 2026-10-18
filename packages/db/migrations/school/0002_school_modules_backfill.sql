-- kind: backfill
-- Roles that existed before the new modules get the new permissions, and the admission requests that used to sit in the approvals queue become enquiries.

UPDATE "roles" SET "permissions" = (
  SELECT jsonb_agg(DISTINCT p) FROM jsonb_array_elements_text("permissions" || '["homework.read","homework.write","exams.read","exams.write","exams.publish","admissions.read","admissions.write","messages.read","messages.write","events.read","events.write"]'::jsonb) p
) WHERE "key" = 'principal';
--> statement-breakpoint
UPDATE "roles" SET "permissions" = (
  SELECT jsonb_agg(DISTINCT p) FROM jsonb_array_elements_text("permissions" || '["admissions.read","admissions.write","messages.read","messages.write","events.read","events.write","homework.read","exams.read"]'::jsonb) p
) WHERE "key" = 'office';
--> statement-breakpoint
UPDATE "roles" SET "permissions" = (
  SELECT jsonb_agg(DISTINCT p) FROM jsonb_array_elements_text("permissions" || '["homework.read","homework.write","exams.read","exams.write","messages.read","messages.write","events.read"]'::jsonb) p
) WHERE "key" = 'teacher';
--> statement-breakpoint
UPDATE "roles" SET "permissions" = (
  SELECT jsonb_agg(DISTINCT p) FROM jsonb_array_elements_text("permissions" || '["events.read"]'::jsonb) p
) WHERE "key" = 'accountant';
--> statement-breakpoint
INSERT INTO "enquiries" ("id", "child_name", "grade_sought", "guardian_name", "phone", "stage", "source", "created_at")
SELECT replace("id", 'apr_adm_', 'enq_'), "requester_name", COALESCE(("payload"->>'grade')::int, 1), 'Family ' || split_part("requester_name", ' ', 2), '', 'applied', 'website', "created_at"
FROM "approvals" WHERE "kind" = 'admission'
ON CONFLICT ("id") DO NOTHING;
--> statement-breakpoint
DELETE FROM "approvals" WHERE "kind" = 'admission';
