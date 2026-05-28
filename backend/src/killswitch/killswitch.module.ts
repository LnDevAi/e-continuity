import { Module } from '@nestjs/common';
import { KillSwitchController } from './killswitch.controller';
import { KillSwitchService } from './killswitch.service';

@Module({
  controllers: [KillSwitchController],
  providers: [KillSwitchService],
  exports: [KillSwitchService],
})
export class KillSwitchModule {}
