import { Inject, Injectable, Module, type DynamicModule, type OnApplicationShutdown } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { PoolManager, Registry } from '@edunest/tenancy';
import { AuthController, MeController } from './auth/auth.controller.js';
import { AuthService } from './auth/auth.service.js';
import { AuthGuard, PermissionsGuard } from './auth/guards.js';
import { ApiExceptionFilter } from '@edunest/nest-kit';
import { MetricsInterceptor, MetricsService } from './common/metrics.js';
import { ENV, type Env } from './env.js';
import { ApprovalsService } from './school/approvals.service.js';
import { AttendanceService } from './school/attendance.service.js';
import { DashboardService } from './school/dashboard.service.js';
import { FeesService } from './school/fees.service.js';
import {
  ApprovalsController, AttendanceController, ClassesController, DashboardController, FeesController, HealthController, SettingsController, StudentsController, TimetableController,
} from './school/school.controllers.js';
import { StudentsService } from './school/students.service.js';
import { AuditService, Messenger, SettingsService } from './school/support.js';
import { TimetableService } from './school/timetable.service.js';
import { POOLS, REGISTRY, TenantGuard, TenantService } from './tenancy/tenant.js';

const OWNS = Symbol('OWNS');

/** Closes the connections this app opened. A server that shares them with another app leaves them to its owner. */
@Injectable()
class Shutdown implements OnApplicationShutdown {
  constructor(
    @Inject(REGISTRY) private readonly registry: Registry,
    @Inject(POOLS) private readonly pools: PoolManager,
    @Inject(OWNS) private readonly owns: boolean,
  ) {}

  async onApplicationShutdown(): Promise<void> {
    if (!this.owns) return;
    await this.pools.closeAll();
    await this.registry.close();
  }
}

@Module({})
export class AppModule {
  static register(env: Env, shared?: { registry: Registry; pools: PoolManager }): DynamicModule {
    const registry = shared?.registry ?? new Registry({ url: env.REGISTRY_DATABASE_URL, secret: env.SECRETS_KEY });
    const pools = shared?.pools ?? new PoolManager();
    return {
      module: AppModule,
      controllers: [
        AuthController, MeController, ClassesController, StudentsController, AttendanceController, FeesController, ApprovalsController,
        TimetableController, DashboardController, SettingsController, HealthController,
      ],
      providers: [
        { provide: ENV, useValue: env },
        { provide: REGISTRY, useValue: registry },
        { provide: POOLS, useValue: pools },
        { provide: OWNS, useValue: !shared },
        Shutdown,
        TenantService, AuthService, AuditService, Messenger, SettingsService, StudentsService, AttendanceService, FeesService, ApprovalsService, TimetableService, DashboardService, MetricsService,
        // Order matters: find the school, then the person, then what they may do.
        { provide: APP_GUARD, useClass: TenantGuard },
        { provide: APP_GUARD, useClass: AuthGuard },
        { provide: APP_GUARD, useClass: PermissionsGuard },
        { provide: APP_FILTER, useClass: ApiExceptionFilter },
        { provide: APP_INTERCEPTOR, useClass: MetricsInterceptor },
      ],
      exports: [TenantService, REGISTRY, POOLS],
    };
  }
}
