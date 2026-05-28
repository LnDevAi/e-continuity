import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { DevicesModule } from './devices/devices.module';
import { SyncModule } from './sync/sync.module';
import { ClipboardModule } from './clipboard/clipboard.module';
import { KillSwitchModule } from './killswitch/killswitch.module';
import { SignalingModule } from './signaling/signaling.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    DevicesModule,
    SyncModule,
    ClipboardModule,
    KillSwitchModule,
    SignalingModule,
  ],
})
export class AppModule {}
