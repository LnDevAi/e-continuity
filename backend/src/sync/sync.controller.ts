import { Controller, Get, Put, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SyncService } from './sync.service';
import { UpdateSyncConfigDto } from './dto/sync-config.dto';

@ApiTags('sync')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Get('config')
  @ApiOperation({ summary: 'Récupérer la configuration de synchronisation' })
  getConfig(@Request() req: any) {
    return this.syncService.getConfig(req.user.id);
  }

  @Put('config')
  @ApiOperation({ summary: 'Mettre à jour les dossiers synchronisés' })
  updateConfig(@Request() req: any, @Body() dto: UpdateSyncConfigDto) {
    return this.syncService.updateConfig(req.user.id, dto);
  }

  @Post('trigger')
  @ApiOperation({ summary: 'Déclencher une synchronisation manuelle' })
  trigger(@Request() req: any) {
    return this.syncService.triggerSync(req.user.id);
  }
}
