import type {
  AttendanceDayPut, ApprovalDecision, ApprovalRow, AssignFee, AttendanceDay, AuditRow, ClassInfo, ContactReveal, CoverRequest, DashboardData, EffectiveConfig, FeeSummary, ImportResult, InvoiceRow,
  LoginRequest, LoginResponse, MessageRequest, NoticeCreate, NoticeRow, Paged, PaymentCreate, SearchHit, SessionUser, SettingsDoc, SettingsPatch, SettingsResponse, ShellData, SlotPatch, StudentCreate, StudentDetail,
  StudentRow, StudentSummary, StudentViews, TeacherLoad, TeacherOption, TimetableView, TokenPair, VerifyRequest,
} from '@edunest/contracts';
import type { Http, Query } from './http';

export interface BrandInfo {
  name: string;
  shortName: string;
  color: string;
  logoText: string;
  tagline: string;
  demoMode: boolean;
  language: string;
}

export type StudentListQuery = {
  query?: string; classId?: string; house?: string; feeStatus?: 'paid' | 'due' | 'overdue'; attendance?: 'low' | 'perfect'; newThisYear?: boolean;
  sort?: 'name' | 'class' | 'attendance' | 'due'; dir?: 'asc' | 'desc'; page?: number; limit?: number;
};

/** Every call the school admin and apps make, typed from the shared contracts. */
export function schoolApi(h: Http) {
  return {
    brand: () => h.get<BrandInfo>('/v1/brand'),
    login: (b: LoginRequest) => h.post<LoginResponse>('/v1/auth/login', b),
    verify: (b: VerifyRequest) => h.post<TokenPair>('/v1/auth/verify', b),
    logout: () => h.post<void>('/v1/auth/logout'),
    me: () => h.get<SessionUser>('/v1/me'),
    config: () => h.get<EffectiveConfig>('/v1/config'),
    shell: () => h.get<ShellData>('/v1/shell'),
    dashboard: (days = 6) => h.get<DashboardData>('/v1/dashboard', { days }),
    search: (q: string) => h.get<SearchHit[]>('/v1/search', { q }),
    classes: () => h.get<ClassInfo[]>('/v1/classes'),
    students: {
      list: (q: StudentListQuery) => h.get<Paged<StudentRow>>('/v1/students', q as Query),
      summary: (q: Pick<StudentListQuery, 'classId' | 'house'>) => h.get<StudentSummary>('/v1/students/summary', q as Query),
      views: () => h.get<StudentViews>('/v1/students/views'),
      detail: (id: string) => h.get<StudentDetail>(`/v1/students/${id}`),
      reveal: (id: string) => h.post<ContactReveal>(`/v1/students/${id}/reveal`),
      create: (b: StudentCreate) => h.post<StudentDetail>('/v1/students', b),
      import: (csv: string) => h.post<ImportResult>('/v1/students/import', { csv }),
      exportCsv: (ids?: string[]) => h.text('/v1/students/export', ids?.length ? { ids: ids.join(',') } : undefined),
      message: (b: MessageRequest) => h.post<{ sent: number }>('/v1/students/message', b),
      assignFee: (b: AssignFee) => h.post<{ created: number }>('/v1/students/assign-fee', b),
    },
    attendance: {
      day: (classId: string, date: string) => h.get<AttendanceDay>('/v1/attendance/day', { classId, date }),
      save: (b: AttendanceDayPut) => h.put<AttendanceDay>('/v1/attendance/day', b),
      remind: () => h.post<{ sent: number; classes: string[] }>('/v1/attendance/remind'),
    },
    fees: {
      summary: () => h.get<FeeSummary>('/v1/fees/summary'),
      invoices: (studentId: string) => h.get<InvoiceRow[]>('/v1/fees/invoices', { studentId }),
      pay: (b: PaymentCreate) => h.post<{ receiptNo: string; amount: number; outstanding: number }>('/v1/fees/payments', b),
      remind: (ids: string[]) => h.post<{ sent: number }>('/v1/fees/reminders', { ids }),
    },
    approvals: {
      needsYou: () => h.get<ApprovalRow[]>('/v1/needs-you'),
      decide: (id: string, b: ApprovalDecision) => h.post<ApprovalRow>(`/v1/approvals/${id}/decision`, b),
    },
    notices: {
      list: () => h.get<NoticeRow[]>('/v1/notices'),
      create: (b: NoticeCreate) => h.post<NoticeRow>('/v1/notices', b),
    },
    timetable: {
      view: (classId: string) => h.get<TimetableView>('/v1/timetable', { classId }),
      loads: (classId: string) => h.get<TeacherLoad[]>('/v1/timetable/loads', { classId }),
      teachers: (slotId: string) => h.get<TeacherOption[]>('/v1/timetable/teachers', { slotId }),
      patch: (id: string, b: SlotPatch) => h.patch<void>(`/v1/timetable/slots/${id}`, b),
      cover: (b: CoverRequest) => h.post<void>('/v1/timetable/cover', b),
      publish: () => h.post<{ families: number; teachers: number; version: number }>('/v1/timetable/publish'),
    },
    settings: {
      get: () => h.get<SettingsResponse>('/v1/settings'),
      patch: (b: SettingsPatch) => h.patch<SettingsDoc>('/v1/settings', b),
      audit: () => h.get<AuditRow[]>('/v1/settings/audit'),
    },
  };
}

export type SchoolApi = ReturnType<typeof schoolApi>;
