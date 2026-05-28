import {
  Controller, Post, Get, Patch,
  Body, Param, UseGuards, Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { KillSwitchService } from './killswitch.service';
import { KillSwitchActionDto } from './dto/killswitch.dto';

@ApiTags('killswitch')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('killswitch')
export class KillSwitchController {
  constructor(private readonly killSwitchService: KillSwitchService) {}

  @Post('lock')
  @ApiOperation({ summary: "Verrouiller un appareil (chiffrement AES-256)" })
  lock(@Request() req: any, @Body() dto: KillSwitchActionDto) {
    return this.killSwitchService.lock(req.user.id, dto);
  }

  @Post('wipe')
  @ApiOperation({ summary: "Effacement sécurisé irréversible (DESTRUCTIF)" })
  wipe(@Request() req: any, @Body() dto: KillSwitchActionDto) {
    return this.killSwitchService.wipe(req.user.id, dto);
  }

  @Get('status/:deviceId')
  @ApiOperation({ summary: "Statut du kill switch pour un appareil" })
  getStatus(@Request() req: any, @Param('deviceId') deviceId: string) {
    return this.killSwitchService.getStatus(req.user.id, deviceId);
  }

  @Patch(':id/executed')
  @ApiOperation({ summary: "Confirmer l'exécution du kill switch par l'appareil cible" })
  markExecuted(@Request() req: any, @Param('id') id: string) {
    return this.killSwitchService.markExecuted(req.user.id, id);
  }
}
