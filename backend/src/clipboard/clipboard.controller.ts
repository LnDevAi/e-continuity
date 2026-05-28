import {
  Controller, Post, Get, Delete,
  Body, Param, UseGuards, Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ClipboardService } from './clipboard.service';
import { CreateClipboardDto } from './dto/create-clipboard.dto';

@ApiTags('clipboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('clipboard')
export class ClipboardController {
  constructor(private readonly clipboardService: ClipboardService) {}

  @Post()
  @ApiOperation({ summary: "Pousser un contenu presse-papier (chiffré, TTL 24h)" })
  create(@Request() req: any, @Body() dto: CreateClipboardDto) {
    return this.clipboardService.create(req.user.id, dto);
  }

  @Get('latest')
  @ApiOperation({ summary: "Dernier item non expiré du presse-papier" })
  getLatest(@Request() req: any) {
    return this.clipboardService.getLatest(req.user.id);
  }

  @Get('history')
  @ApiOperation({ summary: "Historique des 20 derniers items" })
  getHistory(@Request() req: any) {
    return this.clipboardService.getHistory(req.user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: "Supprimer un item du presse-papier" })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.clipboardService.delete(req.user.id, id);
  }
}
