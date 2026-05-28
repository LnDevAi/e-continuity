import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class KillSwitchActionDto {
  @ApiProperty({ description: "ID de l'appareil cible" })
  @IsString()
  @IsNotEmpty()
  targetDeviceId: string;
}
