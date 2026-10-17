import { z } from 'zod';
import { IsoDate } from './common.js';

export const AttendanceStatus = z.enum(['present', 'absent', 'late', 'leave']);
export type AttendanceStatus = z.infer<typeof AttendanceStatus>;

export const FeeStatus = z.enum(['paid', 'due', 'overdue', 'partial']);
export type FeeStatus = z.infer<typeof FeeStatus>;

export interface ClassInfo {
  id: string;
  name: string;
  grade: number;
  section: string;
  studentCount: number;
  classTeacherId: string | null;
  classTeacherName: string | null;
}

export interface StudentRow {
  id: string;
  admissionNo: string;
  name: string;
  initials: string;
  classId: string;
  className: string;
  rollNo: string;
  guardianName: string;
  feeStatus: FeeStatus;
  amountDue: number;
  /** Last ten school days, oldest first. null means no school that day. */
  attendance10: (AttendanceStatus | null)[];
  attendancePct: number;
  status: 'active' | 'inactive';
}

export interface StudentDetail extends StudentRow {
  dob: string;
  bloodGroup: string | null;
  house: string | null;
  address: string | null;
  guardianPhone: string | null;
  guardianEmail: string | null;
  admittedOn: string | null;
  recentActivity: { id: string; at: string; label: string }[];
  roll24: (AttendanceStatus | null)[];
}

export const StudentQuery = z.object({
  query: z.string().trim().max(80).optional(),
  classId: z.string().optional(),
  feeStatus: FeeStatus.optional(),
  attendance: z.enum(['low', 'perfect']).optional(),
  sort: z.enum(['name', 'class', 'attendance', 'due']).default('name'),
  dir: z.enum(['asc', 'desc']).default('asc'),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(25),
});
export type StudentQuery = z.infer<typeof StudentQuery>;

export interface StudentSummary {
  total: number;
  presentToday: number;
  feesDue: number;
  lowAttendance: number;
}

export const StudentCreate = z.object({
  name: z.string().trim().min(2, 'Enter the full name').max(80),
  classId: z.string().min(1, 'Choose a class'),
  rollNo: z.string().trim().max(10).optional(),
  dob: IsoDate,
  guardianName: z.string().trim().min(2).max(80),
  guardianPhone: z.string().trim().min(8).max(20),
  bloodGroup: z.string().trim().max(4).optional(),
  address: z.string().trim().max(200).optional(),
});
export type StudentCreate = z.infer<typeof StudentCreate>;

export const BulkStudentAction = z.object({
  ids: z.array(z.string()).min(1).max(500),
  action: z.enum(['remind-fees', 'message', 'export']),
});
export type BulkStudentAction = z.infer<typeof BulkStudentAction>;

// Attendance
export const AttendanceDayPut = z.object({
  classId: z.string(),
  date: IsoDate,
  marks: z.array(z.object({ studentId: z.string(), status: AttendanceStatus })).min(1).max(200),
});
export type AttendanceDayPut = z.infer<typeof AttendanceDayPut>;

export interface AttendanceDay {
  classId: string;
  date: string;
  submitted: boolean;
  marks: { studentId: string; name: string; rollNo: string; status: AttendanceStatus | null }[];
}

export interface AttendanceWeekPoint {
  date: string;
  label: string;
  present: number;
  total: number;
  pct: number;
  previousPct: number | null;
  isToday: boolean;
}

// Fees
export interface FeeSummary {
  collected: number;
  pending: number;
  overdue: number;
  target: number;
  byClass: { classId: string; className: string; collected: number; due: number }[];
}

export const PaymentCreate = z.object({
  studentId: z.string(),
  invoiceId: z.string(),
  amount: z.number().int().positive('Enter an amount'),
  method: z.enum(['cash', 'upi', 'card', 'netbanking', 'cheque']),
  reference: z.string().trim().max(60).optional(),
});
export type PaymentCreate = z.infer<typeof PaymentCreate>;

export interface InvoiceRow {
  id: string;
  studentId: string;
  title: string;
  amount: number;
  paid: number;
  dueOn: string;
  status: FeeStatus;
}

// Notices
export const NoticeCreate = z.object({
  title: z.string().trim().min(3, 'Give the notice a title').max(120),
  body: z.string().trim().min(3, 'Write the notice').max(4000),
  audience: z.enum(['everyone', 'parents', 'staff', 'class']).default('everyone'),
  classId: z.string().optional(),
  publish: z.boolean().default(false),
});
export type NoticeCreate = z.infer<typeof NoticeCreate>;

export interface NoticeRow {
  id: string;
  title: string;
  body: string;
  audience: string;
  status: 'draft' | 'pending' | 'published';
  author: string;
  publishedAt: string | null;
  createdAt: string;
}

// Approvals
export type ApprovalKind = 'leave' | 'fee_waiver' | 'admission' | 'notice';
export interface ApprovalRow {
  id: string;
  kind: ApprovalKind;
  title: string;
  subtitle: string;
  initials: string;
  tone: 'coral' | 'amber' | 'blue' | 'mint';
  status: 'pending' | 'approved' | 'rejected';
  createdAt: string;
  decidedAt: string | null;
}
export const ApprovalDecision = z.object({ decision: z.enum(['approve', 'reject', 'undo']) });
export type ApprovalDecision = z.infer<typeof ApprovalDecision>;

// Timetable
export interface PeriodDef {
  idx: number;
  label: string;
  starts: string;
  ends: string;
  kind: 'period' | 'break' | 'lunch';
}
export interface SlotRow {
  id: string;
  classId: string;
  day: number;
  period: number;
  subjectId: string;
  subjectName: string;
  subjectColor: string;
  teacherId: string;
  teacherName: string;
  room: string | null;
  substituteId: string | null;
  substituteName: string | null;
}
export interface Clash {
  id: string;
  kind: 'teacher';
  teacherId: string;
  teacherName: string;
  day: number;
  period: number;
  slotIds: string[];
  classNames: string[];
  suggestion: { teacherId: string; teacherName: string; reason: string } | null;
}
export interface TimetableView {
  classId: string;
  className: string;
  periods: PeriodDef[];
  slots: SlotRow[];
  clashes: Clash[];
  publishedAt: string | null;
  draftChanges: number;
  version: number;
}
export const SlotPatch = z.object({
  subjectId: z.string().optional(),
  teacherId: z.string().optional(),
  room: z.string().max(20).nullable().optional(),
});
export type SlotPatch = z.infer<typeof SlotPatch>;
export const CoverRequest = z.object({ slotId: z.string(), teacherId: z.string(), date: IsoDate.optional() });
export type CoverRequest = z.infer<typeof CoverRequest>;
export interface TeacherLoad {
  teacherId: string;
  name: string;
  periodsPerWeek: number;
  max: number;
  subjects: string[];
}

// Dashboard
export interface DashboardData {
  greetingName: string;
  dateLabel: string;
  term: { name: string; note: string };
  kpis: {
    present: { value: number; total: number };
    absent: number;
    feesCollectedWeek: number;
    feesPendingTotal: number;
    approvals: number;
  };
  week: AttendanceWeekPoint[];
  feeBreakdown: { collected: number; pending: number; overdue: number; target: number };
  classRolls: { classId: string; name: string; present: number; late: number; absent: number; unmarked: number }[];
  needsYou: ApprovalRow[];
  today: { id: string; time: string; title: string; subtitle: string; state: 'done' | 'now' | 'next' }[];
}

// Search (command palette)
export interface SearchHit {
  group: 'People' | 'Go to' | 'Actions';
  title: string;
  hint: string;
  href: string;
  keys?: string;
}

// Audit
export interface AuditRow {
  id: string;
  at: string;
  actor: string;
  action: string;
  entity: string;
  detail: string;
}
