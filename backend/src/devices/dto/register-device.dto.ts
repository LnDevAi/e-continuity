import { IsString, IsNotEmpty, IsIn } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDeviceDto {
  @ApiProperty({ example: 'Mon PC Bureau' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'desktop_windows', enum: ['mobile', 'desktop_windows', 'desktop_macos', 'tablet'] })
  @IsIn(['mobile', 'desktop_windows', 'desktop_macos', 'tablet'])
  type: string;

  @ApiProperty({ example: 'windows', enum: ['android', 'ios', 'windows', 'macos'] })
  @IsIn(['android', 'ios', 'windows', 'macos'])
  platform: string;

  @ApiProperty({ example: 'device-unique-token-uuid' })
  @IsString()
  @IsNotEmpty()
  deviceToken: string;

  @ApiProperty({ required: false })
  publicKey?: string;
}
