import { IsString, IsNotEmpty, IsIn, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateClipboardDto {
  @ApiProperty({ description: 'Contenu chiffré AES-256 (Base64)' })
  @IsString()
  @IsNotEmpty()
  content: string;

  @ApiProperty({ example: 'text', enum: ['text', 'url', 'image_url'] })
  @IsIn(['text', 'url', 'image_url'])
  contentType: string;

  @ApiProperty({ required: false, description: "ID de l'appareil source" })
  @IsOptional()
  @IsString()
  sourceDevice?: string;
}
