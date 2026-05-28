import {
  Controller, Post, Get, Delete, Patch,
  Body, Param, UseGuards, Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DevicesService } from './devices.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@ApiTags('devices')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post('register')
  @ApiOperation({ summary: "Enregistrer un nouvel appareil" })
  register(@Request() req: any, @Body() dto: RegisterDeviceDto) {
    return this.devicesService.registerDevice(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: "Liste des appareils de l'utilisateur" })
  findAll(@Request() req: any) {
    return this.devicesService.getUserDevices(req.user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: "Supprimer un appareil enregistré" })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.devicesService.deleteDevice(req.user.id, id);
  }

  @Patch(':id/heartbeat')
  @ApiOperation({ summary: "Mise à jour du statut en ligne (toutes les 30s)" })
  heartbeat(@Request() req: any, @Param('id') id: string) {
    return this.devicesService.heartbeat(req.user.id, id);
  }
}
