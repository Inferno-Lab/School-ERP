import { z } from 'zod';

/** Every action a role can be allowed to do. The admin hides UI and the API refuses requests from this one list. */
export const PERMISSIONS = [
  'students.read',
  'students.write',
  'attendance.read',
  'attendance.mark',
  'fees.read',
  'fees.collect',
  'fees.waive',
  'notices.read',
  'notices.write',
  'notices.publish',
  'approvals.read',
  'approvals.decide',
  'timetable.read',
  'timetable.edit',
  'timetable.publish',
  'settings.read',
  'settings.write',
  'roles.manage',
  'staff.read',
  'staff.write',
  'audit.read',
  'reports.read',
] as const;
export const Permission = z.enum(PERMISSIONS);
export type Permission = z.infer<typeof Permission>;

export interface PermissionInfo {
  key: Permission;
  area: string;
  label: string;
  /** Needs a second person to approve when the school turns approvals on. */
  sensitive?: boolean;
}

export const PERMISSION_CATALOG: PermissionInfo[] = [
  { key: 'students.read', area: 'People', label: 'See students and guardians' },
  { key: 'students.write', area: 'People', label: 'Add and edit students' },
  { key: 'staff.read', area: 'People', label: 'See staff' },
  { key: 'staff.write', area: 'People', label: 'Add and edit staff', sensitive: true },
  { key: 'attendance.read', area: 'Attendance', label: 'See attendance' },
  { key: 'attendance.mark', area: 'Attendance', label: 'Mark attendance' },
  { key: 'fees.read', area: 'Fees', label: 'See fees and payments' },
  { key: 'fees.collect', area: 'Fees', label: 'Record payments' },
  { key: 'fees.waive', area: 'Fees', label: 'Waive or reduce fees', sensitive: true },
  { key: 'notices.read', area: 'Notices', label: 'See notices' },
  { key: 'notices.write', area: 'Notices', label: 'Write notices' },
  { key: 'notices.publish', area: 'Notices', label: 'Publish notices to families' },
  { key: 'approvals.read', area: 'Approvals', label: 'See the approvals queue' },
  { key: 'approvals.decide', area: 'Approvals', label: 'Approve or decline requests' },
  { key: 'timetable.read', area: 'Timetable', label: 'See the timetable' },
  { key: 'timetable.edit', area: 'Timetable', label: 'Edit periods and cover' },
  { key: 'timetable.publish', area: 'Timetable', label: 'Publish the timetable' },
  { key: 'settings.read', area: 'Settings', label: 'See school settings' },
  { key: 'settings.write', area: 'Settings', label: 'Change school settings', sensitive: true },
  { key: 'roles.manage', area: 'Settings', label: 'Change roles and access', sensitive: true },
  { key: 'audit.read', area: 'Settings', label: 'Read the audit log' },
  { key: 'reports.read', area: 'Reports', label: 'See reports' },
];

export interface RoleTemplate {
  key: string;
  name: string;
  description: string;
  permissions: Permission[];
}

const ALL: Permission[] = [...PERMISSIONS];

export const ROLE_TEMPLATES: RoleTemplate[] = [
  { key: 'principal', name: 'Principal', description: 'Everything in the school.', permissions: ALL },
  {
    key: 'office',
    name: 'Office staff',
    description: 'Admissions, people, notices and the timetable.',
    permissions: [
      'students.read', 'students.write', 'staff.read', 'attendance.read', 'notices.read', 'notices.write',
      'approvals.read', 'timetable.read', 'timetable.edit', 'reports.read',
    ],
  },
  {
    key: 'accountant',
    name: 'Accountant',
    description: 'Fees, payments and reports.',
    permissions: ['students.read', 'fees.read', 'fees.collect', 'reports.read', 'notices.read'],
  },
  {
    key: 'teacher',
    name: 'Teacher',
    description: 'Marks attendance and sees their classes.',
    permissions: ['students.read', 'attendance.read', 'attendance.mark', 'notices.read', 'timetable.read'],
  },
];

export function hasPermission(granted: readonly string[], needed: Permission): boolean {
  return granted.includes(needed);
}
