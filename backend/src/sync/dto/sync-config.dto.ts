import { IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateSyncConfigDto {
  @ApiProperty({ example: ['~/Documents', '~/Desktop'] })
  @IsArray()
  @IsString({ each: true })
  syncedPaths: string[];

  @ApiProperty({ example: true })
  @IsBoolean()
  @IsOptional()
  backupEnabled?: boolean;
}
