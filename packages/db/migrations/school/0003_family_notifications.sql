-- kind: expand
-- Which of a person's notifications they have read or dismissed in the app.

CREATE TABLE "notification_state" (
	"user_id" text NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
	"message_id" text NOT NULL,
	"state" text NOT NULL,
	"at" timestamp with time zone DEFAULT now() NOT NULL,
	PRIMARY KEY ("user_id", "message_id")
);
